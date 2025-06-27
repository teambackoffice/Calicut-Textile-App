import 'package:calicut_textile_app/controller/add_supplier_order_controller.dart';
import 'package:calicut_textile_app/modal/add_supplier_order_modal.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/create_purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SavePurchaseOrderButton extends StatefulWidget {
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

  @override
  State<SavePurchaseOrderButton> createState() => _SavePurchaseOrderButtonState();
}

class _SavePurchaseOrderButtonState extends State<SavePurchaseOrderButton> {

   bool _isLoading = false;
  // Helper method to parse the date safely
  DateTime _parseRequiredDate() {
    try {
      if (widget.requiredDate.text.isEmpty) {
        return DateTime.now();
      }
      
      // The requiredDate.text comes in format 'yyyy-MM-dd' from your date picker
      
      // Parse using the correct format that matches your input
      DateTime parsedDate = DateFormat('yyyy-MM-dd').parse(widget.requiredDate.text);
      
      
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
            onPressed: widget.items.isEmpty ? null : () async {
              setState(() {
    _isLoading = true;
  });
              try {
                // Parse the required date safely
                DateTime parsedRequiredDate = _parseRequiredDate();
                String formattedDate = _formatDateForAPI(DateTime.now()); // Current date for order
                String formattedRequiredDate = _formatDateForAPI(parsedRequiredDate); // Required date
                
                
                final controller = context.read<CreateSupplierOrderController>();
        
                // Create product list with proper date handling
                final productList = widget.items.map((item) {
                  
                  return Product(
                    product: item.itemName,
                    qty: item.quantity.toInt(),
                    uom: item.uom,
                    rate: item.rate.toInt(),
                   
                    amount: item.amount.toInt(),
                    requiredDate: parsedRequiredDate, pcs: item.pcs, netQty: item.netQty!, // Use the parsed DateTime directly
                  );
                }).toList();
               productList.forEach((product) {
  print('--- Product ---');
  print('Product Name: ${product.product}');
  print('Quantity: ${product.qty}');
  print('UOM: ${product.uom}');
  print('Rate: ${product.rate}');
  print('Amount: ${product.amount}');
  print('Required Date: ${product.requiredDate}');
  print('PCS: ${product.pcs}');
  print('Net Qty: ${product.netQty}');
});
                
                
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
                
                // Create supplier order
                final result = await controller.CreateSupplierOrder(
                  createsupplierorder: SupplierOrderModal(
                    supplier: widget.supplier!,
                    orderDate: formattedDate,
                    grandTotal: widget.grandTotal.toInt(),
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
              finally {
                setState(() {
                  _isLoading = false;
                });
              
              }
            },
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
            label: Text(_isLoading ? 'SAVING...' : 'SAVE PURCHASE ORDER'),
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