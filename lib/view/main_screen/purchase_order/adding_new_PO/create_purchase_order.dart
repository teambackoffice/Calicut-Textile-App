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
  double rate;
  String color;
  double amount;
  String uom;
  int imageCount; // Added image count field
  
  PurchaseOrderItem({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    required this.rate,
    required this.color,
    required this.amount,
    required this.uom,
    this.imageCount = 0, // Default to 0 images
  });
  
  double get total => quantity * rate;
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

  
    List<String> _selectedImagePaths = [];

      void _handleImagesSelected(List<String> imagePaths) {
    for (int i = 0; i < imagePaths.length; i++) {
    }
    
    setState(() {
      _selectedImagePaths = imagePaths;
    });
    
  }


  final List<String> suppliers = [
    'Global Supplies Ltd.',
    'FreshMart Distributors',
    'BlueWave Traders',
    'Sunrise Industries',
    'GreenLeaf Suppliers',
    'Ace Hardware Co.',
    'Silverline Wholesalers',
    'Urban Essentials',
    'MegaMart Partners',
    'PrimeSource Pvt. Ltd.',
    'FastTrack Logistics',
    'BrightStar Solutions',
    'Infinity Supplies',
    'Royal Traders Group',
    'Galaxy Distributors',
  ];
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
      requireddatecontroller.text = DateFormat('yyyy-MM-dd').format(picked); // ✅ fixed
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

  // Add these imports at the top of your file
void _handleItemCreated(Item item) {
   
    
    setState(() {
      items.add(PurchaseOrderItem(
        itemCode: item.code,
        itemName: item.name,
        quantity: item.quantity?.toInt() ?? 1,
        rate: item.rate ?? 0.0,
        color: item.color ?? '',
        uom: item.selectedUOM!,
        imageCount: 0, amount: (item.rate)! * (item.quantity!),
 // You can update this based on images if needed
      ));
    });
    
    
    // Show success message on the main page
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

// Modified _addItem function
void _addItem() async {
     final apiKey = await const FlutterSecureStorage().read(key: 'api_key');

  if (_formKey.currentState!.validate()) {
    // Show loading indicator
   

    try {
      // Create Product object for API call
      final product = Product(
        productName: _itemNameController.text,
        qty: _quantityController.text,
        rate: _rateController.text,
        amount: (int.parse(_quantityController.text) * double.parse(_rateController.text)).toString(),
        color: _colorController.text,
        uom: _selectedUOM,
        imagePaths: _selectedImagePaths, api_key: apiKey, // Add this list to store selected image paths
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
            rate: double.parse(_rateController.text),
            color: _colorController.text,
            uom: _selectedUOM,
            imageCount: _selectedImageCount, amount: (int.parse(_quantityController.text))! * (double.parse(_rateController.text)),
          ));
        });

        // Clear form fields
        _clearForm();
        
        // Close the dialog/page
        Navigator.pop(context);
        
        // Show success message (already handled in service)
        
      } else if (success == null) {
        // Specific error occurred (handled in service with snackbar)
        // Keep the form open for user to retry
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
      // Hide loading indicator
      
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
                             
                              // First row: Quantity, Rate, Total
                              Row(
                                children: [
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Text(
                                        'Qty: ${item.quantity.toString()}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 20),
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rate: ${item.rate.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 25),
                                  Row(
                                    children: [
                                      const SizedBox(width: 4),
                                      Text(
                                        'Total: ${item.total.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              
                              // Second row: Color, UOM, Images (always show)
                              const SizedBox(height: 8),
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
                                    "UOM: ${item.uom}", // Use item.uom instead of global _selectedUOM
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