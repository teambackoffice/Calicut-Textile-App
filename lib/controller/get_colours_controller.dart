import 'package:calicut_textile_app/modal/get_colours_modal.dart';
import 'package:calicut_textile_app/service/get_colours_service.dart';
import 'package:flutter/material.dart';

class ColorsController extends ChangeNotifier {
  List<String> _colors = [];
  List<ColorItem> _colorItems = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _selectedColor = '';

  // Getters
  List<String> get colors => _colors;
  List<ColorItem> get colorItems => _colorItems;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get hasError => _errorMessage.isNotEmpty;
  String get selectedColor => _selectedColor;

  /// Loads all colors from the API
  Future<void> loadColors() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await ColorsService.getAllColors();
      
      if (response.success) {
        _colors = response.data;
        _colorItems = _colors.map((color) => ColorItem.fromName(color)).toList();
      } else {
        _setError('Failed to load colors');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Refreshes the colors list
  Future<void> refreshColors() async {
    await loadColors();
  }

  /// Filters colors based on search query
  List<String> filterColors(String query) {
    if (query.isEmpty) return _colors;
    
    return _colors
        .where((color) => color.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Filters color items based on search query
  List<ColorItem> filterColorItems(String query) {
    if (query.isEmpty) return _colorItems;
    
    return _colorItems
        .where((colorItem) => colorItem.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  /// Selects a color
  void selectColor(String color) {
    _selectedColor = color;
    notifyListeners();
  }

  /// Clears the selected color
  void clearSelection() {
    _selectedColor = '';
    notifyListeners();
  }

  /// Checks if a specific color exists
  bool hasColor(String color) {
    return _colors.contains(color);
  }

  /// Gets the count of colors
  int get colorsCount => _colors.length;

  /// Groups colors by their first letter
  Map<String, List<String>> get groupedColors {
    final grouped = <String, List<String>>{};
    for (final color in _colors) {
      final firstLetter = color[0].toUpperCase();
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(color);
    }
    return grouped;
  }

  /// Gets colors by category (basic, metallic, etc.)
  List<String> getColorsByCategory(ColorCategory category) {
    switch (category) {
      case ColorCategory.basic:
        return _colors.where((color) => 
          ['Red', 'Green', 'Blue', 'Black', 'White', 'Yellow'].contains(color)
        ).toList();
      case ColorCategory.metallic:
        return _colors.where((color) => 
          ['Gold', 'Rose Gold', 'Silver', 'Copper'].contains(color)
        ).toList();
      case ColorCategory.pastel:
        return _colors.where((color) => 
          ['Pink', 'Beige', 'L Green'].contains(color)
        ).toList();
      case ColorCategory.dark:
        return _colors.where((color) => 
          ['Black', 'Navy Blue', 'Bottle Green', 'Meroon'].contains(color)
        ).toList();
      default:
        return _colors;
    }
  }

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

// enums/color_category.dart
enum ColorCategory {
  all,
  basic,
  metallic,
  pastel,
  dark,
}