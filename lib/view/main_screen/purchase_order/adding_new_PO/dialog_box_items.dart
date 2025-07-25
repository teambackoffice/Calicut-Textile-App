import 'dart:io';

import 'package:calicut_textile_app/controller/get_all_types_controller.dart';
import 'package:calicut_textile_app/controller/get_colours_controller.dart';
import 'package:calicut_textile_app/controller/get_designs_controller.dart';
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
  final String? type;
  final String? design;
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
    this.type,
    this.design,
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
      selectedUOM: datum.uom ?? '',
      rate: datum.rate,
      quantity: datum.quantity,
      pcs: datum.pcs,
      netQty: datum.netQty,
    );
  }

  Item copyWith({
    String? code,
    String? name,
    String? color,
    String? type,
    String? design,
    String? selectedUOM,
    double? rate,
    double? quantity,
    double? pcs,
    double? netQty,
    double? totalAmount,
  }) {
    return Item(
      code: code ?? this.code,
      name: name ?? this.name,
      color: color ?? this.color,
      type: type ?? this.type,
      design: design ?? this.design,
      selectedUOM: selectedUOM ?? this.selectedUOM,
      rate: rate ?? this.rate,
      quantity: quantity ?? this.quantity,
      pcs: pcs ?? this.pcs,
      netQty: netQty ?? this.netQty,
      totalAmount: totalAmount ?? this.totalAmount,
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
    required this.typeController,        // ADD THIS
    required this.designController,      // ADD THIS
    this.existingItems,
    required this.UomOptions,
    required this.onItemCreated,
    this.onUOMSelected,
    this.onImageCountChanged, 
    this.onImagesSelected,
    required this.pcsController,
    this.onCreationModeChanged,
    this.onNewItemCreated,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController itemCodeController;
  final TextEditingController itemNameController;
  final TextEditingController quantityController;
  final TextEditingController pcsController;
  final TextEditingController rateController;
  final TextEditingController colorController;
  final TextEditingController typeController;        // ADD THIS
  final TextEditingController designController;      // ADD THIS
  final List<Item>? existingItems;
  final List<String> UomOptions;
  final void Function(Item) onItemCreated;
  final void Function(String)? onUOMSelected;
  final void Function(int)? onImageCountChanged; 
  final void Function(List<String>)? onImagesSelected;
  final void Function(bool)? onCreationModeChanged;
  final Future<void> Function(Item)? onNewItemCreated;

  @override
  State<DialogBoxItems> createState() => _DialogBoxItemsState();
}

class _DialogBoxItemsState extends State<DialogBoxItems> {
  final FocusNode _colorFocusNode = FocusNode();
  final FocusNode _typeFocusNode = FocusNode();
  final FocusNode _designFocusNode = FocusNode();

  bool _showColorDropdown = false;
  bool _showTypeDropdown = false;
  bool _showDesignDropdown = false;

  String _colorSearchQuery = '';
  String _typeSearchQuery = '';
  String _designSearchQuery = '';

  

  late ColorsController _colorsController;
  late DesignsController _designsController;
  late TextileTypesController _typesController;

  String? _selectedColor;
  String? _selectedType;
  String? _selectedDesign;

  String? _selectedUOM = 'NOS';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController netQtyController = TextEditingController();
  final TextEditingController totalAmountController = TextEditingController();
  
  List<Item> _filteredItems = [];
  List<Item> _allItems = []; 
  bool _isLoadingProducts = false;
  
  Item? _selectedItem;
  bool _isCreatingNew = false;
  bool _showItemForm = false;
  bool _showSimpleForm = false;
  
  bool _isCreatingItem = false;
  
  List<File> _selectedImages = [];
  List<String> _selectedImagePaths = [];
  final ImagePicker _imagePicker = ImagePicker();

  void _performCalculations() {
    if (_showSimpleForm) {
      _calculateSimpleTotal();
    } else if (_showItemForm) {
      _calculateNetQty();
      _calculateTotal();
    }
  }

  void _calculateNetQty() {
    final qty = double.tryParse(widget.quantityController.text) ?? 1.0;
    final pcs = double.tryParse(widget.pcsController.text) ?? 1.0;
    
    final result = qty * pcs;
    netQtyController.text = result.toStringAsFixed(2);
    _calculateTotal();
  }

  void _calculateSimpleTotal() {
    if (!_showSimpleForm) return;
    
    final qty = double.tryParse(widget.quantityController.text) ?? 0.0;
    final rate = double.tryParse(widget.rateController.text) ?? 0.0;
    
    final total = qty * rate;
    totalAmountController.text = total == 0 ? '' : total.toStringAsFixed(2);
  }

  void _calculateTotal() {
    if (!_showItemForm) return;
    
    final netQty = double.tryParse(netQtyController.text) ?? 0.0;
    final rate = double.tryParse(widget.rateController.text) ?? 0.0;
    
    final total = netQty * rate;
    totalAmountController.text = total == 0 ? '' : total.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _selectedUOM = 'NOS'; 

    _colorFocusNode.addListener(_onColorFocusChange);
    _typeFocusNode.addListener(_onTypeFocusChange);
    _designFocusNode.addListener(_onDesignFocusChange);
    
    _colorsController = ColorsController();
    _designsController = DesignsController();
    _typesController = TextileTypesController();
    
    _colorsController.loadColors();
    _designsController.loadDesigns();
    _typesController.loadTextileTypes();
    widget.quantityController.text = '1';
    widget.pcsController.text = '1';
    
    widget.quantityController.addListener(_calculateNetQty);
    widget.quantityController.addListener(_calculateSimpleTotal);
    widget.pcsController.addListener(_calculateNetQty);
    widget.rateController.addListener(_calculateTotal);
    widget.rateController.addListener(_calculateSimpleTotal);
    
    _loadProducts();
  }

  void _onColorFocusChange() {
    setState(() {
      _showColorDropdown = _colorFocusNode.hasFocus;
    });
  }

  void _onTypeFocusChange() {
    setState(() {
      _showTypeDropdown = _typeFocusNode.hasFocus;
    });
  }

  void _onDesignFocusChange() {
    setState(() {
      _showDesignDropdown = _designFocusNode.hasFocus;
    });
  }

  List<String> _getFilteredColors() {
    if (_colorSearchQuery.isEmpty) return _colorsController.colors;
    return _colorsController.colors
        .where((color) => color.toLowerCase().contains(_colorSearchQuery.toLowerCase()))
        .toList();
  }

  List<String> _getFilteredTypes() {
    if (_typeSearchQuery.isEmpty) return _typesController.textileTypes;
    return _typesController.textileTypes
        .where((type) => type.toLowerCase().contains(_typeSearchQuery.toLowerCase()))
        .toList();
  }

  List<String> _getFilteredDesigns() {
    if (_designSearchQuery.isEmpty) return _designsController.designs;
    return _designsController.designs
        .where((design) => design.toLowerCase().contains(_designSearchQuery.toLowerCase()))
        .toList();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoadingProducts = true;
    });

    try {
      final productController = Provider.of<ProductListController>(context, listen: false);
      await productController.fetchProducts();
      
      List<Item> apiItems = productController.products.map((datum) => Item.fromDatum(datum)).toList();
      
      setState(() {
        _allItems = [
          ...apiItems,
          ...(widget.existingItems ?? []),
        ];
        _filteredItems = _allItems;
      });
      
      print("Loaded ${_allItems.length} items total (${apiItems.length} from API, ${widget.existingItems?.length ?? 0} existing)");
    } catch (e) {
      print("Error loading products: $e");
      
      setState(() {
        _allItems = widget.existingItems ?? [];
        _filteredItems = _allItems;
      });
      
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
    print("Filtered ${_filteredItems.length} items for query: '$query'");
  }

  void _selectItemFromSearch(Item item) {
    setState(() {
      _selectedItem = item;
      _showItemForm = true;
      _isCreatingNew = false;
      _showSimpleForm = false;
      
      widget.itemCodeController.text = item.code;
      widget.itemNameController.text = item.name;
      
      if (item.selectedUOM.isNotEmpty && ['NOS', 'METER'].contains(item.selectedUOM)) {
        _selectedUOM = item.selectedUOM;
      } else {
        _selectedUOM = 'NOS';
      }
      
      widget.quantityController.text = '1';
      widget.pcsController.text = '1';
      widget.rateController.clear();
      
      _selectedColor = null;
      _selectedType = null;
      _selectedDesign = null;
      widget.typeController.clear();
      widget.designController.clear();
      _showColorDropdown = false;
      _showTypeDropdown = false;
      _showDesignDropdown = false;
      _colorSearchQuery = '';
      _typeSearchQuery = '';
      _designSearchQuery = '';
      
      netQtyController.text = '1.00';
      totalAmountController.clear();
      
      _selectedImages.clear();
      _selectedImagePaths.clear();
      _updateImageCount();
    });
    
    if (widget.onUOMSelected != null) {
      widget.onUOMSelected!(_selectedUOM!);
    }
    
    if (widget.onCreationModeChanged != null) {
      widget.onCreationModeChanged!(false);
    }
  }

  void _createNewItem() {
    setState(() {
      _isCreatingNew = true;
      _showItemForm = false;
      _showSimpleForm = true;
      _selectedItem = null;
      _selectedUOM = 'NOS';
      
      widget.itemCodeController.clear();
      widget.itemNameController.clear();
      widget.colorController.clear();
      widget.quantityController.text = '1';
      widget.pcsController.text = '1';
      widget.rateController.clear();
      netQtyController.text = '1.00';
      totalAmountController.clear();
      
      _selectedColor = null;
      _selectedType = null;
      _selectedDesign = null;
      widget.typeController.clear();
      widget.designController.clear();
      _showColorDropdown = false;
      _showTypeDropdown = false;
      _showDesignDropdown = false;
      
      _selectedImages.clear();
      _selectedImagePaths.clear();
      _updateImageCount();
    });
    
    if (widget.onCreationModeChanged != null) {
      widget.onCreationModeChanged!(true);
    }
  }

  void _resetToSearch() {
    setState(() {
      _selectedItem = null;
      _isCreatingNew = false;
      _showItemForm = false;
      _showSimpleForm = false;
      _isCreatingItem = false;
      _searchController.clear();
      _filteredItems = _allItems;
      _selectedImages.clear();
      _selectedImagePaths.clear();
      
      _selectedUOM = 'NOS';
      
      _selectedColor = null;
      _selectedType = null;
      _selectedDesign = null;
      widget.typeController.clear();
      widget.designController.clear();
      _showColorDropdown = false;
      _showTypeDropdown = false;
      _showDesignDropdown = false;
      _colorSearchQuery = '';
      _typeSearchQuery = '';
      _designSearchQuery = '';
      
      _updateImageCount();
    });
    
    if (widget.onCreationModeChanged != null) {
      widget.onCreationModeChanged!(false);
    }
  }

  void _createSimpleItem() async {
    if (_validateSimpleForm()) {
      setState(() {
        _isCreatingItem = true;
      });

      try {
        final newItem = Item(
          code: DateTime.now().millisecondsSinceEpoch.toString(),
          name: widget.itemNameController.text,
          selectedUOM: _selectedUOM ?? '',
          rate: double.tryParse(widget.rateController.text),
          quantity: double.tryParse(widget.quantityController.text),
          totalAmount: double.tryParse(totalAmountController.text),
        );
        
        if (widget.onNewItemCreated != null) {
          await widget.onNewItemCreated!(newItem);
        }
        
        setState(() {
          _allItems.insert(0, newItem);
          _filteredItems = _allItems;
        });
        
        await _refreshProductController();
        
        _resetToSearch();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${newItem.name} created successfully! Search for it to add details.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create item: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } finally {
        setState(() {
          _isCreatingItem = false;
        });
      }
    }
  }

  Future<void> _refreshProductController() async {
    try {
      final productController = Provider.of<ProductListController>(context, listen: false);
      
      productController.products.clear();
      
      await productController.fetchProducts();
      
      List<Item> apiItems = productController.products.map((datum) => Item.fromDatum(datum)).toList();
      
      setState(() {
        _allItems = [
          ...apiItems,
          ...(widget.existingItems ?? []),
        ];
        _filteredItems = _allItems;
      });
      
      print("ProductController refreshed successfully");
    } catch (e) {
      print("Failed to refresh ProductController: $e");
    }
  }

  bool _validateSimpleForm() {
    if (widget.itemNameController.text.isEmpty) {
      _showError('Item name is required');
      return false;
    }
    if (_selectedUOM == null || _selectedUOM!.isEmpty) {
      _showError('Please select UOM');
      return false;
    }
    
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Image handling methods
  Future<void> _pickImages() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.photo_camera),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromCamera();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _getImageFromGallery();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _getImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxHeight: 1080,
        maxWidth: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        _addSelectedImage(pickedFile);
      }
    } catch (e) {
      _showImageError(e);
    }
  }

  Future<void> _getImageFromGallery() async {
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
          
          for (XFile file in filesToAdd) {
            _addSelectedImage(file);
          }
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
      _showImageError(e);
    }
  }

  void _addSelectedImage(XFile file) {
    setState(() {
      _selectedImages.add(File(file.path));
      _selectedImagePaths.add(file.path);
    });
    
    _updateImageCount();
    _sendImagePathsToParent();
  }

  void _showImageError(dynamic e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error picking images: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
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
              if (!_showItemForm && !_showSimpleForm) ...[
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
                
                if (_isLoadingProducts) ...[
                  Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            'Loading products...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  if (_filteredItems.isNotEmpty) ...[
                    Text(
                      _searchController.text.isNotEmpty 
                        ? 'Search Results (${_filteredItems.length} items found)'
                        : 'Available Items (${_filteredItems.length} items)',
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  
                                  if (item.selectedUOM.isNotEmpty)
                                    Text(
                                      'UOM: ${item.selectedUOM}',
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
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
                    if (_searchController.text.isNotEmpty) ...[
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
                            Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No items available',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start by creating your first item',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
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
              ],

              // Simple Item Creation Form
              if (_showSimpleForm) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Create New Item',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
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

                _buildFormField(
                  label: 'Item Name *',
                  child: TextFormField(
                    controller: widget.itemNameController,
                    decoration: _getInputDecoration('Enter item name'),
                  ),
                ),

                _buildFormField(
                  label: 'Unit of Measurement *',
                  child: _buildUOMButtons(),
                ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isCreatingItem ? null : _createSimpleItem,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isCreatingItem ? Colors.grey.shade400 : Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: _isCreatingItem ? 0 : 2,
                    ),
                    child: _isCreatingItem
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'CREATING...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'CREATE ITEM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],

              // Detailed Item Form (for existing items)
              if (_showItemForm) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected Item Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _selectedItem!.name,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
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
                          decoration: _getInputDecoration(''),
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
                          decoration: _getInputDecoration(''),
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
                    decoration: _getInputDecoration('1').copyWith(
                      fillColor: Colors.grey[50],
                      filled: true,
                    ),
                  ),
                ),

                // UOM
                _buildFormField(
                  label: 'Unit of Measurement *',
                  child: _buildUOMButtons(),
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

                // Color (optional)
                _buildFormField(
                  label: 'Color (Optional)',
                  child: _buildSearchableColorField(),
                ),

                // Type field:
                _buildFormField(
                  label: 'Type (Optional)',
                  child: _buildSearchableTypeField(),
                ),

                // Design field:
                _buildFormField(
                  label: 'Design (Optional)', 
                  child: _buildSearchableDesignField(),
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for building form components
  Widget _buildUOMButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedUOM = 'NOS';
              });
              if (widget.onUOMSelected != null) {
                widget.onUOMSelected!('NOS');
              }
              _performCalculations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedUOM == 'NOS' ? Colors.blue : Colors.grey[200],
              foregroundColor: _selectedUOM == 'NOS' ? Colors.white : Colors.black87,
              elevation: _selectedUOM == 'NOS' ? 2 : 0,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedUOM == 'NOS' ? Colors.blue : Colors.grey[300]!,
                  width: _selectedUOM == 'NOS' ? 2 : 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 8),
                Text(
                  'NOS',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedUOM == 'NOS' ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedUOM = 'METER';
              });
              if (widget.onUOMSelected != null) {
                widget.onUOMSelected!('METER');
              }
              _performCalculations();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedUOM == 'METER' ? Colors.blue : Colors.grey[200],
              foregroundColor: _selectedUOM == 'METER' ? Colors.white : Colors.black87,
              elevation: _selectedUOM == 'METER' ? 2 : 0,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedUOM == 'METER' ? Colors.blue : Colors.grey[300]!,
                  width: _selectedUOM == 'METER' ? 2 : 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 8),
                Text(
                  'METER',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: _selectedUOM == 'METER' ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchableColorField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.colorController,
          focusNode: _colorFocusNode,
          decoration: _getInputDecoration('Search colors...').copyWith(
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.colorController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        widget.colorController.clear();
                        _selectedColor = null;
                        _colorSearchQuery = '';
                      });
                    },
                  ),
                Icon(Icons.arrow_drop_down),
                SizedBox(width: 8),
              ],
            ),
          ),
          onChanged: (value) {
            setState(() {
              _colorSearchQuery = value;
              _selectedColor = value.isEmpty ? null : value;
            });
          },
          onTap: () {
            setState(() {
              _showColorDropdown = true;
            });
          },
        ),
        
        if (_showColorDropdown) ...[
          SizedBox(height: 4),
          AnimatedBuilder(
            animation: _colorsController,
            builder: (context, child) {
              if (_colorsController.isLoading) {
                return _buildLoadingContainer('Loading colors...');
              }
              
              if (_colorsController.hasError) {
                return _buildErrorContainer('Error loading colors');
              }
              
              final filteredColors = _getFilteredColors();
              
              if (filteredColors.isEmpty) {
                return _buildEmptyContainer('No colors found');
              }
              
              return Container(
                constraints: BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredColors.length,
                  itemBuilder: (context, index) {
                    final color = filteredColors[index];
                    final isSelected = _selectedColor == color;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                          widget.colorController.text = color;
                          _colorSearchQuery = color;
                          _showColorDropdown = false;
                        });
                        _colorFocusNode.unfocus();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : null,
                          border: index > 0 ? Border(top: BorderSide(color: Colors.grey[200]!)) : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                color,
                                style: TextStyle(fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, color: Colors.blue.shade700, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSearchableTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.typeController,
          focusNode: _typeFocusNode,
          decoration: _getInputDecoration('Search types...').copyWith(
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.typeController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                       widget.typeController.clear();
                        _selectedType = null;
                        _typeSearchQuery = '';
                      });
                    },
                  ),
                Icon(Icons.arrow_drop_down),
                SizedBox(width: 8),
              ],
            ),
          ),
          onChanged: (value) {
            setState(() {
              _typeSearchQuery = value;
              _selectedType = value.isEmpty ? null : value;
            });
          },
          onTap: () {
            setState(() {
              _showTypeDropdown = true;
            });
          },
        ),
        
        if (_showTypeDropdown) ...[
          SizedBox(height: 4),
          AnimatedBuilder(
            animation: widget.typeController,
            builder: (context, child) {
              if (_typesController.isLoading) {
                return _buildLoadingContainer('Loading types...');
              }
              
              if (_typesController.hasError) {
                return _buildErrorContainer('Error loading types');
              }
              
              final filteredTypes = _getFilteredTypes();
              
              if (filteredTypes.isEmpty) {
                return _buildEmptyContainer('No types found');
              }
              
              return Container(
                constraints: BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredTypes.length,
                  itemBuilder: (context, index) {
                    final type = filteredTypes[index];
                    final isSelected = _selectedType == type;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedType = type;
                          widget.typeController.text = type;
                          _typeSearchQuery = type;
                          _showTypeDropdown = false;
                        });
                        _typeFocusNode.unfocus();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : null,
                          border: index > 0 ? Border(top: BorderSide(color: Colors.grey[200]!)) : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                type,
                                style: TextStyle(fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                                  color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                ),
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, color: Colors.blue.shade700, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildSearchableDesignField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: widget.designController,
          focusNode: _designFocusNode,
          decoration: _getInputDecoration('Search designs...').copyWith(
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.designController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        widget.designController.clear();
                        _selectedDesign = null;
                        _designSearchQuery = '';
                      });
                    },
                  ),
                Icon(Icons.arrow_drop_down),
                SizedBox(width: 8),
              ],
            ),
          ),
          onChanged: (value) {
            setState(() {
              _designSearchQuery = value;
              _selectedDesign = value.isEmpty ? null : value;
            });
          },
          onTap: () {
            setState(() {
              _showDesignDropdown = true;
            });
          },
        ),
        
        if (_showDesignDropdown) ...[
          SizedBox(height: 4),
          AnimatedBuilder(
            animation: _designsController,
            builder: (context, child) {
              if (_designsController.isLoading) {
                return _buildLoadingContainer('Loading designs...');
              }
              
              if (_designsController.hasError) {
                return _buildErrorContainer('Error loading designs');
              }
              
              final filteredDesigns = _getFilteredDesigns();
              
              if (filteredDesigns.isEmpty) {
                return _buildEmptyContainer('No designs found');
              }
              
              return Container(
                constraints: BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredDesigns.length,
                  itemBuilder: (context, index) {
                    final design = filteredDesigns[index];
                    final isSelected = _selectedDesign == design;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDesign = design;
                          widget.designController.text = design;
                          _designSearchQuery = design;
                          _showDesignDropdown = false;
                        });
                        _designFocusNode.unfocus();
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : null,
                          border: index > 0 ? Border(top: BorderSide(color: Colors.grey[200]!)) : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    design,
                                    style: TextStyle(fontSize: 16,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.bold,
                                      color: isSelected ? Colors.blue.shade700 : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check, color: Colors.blue.shade700, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildLoadingContainer(String message) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text(message, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorContainer(String message) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.red[50],
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, color: Colors.red[600], size: 16),
            SizedBox(width: 8),
            Text(message, style: TextStyle(color: Colors.red[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyContainer(String message) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[600])),
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
    widget.typeController.dispose();
    widget.designController.dispose();
    _colorsController.dispose();
    _designsController.dispose();
    _typesController.dispose();

    _colorFocusNode.removeListener(_onColorFocusChange);
    _typeFocusNode.removeListener(_onTypeFocusChange);
    _designFocusNode.removeListener(_onDesignFocusChange);
    _colorFocusNode.dispose();
    _typeFocusNode.dispose();
    _designFocusNode.dispose();
    
    widget.quantityController.removeListener(_calculateNetQty);
    widget.quantityController.removeListener(_calculateSimpleTotal);
    widget.pcsController.removeListener(_calculateNetQty);
    widget.rateController.removeListener(_calculateTotal);
    widget.rateController.removeListener(_calculateSimpleTotal);
    super.dispose();
  }
}