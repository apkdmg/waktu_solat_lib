/// Represents a Malaysian state and its associated prayer zone codes.
class State {
  /// The name of the state (e.g., "JOHOR").
  final String negeri; // State name

  /// A list of prayer zone codes belonging to this state (e.g., ["JHR01", "JHR02"]).
  final List<String> zones; // List of zone codes

  /// Creates an instance of [State].
  State({required this.negeri, required this.zones});

  /// Creates a [State] instance from a JSON map.
  ///
  /// Throws a [FormatException] if the JSON structure is invalid, missing required fields,
  /// or if the `zones` list contains non-string values.
  factory State.fromJson(Map<String, dynamic> json) {
    // Basic validation
    if (json['negeri'] is! String || json['zones'] is! List) {
      throw const FormatException(
          'Invalid or missing fields (negeri, zones) in State JSON');
    }

    // Validate that zones list contains only strings
    List<String> zoneList;
    try {
      zoneList = List<String>.from(json['zones'] as List);
    } catch (e) {
      throw FormatException(
          'Invalid items in zones list for State JSON. Expected List<String>. Error: $e');
    }

    return State(
      negeri: json['negeri'] as String? ?? '',
      zones: zoneList,
    );
  }

  // Optional: Add toJson, ==, hashCode, toString for completeness
}
