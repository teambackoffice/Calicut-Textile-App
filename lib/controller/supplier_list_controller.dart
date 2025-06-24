import 'package:calicut_textile_app/modal/supplier_list._modaldart';
import 'package:calicut_textile_app/service/suppliers_list_service.dart';

import 'package:flutter/material.dart';

class SuppliersController extends ChangeNotifier {
  final SuppliersListService _service = SuppliersListService();

  List<Supplier> suppliers = [];
  int currentPage = 1;
  final int pageSize = 50;
  bool isLoading = false;
  bool hasMore = true;


  

  Future<void> loadSuppliers({bool isInitialLoad = false}) async {
    if (isLoading || !hasMore) return;

    isLoading = true;
    notifyListeners();

    try {
      List<Supplier> newSuppliers = await _service.getSuppliers(page: currentPage, pageSize: pageSize);

      if (newSuppliers.isNotEmpty) {
        suppliers.addAll(newSuppliers);
        currentPage++;
      } else {
        hasMore = false; // No more data to load
      }
    } catch (e) {
      print(e.toString());
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void refreshSuppliers() {
    suppliers.clear();
    currentPage = 1;
    hasMore = true;
    loadSuppliers();
  }
}
