import 'package:flutter/material.dart';
import '../service/update_product_service.dart';

class UpdateProductController extends ChangeNotifier {
  final UpdateProductService _service = UpdateProductService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _response;

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get response => _response;

  Future<void> updateProduct({
    required String productName,
    required String newProductName,
    required String uom,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _response = await _service.updateProduct(
        productName: productName,
        newProductName: newProductName,
        uom: uom,
      );
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
