import 'package:calicut_textile_app/modal/get_supplier_orders.dart' as OrderModel;
import 'package:calicut_textile_app/service/edit_supplier_order_service.dart';
import 'package:flutter/material.dart';

class UpdateSupplierOrderController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool?> updateSupplierOrder({
    required OrderModel.Order order,
    required BuildContext context,
  }) async {
    setIsLoading(true);
    _errorMessage = null;

    try {
      final result = await UpdateSupplierOrderService.updateSupplierOrder(
        order: order,
        context: context,
      );
      
      if (result == null) {
        _errorMessage = 'Failed to update supplier order';
      }
      
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      setIsLoading(false);
    }
  }
}