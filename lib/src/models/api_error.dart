/// Represents an error response from the Waktu Solat API.
/// Typically used when the API returns a 200 OK status but includes
/// `{"status": "error", "message": "..."}` in the response body.
class ApiError {
  /// The status indication, usually "error".
  final String status;

  /// The descriptive error message from the API.
  final String message;

  /// Creates an instance of [ApiError].
  ApiError({
    required this.status,
    required this.message,
  });

  /// Creates an [ApiError] instance from a JSON map.
  ///
  /// Throws a [FormatException] if the JSON structure is invalid or missing required fields.
  factory ApiError.fromJson(Map<String, dynamic> json) {
    if (json['status'] is! String || json['message'] is! String) {
      throw const FormatException('Invalid JSON structure for ApiError');
    }
    return ApiError(
      status: json['status'] as String,
      message: json['message'] as String,
    );
  }
}
