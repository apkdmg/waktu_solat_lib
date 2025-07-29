import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:waktu_solat_lib/src/models/api_error.dart';
import 'package:waktu_solat_lib/src/models/prayer_time.dart';
import 'package:waktu_solat_lib/src/models/solat_v2.dart';
import 'package:waktu_solat_lib/src/models/state.dart';

void main() {
  group('Model Tests', () {
    group('PrayerTime', () {
      test('fromJson parses valid JSON correctly', () {
        const jsonString = '''{
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
        }''';
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final prayerTime = PrayerTime.fromJson(jsonMap);

        expect(prayerTime.hijri, '1446-09-01');
        expect(prayerTime.date, '2025-03-01');
        expect(prayerTime.day, 6);
        expect(prayerTime.imsak, 1425480000);
        expect(prayerTime.fajr, 1425480480);
        expect(prayerTime.syuruk, 1425485460);
        expect(prayerTime.dhuhr, 1425507480);
        expect(prayerTime.asr, 1425518340);
        expect(prayerTime.maghrib, 1425529800);
        expect(prayerTime.isha, 1425533940);
        // Check that isyraq is calculated correctly (15 minutes after syuruk)
        expect(
            prayerTime.isyraq, 1425486360); // syuruk + 15 minutes (900 seconds)
      });
    });

    group('SolatV2', () {
      test('fromJson parses valid JSON correctly', () {
        const jsonString = '''{
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
            },
            {
              "hijri": "1446-09-02",
              "date": "2025-03-02",
              "day": 0,
              "imsak": 1425566400,
              "fajr": 1425566880,
              "syuruk": 1425571860,
              "dhuhr": 1425593880,
              "asr": 1425604740,
              "maghrib": 1425616200,
              "isha": 1425620340
            }
          ]
        }''';
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final solatV2 = SolatV2.fromJson(jsonMap);

        expect(solatV2.zone, 'sgr01');
        expect(solatV2.origin, 'JAKIM');
        expect(solatV2.prayerTime, isA<List<PrayerTime>>());
        expect(solatV2.prayerTime.length, 2);
        expect(solatV2.prayerTime[0].date, '2025-03-01');
        expect(solatV2.prayerTime[0].day, 6); // Saturday
        expect(solatV2.prayerTime[1].day, 0); // Sunday

        // Check that prayer times are parsed correctly
        expect(solatV2.prayerTime[0].fajr, 1425480480);
        expect(solatV2.prayerTime[0].syuruk, 1425485460);

        // Check that isyraq is calculated correctly for both days
        expect(solatV2.prayerTime[0].isyraq, 1425486360); // syuruk + 15 minutes
        expect(solatV2.prayerTime[1].isyraq, 1425572760); // syuruk + 15 minutes
      });
    });

    group('State', () {
      test('fromJson parses valid JSON correctly', () {
        const jsonString = '''{
          "negeri": "SELANGOR",
          "zones": [
            "sgr01",
            "sgr02",
            "sgr03"
          ]
        }''';
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final state = State.fromJson(jsonMap);

        expect(state.negeri, 'SELANGOR');
        expect(state.zones, isA<List<String>>());
        expect(state.zones.length, 3);
        expect(state.zones, contains('sgr01'));
        expect(state.zones, contains('sgr03'));
      });
    });

    group('ApiError', () {
      test('fromJson parses valid JSON correctly', () {
        const jsonString = '''{
            "status": "error",
            "message": "Error, Zone not found, Please use /zones"
          }''';
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        final apiError = ApiError.fromJson(jsonMap);

        expect(apiError.status, 'error');
        expect(apiError.message, 'Error, Zone not found, Please use /zones');
      });
    });
  });
}
