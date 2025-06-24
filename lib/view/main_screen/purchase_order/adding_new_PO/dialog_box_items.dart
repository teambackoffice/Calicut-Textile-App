import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// Model class for Item
class Item {
  final String code;
  final String name;
  final String? color;
  final String selectedUOM;
  
  Item({required this.code, required this.name, this.color,this.selectedUOM = ''});
}

// Sample data for testing
class SampleItems {
  static List<Item> getSampleItems() {
    return [
      // Construction Materials
      Item(code: 'CM001', name: 'Ceramic Tiles 12x12', color: 'White'),
      Item(code: 'CM002', name: 'Ceramic Tiles 12x12', color: 'Beige'),
      Item(code: 'CM003', name: 'Steel Rods 8mm', color: 'Silver'),
      Item(code: 'CM004', name: 'Steel Rods 10mm', color: 'Silver'),
      Item(code: 'CM005', name: 'Concrete Blocks', color: 'Grey'),
      Item(code: 'CM006', name: 'Red Bricks', color: 'Red'),
      Item(code: 'CM007', name: 'PVC Pipes 4 inch', color: 'White'),
      Item(code: 'CM008', name: 'PVC Pipes 6 inch', color: 'White'),
      Item(code: 'CM009', name: 'Cement Bags 50kg', color: 'Grey'),
      Item(code: 'CM010', name: 'Sand (River Sand)', color: 'Brown'),
      
      // Office Supplies
      Item(code: 'OS001', name: 'A4 Paper Sheets', color: 'White'),
      Item(code: 'OS002', name: 'Blue Pens', color: 'Blue'),
      Item(code: 'OS003', name: 'Black Pens', color: 'Black'),
      Item(code: 'OS004', name: 'Pencils HB', color: 'Yellow'),
      Item(code: 'OS005', name: 'Staplers', color: 'Black'),
      Item(code: 'OS006', name: 'Paper Clips', color: 'Silver'),
      Item(code: 'OS007', name: 'Folders A4', color: 'Blue'),
      Item(code: 'OS008', name: 'Folders A4', color: 'Red'),
      
      // Electronics
      Item(code: 'EL001', name: 'LED Bulbs 9W', color: 'White'),
      Item(code: 'EL002', name: 'LED Bulbs 12W', color: 'White'),
      Item(code: 'EL003', name: 'Extension Cords 5m', color: 'Black'),
      Item(code: 'EL004', name: 'Power Sockets', color: 'White'),
      Item(code: 'EL005', name: 'Switches 2-way', color: 'White'),
      Item(code: 'EL006', name: 'Copper Wires 2.5mm', color: 'Copper'),
      Item(code: 'EL007', name: 'Cable Ties', color: 'Black'),
      
      // Furniture
      Item(code: 'FU001', name: 'Office Chairs', color: 'Black'),
      Item(code: 'FU002', name: 'Office Desks', color: 'Brown'),
      Item(code: 'FU003', name: 'Filing Cabinets', color: 'Grey'),
      Item(code: 'FU004', name: 'Bookshelf 5-tier', color: 'White'),
      Item(code: 'FU005', name: 'Conference Table', color: 'Brown'),
      
      // Plumbing
      Item(code: 'PL001', name: 'Water Taps', color: 'Chrome'),
      Item(code: 'PL002', name: 'Toilet Seats', color: 'White'),
      Item(code: 'PL003', name: 'Shower Heads', color: 'Chrome'),
      Item(code: 'PL004', name: 'Pipe Fittings T-joint', color: 'White'),
      Item(code: 'PL005', name: 'Pipe Fittings Elbow', color: 'White'),
      
      // Tools
      Item(code: 'TL001', name: 'Hammer 500g', color: 'Red'),
      Item(code: 'TL002', name: 'Screwdrivers Set', color: 'Yellow'),
      Item(code: 'TL003', name: 'Drill Bits Set', color: 'Silver'),
      Item(code: 'TL004', name: 'Measuring Tape 5m', color: 'Yellow'),
      Item(code: 'TL005', name: 'Spirit Level 60cm', color: 'Green'),
      
      // Paints & Chemicals
      Item(code: 'PC001', name: 'Wall Paint White', color: 'White'),
      Item(code: 'PC002', name: 'Wall Paint Blue', color: 'Blue'),
      Item(code: 'PC003', name: 'Primer Coat', color: 'White'),
      Item(code: 'PC004', name: 'Thinner', color: 'Clear'),
      Item(code: 'PC005', name: 'Wood Stain', color: 'Brown'),
    ];
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
    this.onImageCountChanged, // Add this callback
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController itemCodeController;
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController rateController;
  final TextEditingController colorController;
  final List<Item>? existingItems;
  final List<String> UomOptions;
  final void Function(Item) onItemCreated;
  final void Function(String)? onUOMSelected;
  final void Function(int)? onImageCountChanged;  // New callback for image count

  @override
  State<DialogBoxItems> createState() => _DialogBoxItemsState();
}

class _DialogBoxItemsState extends State<DialogBoxItems> {
  String? _selectedUOM; 
  final TextEditingController _searchController = TextEditingController();
  List<Item> _filteredItems = [];
  Item? _selectedItem;
  bool _isCreatingNew = false;
  double _totalAmount = 0.0;
  
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.existingItems ?? SampleItems.getSampleItems();
    _selectedUOM = widget.UomOptions.isNotEmpty ? widget.UomOptions[0] : null;
    
    // Add listeners to calculate total amount
    widget.quantityController.addListener(_calculateTotal);
    widget.rateController.addListener(_calculateTotal);
  }

  void _calculateTotal() {
    setState(() {
      final quantity = double.tryParse(widget.quantityController.text) ?? 0.0;
      final rate = double.tryParse(widget.rateController.text) ?? 0.0;
      _totalAmount = quantity * rate;
    });
  }

  void _filterItems(String query) {
    final items = widget.existingItems ?? SampleItems.getSampleItems();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = items;
      } else {
        _filteredItems = items
            .where((item) =>
                item.name.toLowerCase().contains(query.toLowerCase()) ||
                item.code.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Update image count whenever images are added or removed
  void _updateImageCount() {
    if (widget.onImageCountChanged != null) {
      widget.onImageCountChanged!(_selectedImages.length);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum 3 images allowed'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        
      );
      
      
      return;
    }

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile != null) {
       setState(() {
  _selectedImages.add(File(pickedFile.path));
});
_updateImageCount();
        
        _updateImageCount(); // Update image count when image is added
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image added successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      
    }
  
  }
  

  void _removeImage(int index) {
   setState(() {
  _selectedImages.removeAt(index);
});
_updateImageCount(); 
    
    _updateImageCount(); // Update image count when image is removed
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Image removed'),
        backgroundColor: Colors.grey[600],
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Select Image Source',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.blue.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.camera_alt, color: Colors.blue, size: 32),
                                  SizedBox(height: 8),
                                  Text(
                                    'Camera',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.photo_library, color: Colors.green, size: 32),
                                  SizedBox(height: 8),
                                  Text(
                                    'Gallery',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
      // Clear quantity and rate when selecting new item
      widget.quantityController.clear();
      widget.rateController.clear();
      _totalAmount = 0.0;
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
                      'Search Results',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(maxHeight: 200),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          return ListTile(
                            title: Text(item.name),
                            subtitle: Text('Code: ${item.code}'),
                            trailing: Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () => _selectItem(item),
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
                          _filteredItems = widget.existingItems ?? SampleItems.getSampleItems();
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
                            'Rate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: widget.rateController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              if (value?.isEmpty == true) return 'Required';
                              if (double.tryParse(value!) == null) return 'Invalid';
                              if (double.parse(value) <= 0) return 'Must be > 0';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: '0.00',
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
                            'UOM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedUOM,
                            onChanged: (value) {
                              setState(() {
                                _selectedUOM = value!;
                              });
                              if (widget.onUOMSelected != null) {
                                widget.onUOMSelected!(value!);
                              }
                            },
                            items: widget.UomOptions.map((uom) {
                              return DropdownMenuItem(
                                value: uom,
                                child: Text(uom),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                if (_isCreatingNew) ...[
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
                      onPressed: _selectedImages.length < 3 ? _showImageSourceDialog : null,
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
    widget.quantityController.removeListener(_calculateTotal);
    widget.rateController.removeListener(_calculateTotal);
    super.dispose();
  }
}