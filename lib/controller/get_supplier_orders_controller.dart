import 'package:calicut_textile_app/modal/get_supplier_orders.dart';
import 'package:calicut_textile_app/service/get_supplier_orders_service.dart';
import 'package:flutter/material.dart';

class SupplierOrderController extends ChangeNotifier {
  final SupplierOrderListService _service = SupplierOrderListService();

  List<Order> orders = []; // ✅ Use List<Order> instead
  List<Product> products = []; // ✅ Use List<Product> instead

  int _currentPage = 1;
  final int _pageSize = 50;
  bool _isLoading = false;
  bool _hasMore = true;

  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> loadSupplierOrders() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final List<Order> newOrders = await _service.getSupplierOrders(
        page: _currentPage,
        pageSize: _pageSize,
      );

      if (newOrders.length < _pageSize) {
        _hasMore = false;
      }

      if (newOrders.isNotEmpty) {
        orders.addAll(newOrders); // ✅ No casting needed
        _currentPage++;
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error loading supplier orders: $e');
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearOrders() {
    orders.clear();
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();
  }
}
