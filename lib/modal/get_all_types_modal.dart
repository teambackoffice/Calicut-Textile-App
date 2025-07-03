class TextileTypesResponse {
  final bool success;
  final List<String> data;

  TextileTypesResponse({
    required this.success,
    required this.data,
  });

  factory TextileTypesResponse.fromJson(Map<String, dynamic> json) {
    return TextileTypesResponse(
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