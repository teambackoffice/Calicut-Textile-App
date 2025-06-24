import 'package:calicut_textile_app/modal/add_product_modal.dart';
import 'package:calicut_textile_app/modal/product_list_model.dart';
import 'package:calicut_textile_app/service/add_product_service.dart';
import 'package:flutter/material.dart';

import 'package:calicut_textile_app/service/product_list_service.dart';

class ProductListController extends ChangeNotifier {
  final ProductListService _productListService = ProductListService();
  Product? product;
   void setIsLoading(bool value) {
    _isLoading = value;
    //   notifyListeners();
  }

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



  Future<bool?> addProduct(
      {required Product addProductModel,
      required BuildContext context}) async {
    setIsLoading(true);
    final result = await ProductService.createProduct(product: product!, context: context
        );
    setIsLoading(false);
    if (result != null && result) {
      notifyListeners();
      return true;
    } else if (result == null) {
      return null;
    } else {
      notifyListeners();
      return false;
    }
  }
}
