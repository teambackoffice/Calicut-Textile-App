// models/designs_model.dart
class DesignsResponse {
  final bool success;
  final List<String> data;

  DesignsResponse({
    required this.success,
    required this.data,
  });

  factory DesignsResponse.fromJson(Map<String, dynamic> json) {
    return DesignsResponse(
      success: json['message']['success'] ?? false,
      data: List<String>.from(json['message']['data'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': {
        'success': success,
        'data': data,
      }
    };
  }
}