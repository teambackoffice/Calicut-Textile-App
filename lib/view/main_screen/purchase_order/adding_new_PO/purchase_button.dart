import 'dart:io';

import 'package:calicut_textile_app/controller/add_supplier_order_controller.dart';
import 'package:calicut_textile_app/modal/add_supplier_order_modal.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/create_purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

class SavePurchaseOrderButton extends StatefulWidget {
  SavePurchaseOrderButton({
    super.key,
    required this.items,
    required this.grandTotal,
    required this.supplier,
    required this.requiredDate,
    this.imagePaths, // Optional image paths
    this.allowImageSelection = false, // Flag to enable image selection
  });

  final List<PurchaseOrderItem> items;
  final double grandTotal;
  final String? supplier;
  final TextEditingController requiredDate;
  final List<String>? imagePaths; // Optional pre-selected image paths
  final bool allowImageSelection; // Allow user to select images

  @override
  State<SavePurchaseOrderButton> createState() => _SavePurchaseOrderButtonState();
}

class _SavePurchaseOrderButtonState extends State<SavePurchaseOrderButton> {
  bool _isLoading = false;
  List<String> _selectedImagePaths = [];

  @override
  void initState() {
    super.initState();
    // Initialize with any pre-selected image paths
    if (widget.imagePaths != null) {
      _selectedImagePaths = List.from(widget.imagePaths!);
    }
  }

  // Helper method to parse the date safely
  DateTime _parseRequiredDate() {
    try {
      if (widget.requiredDate.text.isEmpty) {
        return DateTime.now();
      }
      
      // The requiredDate.text comes in format 'yyyy-MM-dd' from your date picker
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(widget.requiredDate.text);
      return parsedDate;
      
    } catch (e) {
      print('Error parsing date: $e');
      // Fallback to current date if parsing fails
      return DateTime.now();
    }
  }

  // Helper method to format date for display/API
  String _formatDateForAPI(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Method to pick images
  Future<void> _pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> images = await picker.pickMultiImage();
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImagePaths.addAll(images.map((image) => image.path));
        });
      }
    } catch (e) {
      print('Error picking images: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting images: ${e.toString()}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Method to remove selected image
  void _removeImage(int index) {
    setState(() {
      _selectedImagePaths.removeAt(index);
    });
  }

  // Create supplier order using the updated controller
   Future<void> _createSupplierOrder() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Parse the required date safely
      DateTime parsedRequiredDate = _parseRequiredDate();
      String formattedOrderDate = _formatDateForAPI(DateTime.now());
      
      print('=== ORDER CREATION DEBUG ===');
      print('Supplier: ${widget.supplier}');
      print('Order Date: $formattedOrderDate');
      print('Grand Total: ${widget.grandTotal}');
      print('Items Count: ${widget.items.length}');
      
      // Debug: Print images from widget
      if (widget.imagePaths != null && widget.imagePaths!.isNotEmpty) {
        print('Images from SaveButton: ${widget.imagePaths!.length}');
        for (int i = 0; i < widget.imagePaths!.length; i++) {
          print('  Image ${i + 1}: ${widget.imagePaths![i]}');
        }
      } else {
        print('No images passed to SaveButton');
      }

      // Debug: Print images from each item
      print('Images from each item:');
      for (int i = 0; i < widget.items.length; i++) {
        final item = widget.items[i];
        if (item.imagePaths.isNotEmpty) {
          print('  Item ${i + 1} (${item.itemName}): ${item.imagePaths.length} images');
          for (int j = 0; j < item.imagePaths.length; j++) {
            print('    - ${item.imagePaths[j]}');
          }
        } else {
          print('  Item ${i + 1} (${item.itemName}): No images');
        }
      }
      
      // Validate supplier
      if (widget.supplier == null || widget.supplier!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a supplier first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Create product list
      final productList = widget.items.map((item) {
        return Product(
          product: item.itemName,
          qty: item.quantity.toInt(),
          uom: item.uom ?? "Nos",
          rate: item.rate.toDouble(),
          amount: item.amount.toDouble(),
          requiredDate: parsedRequiredDate,
          pcs: item.pcs?.toDouble(),
          netQty: item.netQty?.toDouble(),
          color: item.color.isNotEmpty ? item.color : null,
        );
      }).toList();

      // Create supplier order modal with images
      final supplierOrderModal = SupplierOrderModal(
        supplier: widget.supplier!,
        orderDate: formattedOrderDate,
        grandTotal: widget.grandTotal,
        products: productList,
        imagePaths: widget.imagePaths, // This should now contain all item images
      );

      print('Final images being sent to API: ${supplierOrderModal.imagePaths?.length ?? 0}');

      // Get controller and create order
      final controller = context.read<CreateSupplierOrderController>();
      
      final result = await controller.createSupplierOrderFromModal(
        supplierOrder: supplierOrderModal,
        context: context,
      );

      // Handle result (your existing code)...
      if (result == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Supplier order created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else if (result == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error or authentication failed. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(controller.errorMessage ?? 'Failed to create supplier order'),
            backgroundColor: Colors.red,
          ),
        );
      }

    } catch (e) {
      print('Error in _createSupplierOrder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving purchase order: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Image selection section (if enabled)
        if (widget.allowImageSelection) ...[
          // Selected images display
          if (_selectedImagePaths.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected Images (${_selectedImagePaths.length})',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImagePaths.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(_selectedImagePaths[index]),
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Add images button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            child: OutlinedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Images'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],

        // Save button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: widget.items.isEmpty || _isLoading ? null : _createSupplierOrder,
            icon: _isLoading 
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save),
            label: Text(_isLoading ? 'SAVING...' : 'SAVE SUPPLIER ORDER'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}

// If you need to add color field to PurchaseOrderItem class
// Add this to your PurchaseOrderItem class:
/*
class PurchaseOrderItem {
  // ... existing fields ...
  final String? color; // Add color field
  
  PurchaseOrderItem({
    // ... existing parameters ...
    this.color, // Add color parameter
  });
}
*/