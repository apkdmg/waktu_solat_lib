/// Represents the prayer times for a single day.
class PrayerTime {
  /// Hijri date string (format: YYYY-MM-DD).
  final String hijri;

  /// Gregorian date string (format: YYYY-MM-DD). May be null from some endpoints.
  final String? date;

  /// Day of the month (integer).
  final int day;

  /// Imsak time as Unix timestamp (seconds since epoch).
  final int? imsak;

  /// Fajr (Subuh) time as Unix timestamp (seconds since epoch).
  final int? fajr;

  /// Syuruk time as Unix timestamp (seconds since epoch).
  final int? syuruk;

  /// Dhuhr (Zohor) time as Unix timestamp (seconds since epoch).
  final int? dhuhr;

  /// Asr time as Unix timestamp (seconds since epoch).
  final int? asr;

  /// Maghrib time as Unix timestamp (seconds since epoch).
  final int? maghrib;

  /// Isha time as Unix timestamp (seconds since epoch).
  final int? isha;

  /// Isyraq time, calculated as 15 minutes after Syuruk.
  final int? isyraq;

  /// Creates an instance of [PrayerTime].
  PrayerTime({
    required this.hijri,
    this.date, // Optional
    required this.day, // Required int
    this.imsak,
    this.fajr,
    this.syuruk,
    this.dhuhr,
    this.asr,
    this.maghrib,
    this.isha,
    this.isyraq,
  });

  /// Creates a [PrayerTime] instance from a JSON map.
  ///
  /// Throws a [FormatException] if the JSON structure is invalid or missing required fields,
  /// or if fields have incorrect types (expects Strings for date/day, ints for times).
  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    // Validate String fields
    final requiredStringFields = ['hijri'];
    for (final field in requiredStringFields) {
      if (json[field] is! String) {
        throw FormatException('Invalid or missing String field: $field in PrayerTime JSON');
      }
    }

    // Validate nullable String field 'date'
    if (json.containsKey('date') && json['date'] != null && json['date'] is! String) {
      throw const FormatException('Invalid field type: date (must be String or null) in PrayerTime JSON');
    }

    // Validate Int fields
    final requiredIntFields = ['day'];
    final nullableIntFields = ['imsak', 'fajr', 'syuruk', 'dhuhr', 'asr', 'maghrib', 'isha', 'isyraq'];

    // Validate required int field 'day'
    for (final field in requiredIntFields) {
      if (json[field] is! int) {
        throw FormatException('Invalid or missing Int field: $field in PrayerTime JSON (got ${json[field].runtimeType})');
      }
    }

    // Validate nullable int fields (prayer times)
    for (final field in nullableIntFields) {
      // Allow null, but if present, must be int (or string int for legacy)
      if (json.containsKey(field) && json[field] != null && json[field] is! int) {
        // Attempt conversion if it's a String representation of an int
        if (json[field] is String) {
          final parsedInt = int.tryParse(json[field] as String);
          if (parsedInt != null) {
            json[field] = parsedInt; // Update json map in place if conversion successful
          } else {
            throw FormatException('Invalid non-integer String field: $field in PrayerTime JSON');
          }
        } else {
          throw FormatException('Invalid or missing Int field: $field in PrayerTime JSON (got ${json[field].runtimeType})');
        }
      }
    }

    // Get initial values from JSON, parsing as nullable ints
    String? hijri = json['hijri'] as String?;
    String? date = json['date'] as String?;
    int? day = json['day'] as int?; // Already validated as required int
    int? initialImsak = json['imsak'] as int?;
    int? fajr = json['fajr'] as int?;
    int? syuruk = json['syuruk'] as int?;
    int? dhuhr = json['dhuhr'] as int?;
    int? asr = json['asr'] as int?;
    int? maghrib = json['maghrib'] as int?;
    int? isha = json['isha'] as int?;

    // Note: isyraq is calculated, not expected from JSON

    // Calculate imsak if missing and fajr is available
    int? finalImsak = initialImsak;
    if (finalImsak == null && fajr != null) {
      finalImsak = fajr - (10 * 60); // 10 minutes before Fajr
    }

    // Calculate isyraq if syuruk is available
    int? calculatedIsyraq;
    if (syuruk != null) {
      calculatedIsyraq = syuruk + (15 * 60); // 15 minutes after Syuruk
    }

    return PrayerTime(
      hijri: hijri!, // We validated hijri is not null earlier
      date: date,
      day: day!,     // We validated day is not null earlier
      imsak: finalImsak, // Use calculated or original imsak
      fajr: fajr,
      syuruk: syuruk,
      dhuhr: dhuhr,
      asr: asr,
      maghrib: maghrib,
      isha: isha,
      isyraq: calculatedIsyraq, // Use calculated isyraq
    );
  }

  // Optional: Add toJson, ==, hashCode, toString for completeness
}
