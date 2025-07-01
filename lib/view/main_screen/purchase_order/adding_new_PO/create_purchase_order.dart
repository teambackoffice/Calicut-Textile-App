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
  double? pcs;
  double? netQty;
  double rate;
  String color;
  double amount;
  String uom;
  int imageCount;
  List<String> imagePaths;
  
  PurchaseOrderItem({
    required this.itemCode,
    required this.itemName,
    required this.quantity,
    this.pcs,
    this.netQty,
    required this.rate,
    required this.color,
    required this.amount,
    required this.uom,
    this.imageCount = 0,
     this.imagePaths = const []
  });
  
  double get total => netQty != null ? netQty! * rate : quantity * rate;
}

class CreatePurchaseOrder extends StatefulWidget {
  const CreatePurchaseOrder({super.key});

  @override
  State<CreatePurchaseOrder> createState() => _CreatePurchaseOrderState();
  
}

class _CreatePurchaseOrderState extends State<CreatePurchaseOrder> {
  String selectedSupplier = 'Select Suppliers';
  String _selectedUOM = '';
  int _selectedImageCount = 0;
   
  
  // Add this to store all images for the order
  List<String> _allOrderImages = []; 
  
  final List<String> _uomOptions = [
    
  
    'NOS',
    'METER',
   
  ].toSet().toList();
  
  bool _isAddingItem = false;
  bool _isCreatingNewItem = false;
  bool _isDialogInCreationMode = false; // New state to track dialog creation mode
  List<String> _selectedImagePaths = [];

  void _handleImagesSelected(List<String> imagePaths) {
    setState(() {
      _selectedImagePaths = imagePaths;
    });
  }

  final TextEditingController requireddatecontroller = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime today = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: DateTime(today.year, today.month, today.day),
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

  // Handle simplified new item creation
  Future<void> _handleNewItemCreation(Item item) async {
    try {
      final apiKey = await const FlutterSecureStorage().read(key: 'api_key');

      // Create Product object for API call with simplified data
      final product = Product(
        productName: item.name,
        qty: item.quantity?.toString() ?? '1',
        pcs: '1', // Default PCS for new items
        netQty: item.quantity?.toString() ?? '1', // Same as quantity for simple items
        rate: item.rate?.toString() ?? '0',
        amount: item.totalAmount?.toString() ?? '0',
        color: '', // Empty color for new items
        uom: item.selectedUOM,
        imagePaths: [], // No images for new item creation
        api_key: apiKey,
      );
     
      final success = await ProductService.createProduct(
        product: product,
        context: context,
      );

      if (success != true) {
        // Throw exception if API call failed
        throw Exception('Failed to create product');
      }
      
      // If we reach here, the API call was successful
      print('Item created successfully: ${item.name}');
      
    } catch (e) {
      // Re-throw the exception so the dialog can handle it
      throw e;
    }
  }

  void _handleItemCreated(Item item) {
    // Extract image paths from the item
    List<String> itemImages = [];
    if (item.image1 != null) itemImages.add(item.image1!);
    if (item.image2 != null) itemImages.add(item.image2!);
    if (item.image3 != null) itemImages.add(item.image3!);

    setState(() {
      items.add(PurchaseOrderItem(
        itemCode: item.code,
        itemName: item.name,
        quantity: item.quantity?.toInt() ?? 1,
        pcs: item.pcs,
        netQty: item.netQty,
        rate: item.rate ?? 0.0,
        color: item.color ?? '',
        uom: item.selectedUOM,
        imageCount: itemImages.length, // Use actual image count
        imagePaths: itemImages, // NEW: Store the actual image paths
        amount: item.totalAmount ?? 0.0,
      ));
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                '${item.name} added to purchase order with ${itemImages.length} image(s)',
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



  void _clearForm() {
    _itemCodeController.clear();
    _itemNameController.clear();
    _quantityController.clear();
    _rateController.clear();
    _colorController.clear();
    _pcsController.clear();
    _selectedUOM = '';
    _selectedImageCount = 0;
    _selectedImagePaths.clear();
  }

  void _removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  void _showAddItemDialog() {
    // Reset dialog creation mode when opening
    setState(() {
      _isDialogInCreationMode = false;
    });
    
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Add Item Dialog',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.elasticOut),
              ),
              child: FadeTransition(
                opacity: animation,
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.95,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.85,
                    ), 
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
                          Flexible(
                            child: DialogBoxItems(
                              formKey: _formKey, 
                              itemCodeController: _itemCodeController, 
                              itemNameController: _itemNameController, 
                              quantityController: _quantityController, 
                              rateController: _rateController,
                              pcsController: _pcsController, 
                              colorController: _colorController,
                              UomOptions: _uomOptions,
                              onUOMSelected: _updateSelectedUOM,
                              onImageCountChanged: _updateImageCount,
                              onItemCreated: _handleItemCreated,
                              onImagesSelected: _handleImagesSelected,
                              onCreationModeChanged: (bool isCreatingNew) {
                                setDialogState(() {
                                  _isDialogInCreationMode = isCreatingNew;
                                });
                                setState(() {
                                  _isCreatingNewItem = isCreatingNew;
                                  _isDialogInCreationMode = isCreatingNew;
                                });
                              },
                              onNewItemCreated: _handleNewItemCreation, // New callback
                            ),
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
                                    onPressed: (_isAddingItem || _isDialogInCreationMode) ? null : () => _addItemWithDialogState(setDialogState),
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
                                      _isAddingItem 
                                        ? 'ADDING...' 
                                        : _isDialogInCreationMode
                                          ? 'CREATING ITEM...'
                                          : 'ADD ITEM',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: (_isAddingItem || _isDialogInCreationMode) ? Colors.grey : Colors.blue,
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
      },
    );
  }

  void _addItemWithDialogState(StateSetter setDialogState) async {
    if (_formKey.currentState!.validate()) {
      setDialogState(() {
        _isAddingItem = true;
      });
      setState(() {
        _isAddingItem = true;
      });

      try {
        final qty = double.tryParse(_quantityController.text) ?? 0;
        final pcs = double.tryParse(_pcsController.text) ?? 1;
        final calculatedNetQty = qty * pcs;

        setState(() {
          items.add(PurchaseOrderItem(
            itemCode: _itemCodeController.text,
            itemName: _itemNameController.text,
            quantity: qty.toInt(),
            pcs: double.tryParse(_pcsController.text),
            netQty: calculatedNetQty,
            rate: double.parse(_rateController.text),
            color: _colorController.text,
            uom: _selectedUOM,
            imageCount: _selectedImagePaths.length,
            imagePaths: List.from(_selectedImagePaths), // NEW: Copy the selected images
            amount: calculatedNetQty * double.parse(_rateController.text),
          ));
        });

        _clearForm();
        Navigator.pop(context);
        
        setState(() {
          _isDialogInCreationMode = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item added successfully with ${_selectedImagePaths.length} image(s)!',
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
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setDialogState(() {
          _isAddingItem = false;
        });
        setState(() {
          _isAddingItem = false;
        });
      }
    }
  }

  List<String> _getAllItemImages() {
    List<String> allImages = [];
    for (var item in items) {
      allImages.addAll(item.imagePaths);
    }
    return allImages;
  }

  String? selectedSupplierId;
  String? selectedSupplierName;
  final TextEditingController suppliercontroller = TextEditingController();

  void _showSupplierDialog() {
    showDialog(
      context: context,
      builder: (context) => SupplierDialogBox(
        suppliers: [],
        onSupplierSelected: (String supplierId, String supplierName) {
          setState(() {
            selectedSupplierId = supplierId;
            selectedSupplierName = supplierName;
            suppliercontroller.text = supplierName;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalImages = _getAllItemImages().length;
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        title: const Text(
          "Create Supplier PO",
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
                        child: SuppliersSelect(supplierName: suppliercontroller),
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
               SavePurchaseOrderButton(
                items: items, 
                grandTotal: grandTotal, 
                supplier: selectedSupplierId, 
                requiredDate: requireddatecontroller,
                imagePaths: _getAllItemImages(), // Pass all images from all items
                allowImageSelection: false, // Disable additional selection since images come from items
              ),
            ],
          ),
        ),
      ),
    );
  }
}