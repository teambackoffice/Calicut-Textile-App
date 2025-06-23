import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/create_purchase_order.dart';
import 'package:flutter/material.dart';

class SavePurchaseOrderButton extends StatelessWidget {
  const SavePurchaseOrderButton({
    super.key,
    required this.items,
  });

  final List<PurchaseOrderItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: items.isEmpty ? null : () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Success'),
                  content: const Text('Purchase order saved successfully!'),
                  
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
             for (var item in items) {
            print('Item: $item');
          }

          // OR simply:
          print('All Items: $items');
        
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

