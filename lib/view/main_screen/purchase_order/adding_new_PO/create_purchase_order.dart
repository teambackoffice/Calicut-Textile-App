import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/dialog_box_header.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/dialog_box_items.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/empty_items_container.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/new_items_add.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/order_summary.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/posting_date.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/purchase_button.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PurchaseOrderItem {
  String itemCode;
  String itemName;
  int quantity;
  double rate;
  String color;
  
  PurchaseOrderItem({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.color,
  });
  
  double get total => quantity * rate;
}

class CreatePurchaseOrder extends StatefulWidget {
  const CreatePurchaseOrder({super.key});

  @override
  State<CreatePurchaseOrder> createState() => _CreatePurchaseOrderState();
}

class _CreatePurchaseOrderState extends State<CreatePurchaseOrder> {
  final List<PurchaseOrderItem> items = [];
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for dialog
  final _itemCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _rateController = TextEditingController();
  final _colorController = TextEditingController();

  double get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  double get totalDiscount => 0.0;
  double get totalVAT => totalAmount * 0.15;
  double get additionalDiscount => 0.0;
  double get grandTotal => totalAmount - totalDiscount + totalVAT - additionalDiscount;

  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        items.add(PurchaseOrderItem(
          itemCode: _itemCodeController.text,
          itemName: _itemNameController.text,
          quantity: int.parse(_quantityController.text),
          rate: double.parse(_rateController.text),
          color: _colorController.text,
        ));
      });
      
      _itemCodeController.clear();
      _itemNameController.clear();
      _quantityController.clear();
      _rateController.clear();
      _colorController.clear();
      
      Navigator.pop(context);
    }
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _showAddItemDialog() {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Add Item Dialog',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, animation, secondaryAnimation) {
      return Container();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.8, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.elasticOut),
        ),
        child: FadeTransition(
          opacity: animation,
          child: Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.95,
              height: MediaQuery.of(context).size.height * 0.85,
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: Column(
                  children: [
                    // Header with blue gradient background
                    DialogBoxHeader(),

                    // Form content
                    DialogBoxItems(formKey: _formKey, itemCodeController: _itemCodeController, itemNameController: _itemNameController, quantityController: _quantityController, rateController: _rateController, colorController: _colorController),

                    // Action buttons
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(28),
                          bottomRight: Radius.circular(28),
                        ),
                      ),
                      child: Row(
                        children: [
                         
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: _addItem,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text(
                                'ADD ITEM',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Create Purchase Order",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
       
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              PostingDate(),
              const SizedBox(height: 20),

              // Items Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Items',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${items.length} item(s)',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Add Item Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('ADD ITEM'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Items List
                  if (items.isEmpty)
                    EmptyItemsContainer()
                  else
                    ...items.asMap().entries.map((entry) {
                      int index = entry.key;
                      PurchaseOrderItem item = entry.value;
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeItem(index),
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    constraints: const BoxConstraints(),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Code: ${item.itemCode}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.numbers, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Qty: ${item.quantity.toString()}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Row(
                                    children: [
                                      Icon(Icons.attach_money, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rate: \$${item.rate.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Row(
                                    children: [
                                      Icon(Icons.calculate, size: 16, color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Total: \$${item.total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              if (item.color.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.color_lens, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      item.color,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Section
              OrderSummaryCard(totalQuantity: totalQuantity, totalAmount: totalAmount, grandTotal: grandTotal),
              const SizedBox(height: 24),

              // Action Buttons
              SavePurchaseOrderButton(items: items),
            ],
          ),
        ),
      ),
    );
  }
}

