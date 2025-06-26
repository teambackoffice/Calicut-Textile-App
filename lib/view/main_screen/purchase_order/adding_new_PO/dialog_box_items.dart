import 'dart:io';

import 'package:calicut_textile_app/controller/product_controller.dart';
import 'package:calicut_textile_app/modal/product_list_model.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/create_new_item.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

// Model class for Item
// Updated Item class with pcs and netQty
class Item {
  final String code;
  final String name;
  final String? color;
  final String selectedUOM;
  final double? rate;
  final double? quantity;
  final int? pcs;        // Already exists
  final double? netQty;  // Changed from int? to double?
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
    this.image1,
    this.image2,
    this.image3,
  });

  // Updated factory constructor
  factory Item.fromDatum(Datum datum) {
    return Item(
      code: datum.name,
      name: datum.productName,
      color: datum.color,
      selectedUOM: datum.uom,
      rate: datum.rate,
      quantity: datum.quantity,
      pcs: datum.pcs,      // Add this if exists in Datum
      netQty: datum.netQty, // Add this if exists in Datum
      image1: datum.image1,
      image2: datum.image2,
      image3: datum.image3,
    );
  }
}

// Sample data for testing

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
    this.onImagesSelected, required this.pcsController,// Add this callback
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

  String? _selectedUOM ; 
  final TextEditingController _searchController = TextEditingController();
   List<Item> _filteredItems = [];
  List<Item> _allItems = []; 
  bool _isLoadingProducts = false;
  double _totalAmount = 0.0; 
 
  Item? _selectedItem;
  bool _isCreatingNew = false;
  
  
  List<File> _selectedImages = [];
   List<String> _selectedImagePaths = [];
  final ImagePicker _imagePicker = ImagePicker();

  final TextEditingController netQtyController = TextEditingController();
  void _calculateNetQty() {
  final qty = double.tryParse(widget.quantityController.text);
  final pcs = double.tryParse(widget.pcsController.text);

  if (qty != null && pcs != null) {
    final result = qty * pcs;
    netQtyController.text = result.toStringAsFixed(2);
  } else {
    netQtyController.text = '';
  }
}


  @override
  void initState() {
    super.initState();
    widget.quantityController.addListener(_calculateNetQty);
  widget.pcsController.addListener(_calculateNetQty);
     _selectedUOM = null;
    
    // Add listeners to calculate total amount
    widget.quantityController.addListener(_calculateTotal);
    widget.rateController.addListener(_calculateTotal);
     _loadProducts();
  }

   // Updated _addSearchItemDirectly method in DialogBoxItems
void _addSearchItemDirectly(Item item) {
  // Create a new item with current form values for pcs and netQty
  final updatedItem = Item(
    code: item.code,
    name: item.name,
    color: item.color,
    selectedUOM: item.selectedUOM,
    rate: item.rate,
    quantity: item.quantity,
    pcs: int.tryParse(widget.pcsController.text), // Get from form
    netQty: double.tryParse(netQtyController.text), // Get from calculated field
    image1: item.image1,
    image2: item.image2,
    image3: item.image3,
  );
  
  // Send updated data back to parent page via callback
  widget.onItemCreated(updatedItem);
  
  // Close the dialog
  Navigator.pop(context);
}


  Future<void> _loadProducts() async {
  setState(() {
    _isLoadingProducts = true;
  });

  try {
    final productController = Provider.of<ProductListController>(context, listen: false);
    await productController.fetchProducts();
    
    // Convert API products to Items
    List<Item> apiItems = productController.products.map((datum) => Item.fromDatum(datum)).toList();
    
    // Combine API items with existing items (if any)
    _allItems = [
      ...apiItems,
      ...(widget.existingItems ?? []),
    ];
    
    _filteredItems = _allItems;
  } catch (e) {
    // Fallback to existing items if API fails
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

  void _calculateTotal() {
    setState(() {
      final quantity = double.tryParse(widget.quantityController.text) ?? 0.0;
      final rate = double.tryParse(widget.rateController.text) ?? 0.0;
      _totalAmount = quantity * rate;
    });
  }

  void _filterItems(String query) {
  setState(() {
    if (query.isEmpty) {
      _filteredItems = _allItems;
    } else {
      _filteredItems = _allItems
          .where((item) =>
              item.name.toLowerCase().contains(query.toLowerCase()) ||
              item.code.toLowerCase().contains(query.toLowerCase()) ||
              (item.color?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }
  });
}
  // Update image count whenever images are added or removed
  

   Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxHeight: 1080,
        maxWidth: 1080,
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        // Limit to 3 images maximum
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
          _sendImagePathsToParent(); // Send paths to parent
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

  // Update image count whenever images are added or removed
  void _updateImageCount() {
    if (widget.onImageCountChanged != null) {
      widget.onImageCountChanged!(_selectedImages.length);
    }
  }

  // Send image paths to parent widget
  void _sendImagePathsToParent() {
    if (widget.onImagesSelected != null) {
      widget.onImagesSelected!(_selectedImagePaths);
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Product Images',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton.icon(
              onPressed: _selectedImages.length < 3 ? _pickImages : null,
              icon: const Icon(Icons.add_photo_alternate),
              label: Text('Add Images (${_selectedImages.length}/3)'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedImages.isNotEmpty)
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
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
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
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
    );
  }

  void _clearAllImages() {
    setState(() {
      _selectedImages.clear();
    });
    _updateImageCount(); // Update image count when all images are cleared
  }

  List<String> getImagePaths() {
    return _selectedImages.map((image) => image.path).toList();
  }

  void _selectItem(Item item) {
  setState(() {
    _selectedItem = item;
    _isCreatingNew = false;
    widget.itemCodeController.text = item.code;
    widget.itemNameController.text = item.name;
    widget.colorController.text = item.color ?? '';
    
    // Set pcs and quantity if available
    if (item.pcs != null) {
      widget.pcsController.text = item.pcs.toString();
    }
    if (item.quantity != null) {
      widget.quantityController.text = item.quantity.toString();
    }
    
    widget.rateController.clear();
    _totalAmount = 0.0;
    
    // Trigger calculation after setting values
    _calculateNetQty();
  });
}
  void _createNewItem() {
    setState(() {
      _isCreatingNew = true;
      _selectedItem = null;
      widget.itemCodeController.clear();
      widget.itemNameController.clear();
      widget.colorController.clear();
      widget.quantityController.clear();
      widget.pcsController.clear();
      widget.rateController.clear();
      widget.rateController.clear();
      _totalAmount = 0.0;
      _selectedImages.clear(); // Clear images when creating new item
    });
    _updateImageCount(); // Update image count when creating new item
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
              // Search Bar
              if (!_isCreatingNew && _selectedItem == null) ...[
                Text(
                  'Search Items',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
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
                
                // Search Results
                if (_searchController.text.isNotEmpty) ...[
                  if (_filteredItems.isNotEmpty) ...[
                    Text(
                      'Search Results (Click to add)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(maxHeight: 300),
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
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Code: ${item.code}'),
                                  if (item.color != null && item.color!.isNotEmpty)
                                    Text('Color: ${item.color}'),
                                  Row(
                                    children: [
                                      if (item.rate != null)
                                        Text('Rate: ₹${item.rate!.toStringAsFixed(2)}'),
                                      if (item.rate != null && item.quantity != null)
                                        Text(' | '),
                                      if (item.quantity != null)
                                        Text('Qty: ${item.quantity!.toStringAsFixed(0)}'),
                                      Text(' | UOM: ${item.selectedUOM}'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  'Add',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () => _addSearchItemDirectly(item), // Direct add!
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 8),
                          Text(
                            'No items found for "${_searchController.text}"',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _createNewItem,
                            icon: Icon(Icons.add),
                            label: Text('Create New Item'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                ],
              ],

              // Selected Item or Create New Form
              if (_selectedItem != null || _isCreatingNew) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _isCreatingNew ? 'Create New Item' : 'Selected Item: ${_selectedItem!.name}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
  onPressed: () {
    setState(() {
      _selectedItem = null;
      _isCreatingNew = false;
      _searchController.clear();
      _filteredItems = _allItems;  // Change this line
      _totalAmount = 0.0;
      _selectedImages.clear();
    });
    _updateImageCount(); // Update image count when resetting
  },
  icon: Icon(Icons.close),
),
                  ],
                ),

                if (_isCreatingNew) ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Item Name',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: widget.itemNameController,
                    validator: (value) => value?.isEmpty == true ? 'Item name is required' : null,
                    decoration: InputDecoration(
                      hintText: 'Enter item name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Quantity, Rate, and UOM Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quantity',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: widget.quantityController,
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (double.tryParse(value!) == null) return 'Invalid';
                              if (double.parse(value) <= 0) return 'Must be > 0';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PCS',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: widget.pcsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (double.tryParse(value!) == null) return 'Invalid';
                              if (double.parse(value) <= 0) return 'Must be > 0';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                     Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Net QTY',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
  controller: netQtyController,
  readOnly: true, // Prevent manual editing
  decoration: InputDecoration(
    hintText: '0',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 20,
    ),
  ),
),
SizedBox(height: 10,),


                        ],
                      ),
                    ),
                    
                   
                  ],
                ),

                const SizedBox(height: 24),

                if (_isCreatingNew) ...[
                   Row(
                     children: [
                       Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UOM',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                         isExpanded: true, // 🔐 Prevents overflow
                         value: _selectedUOM,
                         hint: const Text(
                           'Select UOM',
                           overflow: TextOverflow.ellipsis, // Optional: helps clip long hint
                           style: TextStyle(color: Colors.grey),
                         ),
                         onChanged: (value) {
                           print(_selectedUOM);
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
                             child: Text(
                               uom,
                               overflow: TextOverflow.ellipsis, // Optional: handles long UOM names
                             ),
                           );
                         }).toList(),
                         decoration: InputDecoration(
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(16),
                           ),
                           contentPadding: const EdgeInsets.symmetric(
                             horizontal: 16,
                             vertical: 20,
                           ),
                         ),
                       )
                       
                            ],
                          ),
                        ),
                     ],
                   ),
                    const SizedBox(height: 24),
                  

                  Text(
                    'Color (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: widget.colorController,
                    decoration: InputDecoration(
                      hintText: 'Enter color',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                    ),
                  ),

                  SizedBox(height: 24),
                  Text(
                    'Item Images (${_selectedImages.length}/3)', // Show current count
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

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
                      icon: Icon(
                        _selectedImages.isEmpty ? Icons.add_a_photo : Icons.add_photo_alternate,
                        size: 20,
                      ),
                      label: Text(
                        _selectedImages.isEmpty 
                          ? 'Add Images (Optional)' 
                          : 'Add More Images (${_selectedImages.length}/3)',
                        style: TextStyle(fontSize: 14),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: _selectedImages.length < 3 ? Colors.blue : Colors.grey[300]!,
                          width: 1.5,
                        ),
                        foregroundColor: _selectedImages.length < 3 ? Colors.blue : Colors.grey[500],
                        backgroundColor: _selectedImages.length < 3 ? Colors.blue.withOpacity(0.05) : Colors.grey[50],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    widget.quantityController.removeListener(_calculateNetQty);
  widget.pcsController.removeListener(_calculateNetQty);
  netQtyController.dispose();
    widget.quantityController.removeListener(_calculateTotal);
    widget.rateController.removeListener(_calculateTotal);
    super.dispose();
  }
}