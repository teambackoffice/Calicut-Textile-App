class SupplierGroup {
  final String name;
  final String? parentSupplierGroup;

  SupplierGroup({
    required this.name,
    this.parentSupplierGroup,
  });

  factory SupplierGroup.fromJson(Map<String, dynamic> json) {
    return SupplierGroup(
      name: json['name']?.toString() ?? '',
      parentSupplierGroup: json['parent_supplier_group']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'parent_supplier_group': parentSupplierGroup,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SupplierGroup && other.name == name;
  }

  @override
  int get hashCode => name.hashCode;
}

// models/api_response.dart
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final String? error;

  ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error) {
    return ApiResponse<T>(
      success: false,
      error: error,
    );
  }

  factory ApiResponse.fromJson(Map<String, dynamic> json, T Function(dynamic) fromJsonT) {
    try {
      return ApiResponse<T>(
        success: json['success'] ?? false,
        message: json['message']?.toString(),
        data: json['data'] != null ? fromJsonT(json['data']) : null,
        error: json['error']?.toString(),
      );
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }
}
