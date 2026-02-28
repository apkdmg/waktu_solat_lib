## 1.0.3 - 2026-02-28

* Fix `getPrayerTimesByGps` to call the documented endpoint path `/v2/solat/gps/{lat}/{long}`.
* Add support for for Flutter `3.41.2` / Dart `3.11.0`.

## 1.0.2 - 2025-07-29

* Fix pubspec.yaml

## 1.0.1 - 2025-07-29

* Fix GPS endpoint path
* Fix pub.dev score: shorter description, correct repository URL.

## 1.0.0 - 2025-04-04

* First stable release of the Waktu Solat Library
* Features:
  * Fetch prayer times by zone code (`getPrayerTimesByZone`)
  * Fetch prayer times by GPS coordinates (`getPrayerTimesByGps`)
  * Get a list of all available zone codes (`getZones`) and states (`getStates`)
  * Automatic calculation of Imsak time (10 minutes before Fajr) if not provided by API
  * Automatic calculation of Isyraq time (15 minutes after Syuruk)
  * Comprehensive error handling with `WaktuSolatApiException`
  * Full test coverage for models and API client
  * Example app demonstrating all features
* Improvements:
  * Nullable prayer time fields to handle missing data from API
  * Proper handling of integer-based timestamps for prayer times
  * Cross-platform compatibility (Android, iOS, Web, Windows, macOS, Linux)
  * Comprehensive documentation
