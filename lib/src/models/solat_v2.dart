import 'package:waktu_solat_lib/src/models/prayer_time.dart';

/// Represents the response structure for prayer times fetched from the API
/// (endpoints `/v2/solat/zone/{zone}` and `/v2/solat/gps/{lat}/{long}`).
class SolatV2 {
  /// The prayer zone code (e.g., "SGR01").
  final String zone;

  /// The source or origin of the prayer time data (e.g., "JAKIM"). May be null.
  final String? origin;

  /// A list of [PrayerTime] objects, typically containing prayer times for a specific month or period.
  final List<PrayerTime> prayerTime;

  /// Creates an instance of [SolatV2].
  SolatV2({
    required this.zone,
    this.origin,
    required this.prayerTime,
  });

  /// Creates a [SolatV2] instance from a JSON map.
  ///
  /// Throws a [FormatException] if the JSON structure is invalid, missing required fields,
  /// or if the `prayerTime` list cannot be parsed.
  factory SolatV2.fromJson(Map<String, dynamic> json) {
    // Validate required top-level fields
    if (json['zone'] is! String) {
      throw const FormatException('Invalid or missing field (zone) in SolatV2 JSON');
    }

    // Validate and parse the prayerTime list
    // API uses 'prayers', model uses 'prayerTime'
    if (json['prayers'] is! List || json['prayers'] == null) {
      throw const FormatException('Missing or invalid field: prayers in SolatV2 JSON');
    }
    List<PrayerTime> prayerTimes = [];
    try {
      prayerTimes = (json['prayers'] as List) // Parse from 'prayers' key
          .map((item) => PrayerTime.fromJson(item as Map<String, dynamic>))
          .toList();
    } on FormatException catch (e) { // Catch only FormatExceptions from PrayerTime.fromJson
      throw FormatException('Failed to parse prayerTime list in SolatV2 JSON: $e');
    } catch (e) { // Catch other potential errors during list processing
      throw FormatException('An unexpected error occurred while parsing prayerTime list: $e');
    }

    return SolatV2(
      zone: json['zone'] as String,
      origin: json['origin'] as String?, // Origin is optional and nullable
      prayerTime: prayerTimes,
    );
  }
}
