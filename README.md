# Waktu Solat Library

A Flutter package for accessing Malaysia prayer times (waktu solat) from the Waktu Solat API. This package provides easy access to prayer times by zone code or GPS coordinates.

## Features

- Fetch prayer times by zone code (e.g., SGR01 for Selangor)
- Fetch prayer times by GPS coordinates (latitude and longitude)
- Get a list of all available zone codes
- Automatic calculation of Imsak time (10 minutes before Fajr) if not provided by the API
- Automatic calculation of Isyraq time (15 minutes after Syuruk)
- Proper error handling and parsing of API responses
- Comprehensive example app demonstrating all features

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  waktu_solat_lib: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Usage

### Initialize the client

```dart
import 'package:waktu_solat_lib/waktu_solat_lib.dart' as waktu_solat;

// Create an instance of the client
final client = waktu_solat.WaktuSolatClient();
```

### Get all available states

You can fetch a list of all available states (negeri) in Malaysia:

```dart
final states = await client.getStates();

// Example response:
// [
//   "Johor",
//   "Kedah",
//   "Kelantan",
//   "Melaka",
//   "Negeri Sembilan",
//   "Pahang",
//   "Perlis",
//   "Pulau Pinang",
//   "Perak",
//   "Sabah",
//   "Selangor",
//   "Sarawak",
//   "Terengganu",
//   "Wilayah Persekutuan"
// ]
```

### Get all available zone codes

You can fetch detailed information about all available zones:

```dart
final zones = await client.getZones();

// Example response (List<ZoneInfo>):
// [
//   ZoneInfo(jakimCode: "JHR01", negeri: "Johor", daerah: "Pulau Aur dan Pemanggil"),
//   ZoneInfo(jakimCode: "JHR02", negeri: "Johor", daerah: "Kota Tinggi, Mersing, Johor Bahru"),
//   ZoneInfo(jakimCode: "SGR01", negeri: "Selangor", daerah: "Gombak, Hulu Selangor, Rawang"),
//   // ... more zones
// ]
```

### Get prayer times by zone code

Fetch prayer times for a specific zone. By default, this returns prayer times for the current month:

```dart
// Get prayer times for SGR01 (Selangor)
final prayerTimes = await client.getPrayerTimesByZone('SGR01');

// Response structure (SolatV2)
print('Zone: ${prayerTimes.zone}'); // "SGR01"
print('Origin: ${prayerTimes.origin}'); // May be null for some endpoints
print('Number of days: ${prayerTimes.prayerTime.length}'); // Typically returns the full month (28-31 days)

// Access the prayer times for each day
for (final pt in prayerTimes.prayerTime) {
  print('Date: ${pt.date}'); // e.g., "2025-04-01"
  print('Hijri: ${pt.hijri}'); // e.g., "1446-09-22"
  print('Day: ${pt.day}'); // Day of week (1-7, where 1 is Monday)
  
  // Prayer times are stored as Unix timestamps (seconds since epoch)
  // They may be null if not provided by the API
  print('Imsak: ${_formatTimestamp(pt.imsak)}'); // Calculated as 10 minutes before Fajr if not provided
  print('Fajr: ${_formatTimestamp(pt.fajr)}');
  print('Syuruk: ${_formatTimestamp(pt.syuruk)}');
  print('Isyraq: ${_formatTimestamp(pt.isyraq)}'); // Calculated as 15 minutes after Syuruk
  print('Dhuhr: ${_formatTimestamp(pt.dhuhr)}');
  print('Asr: ${_formatTimestamp(pt.asr)}');
  print('Maghrib: ${_formatTimestamp(pt.maghrib)}');
  print('Isha: ${_formatTimestamp(pt.isha)}');
}

// Helper function to format timestamps
String _formatTimestamp(int? timestamp) {
  if (timestamp == null) return '--:--';
  final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
```

### Get prayer times by GPS coordinates

You can also fetch prayer times based on GPS coordinates:

```dart
// Get prayer times for Kuala Lumpur coordinates
final double latitude = 3.1390;
final double longitude = 101.6869;
final prayerTimes = await client.getPrayerTimesByGps(latitude, longitude);

// The response structure is the same as getPrayerTimesByZone
// It will determine the closest zone to your coordinates and return prayer times for that zone

// Example response for the coordinates above might be for the Kuala Lumpur zone
print('Zone determined from GPS: ${prayerTimes.zone}'); // e.g., "WLY01"
```

### Optional parameters for specific month and year

Both `getPrayerTimesByZone` and `getPrayerTimesByGps` accept optional `year` and `month` parameters to fetch prayer times for a specific period:

```dart
// Get prayer times for SGR01 for March 2025
final prayerTimes = await client.getPrayerTimesByZone('SGR01', year: 2025, month: 3);

// This will return prayer times for all days in March 2025 (31 days)
// Each day will have a complete set of prayer times (imsak, fajr, syuruk, etc.)
```

### Duration of prayer times data

When you fetch prayer times, the API returns data for the entire month:

- If you specify both `year` and `month`, you get prayer times for all days in that month.
- If you specify only `year`, you get prayer times for all days in the current month of that year.
- If you don't specify any parameters, you get prayer times for all days in the current month of the current year.

Each API response contains a list of `PrayerTime` objects, one for each day in the month (typically 28-31 days depending on the month).

### Get prayer times for a specific date

For a more user-friendly way to get prayer times for a specific date, use these convenience methods:

```dart
// Get prayer times for a specific date by zone
final DateTime specificDate = DateTime(2025, 4, 15); // April 15, 2025
final prayerTime = await client.getPrayerTimeByDate('SGR01', specificDate);

// Access the prayer times directly
if (prayerTime != null) {
  print('Prayer times for ${specificDate.toIso8601String().split('T')[0]}:');
  print('Imsak: ${_formatTimestamp(prayerTime.imsak)}');
  print('Fajr: ${_formatTimestamp(prayerTime.fajr)}');
  print('Syuruk: ${_formatTimestamp(prayerTime.syuruk)}');
  print('Isyraq: ${_formatTimestamp(prayerTime.isyraq)}'); // Calculated as 15 minutes after Syuruk
  print('Dhuhr: ${_formatTimestamp(prayerTime.dhuhr)}');
  print('Asr: ${_formatTimestamp(prayerTime.asr)}');
  print('Maghrib: ${_formatTimestamp(prayerTime.maghrib)}');
  print('Isha: ${_formatTimestamp(prayerTime.isha)}');
} else {
  print('No prayer times found for the specified date');
}
```

### Get prayer times for a specific date using GPS coordinates

```dart
// Get prayer times for a specific date by GPS coordinates
final DateTime specificDate = DateTime(2025, 4, 15); // April 15, 2025
final double latitude = 3.1390;
final double longitude = 101.6869;

final prayerTime = await client.getPrayerTimeByDateGps(latitude, longitude, specificDate);

// Access the prayer times as shown above
```

These methods make it much easier to retrieve prayer times for a specific date without having to manually filter through the month's data.

## Credits

This library uses the [Malaysia Prayer Time API](https://api.waktusolat.app/docs) created by [Muhammad Fareez Iqmal](https://iqfareez.com/about), a Software Engineer specializing in Flutter, Laravel, and .NET technologies. The API provides accurate prayer times data for all locations in Malaysia.

The data is collected from [e-solat JAKIM](https://www.e-solat.gov.my/) and stored in a database to maintain stability and availability. For more technical information, visit the API repository at [https://github.com/mptwaktusolat/api-waktusolat](https://github.com/mptwaktusolat/api-waktusolat).

## Error Handling

The library throws `WaktuSolatApiException` for API errors, network issues, or parsing problems:

```dart
try {
  final prayerTimes = await client.getPrayerTimesByZone('INVALID_ZONE');
} on waktu_solat.WaktuSolatApiException catch (e) {
  print('Error: ${e.message}');
  print('Status code: ${e.statusCode}'); // If applicable
}
```

## Additional Information

- This package uses the public Waktu Solat API.
- For a complete example, see the `/example` folder.
- Contributions and bug reports are welcome on the [GitHub repository](https://github.com/apkdmg/waktu_solat_lib).
- This package is compatible with all platforms supported by Flutter (Android, iOS, Web, Windows, macOS, Linux).
