import 'package:flutter/material.dart';

class ItemsAdding extends StatelessWidget {
  const ItemsAdding({
    super.key,
    required TextEditingController itemCodeController,
    required TextEditingController itemNameController,
    required TextEditingController quantityController,
    required TextEditingController rateController,
    required TextEditingController colorController,
  }) : _itemCodeController = itemCodeController, _itemNameController = itemNameController, _quantityController = quantityController, _rateController = rateController, _colorController = colorController;

  final TextEditingController _itemCodeController;
  final TextEditingController _itemNameController;
  final TextEditingController _quantityController;
  final TextEditingController _rateController;
  final TextEditingController _colorController;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: _itemCodeController,
          validator: (value) => value?.isEmpty == true ? 'Item code is required' : null,
          decoration: InputDecoration(
            labelText: 'Item Code',
            prefixIcon: const Icon(Icons.qr_code),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _itemNameController,
          validator: (value) => value?.isEmpty == true ? 'Item name is required' : null,
          decoration: InputDecoration(
            labelText: 'Item Name',
            prefixIcon: const Icon(Icons.inventory),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _quantityController,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Quantity is required';
            if (int.tryParse(value!) == null) return 'Enter a valid number';
            if (int.parse(value) <= 0) return 'Quantity must be greater than 0';
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Quantitqqqy',
            prefixIcon: const Icon(Icons.numbers),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (value?.isEmpty == true) return 'Rate is required';
            if (double.tryParse(value!) == null) return 'Enter a valid amount';
            if (double.parse(value) <= 0) return 'Rate must be greater than 0';
            return null;
          },
          decoration: InputDecoration(
            labelText: 'Rate',
            prefixIcon: const Icon(Icons.attach_money),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _colorController,
          decoration: InputDecoration(
            labelText: 'Color',
            prefixIcon: const Icon(Icons.color_lens),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}

