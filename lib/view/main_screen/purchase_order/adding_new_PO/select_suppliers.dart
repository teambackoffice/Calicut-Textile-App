import 'package:flutter/material.dart';

class SuppliersSelect extends StatelessWidget {
  const SuppliersSelect({
    super.key,
    this.supplierName, // Keep original parameter name
  });

  final TextEditingController? supplierName; // Keep original parameter name

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
        
        hintStyle: TextStyle(
          
           
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
      // Use the supplierName directly as the controller text
      controller: TextEditingController(
        text: supplierName!.text, // Use null-aware operator
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