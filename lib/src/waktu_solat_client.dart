import 'dart:convert';
import 'package:http/http.dart' as http;

import 'models/state.dart'; // Import the State model
import 'models/solat_v2.dart'; // Import the SolatV2 model
import 'models/api_error.dart'; // Import the ApiError model
import 'models/zone_info.dart'; // Import the ZoneInfo model
import 'models/prayer_time.dart'; // Import the PrayerTime model

/// Exception class for Waktu Solat API related errors.
class WaktuSolatApiException implements Exception {
  /// The error message describing the issue.
  final String message;

  /// The HTTP status code associated with the error, if available.
  final int? statusCode;

  /// The detailed API error object, if available (parsed from the response body).
  final ApiError? apiError;

  /// Creates a [WaktuSolatApiException].
  ///
  /// [message] is required. [statusCode] and [apiError] are optional.
  WaktuSolatApiException(this.message, {this.statusCode, this.apiError});

  @override
  String toString() {
    return 'WaktuSolatApiException: $message${statusCode != null ? ' (Status Code: $statusCode)' : ''}';
  }
}

/// A client for interacting with the Waktu Solat API v2 (https://api.waktusolat.app/docs).
///
/// Provides methods to fetch prayer times, state lists, and zone lists.
class WaktuSolatClient {
  /// The base URL for the Waktu Solat API.
  static const String _baseUrl = 'https://api.waktusolat.app';

  /// The HTTP client used for making requests.
  /// Defaults to `http.Client()` if not provided.
  final http.Client _httpClient;

  /// Indicates whether the client owns the [_httpClient] instance.
  /// If true, the client will close the http client when disposed.
  final bool _isHttpClientOwned;

  /// Creates a new [WaktuSolatClient].
  ///
  /// If [httpClient] is provided, it will be used for requests.
  /// Otherwise, a new [http.Client] instance is created.
  WaktuSolatClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client(),
        _isHttpClientOwned = httpClient == null;

  /// Closes the HTTP client if it was created internally.
  ///
  /// Call this method when the client is no longer needed to release resources,
  /// but only if you didn't provide your own `httpClient` instance.
  void dispose() {
    if (_isHttpClientOwned) {
      _httpClient.close();
    }
  }

  /// Internal helper method to perform a GET request and handle common errors.
  ///
  /// Takes a [uri] to request.
  /// Returns the decoded JSON response (dynamic type, could be Map or List).
  ///
  /// Throws [WaktuSolatApiException] for:
  ///   - Non-200 status codes (parsing `ApiError` if possible).
  ///   - `status: "error"` in the JSON response body (even with 200 OK).
  ///   - Network errors (`ClientException`).
  ///   - JSON decoding errors (`FormatException`).
  ///   - Other unexpected errors.
  Future<dynamic> _getRequest(String endpoint,
      {Map<String, String>? queryParameters}) async {
    final url = Uri.parse('$_baseUrl$endpoint')
        .replace(queryParameters: queryParameters);
    http.Response response;

    try {
      response = await _httpClient.get(url);

      // Check for non-200 status codes first
      if (response.statusCode >= 400) {
        // Try to parse as ApiError if possible, otherwise throw generic error
        try {
          final Map<String, dynamic> errorJson = jsonDecode(response.body);
          final apiError = ApiError.fromJson(errorJson);
          throw WaktuSolatApiException('API Error: ${apiError.message}',
              statusCode: response.statusCode, apiError: apiError);
        } catch (_) {
          // If parsing errorJson fails or it's not the expected format
          throw WaktuSolatApiException(
              'API Request failed with status ${response.statusCode}. Response: ${response.body}',
              statusCode: response.statusCode);
        }
      }

      // Proceed to decode JSON only for successful (2xx) responses
      final jsonResponse = jsonDecode(response.body);

      // Handle potential API errors returned with 200 OK (check for "status":"error")
      if (jsonResponse is Map<String, dynamic> &&
          jsonResponse['status'] == 'error') {
        final apiError = ApiError.fromJson(jsonResponse);
        throw WaktuSolatApiException(apiError.message,
            statusCode: response.statusCode, apiError: apiError);
      }

      return jsonResponse;
    } on http.ClientException catch (e) {
      // Handle network/connection errors
      throw WaktuSolatApiException('Network error: $e');
    } on FormatException catch (e) {
      // Handle JSON decoding errors
      throw WaktuSolatApiException('Failed to parse API response: $e');
    } catch (e) {
      // Rethrow other specific exceptions like WaktuSolatApiException or rethrow unexpected ones
      if (e is WaktuSolatApiException) rethrow;
      throw WaktuSolatApiException('An unexpected error occurred: $e');
    }
  }

  /// Fetches the list of all Malaysian states and their corresponding zones.
  ///
  /// Corresponds to the `/v2/negeri` endpoint.
  ///
  /// Returns a `Future<List<State>>` upon success.
  /// Throws [WaktuSolatApiException] on failure.
  Future<List<State>> getStates() async {
    final response = await _getRequest('/v2/negeri');

    if (response is List) {
      try {
        return response
            .map((stateJson) =>
                State.fromJson(stateJson as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Handle potential parsing errors within the list
        throw WaktuSolatApiException('Failed to parse states list: $e');
      }
    } else {
      // Handle unexpected response format
      throw WaktuSolatApiException(
          'Unexpected response format received for /v2/negeri. Expected a List.');
    }
  }

  /// Fetches the list of all prayer zone information.
  ///
  /// Corresponds to the `/zones` endpoint.
  /// See zones visually at https://peta.waktusolat.app
  ///
  /// Returns a `Future<List<ZoneInfo>>` containing detailed zone info upon success.
  /// Throws [WaktuSolatApiException] on failure.
  Future<List<ZoneInfo>> getZones() async {
    final response = await _getRequest('/zones');

    if (response is List) {
      try {
        // Parse the list of JSON objects into ZoneInfo objects
        return response
            .map((item) => ZoneInfo.fromJson(item as Map<String, dynamic>))
            .toList();
      } catch (e) {
        // Handle potential parsing errors (e.g., invalid item format)
        throw WaktuSolatApiException(
            'Failed to parse zone info list response: $e');
      }
    } else {
      // Handle unexpected response format
      throw WaktuSolatApiException(
          'Unexpected response format received for /zones. Expected a List of zone objects.');
    }
  }

  /// Fetches prayer times for a specific zone, optionally for a given year and month.
  ///
  /// Corresponds to the `/v2/solat/zone/{zone}` endpoint.
  ///
  /// Parameters:
  ///   - [zone]: The zone code (e.g., "SGR01"). A list of valid zones can be obtained from [getZones] or [getStates].
  ///   - [year]: Optional. The year for which to fetch prayer times (e.g., 2024).
  ///             If omitted, the API defaults to the current year.
  ///   - [month]: Optional. The month for which to fetch prayer times (1-12).
  ///             If omitted, the API defaults to the current month.
  ///
  /// Returns a `Future<SolatV2>` containing the prayer times and metadata upon success.
  /// Throws [WaktuSolatApiException] on failure (e.g., invalid zone, network error).
  Future<SolatV2> getPrayerTimesByZone(String zone,
      {int? year, int? month}) async {
    final Map<String, String> queryParameters = {};
    if (year != null) queryParameters['year'] = year.toString();
    if (month != null) queryParameters['month'] = month.toString();

    try {
      final jsonResponse = await _getRequest('/v2/solat/$zone',
          queryParameters: queryParameters.isEmpty ? null : queryParameters);
      // _getRequest now handles JSON parsing and basic API errors
      // We only need to handle the specific SolatV2.fromJson parsing here
      return SolatV2.fromJson(jsonResponse as Map<String, dynamic>);
    } on FormatException catch (e) {
      // Catch FormatExceptions specifically from SolatV2.fromJson
      throw WaktuSolatApiException('Failed to parse SolatV2 response: $e');
    } catch (e) {
      // Rethrow WaktuSolatApiException from _getRequest or other unexpected errors
      rethrow;
    }
  }

  /// Fetches prayer times based on GPS coordinates, optionally for a given year and month.
  ///
  /// Corresponds to the `/v2/solat/gps/{lat}/{long}` endpoint.
  ///
  /// Parameters:
  ///   - [latitude]: The latitude coordinate.
  ///   - [longitude]: The longitude coordinate.
  ///   - [year]: Optional. The year for which to fetch prayer times (e.g., 2024).
  ///             If omitted, the API defaults to the current year.
  ///   - [month]: Optional. The month for which to fetch prayer times (1-12).
  ///             If omitted, the API defaults to the current month.
  ///
  /// Returns a `Future<SolatV2>` containing the prayer times and metadata upon success.
  /// Throws [WaktuSolatApiException] on failure (e.g., invalid coordinates, network error).
  Future<SolatV2> getPrayerTimesByGps(double latitude, double longitude,
      {int? year, int? month}) async {
    final Map<String, String> queryParameters = {};
    if (year != null) queryParameters['year'] = year.toString();
    if (month != null) queryParameters['month'] = month.toString();

    final endpoint = '/v2/solat/gps/$latitude/$longitude';

    try {
      final jsonResponse = await _getRequest(endpoint,
          queryParameters: queryParameters.isEmpty ? null : queryParameters);
      // Use the same SolatV2 model, as the response structure is expected to be identical
      return SolatV2.fromJson(jsonResponse as Map<String, dynamic>);
    } on FormatException catch (e) {
      // Catch FormatExceptions specifically from SolatV2.fromJson
      throw WaktuSolatApiException('Failed to parse SolatV2 response: $e');
    } catch (e) {
      // Rethrow WaktuSolatApiException from _getRequest or other unexpected errors
      rethrow;
    }
  }

  /// Fetches prayer times for a specific date.
  ///
  /// This is a convenience method that fetches prayer times for the month containing
  /// the specified date and then filters out the specific day's prayer time.
  ///
  /// Parameters:
  ///   - [zone]: The zone code (e.g., "SGR01"). A list of valid zones can be obtained from [getZones] or [getStates].
  ///   - [date]: The specific date for which to fetch prayer times (e.g., DateTime(2025, 4, 15)).
  ///
  /// Returns a `Future<PrayerTime>` containing the prayer times for the specified date upon success.
  /// Returns `null` if no prayer time is found for the specified date.
  /// Throws [WaktuSolatApiException] on failure (e.g., invalid zone, network error).
  Future<PrayerTime?> getPrayerTimeByDate(String zone, DateTime date) async {
    // Extract year and month from the date
    final year = date.year;
    final month = date.month;
    final day = date.day;

    // Get prayer times for the entire month
    final solatV2 = await getPrayerTimesByZone(zone, year: year, month: month);

    // Find the prayer time for the specific date
    // First try to match by the Gregorian date string (YYYY-MM-DD)
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Look for a prayer time with a matching date string
    PrayerTime? prayerTime = solatV2.prayerTime.firstWhere(
      (pt) => pt.date == dateString,
      orElse: () =>
          PrayerTime(hijri: '', day: -1), // Dummy value to indicate not found
    );

    // If not found by date string, try to find by day of month
    if (prayerTime.day == -1) {
      prayerTime = solatV2.prayerTime.firstWhere(
        (pt) => pt.day == day,
        orElse: () =>
            PrayerTime(hijri: '', day: -1), // Dummy value to indicate not found
      );
    }

    // Return null if no matching prayer time was found
    return prayerTime.day == -1 ? null : prayerTime;
  }

  /// Fetches prayer times for a specific date using GPS coordinates.
  ///
  /// This is a convenience method that fetches prayer times for the month containing
  /// the specified date and then filters out the specific day's prayer time.
  ///
  /// Parameters:
  ///   - [latitude]: The latitude coordinate.
  ///   - [longitude]: The longitude coordinate.
  ///   - [date]: The specific date for which to fetch prayer times (e.g., DateTime(2025, 4, 15)).
  ///
  /// Returns a `Future<PrayerTime>` containing the prayer times for the specified date upon success.
  /// Returns `null` if no prayer time is found for the specified date.
  /// Throws [WaktuSolatApiException] on failure (e.g., invalid coordinates, network error).
  Future<PrayerTime?> getPrayerTimeByDateGps(
      double latitude, double longitude, DateTime date) async {
    // Extract year and month from the date
    final year = date.year;
    final month = date.month;
    final day = date.day;

    // Get prayer times for the entire month
    final solatV2 = await getPrayerTimesByGps(latitude, longitude,
        year: year, month: month);

    // Find the prayer time for the specific date
    // First try to match by the Gregorian date string (YYYY-MM-DD)
    final dateString =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    // Look for a prayer time with a matching date string
    PrayerTime? prayerTime = solatV2.prayerTime.firstWhere(
      (pt) => pt.date == dateString,
      orElse: () =>
          PrayerTime(hijri: '', day: -1), // Dummy value to indicate not found
    );

    // If not found by date string, try to find by day of month
    if (prayerTime.day == -1) {
      prayerTime = solatV2.prayerTime.firstWhere(
        (pt) => pt.day == day,
        orElse: () =>
            PrayerTime(hijri: '', day: -1), // Dummy value to indicate not found
      );
    }

    // Return null if no matching prayer time was found
    return prayerTime.day == -1 ? null : prayerTime;
  }
}
