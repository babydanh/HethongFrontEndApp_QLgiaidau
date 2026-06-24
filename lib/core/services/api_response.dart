class ApiResponse<T> {
  final int? statusCode;
  final String? message;
  final T? data;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    this.statusCode,
    this.message,
    this.data,
    this.meta,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic json)? fromJsonT,
  ) {
    final rawData = json['data'];
    final data = (rawData != null && fromJsonT != null)
        ? fromJsonT(rawData)
        : (rawData as T? ?? json as T?);

    return ApiResponse<T>(
      statusCode: json['statusCode'] as int?,
      message: json['message'] as String?,
      data: data,
      meta: json['meta'] as Map<String, dynamic>?,
    );
  }
}
