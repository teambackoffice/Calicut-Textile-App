import 'package:flutter/material.dart';

class SuppliersSelect extends StatelessWidget {
  const SuppliersSelect({
    super.key,
    required this.selectedSupplier,
  });

  final String selectedSupplier;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Suppliers',
        labelStyle: const TextStyle(
          color: Colors.blueAccent,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        hintText: selectedSupplier == null || selectedSupplier!.isEmpty 
            ? 'Tap to select supplier' 
            : selectedSupplier,
        hintStyle: TextStyle(
          color: selectedSupplier == null || selectedSupplier!.isEmpty 
              ? Colors.grey[500] 
              : Colors.black87,
          fontSize: 16,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 18, 
          horizontal: 20,
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.only(left: 12, right: 8),
          child: Icon(
            Icons.business,
            color: selectedSupplier == null || selectedSupplier!.isEmpty 
                ? Colors.grey[400] 
                : Colors.blueAccent,
            size: 22,
          ),
        ),
        suffixIcon: Container(
          margin: const EdgeInsets.only(right: 12),
          child: Icon(
            Icons.keyboard_arrow_down,
            color: Colors.grey[600],
            size: 24,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      controller: TextEditingController(
        text: selectedSupplier == null || selectedSupplier!.isEmpty 
            ? '' 
            : selectedSupplier,
      ),
      style: const TextStyle(
        fontSize: 16, 
        color: Colors.black87,
        fontWeight: FontWeight.w500,
      ),
      readOnly: true,
    );
  }
}

