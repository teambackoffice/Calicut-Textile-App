import 'package:calicut_textile_app/service/get_designs_service.dart';
import 'package:flutter/material.dart';

class DesignsController extends ChangeNotifier {
  List<String> _designs = [];
  bool _isLoading = false;
  String _errorMessage = '';
  List<String> _selectedDesigns = [];
  bool _allowMultipleSelection = false;

  // Getters
  List<String> get designs => _designs;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  List<String> get selectedDesigns => _selectedDesigns;
  bool get allowMultipleSelection => _allowMultipleSelection;

  /// Loads all designs from the API
  Future<void> loadDesigns() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await DesignsService.getAllDesigns();
      
      if (response.success) {
        _designs = response.data;
      } else {
        _setError('Failed to load designs');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the designs list
  Future<void> refreshDesigns() async {
    await loadDesigns();
  }

  /// Filters designs based on search query
  List<String> filterDesigns(String query) {
    if (query.isEmpty) return _designs;
    
    return _designs
        .where((design) => design.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Filters design items based on search query
  // List<DesignItem> filterDesignItems(String query) {
  //   if (query.isEmpty) return _designItems;
    
  //   return _designItems
  //       .where((designItem) => 
  //         designItem.name.toLowerCase().contains(query.toLowerCase()) ||
  //         designItem.description.toLowerCase().contains(query.toLowerCase())
  //       )
  //       .toList();
  // }

  /// Gets designs by category
  // List<DesignItem> getDesignsByCategory(DesignCategory category) {
  //   if (category == DesignCategory.all) return _designItems;
    
  //   return _designItems
  //       .where((designItem) => designItem.category == category)
  //       .toList();
  // }

  /// Sets multiple selection mode
  void setMultipleSelectionMode(bool enabled) {
    _allowMultipleSelection = enabled;
    if (!enabled && _selectedDesigns.length > 1) {
      // Keep only the first selected design
      _selectedDesigns = _selectedDesigns.take(1).toList();
    }
    notifyListeners();
  }

  /// Selects a design
  void selectDesign(String design) {
    if (_allowMultipleSelection) {
      if (_selectedDesigns.contains(design)) {
        _selectedDesigns.remove(design);
      } else {
        _selectedDesigns.add(design);
      }
    } else {
      _selectedDesigns = [design];
    }
    notifyListeners();
  }

  /// Checks if a design is selected
  bool isDesignSelected(String design) {
    return _selectedDesigns.contains(design);
  }

  /// Clears all selected designs
  void clearSelection() {
    _selectedDesigns.clear();
    notifyListeners();
  }

  /// Selects all designs in a category
  // void selectAllInCategory(DesignCategory category) {
  //   if (!_allowMultipleSelection) return;
    
  //   final categoryDesigns = getDesignsByCategory(category);
  //   for (final designItem in categoryDesigns) {
  //     if (!_selectedDesigns.contains(designItem.name)) {
  //       _selectedDesigns.add(designItem.name);
  //     }
  //   }
  //   notifyListeners();
  // }

  /// Checks if a specific design exists
  // bool hasDesign(String design) {
  //   return _designs.contains(design);
  // }

  // /// Gets the count of designs
  // int get designsCount => _designs.length;

  // /// Gets the count of selected designs
  // int get selectedDesignsCount => _selectedDesigns.length;

  // /// Groups designs by category
  // Map<DesignCategory, List<DesignItem>> get groupedDesigns {
  //   final grouped = <DesignCategory, List<DesignItem>>{};
    
  //   for (final category in DesignCategory.values) {
  //     if (category == DesignCategory.all) continue;
  //     grouped[category] = getDesignsByCategory(category);
  //   }
    
  //   return grouped;
  // }

  /// Gets popular designs (hardcoded for demo)
  List<String> get popularDesigns => ['Floral', 'Peacock', 'Geometrical', 'Abstract'];

  /// Gets traditional designs
  // List<String> get traditionalDesigns => 
  //   getDesignsByCategory(DesignCategory.traditional).map((e) => e.name).toList();

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  /// Disposes resources
  @override
  void dispose() {
    super.dispose();
  }
}
