import 'package:calicut_textile_app/modal/supplier_group_modal.dart';
import 'package:calicut_textile_app/service/supplier_group_service.dart';
import 'package:flutter/foundation.dart';
// controllers/supplier_provider.dart
import 'package:flutter/foundation.dart';

class SupplierProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<SupplierGroup> _supplierGroups = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Getters
  List<SupplierGroup> get supplierGroups => _supplierGroups;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  bool get hasData => _supplierGroups.isNotEmpty;
  
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
  
  Future<void> fetchSupplierGroups() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final response = await _apiService.getSupplierGroups();
      
      if (response.success && response.data != null) {
        _supplierGroups = response.data!;
      } else {
        _errorMessage = response.error ?? 'Unknown error occurred';
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch supplier groups: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<SupplierGroup?> fetchSupplierGroupById(String id) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final response = await _apiService.getSupplierGroupById(id);
      
      if (response.success && response.data != null) {
        return response.data!;
      } else {
        _errorMessage = response.error ?? 'Supplier group not found';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Failed to fetch supplier group: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refreshSupplierGroups() async {
    await fetchSupplierGroups();
  }
  
  // Add a supplier group to the list (for local updates)
  void addSupplierGroup(SupplierGroup group) {
    _supplierGroups.add(group);
    notifyListeners();
  }
  
  // Update a supplier group in the list
  void updateSupplierGroup(SupplierGroup updatedGroup) {
    final index = _supplierGroups.indexWhere((group) => group.name == updatedGroup.name);
    if (index != -1) {
      _supplierGroups[index] = updatedGroup;
      notifyListeners();
    }
  }
  
  // Remove a supplier group from the list
  void removeSupplierGroup(String name) {
    _supplierGroups.removeWhere((group) => group.name == name);
    notifyListeners();
  }
  
  // Get supplier group by name
  SupplierGroup? getSupplierGroupByName(String name) {
    try {
      return _supplierGroups.firstWhere((group) => group.name == name);
    } catch (e) {
      return null;
    }
  }
}