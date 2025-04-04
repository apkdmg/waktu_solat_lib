/// A Flutter library for fetching Malaysian prayer times from the Waktu Solat API.
library waktu_solat_lib;

// Export the API client and exception
export 'src/waktu_solat_client.dart' show WaktuSolatClient, WaktuSolatApiException;

// Export the data models
export 'src/models/prayer_time.dart' show PrayerTime;
export 'src/models/solat_v2.dart' show SolatV2;
export 'src/models/state.dart' show State;
export 'src/models/zone_info.dart';

// Note: ApiError is primarily for internal error handling within the client,
// but could be exported if direct access is deemed useful for consumers.
// export 'src/models/api_error.dart' show ApiError;
