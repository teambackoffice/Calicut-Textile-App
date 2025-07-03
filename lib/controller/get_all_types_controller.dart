import 'package:calicut_textile_app/service/get_all_types.dart';
import 'package:flutter/material.dart';

class TextileTypesController extends ChangeNotifier {
  List<String> _textileTypes = [];
  bool _isLoading = false;
  String _errorMessage = '';

  // Getters
  List<String> get textileTypes => _textileTypes;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;

  /// Loads all textile types from the API
  Future<void> loadTextileTypes() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await TextileTypesService.getAllTypes();
      
      if (response.success) {
        _textileTypes = response.data;
      } else {
        _setError('Failed to load textile types');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the textile types list
  Future<void> refreshTextileTypes() async {
    await loadTextileTypes();
  }

  /// Filters textile types based on search query
  List<String> filterTextileTypes(String query) {
    if (query.isEmpty) return _textileTypes;
    
    return _textileTypes
        .where((type) => type.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Checks if a specific textile type exists
  bool hasTextileType(String type) {
    return _textileTypes.contains(type);
  }

  /// Gets the count of textile types
  int get textileTypesCount => _textileTypes.length;

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
