import 'dart:io';

import 'package:calicut_textile_app/controller/product_controller.dart';
import 'package:calicut_textile_app/modal/product_list_model.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/create_new_item.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Updated Item class
class Item {
  final String code;
  final String name;
  final String? color;
  final String selectedUOM;
  final double? rate;
  final double? quantity;
  final double? pcs;
  final double? netQty;
  final double? totalAmount;
  final String? image1;
  final String? image2;
  final String? image3;
  
  Item({
    required this.code, 
    required this.name, 
    this.color,
    this.selectedUOM = '',
    this.rate,
    this.quantity,
    this.pcs,
    this.netQty,
    this.totalAmount,
    this.image1,
    this.image2,
    this.image3,
  });

  factory Item.fromDatum(Datum datum) {
    return Item(
      code: datum.name,
      name: datum.productName,
      color: datum.color,
      selectedUOM: datum.uom,
      rate: datum.rate,
      quantity: datum.quantity,
      pcs: datum.pcs,
      netQty: datum.netQty,
      image1: datum.image1,
      image2: datum.image2,
      image3: datum.image3,
    );
  }
}

class DialogBoxItems extends StatefulWidget {
  DialogBoxItems({
    super.key,
    required this.formKey,
    required this.itemCodeController,
    required this.itemNameController,
    required this.quantityController,
    required this.rateController,
    required this.colorController,
    this.existingItems,
    required this.UomOptions,
    required this.onItemCreated,
    this.onUOMSelected,
    this.onImageCountChanged, 
    this.onImagesSelected,
    required this.pcsController,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController itemCodeController;
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController pcsController;
  final TextEditingController rateController;
  final TextEditingController colorController;
  final List<Item>? existingItems;
  final List<String> UomOptions;
  final void Function(Item) onItemCreated;
  final void Function(String)? onUOMSelected;
  final void Function(int)? onImageCountChanged; 
  final void Function(List<String>)? onImagesSelected;

  @override
  State<DialogBoxItems> createState() => _DialogBoxItemsState();
}

class _DialogBoxItemsState extends State<DialogBoxItems> {
  String? _selectedUOM;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController netQtyController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  
  List<Item> _filteredItems = [];
  List<Item> _allItems = []; 
  bool _isLoadingProducts = false;
  
  Item? _selectedItem;
  bool _isCreatingNew = false;
  bool _showItemForm = false; // New state to control form visibility
  
  List<File> _selectedImages = [];
  List<String> _selectedImagePaths = [];
  final ImagePicker _imagePicker = ImagePicker();

  // Calculate net quantity (qty * pcs)
  void _calculateNetQty() {
    final qty = double.tryParse(widget.quantityController.text) ?? 0.0;
    final pcs = double.tryParse(widget.pcsController.text) ?? 0.0;
    
    final result = qty * pcs;
    netQtyController.text = result.toStringAsFixed(2);
    _calculateTotal(); // Recalculate total when net qty changes
  }

  // Calculate total amount (net_qty * rate)
  void _calculateTotal() {
    final netQty = double.tryParse(netQtyController.text) ?? 0.0;
    final rate = double.tryParse(widget.rateController.text) ?? 0.0;
    
    final total = netQty * rate;
    totalAmountController.text = total.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _selectedUOM = null;
    
    // Add listeners for calculations
    widget.quantityController.addListener(_calculateNetQty);
    widget.pcsController.addListener(_calculateNetQty);
    widget.rateController.addListener(_calculateTotal);
    
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final productController = Provider.of<ProductListController>(context, listen: false);
      await productController.fetchProducts();
      
      List<Item> apiItems = productController.products.map((datum) => Item.fromDatum(datum)).toList();
      
      _allItems = [
        ...apiItems,
        ...(widget.existingItems ?? []),
      ];
      
      _filteredItems = _allItems;
    } catch (e) {
      _allItems = widget.existingItems ?? [];
      _filteredItems = _allItems;
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load products from server. ${_allItems.isEmpty ? 'No items available.' : 'Using local data.'}'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingProducts = false;
      });
    }
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = _allItems;
      } else {
        _filteredItems = _allItems
            .where((item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Select item from search and show form
  void _selectItemFromSearch(Item item) {
    setState(() {
      _selectedItem = item;
      _showItemForm = true;
      _isCreatingNew = false;
      
      // Set basic item details
      widget.itemCodeController.text = item.code;
      widget.itemNameController.text = item.name;
      _selectedUOM = item.selectedUOM;
      
      // Clear form fields for user input
      widget.quantityController.clear();
      widget.pcsController.clear();
      widget.rateController.clear();
      widget.colorController.clear();
      netQtyController.clear();
      totalAmountController.clear();
      
      // Clear images
      _selectedImages.clear();
      _selectedImagePaths.clear();
      _updateImageCount();
    });
  }

  // Create new item
  void _createNewItem() {
    setState(() {
      _isCreatingNew = true;
      _showItemForm = true;
      _selectedItem = null;
      _selectedUOM = null;
      
      // Clear all form fields
      widget.itemCodeController.clear();
      widget.itemNameController.clear();
      widget.colorController.clear();
      widget.quantityController.clear();
      widget.pcsController.clear();
      widget.rateController.clear();
      netQtyController.clear();
      totalAmountController.clear();
      
      // Clear images
      _selectedImages.clear();
      _selectedImagePaths.clear();
      _updateImageCount();
    });
  }

  // Reset to search view
  void _resetToSearch() {
    setState(() {
      _selectedItem = null;
      _isCreatingNew = false;
      _showItemForm = false;
      _searchController.clear();
      _filteredItems = _allItems;
      _selectedImages.clear();
      _selectedImagePaths.clear();
      _updateImageCount();
    });
  }

  // Add item with current form data
  void _addCurrentItem() {
    if (widget.formKey.currentState!.validate()) {
      final newItem = Item(
        code: _isCreatingNew ? 
          DateTime.now().millisecondsSinceEpoch.toString() : // Generate code for new items
          _selectedItem!.code,
        name: widget.itemNameController.text,
        color: widget.colorController.text.isEmpty ? null : widget.colorController.text,
        selectedUOM: _selectedUOM ?? '',
        rate: double.tryParse(widget.rateController.text),
        quantity: double.tryParse(widget.quantityController.text),
        pcs: double.tryParse(widget.pcsController.text),
        netQty: double.tryParse(netQtyController.text),
        totalAmount: double.tryParse(totalAmountController.text),
        image1: _selectedImagePaths.isNotEmpty ? _selectedImagePaths[0] : null,
        image2: _selectedImagePaths.length > 1 ? _selectedImagePaths[1] : null,
        image3: _selectedImagePaths.length > 2 ? _selectedImagePaths[2] : null,
      );
      
      widget.onItemCreated(newItem);
      Navigator.pop(context);
    }
  }

  // Image handling methods
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxHeight: 1080,
        maxWidth: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        final int maxImages = 3;
        final int currentCount = _selectedImages.length;
        final int remainingSlots = maxImages - currentCount;
        
        if (remainingSlots > 0) {
          final List<XFile> filesToAdd = pickedFiles.take(remainingSlots).toList();
          
          setState(() {
            for (XFile file in filesToAdd) {
              _selectedImages.add(File(file.path));
              _selectedImagePaths.add(file.path);
            }
          });
          
          _updateImageCount();
          _sendImagePathsToParent();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Maximum 3 images allowed'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking images: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _selectedImagePaths.removeAt(index);
    });
    _updateImageCount();
    _sendImagePathsToParent();
  }

  void _updateImageCount() {
    if (widget.onImageCountChanged != null) {
      widget.onImageCountChanged!(_selectedImages.length);
    }
  }

  void _sendImagePathsToParent() {
    if (widget.onImagesSelected != null) {
      widget.onImagesSelected!(_selectedImagePaths);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Form(
        key: widget.formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Interface
              if (!_showItemForm) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _createNewItem,
                      icon: Icon(Icons.add),
                      label: Text('Create New'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Search Bar
                TextFormField(
                  controller: _searchController,
                  onChanged: _filterItems,
                  decoration: InputDecoration(
                    hintText: 'Search by item name or code...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Search Results - Show only item names
                if (_searchController.text.isNotEmpty) ...[
                  if (_filteredItems.isNotEmpty) ...[
                    Text(
                      'Search Results (${_filteredItems.length} items found)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      constraints: BoxConstraints(maxHeight: 400),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return Container(
                            decoration: BoxDecoration(
                              border: index > 0 
                                  ? Border(top: BorderSide(color: Colors.grey[200]!))
                                  : null,
                            ),
                            child: ListTile(
                              title: Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'Code: ${item.code}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: Colors.grey[400],
                              ),
                              onTap: () => _selectItemFromSearch(item),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No items found for "${_searchController.text}"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _createNewItem,
                            icon: Icon(Icons.add),
                            label: Text('Create New Item'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],

              // Item Form
              if (_showItemForm) ...[
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isCreatingNew ? 'Create New Item' : 'Selected Item Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          if (!_isCreatingNew) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedItem!.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _resetToSearch,
                      icon: Icon(Icons.close),
                      tooltip: 'Back to search',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Item Name (for new items only)
                if (_isCreatingNew) ...[
                  _buildFormField(
                    label: 'Item Name *',
                    child: TextFormField(
                      controller: widget.itemNameController,
                      validator: (value) => value?.isEmpty == true ? 'Item name is required' : null,
                      decoration: _getInputDecoration('Enter item name'),
                    ),
                  ),
                ],

                // Quantity and PCS Row
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        label: 'Quantity *',
                        child: TextFormField(
                          controller: widget.quantityController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (double.tryParse(value!) == null) return 'Invalid number';
                            if (double.parse(value) <= 0) return 'Must be > 0';
                            return null;
                          },
                          decoration: _getInputDecoration('0'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildFormField(
                        label: 'PCS *',
                        child: TextFormField(
                          controller: widget.pcsController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            if (value?.isEmpty == true) return 'Required';
                            if (double.tryParse(value!) == null) return 'Invalid number';
                            if (double.parse(value) <= 0) return 'Must be > 0';
                            return null;
                          },
                          decoration: _getInputDecoration('0'),
                        ),
                      ),
                    ),
                  ],
                ),

                // Net Quantity (calculated)
                _buildFormField(
                  label: 'Net Quantity (Qty × PCS)',
                  child: TextFormField(
                    controller: netQtyController,
                    readOnly: true,
                    decoration: _getInputDecoration('Calculated automatically').copyWith(
                      fillColor: Colors.grey[50],
                      filled: true,
                    ),
                  ),
                ),

                // Rate
                _buildFormField(
                  label: 'Rate *',
                  child: TextFormField(
                    controller: widget.rateController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value?.isEmpty == true) return 'Rate is required';
                      if (double.tryParse(value!) == null) return 'Invalid number';
                      if (double.parse(value) <= 0) return 'Must be > 0';
                      return null;
                    },
                    decoration: _getInputDecoration('0.00').copyWith(
                      prefixText: '₹ ',
                    ),
                  ),
                ),

                // Total Amount (calculated)
                _buildFormField(
                  label: 'Total Amount (Net Qty × Rate)',
                  child: TextFormField(
                    controller: totalAmountController,
                    readOnly: true,
                    decoration: _getInputDecoration('Calculated automatically').copyWith(
                      fillColor: Colors.grey[50],
                      filled: true,
                      prefixText: '₹ ',
                    ),
                  ),
                ),

                // UOM (for new items)
                if (_isCreatingNew) ...[
                  _buildFormField(
                    label: 'Unit of Measurement *',
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: _selectedUOM,
                      hint: const Text('Select UOM'),
                      validator: (value) => value == null ? 'Please select UOM' : null,
                      onChanged: (value) {
                        setState(() {
                          _selectedUOM = value;
                        });
                        if (widget.onUOMSelected != null && value != null) {
                          widget.onUOMSelected!(value);
                        }
                      },
                      items: widget.UomOptions.map((uom) {
                        return DropdownMenuItem<String>(
                          value: uom,
                          child: Text(uom),
                        );
                      }).toList(),
                      decoration: _getInputDecoration('Select UOM'),
                    ),
                  ),
                ],

                // Color (optional)
                _buildFormField(
                  label: 'Color (Optional)',
                  child: TextFormField(
                    controller: widget.colorController,
                    decoration: _getInputDecoration('Enter color'),
                  ),
                ),

                // Images Section
                _buildFormField(
                  label: 'Product Images (Optional - 0 to 3 images)',
                  child: Column(
                    children: [
                      if (_selectedImages.isNotEmpty) ...[
                        Container(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: EdgeInsets.only(right: 12),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        _selectedImages[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removeImage(index),
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.8),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
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
                        const SizedBox(height: 16),
                      ],
                      Container(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _selectedImages.length < 3 ? _pickImages : null,
                          icon: Icon(Icons.add_photo_alternate),
                          label: Text(
                            _selectedImages.isEmpty 
                              ? 'Add Images' 
                              : 'Add More Images (${_selectedImages.length}/3)',
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Add Item Button
                // Container(
                //   width: double.infinity,
                //   child: ElevatedButton(
                //     onPressed: _isCreatingNew ? _addCurrentItem : null, // Only enabled for new items
                //     style: ElevatedButton.styleFrom(
                //       backgroundColor: _isCreatingNew ? Colors.blue : Colors.grey[300],
                //       foregroundColor: _isCreatingNew ? Colors.white : Colors.grey[600],
                //       padding: EdgeInsets.symmetric(vertical: 16),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(12),
                //       ),
                //     ),
                //     child: Text(
                //       'Add Item',
                //       style: TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.w600,
                //       ),
                //     ),
                //   ),
                // ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        child,
        const SizedBox(height: 20),
      ],
    );
  }

  InputDecoration _getInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    netQtyController.dispose();
    totalAmountController.dispose();
    widget.quantityController.removeListener(_calculateNetQty);
    widget.pcsController.removeListener(_calculateNetQty);
    widget.rateController.removeListener(_calculateTotal);
    super.dispose();
  }
}