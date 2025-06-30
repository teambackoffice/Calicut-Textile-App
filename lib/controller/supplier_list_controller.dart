
// controller/suppliers_controller.dart
import 'package:calicut_textile_app/modal/supplier_list_modal.dart';
import 'package:calicut_textile_app/service/suppliers_list_service.dart';
import 'package:flutter/material.dart';

class SuppliersController extends ChangeNotifier {
  final SuppliersListService _service = SuppliersListService();

  List<Supplier> suppliers = [];
  List<Supplier> allSuppliers = []; // Keep track of all loaded suppliers
  int currentPage = 1;
  final int pageSize = 50;
  bool isLoading = false;
  bool hasMore = true;
  String? errorMessage;

  // Search and filter parameters
  String _searchQuery = '';
  String? _selectedGroup;
  int totalSuppliers = 0;
  int totalPages = 1;

  // Getters
  String get searchQuery => _searchQuery;
  String? get selectedGroup => _selectedGroup;
  bool get hasError => errorMessage != null;

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<void> loadSuppliers({
    bool isInitialLoad = false,
    bool isRefresh = false,
  }) async {
    if (isLoading || (!hasMore && !isRefresh && !isInitialLoad)) return;

    if (isRefresh || isInitialLoad) {
      suppliers.clear();
      allSuppliers.clear();
      currentPage = 1;
      hasMore = true;
      errorMessage = null;
    }

    isLoading = true;
    notifyListeners();

    try {
      final response = await _service.getSuppliers(
        page: currentPage,
        pageSize: pageSize,
        supplierName: _searchQuery.isNotEmpty ? _searchQuery : null,
        supplierGroup: _selectedGroup,
      );

      totalSuppliers = response.message.totalSuppliers;
      totalPages = response.message.totalPages;

      if (response.message.suppliers.isNotEmpty) {
        if (isRefresh || isInitialLoad) {
          suppliers = response.message.suppliers;
          allSuppliers = List.from(response.message.suppliers);
        } else {
          // Remove duplicates before adding
          final newSuppliers = response.message.suppliers.where(
            (newSupplier) => !suppliers.any(
              (existingSupplier) => existingSupplier.supplierId == newSupplier.supplierId,
            ),
          ).toList();
          
          suppliers.addAll(newSuppliers);
          allSuppliers.addAll(newSuppliers);
        }
        currentPage++;
        
        // Check if we have more pages
        hasMore = currentPage <= totalPages;
      } else {
        hasMore = false;
      }
    } catch (e) {
      errorMessage = e.toString();
      print('Controller Error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Search functionality
  Future<void> searchSuppliers(String query) async {
    if (_searchQuery == query) return;

    _searchQuery = query;
    await loadSuppliers(isRefresh: true);
  }

  // Group filter functionality
  Future<void> filterByGroup(String? groupName) async {
    if (_selectedGroup == groupName) return;

    _selectedGroup = groupName;
    await loadSuppliers(isRefresh: true);
  }

  // Combined search and filter
  Future<void> applyFilters({
    String? searchQuery,
    String? groupName,
  }) async {
    bool hasChanged = false;

    if (searchQuery != null && _searchQuery != searchQuery) {
      _searchQuery = searchQuery;
      hasChanged = true;
    }

    if (groupName != _selectedGroup) {
      _selectedGroup = groupName;
      hasChanged = true;
    }

    if (hasChanged) {
      await loadSuppliers(isRefresh: true);
    }
  }

  // Clear all filters
  Future<void> clearFilters() async {
    if (_searchQuery.isEmpty && _selectedGroup == null) return;

    _searchQuery = '';
    _selectedGroup = null;
    await loadSuppliers(isRefresh: true);
  }

  // Refresh suppliers
  Future<void> refreshSuppliers() async {
    await loadSuppliers(isRefresh: true);
  }

  // Load more suppliers (pagination)
  Future<void> loadMoreSuppliers() async {
    if (!isLoading && hasMore) {
      await loadSuppliers();
    }
  }

  // Get filtered suppliers (for local filtering if needed)
  List<Supplier> getFilteredSuppliers({
    String? localSearchQuery,
    String? localGroupFilter,
  }) {
    var filtered = List<Supplier>.from(suppliers);

    if (localSearchQuery != null && localSearchQuery.isNotEmpty) {
      filtered = filtered.where((supplier) {
        return supplier.supplierName.toLowerCase().contains(localSearchQuery.toLowerCase()) ||
               supplier.supplierId.toLowerCase().contains(localSearchQuery.toLowerCase());
      }).toList();
    }

    if (localGroupFilter != null && localGroupFilter.isNotEmpty) {
      filtered = filtered.where((supplier) {
        return supplier.supplierGroup == localGroupFilter;
      }).toList();
    }

    return filtered;
  }

  // Get supplier statistics
  Map<String, int> getSupplierGroupCounts() {
    Map<String, int> groupCounts = {};
    for (var supplier in allSuppliers) {
      groupCounts[supplier.supplierGroup] = (groupCounts[supplier.supplierGroup] ?? 0) + 1;
    }
    return groupCounts;
  }

  @override
  void dispose() {
    suppliers.clear();
    allSuppliers.clear();
    super.dispose();
  }
}