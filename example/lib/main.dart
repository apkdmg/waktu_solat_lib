import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages
import 'package:waktu_solat_lib/waktu_solat_lib.dart' as waktu_solat;
import 'package:intl/intl.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Waktu Solat Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  // Instantiate the client
  final waktu_solat.WaktuSolatClient _client = waktu_solat.WaktuSolatClient();

  // State variables to hold API results
  List<waktu_solat.ZoneInfo>? _zones;
  waktu_solat.SolatV2? _prayerTimesZone;
  waktu_solat.SolatV2? _prayerTimesGps;
  double? _lastGpsLat;
  double? _lastGpsLon;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Optionally, fetch data on init
    // _fetchZones();
  }

  // --- API Fetching Methods ---

  Future<void> _fetchZones() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _zones = null; // Clear previous results
    });
    try {
      final zonesData = await _client.getZones(); // Returns List<ZoneInfo>
      setState(() {
        _zones = zonesData; // Assign List<ZoneInfo>
        _isLoading = false;
      });
    } on waktu_solat.WaktuSolatApiException catch (e) {
      // ignore: avoid_print
      print('Error fetching zones: $e');
      setState(() {
        _error = 'Error fetching zones: $e';
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Unexpected error: $e');
      setState(() {
        _error = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPrayerTimesByZone(String zone) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _prayerTimesZone = null;
    });
    try {
      final prayerTimes = await _client.getPrayerTimesByZone(zone);
      setState(() {
        _prayerTimesZone = prayerTimes;
        _isLoading = false;
      });
    } on waktu_solat.WaktuSolatApiException catch (e) {
      // ignore: avoid_print
      print('Error fetching prayer times for zone $zone: $e');
      setState(() {
        _error = 'Error fetching prayer times for zone $zone: $e';
        _isLoading = false;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Unexpected error: $e');
      setState(() {
        _error = 'Unexpected error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPrayerTimesByGps() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _prayerTimesGps = null; // Clear previous GPS results
    });
    try {
      // Example coordinates (Kuala Lumpur)
      const double latitude = 3.1390;
      const double longitude = 101.6869;

      final times = await _client.getPrayerTimesByGps(latitude, longitude);
      setState(() {
        _prayerTimesGps = times;
        _isLoading = false;
      });
    } on waktu_solat.WaktuSolatApiException catch (e) {
      setState(() {
        _error = 'Error fetching prayer times for GPS: $e';
        _isLoading = false;
      });
      // ignore: avoid_print
      print(_error); // Log error
    } catch (e) {
      // Catch other potential errors
      setState(() {
        _error = 'An unexpected error occurred during GPS fetch: $e';
        _isLoading = false;
      });
      // ignore: avoid_print
      print(_error); // Log error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waktu Solat Lib Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text(
              'Tap buttons to fetch data:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),

            // --- Buttons --- 
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchZones,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Fetch Zones'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _fetchPrayerTimesByZone('SGR01'), // Example zone
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Fetch Times (SGR01)'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _fetchPrayerTimesByGps, // Placeholder coords
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Fetch Times (GPS)'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // --- Scrollable Content Area ---
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Display Error Messages
                    if (_error != null &&
                        _zones == null &&
                        _prayerTimesZone == null &&
                        _prayerTimesGps == null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Display Zones
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_zones != null)
                      _buildZoneInfoList(_zones!) // No Expanded needed here
                    else if (_error != null && _zones == null)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Display Prayer Times (Zone)
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_prayerTimesZone != null)
                      _buildPrayerTimeSection('Prayer Times (Zone: ${_prayerTimesZone!.zone})', _prayerTimesZone!),

                    // Display Prayer Times (GPS)
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_prayerTimesGps != null)
                      _buildPrayerTimeSection(
                          'Prayer Times (GPS: Lat ${_lastGpsLat?.toStringAsFixed(1)}, Lon ${_lastGpsLon?.toStringAsFixed(1)})', // Use stored coordinates
                          _prayerTimesGps!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSection(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          // Display first few items or a summary for large lists
          Text(items.take(10).join('\n')), 
          if (items.length > 10) const Text('...'),
        ],
      ),
    );
  }

  // Helper widget to display SolatV2 data
  Widget _buildPrayerTimeSection(String title, waktu_solat.SolatV2 data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          // Conditionally display origin if not null
          if (data.origin != null)
            Text('Origin: ${data.origin}')
          else
            const Text('Origin: N/A'), // Or handle null case as needed
          Text('Zone: ${data.zone}'),
          const SizedBox(height: 5),
          const Text('First Day Times:'),
          if (data.prayerTime.isNotEmpty) ...[
            _buildPrayerTimeRow(data.prayerTime.first)
          ] else
            const Text('No prayer times data available.'),
          if (data.prayerTime.length > 1)
            const Text('...'),
        ],
      ),
    );
  }

  // Helper to format a single PrayerTime entry
  Widget _buildPrayerTimeRow(waktu_solat.PrayerTime pt) {
    // Helper to format Unix timestamp (seconds) to HH:mm string
    String formatTimestamp(int? timestamp) {
      if (timestamp == null) {
        return '--:--'; // Placeholder for missing times
      }
      try {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000, isUtc: false); // Assuming local time
        return DateFormat('HH:mm').format(dateTime);
      } catch (e) {
        // Handle potential errors during formatting (e.g., invalid timestamp)
        // ignore: avoid_print
        print('Error formatting timestamp $timestamp: $e');
        return 'Err';
      }
    }

    return Text(
      // Display date if available, otherwise use Hijri date as fallback
      '${pt.date ?? pt.hijri} (${pt.day.toString()}): ' // Date (or Hijri fallback) and Day
      'Imsak ${formatTimestamp(pt.imsak)}, ' // Formatted times
      'Fajr ${formatTimestamp(pt.fajr)}, ' 
      'Syuruk ${formatTimestamp(pt.syuruk)}, ' 
      'Isyraq ${formatTimestamp(pt.isyraq)}, ' // Add Isyraq
      'Dhuhr ${formatTimestamp(pt.dhuhr)}, ' 
      'Asr ${formatTimestamp(pt.asr)}, ' 
      'Maghrib ${formatTimestamp(pt.maghrib)}, ' 
      'Isha ${formatTimestamp(pt.isha)}', 
      style: const TextStyle(fontSize: 12),
    );
  }

  // Helper widget to display ZoneInfo data
  Widget _buildZoneInfoList(List<waktu_solat.ZoneInfo> zones) {
    return ListView.builder(
      shrinkWrap: true, // Re-add shrinkWrap as it will be inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Re-add physics to disable nested scrolling
      itemCount: zones.length,
      itemBuilder: (context, index) {
        final zone = zones[index];
        return ListTile(
          title: Text('(${zone.jakimCode}) ${zone.daerah}'),
          subtitle: Text(zone.negeri),
          dense: true, // Make items slightly smaller
        );
      },
    );
  }
}
