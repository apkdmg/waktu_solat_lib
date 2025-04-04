import 'package:meta/meta.dart';

/// Represents zone information returned by the API.
///
/// Contains the JAKIM code, the state (negeri), and the district/area (daerah).
@immutable
class ZoneInfo {
  /// The JAKIM zone code (e.g., "JHR01", "SGR02").
  final String jakimCode;

  /// The name of the state (negeri) the zone belongs to.
  final String negeri;

  /// The name of the district or area (daerah) covered by the zone.
  final String daerah;

  /// Creates a [ZoneInfo] instance.
  const ZoneInfo({
    required this.jakimCode,
    required this.negeri,
    required this.daerah,
  });

  /// Creates a [ZoneInfo] instance from a JSON map.
  ///
  /// Throws [FormatException] if the JSON structure is invalid.
  factory ZoneInfo.fromJson(Map<String, dynamic> json) {
    try {
      return ZoneInfo(
        jakimCode: json['jakimCode'] as String,
        negeri: json['negeri'] as String,
        daerah: json['daerah'] as String,
      );
    } catch (e) {
      throw FormatException('Invalid JSON format for ZoneInfo: $e', json);
    }
  }

  @override
  String toString() =>
      'ZoneInfo(jakimCode: $jakimCode, negeri: $negeri, daerah: $daerah)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ZoneInfo &&
          runtimeType == other.runtimeType &&
          jakimCode == other.jakimCode &&
          negeri == other.negeri &&
          daerah == other.daerah;

  @override
  int get hashCode => jakimCode.hashCode ^ negeri.hashCode ^ daerah.hashCode;
}
