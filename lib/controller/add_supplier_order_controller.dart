import 'package:calicut_textile_app/modal/add_supplier_order_modal.dart';
import 'package:calicut_textile_app/service/add_supplier_order_service.dart';
import 'package:flutter/material.dart';


class CreateSupplierOrderController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  bool _isOrderCreated = false;
  
  
  
  // Product list for the order
  List<SupplierOrderModal> _products = [];
  
  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOrderCreated => _isOrderCreated;
  List<SupplierOrderModal> get products => _products;
  
  // Add product to the order
  
  
  // Update product in the order
  
  // Calculate grand total based on products
  
  // Create supplier order
  Future<bool?> CreateSupplierOrder(
      {required SupplierOrderModal createsupplierorder,
      required BuildContext context}) async {
    setIsLoading(true);
    final result = await SupplierOrderService.createSupplierOrder( context: context, supplierOrder: createsupplierorder
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
   void setIsLoading(bool value) {
    _isLoading = value;
    //   notifyListeners();
  }
  
  // Validate form
  
  
  // Helper method to create a product
}