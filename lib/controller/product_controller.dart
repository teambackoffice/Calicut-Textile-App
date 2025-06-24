import 'package:calicut_textile_app/modal/product_list_model.dart';
import 'package:flutter/material.dart';

import 'package:calicut_textile_app/service/product_list_service.dart';

class ProductListController extends ChangeNotifier {
  final ProductListService _productListService = ProductListService();

  List<Datum> _products = [];
  List<Datum> get products => _products;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Fetch all products
  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _products = await _productListService.getProducts();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh product list
  Future<void> refreshProducts() async {
    await fetchProducts();
  }
}
