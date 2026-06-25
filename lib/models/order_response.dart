class OrderResponse {
  final bool success;
  final int? id;
  final String? orderKey;
  final String? message;
  final int? statusCode;
  final String? rawBody;

  OrderResponse({
    required this.success,
    this.id,
    this.orderKey,
    this.message,
    this.statusCode,
    this.rawBody,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json, int statusCode, String rawBody) {
    if (statusCode == 200 || statusCode == 201) {
      return OrderResponse(
        success: true,
        id: json['id'],
        orderKey: json['order_key'],
        statusCode: statusCode,
        rawBody: rawBody,
      );
    } else {
      return OrderResponse(
        success: false,
        message: json['message'] ?? 'An error occurred while placing the order.',
        statusCode: statusCode,
        rawBody: rawBody,
      );
    }
  }

  factory OrderResponse.error(String message, [int? statusCode, String? rawBody]) {
    return OrderResponse(
      success: false,
      message: message,
      statusCode: statusCode,
      rawBody: rawBody,
    );
  }
}
