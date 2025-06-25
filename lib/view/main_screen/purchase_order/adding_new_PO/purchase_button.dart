import 'package:calicut_textile_app/controller/add_supplier_order_controller.dart';
import 'package:calicut_textile_app/modal/add_supplier_order_modal.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/create_purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SavePurchaseOrderButton extends StatelessWidget {
  SavePurchaseOrderButton({
    super.key,
    required this.items,
    required this.grandTotal,
    required this.supplier,
    required this.requiredDate
  });

  final List<PurchaseOrderItem> items;
  final double grandTotal;
  final String? supplier;
  final TextEditingController requiredDate;

  // Helper method to parse the date safely
  DateTime _parseRequiredDate() {
    try {
      if (requiredDate.text.isEmpty) {
        return DateTime.now();
      }
      
      // The requiredDate.text comes in format 'yyyy-MM-dd' from your date picker
      
      // Parse using the correct format that matches your input
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(requiredDate.text);
      
      
      return parsedDate;
      
    } catch (e) {
      
      // Fallback to current date if parsing fails
      return DateTime.now();
    }
  }

  // Helper method to format date for display/API
  String _formatDateForAPI(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: items.isEmpty ? null : () async {
              try {
                // Parse the required date safely
                DateTime parsedRequiredDate = _parseRequiredDate();
                String formattedDate = _formatDateForAPI(DateTime.now()); // Current date for order
                String formattedRequiredDate = _formatDateForAPI(parsedRequiredDate); // Required date
                
                
                final controller = context.read<CreateSupplierOrderController>();
        
                // Create product list with proper date handling
                final productList = items.map((item) {
                  
                  return Product(
                    product: item.itemName,
                    qty: item.quantity.toInt(),
                    uom: item.uom ?? "Nos",
                    rate: item.rate.toInt(),
                    amount: item.amount.toInt(),
                    requiredDate: parsedRequiredDate, // Use the parsed DateTime directly
                  );
                }).toList();
                
                
                // Validate supplier
                if (supplier == null || supplier!.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please select a supplier first'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                // Create supplier order
                final result = await controller.CreateSupplierOrder(
                  createsupplierorder: SupplierOrderModal(
                    supplier: supplier!,
                    orderDate: formattedDate,
                    grandTotal: grandTotal.toInt(),
                    products: productList,
                  ),
                  context: context,
                );
                
                // Handle result if needed
                if (result != null) {
                  Navigator.pop(context);
                  // You might want to navigate back or show success message
                } else {
                }
                
              } catch (e) {
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving purchase order: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.save),
            label: const Text('SAVE PURCHASE ORDER'),
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