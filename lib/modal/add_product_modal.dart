// models/product_model.dart
class Product {
  final String productName;
  final String qty;
  final String rate;
  final String amount;
  final String? color;
  final String uom;
  final List<String>? imagePaths;
  final String? api_key;


  Product({
    required this.productName,
    required this.qty,
    required this.rate,
    required this.amount,
     this.color,
    required this.uom,
     this.imagePaths,
     this.api_key,
  });

  Map<String, String> toMap() {
    return {
      'product_name': productName,
      'qty': qty,
      'rate': rate,
      'amount': amount,
      'color': color!,
      'uom': uom,
      'api_key': api_key!, // You might want to move this to config
    };
  }
}

class ProductResponse {
  final bool success;
  final String message;
  final dynamic data;

  ProductResponse({
    required this.success,
    required this.message,
    this.data,
  });

  factory ProductResponse.fromJson(Map<String, dynamic> json) {
    return ProductResponse(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
    );
  }
}