import 'package:calicut_textile_app/modal/add_product_modal.dart';
import 'package:calicut_textile_app/service/add_product_service.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/dialog_box_header.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/dialog_box_items.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/empty_items_container.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/new_items_add.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/order_summary.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/posting_date.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/purchase_button.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/select_suppliers.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/supplier_dialog_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class PurchaseOrderItem {
  String itemCode;
  String itemName;
  int quantity;
  double? pcs;           // Added pcs field
  double? netQty;     // Added netQty field
  double rate;
  String color;
  double amount;
  String uom;
  int imageCount;
  
  PurchaseOrderItem({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    this.pcs,           // Optional pcs
    this.netQty,        // Optional netQty
    required this.rate,
    required this.color,
    required this.amount,
    required this.uom,
    this.imageCount = 0,
  });
  
  double get total => netQty! * rate;
}

class CreatePurchaseOrder extends StatefulWidget {
  const CreatePurchaseOrder({super.key});

  @override
  State<CreatePurchaseOrder> createState() => _CreatePurchaseOrderState();
}

class _CreatePurchaseOrderState extends State<CreatePurchaseOrder> {
  String selectedSupplier = 'Select Suppliers';
  String _selectedUOM = '';
  int _selectedImageCount = 0; // Track image count from dialog
  final List<String> _uomOptions = ['unit', 'box', 'pair', 'set', 'meter', 'foot','kg','cm'];

  // Add loading state variable
  bool _isAddingItem = false;
  
  List<String> _selectedImagePaths = [];

  void _handleImagesSelected(List<String> imagePaths) {
    for (int i = 0; i < imagePaths.length; i++) {
    }
    
    setState(() {
      _selectedImagePaths = imagePaths;
    });
  }

  final TextEditingController requireddatecontroller = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        requireddatecontroller.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  final List<PurchaseOrderItem> items = [];
  final _formKey = GlobalKey<FormState>();
  
  // Controllers for dialog
  final _itemCodeController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _pcsController = TextEditingController();
  final _rateController = TextEditingController();
  final _colorController = TextEditingController();

  double get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  double get totalDiscount => 0.0;
  double get totalVAT => totalAmount * 0.15;
  double get additionalDiscount => 0.0;
  double get grandTotal => totalAmount;

  void _updateSelectedUOM(String selectedUOM) {
    setState(() {
      _selectedUOM = selectedUOM;
    });
  }

  void _updateImageCount(int imageCount) {
    setState(() {
      _selectedImageCount = imageCount;
    });
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _handleItemCreated(Item item) {
    setState(() {
      items.add(PurchaseOrderItem(
        itemCode: item.code,
        itemName: item.name,
        quantity: item.quantity?.toInt() ?? 1,
        pcs: item.pcs,                    // Pass pcs value
        netQty: item.netQty,              // Pass netQty value
        rate: item.rate ?? 0.0,
        color: item.color ?? '',
        uom: item.selectedUOM,
        imageCount: 0,
        amount: (item.rate ?? 0.0) * (item.quantity ?? 1),
      ));
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.name} added to purchase order',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Modified _addItem function with loading indicator
  void _addItem() async {
    if (_formKey.currentState!.validate()) {
      // Set loading state to true
      setState(() {
        _isAddingItem = true;
      });

      try {
        final apiKey = await const FlutterSecureStorage().read(key: 'api_key');

        // Calculate netQty if needed
        final qty = double.tryParse(_quantityController.text) ?? 0;
        final pcs = int.tryParse(_pcsController.text) ?? 0;
        final calculatedNetQty = qty * pcs;

        // Create Product object for API call
        final product = Product(
          productName: _itemNameController.text,
          qty: _quantityController.text,
          pcs: _pcsController.text,              // Include pcs
          netQty: calculatedNetQty.toString(),   // Include calculated netQty
          rate: _rateController.text,
          amount: (int.parse(_quantityController.text) * double.parse(_rateController.text)).toString(),
          color: _colorController.text,
          uom: _selectedUOM,
          imagePaths: _selectedImagePaths,
          api_key: apiKey,
        );
       
        // Call the API service
        final success = await ProductService.createProduct(
          product: product,
          context: context,
        );

        if (success == true) {
          // API call successful - add to local list
          setState(() {
            items.add(PurchaseOrderItem(
              itemCode: _itemCodeController.text,
              itemName: _itemNameController.text,
              quantity: int.parse(_quantityController.text),
              pcs: double.tryParse(_pcsController.text),          // Include pcs
              netQty: calculatedNetQty,                        // Include netQty
              rate: double.parse(_rateController.text),
              color: _colorController.text,
              uom: _selectedUOM,
              imageCount: _selectedImageCount,
              amount: (int.parse(_quantityController.text)) * (double.parse(_rateController.text)),
            ));
          });

          // Clear form fields
          _clearForm();
          
          // Close the dialog/page
          Navigator.pop(context);
          
        } else if (success == null) {
          // Handle specific error
        } else {
          // General failure
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create product. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle any unexpected errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // Always set loading state to false when done
        setState(() {
          _isAddingItem = false;
        });
      }
    }
  }

  void _clearForm() {
    _itemCodeController.clear();
    _itemNameController.clear();
    _quantityController.clear();
    _rateController.clear();
    _colorController.clear();
    _selectedUOM = '';
    _selectedImageCount = 0;
    // _selectedImagePaths.clear(); // Clear image paths
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
                      DialogBoxItems(
                        formKey: _formKey, 
                        itemCodeController: _itemCodeController, 
                        itemNameController: _itemNameController, 
                        quantityController: _quantityController, 
                        rateController: _rateController,
                        pcsController: _pcsController, 
                        colorController: _colorController,
                        UomOptions: _uomOptions,
                        onUOMSelected: _updateSelectedUOM,
                        onImageCountChanged: _updateImageCount, // Add image count callback
                        onItemCreated: _handleItemCreated,
                        onImagesSelected: _handleImagesSelected,
                      ),

                      // Action buttons with loading indicator
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
                                onPressed: _isAddingItem ? null : _addItem, // Disable when loading
                                icon: _isAddingItem 
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Icon(Icons.add_rounded),
                                label: Text(
                                  _isAddingItem ? 'ADDING...' : 'ADD ITEM',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _isAddingItem ? Colors.grey : Colors.blue,
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
  
  String? selectedSupplierId; // Store the supplier ID
  String? selectedSupplierName;
  final TextEditingController suppliercontroller =TextEditingController();

  void _showSupplierDialog() {
    showDialog(
      context: context,
      builder: (context) => SupplierDialogBox(
        suppliers: [], // Your suppliers list
        onSupplierSelected: (String supplierId, String supplierName) {
          setState(() {
            selectedSupplierId = supplierId;
            selectedSupplierName = supplierName;
            suppliercontroller.text = supplierName; // Update the TextField
          });
          
          // Optional: Call any additional callback if needed
        },
      ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required By',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Required Date',
                      labelStyle: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18, 
                        horizontal: 20,
                      ),
                      suffixIcon: Container(
                        margin: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.calendar_today,
                          color: Colors.blue,
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
                    controller: requireddatecontroller,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Suppliers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _showSupplierDialog,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AbsorbPointer(
                        child: SuppliersSelect(supplierName : suppliercontroller),
                      ),
                    ),
                  )
                ],
              ),

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
                            const SizedBox(height: 12),
                           
                            // First row: Quantity, PCS, Net Qty
                            Row(
                              children: [
                                // Quantity
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.inventory, size: 14, color: Colors.blue.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Qty: ${item.quantity}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.blue.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // PCS (if available)
                                if (item.pcs != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.apps, size: 14, color: Colors.green.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'PCS: ${item.pcs}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.green.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                
                                // Net Qty (if available)
                                if (item.netQty != null) ...[
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.purple.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calculate, size: 14, color: Colors.purple.shade700),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Net: ${item.netQty!.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.purple.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Second row: Rate and Total
                            Row(
                              children: [
                                // Rate
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.currency_rupee, size: 14, color: Colors.orange.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rate: ${item.rate.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                
                                const SizedBox(width: 12),
                                
                                // Total
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.calculate, size: 14, color: Colors.red.shade700),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Total: ₹${item.total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.red.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 8),
                            
                            // Third row: Color, UOM, Images (metadata)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Color (only if not empty)
                                if (item.color.isNotEmpty) ...[
                                  Icon(Icons.color_lens, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.color,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                ],
                                
                                // UOM (always show)
                                Icon(Icons.straighten, size: 16, color: Colors.grey.shade600),
                                const SizedBox(width: 4),
                                Text(
                                  "UOM: ${item.uom}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                
                                // Images (only if > 0)
                                if (item.imageCount > 0) ...[
                                  const SizedBox(width: 20),
                                  Icon(Icons.photo_library, size: 16, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text(
                                    "${item.imageCount} image${item.imageCount > 1 ? 's' : ''}",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
              SavePurchaseOrderButton(items: items,grandTotal :grandTotal,supplier :selectedSupplierId,requiredDate : requireddatecontroller  ),
            ],
          ),
        ),
      ),
    );
  }
}