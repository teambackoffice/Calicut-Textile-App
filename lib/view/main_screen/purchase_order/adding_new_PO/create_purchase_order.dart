import 'package:calicut_textile_app/controller/get_all_types_controller.dart';
import 'package:calicut_textile_app/controller/get_colours_controller.dart';
import 'package:calicut_textile_app/controller/get_designs_controller.dart';
import 'package:calicut_textile_app/modal/add_product_modal.dart';
import 'package:calicut_textile_app/service/add_product_service.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/dialog_box_header.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/dialog_box_items.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/empty_items_container.dart';
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
  String? type; // NEW FIELD
  String? design; // NEW FIELD
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
    this.type, // NEW FIELD
    this.design, // NEW FIELD
    required this.amount,
    required this.uom,
    this.imageCount = 0,
    this.imagePaths = const [],
  });

  double get total => netQty != null ? netQty! * rate : quantity * rate;
  PurchaseOrderItem copy() {
    return PurchaseOrderItem(
      itemCode: itemCode,
      itemName: itemName,
      quantity: quantity,
      pcs: pcs,
      netQty: netQty,
      rate: rate,
      color: color,
      type: type,
      design: design,
      amount: amount,
      uom: uom,
      imageCount: imageCount,
      imagePaths: List<String>.from(imagePaths),
    );
  }
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
  final _typeController = TextEditingController();
  final _designController = TextEditingController();

  int? _editingIndex;
  bool _showEditForm = false;

  final _editItemCodeController = TextEditingController();
  final _editItemNameController = TextEditingController();
  final _editQuantityController = TextEditingController();
  final _editPcsController = TextEditingController();
  final _editRateController = TextEditingController();
  final _editColorController = TextEditingController();
  final _editTypeController = TextEditingController();
  final _editDesignController = TextEditingController();
  final _editNetQtyController = TextEditingController();
  final _editTotalAmountController = TextEditingController();

  String _editSelectedUOM = '';
  List<String> _editSelectedImagePaths = [];
  final _editFormKey = GlobalKey<FormState>();

  // Controllers for searchable dropdowns
  late ColorsController _editColorsController;
  late DesignsController _editDesignsController;
  late TextileTypesController _editTypesController;

  // Focus nodes for edit form
  final FocusNode _editColorFocusNode = FocusNode();
  final FocusNode _editTypeFocusNode = FocusNode();
  final FocusNode _editDesignFocusNode = FocusNode();

  // Dropdown states for edit form
  bool _editShowColorDropdown = false;
  bool _editShowTypeDropdown = false;
  bool _editShowDesignDropdown = false;

  String _editColorSearchQuery = '';
  String _editTypeSearchQuery = '';
  String _editDesignSearchQuery = '';

  String? _editSelectedColor;
  String? _editSelectedType;
  String? _editSelectedDesign;

  // Add this to store all images for the order
  final List<String> _allOrderImages = [];

  final List<String> _uomOptions = {'NOS', 'METER'}.toList();

  bool _isAddingItem = false;
  bool _isCreatingNewItem = false;
  bool _isDialogInCreationMode =
      false; // New state to track dialog creation mode
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
  void initState() {
    super.initState();

    // Initialize edit controllers
    _editColorsController = ColorsController();
    _editDesignsController = DesignsController();
    _editTypesController = TextileTypesController();

    // Load data for edit form
    _editColorsController.loadColors();
    _editDesignsController.loadDesigns();
    _editTypesController.loadTextileTypes();

    // Add listeners for edit form focus nodes
    _editColorFocusNode.addListener(_onEditColorFocusChange);
    _editTypeFocusNode.addListener(_onEditTypeFocusChange);
    _editDesignFocusNode.addListener(_onEditDesignFocusChange);

    // Add listeners for edit form calculations
    _editQuantityController.addListener(_calculateEditNetQty);
    _editPcsController.addListener(_calculateEditNetQty);
    _editRateController.addListener(_calculateEditTotal);

    // ... rest of existing initState code ...
  }

  @override
  void dispose() {
    _itemCodeController.dispose();
    _itemNameController.dispose();
    _quantityController.dispose();
    _rateController.dispose();
    _colorController.dispose();
    _typeController.dispose(); // ADD THIS
    _designController.dispose(); // ADD THIS
    _editItemCodeController.dispose();
    _editItemNameController.dispose();
    _editQuantityController.dispose();
    _editPcsController.dispose();
    _editRateController.dispose();
    _editColorController.dispose();
    _editTypeController.dispose();
    _editDesignController.dispose();
    _editNetQtyController.dispose();
    _editTotalAmountController.dispose();

    // Dispose edit focus nodes
    _editColorFocusNode.dispose();
    _editTypeFocusNode.dispose();
    _editDesignFocusNode.dispose();

    // Dispose edit data controllers
    _editColorsController.dispose();
    _editDesignsController.dispose();
    _editTypesController.dispose();
    super.dispose();
  }

  void _onEditColorFocusChange() {
    setState(() {
      _editShowColorDropdown = _editColorFocusNode.hasFocus;
    });
  }

  void _onEditTypeFocusChange() {
    setState(() {
      _editShowTypeDropdown = _editTypeFocusNode.hasFocus;
    });
  }

  void _onEditDesignFocusChange() {
    setState(() {
      _editShowDesignDropdown = _editDesignFocusNode.hasFocus;
    });
  }

  // Edit form calculation methods
  void _calculateEditNetQty() {
    final qty = double.tryParse(_editQuantityController.text) ?? 1.0;
    final pcs = double.tryParse(_editPcsController.text) ?? 1.0;

    final result = qty * pcs;
    _editNetQtyController.text = result.toStringAsFixed(2);
    _calculateEditTotal();
  }

  void _calculateEditTotal() {
    final netQty = double.tryParse(_editNetQtyController.text) ?? 0.0;
    final rate = double.tryParse(_editRateController.text) ?? 0.0;

    final total = netQty * rate;
    _editTotalAmountController.text = total == 0
        ? ''
        : total.toStringAsFixed(2);
  }

  // Filter methods for edit dropdowns
  List<String> _getEditFilteredColors() {
    if (_editColorSearchQuery.isEmpty) return _editColorsController.colors;
    return _editColorsController.colors
        .where(
          (color) =>
              color.toLowerCase().contains(_editColorSearchQuery.toLowerCase()),
        )
        .toList();
  }

  List<String> _getEditFilteredTypes() {
    if (_editTypeSearchQuery.isEmpty) return _editTypesController.textileTypes;
    return _editTypesController.textileTypes
        .where(
          (type) =>
              type.toLowerCase().contains(_editTypeSearchQuery.toLowerCase()),
        )
        .toList();
  }

  List<String> _getEditFilteredDesigns() {
    if (_editDesignSearchQuery.isEmpty) return _editDesignsController.designs;
    return _editDesignsController.designs
        .where(
          (design) => design.toLowerCase().contains(
            _editDesignSearchQuery.toLowerCase(),
          ),
        )
        .toList();
  }

  void _editItem(int index) {
    final item = items[index];

    // Populate edit controllers with existing item data
    _editItemCodeController.text = item.itemCode;
    _editItemNameController.text = item.itemName;
    _editQuantityController.text = item.quantity.toString();
    _editPcsController.text = item.pcs?.toString() ?? '';
    _editRateController.text = item.rate.toString();
    _editColorController.text = item.color;
    _editTypeController.text = item.type ?? '';
    _editDesignController.text = item.design ?? '';
    _editSelectedUOM = item.uom;
    _editSelectedImagePaths = List.from(item.imagePaths);

    // Calculate net qty and total
    final qty = double.tryParse(_editQuantityController.text) ?? 1.0;
    final pcs = double.tryParse(_editPcsController.text) ?? 1.0;
    _editNetQtyController.text = (qty * pcs).toStringAsFixed(2);
    _editTotalAmountController.text = item.total.toStringAsFixed(2);

    // Set selected values for dropdowns
    _editSelectedColor = item.color.isNotEmpty ? item.color : null;
    _editSelectedType = item.type;
    _editSelectedDesign = item.design;

    // Set editing state
    setState(() {
      _editingIndex = index;
      _showEditForm = true;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIndex = null;
      _showEditForm = false;
    });
    _clearEditForm();
  }

  void _clearEditForm() {
    _editItemCodeController.clear();
    _editItemNameController.clear();
    _editQuantityController.clear();
    _editPcsController.clear();
    _editRateController.clear();
    _editColorController.clear();
    _editTypeController.clear();
    _editDesignController.clear();
    _editNetQtyController.clear();
    _editTotalAmountController.clear();
    _editSelectedUOM = '';
    _editSelectedImagePaths.clear();

    // Reset dropdown states
    _editSelectedColor = null;
    _editSelectedType = null;
    _editSelectedDesign = null;
    _editShowColorDropdown = false;
    _editShowTypeDropdown = false;
    _editShowDesignDropdown = false;
    _editColorSearchQuery = '';
    _editTypeSearchQuery = '';
    _editDesignSearchQuery = '';
  }

  void _saveEdit() async {
    if (_editFormKey.currentState!.validate() && _editingIndex != null) {
      setState(() {
        _isAddingItem = true;
      });

      try {
        final qty = double.tryParse(_editQuantityController.text) ?? 0;
        final pcs = double.tryParse(_editPcsController.text) ?? 1;
        final calculatedNetQty = qty * pcs;

        // Update the item
        setState(() {
          items[_editingIndex!] = PurchaseOrderItem(
            itemCode: _editItemCodeController.text,
            itemName: _editItemNameController.text,
            quantity: qty.toInt(),
            pcs: double.tryParse(_editPcsController.text),
            netQty: calculatedNetQty,
            rate: double.parse(_editRateController.text),
            color: _editColorController.text,
            type: _editTypeController.text.isEmpty
                ? null
                : _editTypeController.text,
            design: _editDesignController.text.isEmpty
                ? null
                : _editDesignController.text,
            uom: _editSelectedUOM,
            imageCount: _editSelectedImagePaths.length,
            imagePaths: List.from(_editSelectedImagePaths),
            amount: calculatedNetQty * double.parse(_editRateController.text),
          );
        });

        _cancelEdit();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Item updated successfully!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.blue.shade600,
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
        setState(() {
          _isAddingItem = false;
        });
      }
    }
  }

  Widget _buildEditForm() {
    return Card(
      color: Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _editFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit Item',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _cancelEdit,
                    icon: Icon(Icons.close, size: 18),
                    label: Text('Cancel'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Form fields
              Row(
                children: [
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Item Code',
                      child: TextFormField(
                        controller: _editItemCodeController,
                        readOnly: true,
                        decoration: _getEditInputDecoration(
                          '',
                        ).copyWith(fillColor: Colors.grey[100], filled: true),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Item Name',
                      child: TextFormField(
                        controller: _editItemNameController,
                        readOnly: true,
                        decoration: _getEditInputDecoration(
                          '',
                        ).copyWith(fillColor: Colors.grey[100], filled: true),
                      ),
                    ),
                  ),
                ],
              ),

              // Quantity and PCS
              Row(
                children: [
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Quantity *',
                      child: TextFormField(
                        controller: _editQuantityController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          if (double.tryParse(value!) == null) return 'Invalid';
                          if (double.parse(value) <= 0) return 'Must be > 0';
                          return null;
                        },
                        decoration: _getEditInputDecoration(''),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditFormField(
                      label: 'PCS *',
                      child: TextFormField(
                        controller: _editPcsController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          if (double.tryParse(value!) == null) return 'Invalid';
                          if (double.parse(value) <= 0) return 'Must be > 0';
                          return null;
                        },
                        decoration: _getEditInputDecoration(''),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Net Qty',
                      child: TextFormField(
                        controller: _editNetQtyController,
                        readOnly: true,
                        decoration: _getEditInputDecoration(
                          '',
                        ).copyWith(fillColor: Colors.grey[100], filled: true),
                      ),
                    ),
                  ),
                ],
              ),

              // Rate and UOM
              Row(
                children: [
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Rate *',
                      child: TextFormField(
                        controller: _editRateController,
                        keyboardType: TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Required';
                          if (double.tryParse(value!) == null) return 'Invalid';
                          if (double.parse(value) <= 0) return 'Must be > 0';
                          return null;
                        },
                        decoration: _getEditInputDecoration(
                          '0.00',
                        ).copyWith(prefixText: '₹ '),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditFormField(
                      label: 'UOM *',
                      child: _buildEditUOMButtons(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Total Amount',
                      child: TextFormField(
                        controller: _editTotalAmountController,
                        readOnly: true,
                        decoration: _getEditInputDecoration('').copyWith(
                          fillColor: Colors.grey[100],
                          filled: true,
                          prefixText: '₹ ',
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // Color, Type, Design
              Row(
                children: [
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Color',
                      child: _buildEditSearchableColorField(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Type',
                      child: _buildEditSearchableTypeField(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildEditFormField(
                      label: 'Design',
                      child: _buildEditSearchableDesignField(),
                    ),
                  ),
                ],
              ),

              // Action buttons
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _cancelEdit,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade600),
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _isAddingItem ? null : _saveEdit,
                      icon: _isAddingItem
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Icon(Icons.save),
                      label: Text(
                        _isAddingItem ? 'Updating...' : 'Update Item',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isAddingItem
                            ? Colors.grey
                            : Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for edit form
  Widget _buildEditFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        const SizedBox(height: 6),
        child,
        const SizedBox(height: 16),
      ],
    );
  }

  InputDecoration _getEditInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      isDense: true,
    );
  }

  Widget _buildEditUOMButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _editSelectedUOM = 'NOS';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _editSelectedUOM == 'NOS'
                  ? Colors.blue.shade600
                  : Colors.grey[200],
              foregroundColor: _editSelectedUOM == 'NOS'
                  ? Colors.white
                  : Colors.black87,
              elevation: _editSelectedUOM == 'NOS' ? 2 : 0,
              padding: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text('NOS', style: TextStyle(fontSize: 12)),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _editSelectedUOM = 'METER';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _editSelectedUOM == 'METER'
                  ? Colors.blue.shade600
                  : Colors.grey[200],
              foregroundColor: _editSelectedUOM == 'METER'
                  ? Colors.white
                  : Colors.black87,
              elevation: _editSelectedUOM == 'METER' ? 2 : 0,
              padding: EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text('METER', style: TextStyle(fontSize: 12)),
          ),
        ),
      ],
    );
  }

  // Searchable dropdown methods for edit form (similar to DialogBoxItems)
  Widget _buildEditSearchableColorField() {
    return Column(
      children: [
        TextFormField(
          controller: _editColorController,
          focusNode: _editColorFocusNode,
          decoration: _getEditInputDecoration(
            'Search colors...',
          ).copyWith(suffixIcon: Icon(Icons.arrow_drop_down, size: 20)),
          onChanged: (value) {
            setState(() {
              _editColorSearchQuery = value;
              _editSelectedColor = value.isEmpty ? null : value;
            });
          },
          onTap: () {
            setState(() {
              _editShowColorDropdown = true;
            });
          },
        ),
        if (_editShowColorDropdown) ...[
          SizedBox(height: 4),
          _buildEditDropdown(_getEditFilteredColors(), _editSelectedColor, (
            color,
          ) {
            setState(() {
              _editSelectedColor = color;
              _editColorController.text = color;
              _editShowColorDropdown = false;
            });
            _editColorFocusNode.unfocus();
          }),
        ],
      ],
    );
  }

  Widget _buildEditSearchableTypeField() {
    return Column(
      children: [
        TextFormField(
          controller: _editTypeController,
          focusNode: _editTypeFocusNode,
          decoration: _getEditInputDecoration(
            'Search types...',
          ).copyWith(suffixIcon: Icon(Icons.arrow_drop_down, size: 20)),
          onChanged: (value) {
            setState(() {
              _editTypeSearchQuery = value;
              _editSelectedType = value.isEmpty ? null : value;
            });
          },
          onTap: () {
            setState(() {
              _editShowTypeDropdown = true;
            });
          },
        ),
        if (_editShowTypeDropdown) ...[
          SizedBox(height: 4),
          _buildEditDropdown(_getEditFilteredTypes(), _editSelectedType, (
            type,
          ) {
            setState(() {
              _editSelectedType = type;
              _editTypeController.text = type;
              _editShowTypeDropdown = false;
            });
            _editTypeFocusNode.unfocus();
          }),
        ],
      ],
    );
  }

  Widget _buildEditSearchableDesignField() {
    return Column(
      children: [
        TextFormField(
          controller: _editDesignController,
          focusNode: _editDesignFocusNode,
          decoration: _getEditInputDecoration(
            'Search designs...',
          ).copyWith(suffixIcon: Icon(Icons.arrow_drop_down, size: 20)),
          onChanged: (value) {
            setState(() {
              _editDesignSearchQuery = value;
              _editSelectedDesign = value.isEmpty ? null : value;
            });
          },
          onTap: () {
            setState(() {
              _editShowDesignDropdown = true;
            });
          },
        ),
        if (_editShowDesignDropdown) ...[
          SizedBox(height: 4),
          _buildEditDropdown(_getEditFilteredDesigns(), _editSelectedDesign, (
            design,
          ) {
            setState(() {
              _editSelectedDesign = design;
              _editDesignController.text = design;
              _editShowDesignDropdown = false;
            });
            _editDesignFocusNode.unfocus();
          }),
        ],
      ],
    );
  }

  Widget _buildEditDropdown(
    List<String> items,
    String? selectedItem,
    Function(String) onSelect,
  ) {
    return Container(
      constraints: BoxConstraints(maxHeight: 150),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isSelected = selectedItem == item;

          return InkWell(
            onTap: () => onSelect(item),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue.shade50 : null,
              ),
              child: Text(
                item,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
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
        netQty:
            item.quantity?.toString() ??
            '1', // Same as quantity for simple items
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
      rethrow;
    }
  }

  void _handleItemCreated(Item item) {
    // Extract image paths from the item
    List<String> itemImages = [];
    if (item.image1 != null) itemImages.add(item.image1!);
    if (item.image2 != null) itemImages.add(item.image2!);
    if (item.image3 != null) itemImages.add(item.image3!);

    // Use the same fallback logic as in _addCurrentItem
    final finalUOM = item.selectedUOM.isNotEmpty ? item.selectedUOM : '';

    setState(() {
      items.add(
        PurchaseOrderItem(
          itemCode: item.code,
          itemName: item.name,
          quantity: item.quantity?.toInt() ?? 1,
          pcs: item.pcs,
          netQty: item.netQty,
          rate: item.rate ?? 0.0,
          color: item.color ?? '',
          type: item.type, // Make sure this is included
          design: item.design, // Make sure this is included
          uom: finalUOM,
          imageCount: itemImages.length,
          imagePaths: itemImages,
          amount: item.totalAmount ?? 0.0,
        ),
      );
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
    _typeController.clear(); // ADD THIS
    _designController.clear(); // ADD THIS
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
                  insetPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 40,
                  ),
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
                              typeController: _typeController, // ADD THIS
                              designController: _designController,
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
                              onNewItemCreated:
                                  _handleNewItemCreation, // New callback
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
                                    onPressed:
                                        (_isAddingItem ||
                                            _isDialogInCreationMode)
                                        ? null
                                        : () => _addItemWithDialogState(
                                            setDialogState,
                                          ),
                                    icon: _isAddingItem
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                    Colors.white,
                                                  ),
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
                                      backgroundColor:
                                          (_isAddingItem ||
                                              _isDialogInCreationMode)
                                          ? Colors.grey
                                          : Colors.blue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
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

        // You need to get the type and design values from the dialog
        // Add these controllers to your class if they don't exist
        // You need to pass this from the dialog

        setState(() {
          items.add(
            PurchaseOrderItem(
              itemCode: _itemCodeController.text,
              itemName: _itemNameController.text,
              quantity: qty.toInt(),
              pcs: double.tryParse(_pcsController.text),
              netQty: calculatedNetQty,
              rate: double.parse(_rateController.text),
              color: _colorController.text,
              type: _typeController.text.isEmpty
                  ? null
                  : _typeController.text, // ADD THIS
              design: _designController.text.isEmpty
                  ? null
                  : _designController.text, // ADD THIS
              uom: _selectedUOM,
              imageCount: _selectedImagePaths.length,
              imagePaths: List.from(_selectedImagePaths),
              amount: calculatedNetQty * double.parse(_rateController.text),
            ),
          );
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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

  void _duplicateItem(int index) {
    final originalItem = items[index];
    final duplicatedItem = originalItem.copy();

    setState(() {
      items.insert(index + 1, duplicatedItem);
    });
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
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Colors.blueAccent,
                          width: 2,
                        ),
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
                        child: SuppliersSelect(
                          supplierName: suppliercontroller,
                        ),
                      ),
                    ),
                  ),
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
                  if (_showEditForm) _buildEditForm(),

                  if (items.isEmpty)
                    EmptyItemsContainer()
                  else
                    ...items.asMap().entries.map((entry) {
                      int index = entry.key;
                      PurchaseOrderItem item = entry.value;
                      bool isBeingEdited = _editingIndex == index;
                      return Card(
                        color: Colors.white,
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: isBeingEdited ? 3 : 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: isBeingEdited
                              ? BorderSide(
                                  color: Colors.blue.shade600,
                                  width: 2,
                                )
                              : BorderSide.none,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.itemName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isBeingEdited
                                            ? Colors.blue.shade800
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  // Action buttons
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Edit button - disable if already editing or if another item is being edited
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed:
                                              (_showEditForm && !isBeingEdited)
                                              ? null
                                              : () => _editItem(index),
                                          icon: Icon(
                                            isBeingEdited
                                                ? Icons.edit
                                                : Icons.edit,
                                            color:
                                                (_showEditForm &&
                                                    !isBeingEdited)
                                                ? Colors.grey.shade400
                                                : Colors.blue.shade600,
                                            size: 20,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                        ),
                                      ),
                                      if (isBeingEdited) ...[
                                        const SizedBox(height: 8),
                                      ],
                                      const SizedBox(width: 8),
                                      // Delete button - disable if editing
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: _showEditForm
                                              ? null
                                              : () => _removeItem(index),
                                          icon: Icon(
                                            Icons.delete_outline,
                                            color: _showEditForm
                                                ? Colors.grey.shade400
                                                : Colors.red.shade600,
                                            size: 20,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          tooltip: _showEditForm
                                              ? 'Cannot delete while editing'
                                              : 'Delete Item',
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: IconButton(
                                          onPressed: _showEditForm
                                              ? null
                                              : () => _duplicateItem(index),
                                          icon: Icon(
                                            Icons.copy,
                                            color: _showEditForm
                                                ? Colors.grey.shade400
                                                : Colors.orange.shade600,
                                            size: 20,
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 36,
                                            minHeight: 36,
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          tooltip: _showEditForm
                                              ? 'Cannot duplicate while editing'
                                              : 'Duplicate Item',
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // First row: Quantity, PCS, Net Qty
                              Row(
                                children: [
                                  // Quantity
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.inventory,
                                          size: 14,
                                          color: Colors.blue.shade700,
                                        ),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.apps,
                                            size: 14,
                                            color: Colors.green.shade700,
                                          ),
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
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.purple.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calculate,
                                            size: 14,
                                            color: Colors.purple.shade700,
                                          ),
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
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.currency_rupee,
                                          size: 14,
                                          color: Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Rate: ${item.rate.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(width: 12),

                                  // Total
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.calculate,
                                          size: 14,
                                          color: Colors.red.shade700,
                                        ),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // First row: Color, Type, Design
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Color (only if not empty)
                                      if (item.color.isNotEmpty) ...[
                                        Icon(
                                          Icons.color_lens,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
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

                                      // Type (only if not empty)
                                      if (item.type != null &&
                                          item.type!.isNotEmpty) ...[
                                        Icon(
                                          Icons.category,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Type: ${item.type}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 20),
                                      ],

                                      // Design (only if not empty)
                                      if (item.design != null &&
                                          item.design!.isNotEmpty) ...[
                                        Icon(
                                          Icons.brush,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "Design: ${item.design}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  const SizedBox(height: 8),

                                  // Second row: UOM, Images
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // UOM (always show)
                                      Icon(
                                        Icons.straighten,
                                        size: 16,
                                        color: Colors.grey.shade600,
                                      ),
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
                                        Icon(
                                          Icons.photo_library,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
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
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
              const SizedBox(height: 20),

              // Summary Section
              OrderSummaryCard(
                totalQuantity: totalQuantity,
                totalAmount: totalAmount,
                grandTotal: grandTotal,
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SavePurchaseOrderButton(
                items: items,
                grandTotal: grandTotal,
                supplier: selectedSupplierId,
                requiredDate: requireddatecontroller,
                imagePaths:
                    _getAllItemImages(), // Pass all images from all items
                allowImageSelection:
                    false, // Disable additional selection since images come from items
              ),
            ],
          ),
        ),
      ),
    );
  }
}
