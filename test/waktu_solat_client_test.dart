import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:waktu_solat_lib/src/waktu_solat_client.dart';
import 'package:waktu_solat_lib/src/models/state.dart';
import 'package:waktu_solat_lib/src/models/solat_v2.dart';
import 'package:waktu_solat_lib/src/models/zone_info.dart';

// Create a mock HTTP client
class MockHttpClient extends http.BaseClient {
  final Map<Uri, http.Response> _responses = {};
  final Map<Uri, Exception> _exceptions = {};

  void mockGet(Uri uri, http.Response response) {
    _responses[uri] = response;
  }

  void mockGetError(Uri uri, Exception exception) {
    _exceptions[uri] = exception;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final uri = request.url;
    
    if (_exceptions.containsKey(uri)) {
      throw _exceptions[uri]!;
    }
    
    if (_responses.containsKey(uri)) {
      final response = _responses[uri]!;
      return http.StreamedResponse(
        Stream.value(response.bodyBytes),
        response.statusCode,
        headers: response.headers,
      );
    }
    
    throw Exception('No mock response found for $uri');
  }
}

void main() {
  late MockHttpClient mockClient;
  late WaktuSolatClient client;

  // Base URL for mocking
  const String baseUrl = 'https://api.waktusolat.app';

  setUp(() {
    // Create a new mock client for each test.
    mockClient = MockHttpClient();
    // Create the client instance with the mock HTTP client.
    client = WaktuSolatClient(httpClient: mockClient);
  });

  group('WaktuSolatClient', () {
    group('getStates', () {
      final statesUri = Uri.parse('$baseUrl/v2/negeri');
      const mockJsonResponse = '''
        [
          {"negeri":"JOHOR","zones":["jhr01","jhr02","jhr03","jhr04"]},
          {"negeri":"KEDAH","zones":["kdh01","kdh02","kdh03","kdh04","kdh05","kdh06","kdh07"]}
        ]
      ''';

      test('returns a List<State> if the http call completes successfully', () async {
        // Arrange
        mockClient.mockGet(statesUri, http.Response(mockJsonResponse, 200));

        // Act
        final states = await client.getStates();

        // Assert
        expect(states, isA<List<State>>());
        expect(states.length, 2);
        expect(states[0].negeri, 'JOHOR');
        expect(states[0].zones, contains('jhr01'));
        expect(states[1].negeri, 'KEDAH');
        expect(states[1].zones, contains('kdh01'));
      });

      test('throws a WaktuSolatApiException if the http call returns an error status code', () async {
        // Arrange
        mockClient.mockGet(statesUri, http.Response('{"message":"Server Error"}', 500));

        // Act & Assert
        expect(() => client.getStates(), throwsA(isA<WaktuSolatApiException>()));
      });

      test('throws a WaktuSolatApiException if the http call throws ClientException', () async {
        // Arrange
        mockClient.mockGetError(statesUri, http.ClientException('Connection failed'));

        // Act & Assert
        expect(() => client.getStates(), throwsA(isA<WaktuSolatApiException>()));
      });

      test('throws a WaktuSolatApiException if the response format is incorrect (not a list)', () async {
        // Arrange
        const badJsonResponse = '{"negeri":"JOHOR","zones":["jhr01"]}'; // map, not list
        mockClient.mockGet(statesUri, http.Response(badJsonResponse, 200));

        // Act & Assert
        expect(() => client.getStates(), throwsA(isA<WaktuSolatApiException>()));
      });
    });

    group('getZones', () {
      final zonesUri = Uri.parse('$baseUrl/zones');
      const mockJsonResponse = '''
        [
          {"jakimCode":"jhr01","negeri":"JOHOR","daerah":"Pulau Aur dan Pulau Pemanggil"},
          {"jakimCode":"jhr02","negeri":"JOHOR","daerah":"Kota Tinggi, Mersing, Johor Bahru"},
          {"jakimCode":"kdh01","negeri":"KEDAH","daerah":"Kota Setar, Kubang Pasu, Pokok Sena"},
          {"jakimCode":"sgr01","negeri":"SELANGOR","daerah":"Gombak, Petaling, Sepang, Hulu Langat, Hulu Selangor, S.Alam"}
        ]
      ''';

      test('returns a List<ZoneInfo> if the http call completes successfully', () async {
        // Arrange
        mockClient.mockGet(zonesUri, http.Response(mockJsonResponse, 200));

        // Act
        final zones = await client.getZones();

        // Assert
        expect(zones, isA<List<ZoneInfo>>());
        expect(zones.length, 4);
        expect(zones[0].jakimCode, 'jhr01');
        expect(zones[0].negeri, 'JOHOR');
        expect(zones[0].daerah, 'Pulau Aur dan Pulau Pemanggil');
        expect(zones[3].jakimCode, 'sgr01');
      });

      test('throws a WaktuSolatApiException if the http call returns an error status code', () async {
        // Arrange
        mockClient.mockGet(zonesUri, http.Response('{"message":"Not Found"}', 404));

        // Act & Assert
        expect(() => client.getZones(), throwsA(isA<WaktuSolatApiException>()));
      });

      test('throws a WaktuSolatApiException if the http call throws ClientException', () async {
        // Arrange
        mockClient.mockGetError(zonesUri, http.ClientException('Network error'));

        // Act & Assert
        expect(() => client.getZones(), throwsA(isA<WaktuSolatApiException>()));
      });
    });

    group('getPrayerTimesByZone', () {
      const testZone = 'sgr01';
      final zoneUri = Uri.parse('$baseUrl/v2/solat/$testZone');
      final zoneUriWithParams = Uri.parse('$baseUrl/v2/solat/$testZone?year=2025&month=3');

      const successResponseJson = '''{
        "zone": "sgr01",
        "origin": "JAKIM",
        "prayers": [
          {
            "hijri": "1446-09-01",
            "date": "2025-03-01",
            "day": 6,
            "imsak": 1425480000,
            "fajr": 1425480480,
            "syuruk": 1425485460,
            "dhuhr": 1425507480,
            "asr": 1425518340,
            "maghrib": 1425529800,
            "isha": 1425533940
          }
        ]
      }''';
      
      const errorResponseJson = '''{
        "status": "error",
        "message": "Error, Zone not found, Please use /zones"
      }''';

      test('returns SolatV2 on success (200 OK)', () async {
        mockClient.mockGet(zoneUri, http.Response(successResponseJson, 200));

        final result = await client.getPrayerTimesByZone(testZone);

        expect(result, isA<SolatV2>());
        expect(result.zone, testZone);
        expect(result.origin, 'JAKIM');
        expect(result.prayerTime.length, 1);
        expect(result.prayerTime[0].date, '2025-03-01');
      });

      test('returns SolatV2 on success with year/month params (200 OK)', () async {
        mockClient.mockGet(zoneUriWithParams, http.Response(successResponseJson, 200));

        final result = await client.getPrayerTimesByZone(testZone, year: 2025, month: 3);

        expect(result, isA<SolatV2>());
        expect(result.zone, testZone);
      });

      test('throws WaktuSolatApiException on API error (200 OK with error JSON)', () async {
        mockClient.mockGet(zoneUri, http.Response(errorResponseJson, 200));

        expect(
          () => client.getPrayerTimesByZone(testZone),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.message, 'message', contains('Zone not found'))
          ),
        );
      });

      test('throws WaktuSolatApiException on server error (500)', () async {
        mockClient.mockGet(zoneUri, http.Response('Server Error', 500));

        expect(
          () => client.getPrayerTimesByZone(testZone),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', contains('API Request failed with status 500'))
          ),
        );
      });

      test('throws WaktuSolatApiException on network error', () async {
        const exceptionMessage = 'Could not connect';
        mockClient.mockGetError(zoneUri, http.ClientException(exceptionMessage));

        expect(
          () => client.getPrayerTimesByZone(testZone),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.message, 'message', contains('Network error: ClientException: $exceptionMessage'))
          ),
        );
      });

      test('throws WaktuSolatApiException on invalid JSON response', () async {
        mockClient.mockGet(zoneUri, http.Response('invalid json', 200));

        expect(
          () => client.getPrayerTimesByZone(testZone),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.message, 'message', contains('Failed to parse API response'))
          ),
        );
      });

      test('throws WaktuSolatApiException on malformed success JSON (missing fields)', () async {
        const malformedJson = '{"zone": "sgr01", "origin": "JAKIM"}'; // Missing prayers
        mockClient.mockGet(zoneUri, http.Response(malformedJson, 200));

        expect(
          () => client.getPrayerTimesByZone(testZone),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.message, 'message', contains('Failed to parse SolatV2 response'))
          ),
        );
      });
    });

    group('getPrayerTimesByGps', () {
      const testLat = 3.0738;
      const testLong = 101.5183;
      final gpsUri = Uri.parse('$baseUrl/v2/solat/gps/$testLat/$testLong');
      final gpsUriWithParams = Uri.parse('$baseUrl/v2/solat/gps/$testLat/$testLong?year=2025&month=3');

      const successResponseJsonGps = '''{
        "zone": "WLP01",
        "origin": "JAKIM",
        "prayers": [
          {
            "hijri": "1446-09-01",
            "date": "2025-03-01",
            "day": 6,
            "imsak": 1425480000,
            "fajr": 1425480480,
            "syuruk": 1425485460,
            "dhuhr": 1425507480,
            "asr": 1425518340,
            "maghrib": 1425529800,
            "isha": 1425533940
          }
        ]
      }''';

      const errorResponseJsonGps = '''{
        "status": "error",
        "message": "Invalid coordinates or no data available."
      }''';

      test('returns SolatV2 on success (200 OK)', () async {
        mockClient.mockGet(gpsUri, http.Response(successResponseJsonGps, 200));

        final result = await client.getPrayerTimesByGps(testLat, testLong);

        expect(result, isA<SolatV2>());
        expect(result.zone, 'WLP01'); // Zone determined by API based on GPS
        expect(result.origin, 'JAKIM');
        expect(result.prayerTime.length, 1);
        expect(result.prayerTime[0].date, '2025-03-01');
      });

      test('returns SolatV2 on success with year/month params (200 OK)', () async {
        mockClient.mockGet(gpsUriWithParams, http.Response(successResponseJsonGps, 200));

        final result = await client.getPrayerTimesByGps(testLat, testLong, year: 2025, month: 3);

        expect(result, isA<SolatV2>());
        expect(result.zone, 'WLP01');
      });

      test('throws WaktuSolatApiException on API error (200 OK with error JSON)', () async {
        mockClient.mockGet(gpsUri, http.Response(errorResponseJsonGps, 200));

        expect(
          () => client.getPrayerTimesByGps(testLat, testLong),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.message, 'message', contains('Invalid coordinates'))
          ),
        );
      });

      test('throws WaktuSolatApiException on server error (500)', () async {
        mockClient.mockGet(gpsUri, http.Response('Internal Server Error', 500));

        expect(
          () => client.getPrayerTimesByGps(testLat, testLong),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.statusCode, 'statusCode', 500)
            .having((e) => e.message, 'message', contains('API Request failed with status 500'))
          ),
        );
      });

      test('throws WaktuSolatApiException on network error', () async {
        const exceptionMessage = 'Could not connect';
        mockClient.mockGetError(gpsUri, http.ClientException(exceptionMessage));

        expect(
          () => client.getPrayerTimesByGps(testLat, testLong),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.message, 'message', contains('Network error: ClientException: $exceptionMessage'))
          ),
        );
      });

      test('throws WaktuSolatApiException on invalid JSON response', () async {
        mockClient.mockGet(gpsUri, http.Response('not json', 200));

        expect(
          () => client.getPrayerTimesByGps(testLat, testLong),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.message, 'message', contains('Failed to parse API response'))
          ),
        );
      });

      test('throws WaktuSolatApiException on malformed success JSON (missing prayers)', () async {
        const malformedJson = '{"zone": "WLP01", "origin": "JAKIM"}'; // Missing prayers
        mockClient.mockGet(gpsUri, http.Response(malformedJson, 200));

        expect(
          () => client.getPrayerTimesByGps(testLat, testLong),
          throwsA(isA<WaktuSolatApiException>()
            .having((e) => e.message, 'message', contains('Failed to parse SolatV2'))
          ),
        );
      });
    });
  });
}
