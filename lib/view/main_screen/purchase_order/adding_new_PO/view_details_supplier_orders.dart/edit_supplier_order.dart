import 'package:calicut_textile_app/controller/get_all_types_controller.dart';
import 'package:calicut_textile_app/controller/get_colours_controller.dart';
import 'package:calicut_textile_app/controller/get_designs_controller.dart';
import 'package:calicut_textile_app/controller/get_supplier_orders_controller.dart';
import 'package:calicut_textile_app/controller/product_controller.dart';
import 'package:calicut_textile_app/controller/supplier_list_controller.dart';
import 'package:calicut_textile_app/modal/product_list_model.dart';
import 'package:calicut_textile_app/modal/supplier_list_modal.dart';
import 'package:calicut_textile_app/service/edit_supplier_order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:calicut_textile_app/modal/get_supplier_orders.dart' as OrderModel;

class EditSupplierOrderPage extends StatefulWidget {
  final OrderModel.Order order;

  const EditSupplierOrderPage({
    super.key,
    required this.order,
  });

  @override
  State<EditSupplierOrderPage> createState() => _EditSupplierOrderPageState();
}

class _EditSupplierOrderPageState extends State<EditSupplierOrderPage> {
  final _formKey = GlobalKey<FormState>();
  late OrderModel.Order _editedOrder;
  bool _isLoading = false;

  // ✅ API Controllers for new fields
  late ColorsController _colorsController;
  late DesignsController _designsController;
  late TextileTypesController _typesController;

  // Controllers for order details
  late TextEditingController _orderDateController;
  late String _selectedStatus;
  late String _selectedSupplierId;
  late String _selectedSupplierName;

  // Controllers for products
  List<ProductControllers> _productControllers = [];

  // Selected products and suppliers from API
  List<Datum> _availableProducts = [];
  List<Supplier> _availableSuppliers = [];

  @override
  void initState() {
    super.initState();
    
    // ✅ Initialize API controllers
    _colorsController = ColorsController();
    _designsController = DesignsController();
    _typesController = TextileTypesController();
    
    _initializeData();
    _loadData();
    _loadDropdownData(); // ✅ Load dropdown data
  }

  // ✅ Load dropdown data
  Future<void> _loadDropdownData() async {
    await Future.wait([
      _colorsController.loadColors(),
      _designsController.loadDesigns(),
      _typesController.loadTextileTypes(),
    ]);
  }

  // Helper function to format numbers without unnecessary decimals
  String _formatNumber(dynamic value) {
    if (value == null) return '0';
    
    double doubleValue;
    if (value is String) {
      doubleValue = double.tryParse(value) ?? 0;
    } else if (value is int) {
      doubleValue = value.toDouble();
    } else if (value is double) {
      doubleValue = value;
    } else {
      return '0';
    }
    
    // If it's a whole number, return without decimal
    if (doubleValue == doubleValue.roundToDouble()) {
      return doubleValue.round().toString();
    } else {
      return doubleValue.toString();
    }
  }

  void _initializeData() {
    // Create a copy of the order to edit
    _editedOrder = OrderModel.Order(
      orderId: widget.order.orderId,
      supplier: widget.order.supplier,
      supplierName: widget.order.supplierName,
      orderDate: widget.order.orderDate,
      grandTotal: widget.order.grandTotal,
      status: widget.order.status,
      products: widget.order.products.map((p) => OrderModel.Product(
        product: p.product,
        quantity: p.quantity,
        uom: p.uom,
        rate: p.rate,
        pcs: p.pcs,
        netQty: p.netQty,
        amount: p.amount,
        requiredBy: p.requiredBy,
        // ✅ Include new fields
        color: p.color,
        type: p.type,
        design: p.design,
      )).toList(),
    );

    // Initialize order controllers
    _orderDateController = TextEditingController(
        text: "${_editedOrder.orderDate.day}/${_editedOrder.orderDate.month}/${_editedOrder.orderDate.year}");
    _selectedStatus = _editedOrder.status;
    _selectedSupplierId = _editedOrder.supplier ?? '';
    _selectedSupplierName = _editedOrder.supplierName ?? '';

    // Initialize product controllers with proper number formatting and UOM preservation
    _productControllers = _editedOrder.products.map((product) {
      print('Product: ${product.product} - Original UOM from backend: ${product.uom}');
      
      return ProductControllers(
        productController: TextEditingController(text: product.product),
        quantityController: TextEditingController(text: _formatNumber(product.quantity)),
        rateController: TextEditingController(text: product.rate.toString()),
        pcsController: TextEditingController(text: _formatNumber(product.pcs)),
        netQtyController: TextEditingController(text: _formatNumber(product.netQty)),
        amountController: TextEditingController(text: product.amount.toString()),
        requiredByController: TextEditingController(
            text: "${product.requiredBy.day}/${product.requiredBy.month}/${product.requiredBy.year}"),
        // ✅ Initialize new dropdown controllers
        colorController: TextEditingController(text: product.color ?? ''),
        typeController: TextEditingController(text: product.type ?? ''),
        designController: TextEditingController(text: product.design ?? ''),
        // ✅ Preserve the exact UOM from backend data
        selectedUom: product.uom ?? OrderModel.Uom.NOS,
        selectedProductName: product.product,
        // ✅ Initialize selected values
        selectedColor: product.color,
        selectedType: product.type,
        selectedDesign: product.design,
        // ✅ ADD: Initialize dropdown states
        showColorDropdown: false,
        showTypeDropdown: false,
        showDesignDropdown: false,
        colorSearchQuery: '',
        typeSearchQuery: '',
        designSearchQuery: '',
      );
    }).toList();

    // Ensure calculations are correct on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _productControllers.length; i++) {
        _calculateAmount(i);
      }
    });
  }

  Future<void> _loadData() async {
    // Load products and suppliers
    await Future.wait([
      Provider.of<ProductListController>(context, listen: false).fetchProducts(),
      Provider.of<SuppliersController>(context, listen: false).loadSuppliers(),
    ]);

    if (mounted) {
      final productController = Provider.of<ProductListController>(context, listen: false);
      final supplierController = Provider.of<SuppliersController>(context, listen: false);
      
      _availableProducts = productController.products;
      _availableSuppliers = supplierController.suppliers;
      
      // ✅ Check supplier by ID, not name
      final supplierExists = _availableSuppliers.any((supplier) => supplier.supplierId == _selectedSupplierId);
      if (!supplierExists && _availableSuppliers.isNotEmpty) {
        print('Original supplier not found in list');
      }
      
      // Validate selected products exist in the list, but preserve UOM
      for (int i = 0; i < _productControllers.length; i++) {
        final selectedProductName = _productControllers[i].selectedProductName;
        final productExists = _availableProducts.any((product) => product.name == selectedProductName);
        if (!productExists && selectedProductName.isNotEmpty) {
          _productControllers[i].selectedProductName = '';
        }
      }
      
      setState(() {});
    }
  }

  @override
  void dispose() {
    _orderDateController.dispose();
    for (var controllers in _productControllers) {
      controllers.dispose();
    }
    // ✅ Dispose API controllers
    _colorsController.dispose();
    _designsController.dispose();
    _typesController.dispose();
    super.dispose();
  }

  void _calculateAmount(int index) {
    final netQty = double.tryParse(_productControllers[index].netQtyController.text) ?? 0;
    final rate = double.tryParse(_productControllers[index].rateController.text) ?? 0;
    
    final amount = rate * netQty;
    _productControllers[index].amountController.text = amount.toStringAsFixed(2);
    
    _calculateGrandTotal();
  }

  void _calculateNetQtyFromQtyAndPcs(int index) {
    final quantity = double.tryParse(_productControllers[index].quantityController.text) ?? 0;
    final pcs = double.tryParse(_productControllers[index].pcsController.text) ?? 0;
    
    final netQty = quantity * pcs;
    _productControllers[index].netQtyController.text = _formatNumber(netQty);
    
    _calculateAmount(index);
  }

  void _onNetQtyChanged(int index) {
    _calculateAmount(index);
  }

  void _calculateGrandTotal() {
    double total = 0;
    for (var controllers in _productControllers) {
      final amount = double.tryParse(controllers.amountController.text) ?? 0;
      total += amount;
    }
    setState(() {
      _editedOrder.grandTotal = total;
    });
  }

  void _addNewProduct() {
    setState(() {
      _productControllers.add(ProductControllers(
        productController: TextEditingController(),
        quantityController: TextEditingController(text: '1'),
        rateController: TextEditingController(text: '0'),
        pcsController: TextEditingController(text: '1'),
        netQtyController: TextEditingController(text: '1'),
        amountController: TextEditingController(text: '0'),
        requiredByController: TextEditingController(),
        // ✅ Initialize new dropdown controllers for new products
        colorController: TextEditingController(),
        typeController: TextEditingController(),
        designController: TextEditingController(),
        selectedUom: OrderModel.Uom.NOS,
        selectedProductName: '',
        // ✅ Initialize selected values for new products
        selectedColor: null,
        selectedType: null,
        selectedDesign: null,
        // ✅ Initialize dropdown states for new products
        showColorDropdown: false,
        showTypeDropdown: false,
        showDesignDropdown: false,
        colorSearchQuery: '',
        typeSearchQuery: '',
        designSearchQuery: '',
      ));
    });
  }

  void _removeProduct(int index) {
    if (_productControllers.length > 1) {
      setState(() {
        _productControllers[index].dispose();
        _productControllers.removeAt(index);
        _calculateGrandTotal();
      });
    }
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime today = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: DateTime(today.year, today.month, today.day),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  bool _validateAllFields() {
    if (!_formKey.currentState!.validate()) {
      _showValidationError('Please fill all required fields correctly.');
      return false;
    }

    if (_selectedSupplierId.isEmpty) {
      _showValidationError('Please select a supplier.');
      return false;
    }

    if (_productControllers.isEmpty) {
      _showValidationError('Please add at least one product.');
      return false;
    }

    for (int i = 0; i < _productControllers.length; i++) {
      final controller = _productControllers[i];
      
      if (controller.selectedProductName.isEmpty) {
        _showValidationError('Please select a product for Product ${i + 1}.');
        return false;
      }
      
      if (controller.requiredByController.text.isEmpty) {
        _showValidationError('Please select Required By date for Product ${i + 1}.');
        return false;
      }
      
      final quantity = double.tryParse(controller.quantityController.text) ?? 0;
      if (quantity <= 0) {
        _showValidationError('Quantity must be greater than 0 for Product ${i + 1}.');
        return false;
      }
      
      final rate = double.tryParse(controller.rateController.text) ?? 0;
      if (rate <= 0) {
        _showValidationError('Rate must be greater than 0 for Product ${i + 1}.');
        return false;
      }
    }

    return true;
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _saveOrder() async {
    if (!_validateAllFields()) return;

    setState(() => _isLoading = true);

    try {
      final dateParts = _orderDateController.text.split('/');
      if (dateParts.length == 3) {
        _editedOrder.orderDate = DateTime(
          int.parse(dateParts[2]),
          int.parse(dateParts[1]),
          int.parse(dateParts[0]),
        );
      }

      _editedOrder.supplier = _selectedSupplierId.isNotEmpty ? _selectedSupplierId : widget.order.supplier;
      _editedOrder.supplierName = _selectedSupplierName.isNotEmpty ? _selectedSupplierName : widget.order.supplierName;
      _editedOrder.status = _selectedStatus;

      print('Saving with Supplier ID: ${_editedOrder.supplier}');
      print('Saving with Supplier Name: ${_editedOrder.supplierName}');

      _editedOrder.products = _productControllers.map((controller) {
        final requiredDateParts = controller.requiredByController.text.split('/');
        DateTime requiredDate = DateTime.now();
        if (requiredDateParts.length == 3) {
          requiredDate = DateTime(
            int.parse(requiredDateParts[2]),
            int.parse(requiredDateParts[1]),
            int.parse(requiredDateParts[0]),
          );
        }

        return OrderModel.Product(
          product: controller.productController.text,
          quantity: double.tryParse(controller.quantityController.text) ?? 0,
          uom: controller.selectedUom,
          rate: double.tryParse(controller.rateController.text) ?? 0,
          pcs: double.tryParse(controller.pcsController.text),
          netQty: double.tryParse(controller.netQtyController.text) ?? 0,
          amount: double.tryParse(controller.amountController.text) ?? 0,
          requiredBy: requiredDate,
          // ✅ Include new fields in save
          color: controller.selectedColor?.trim().isEmpty == true ? null : controller.selectedColor,
          type: controller.selectedType?.trim().isEmpty == true ? null : controller.selectedType,
          design: controller.selectedDesign?.trim().isEmpty == true ? null : controller.selectedDesign,
        );
      }).toList();

      final result = await UpdateSupplierOrderService.updateSupplierOrder(
        order: _editedOrder,
        context: context,
      );

      if (result == true && mounted) {
        Navigator.pop(context, true); 
        Provider.of<SupplierOrderController>(context, listen: false).loadSupplierOrders();
      } else if (result == null && mounted) {
        // Error handled in service
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Close all dropdowns when tapping outside
        for (int i = 0; i < _productControllers.length; i++) {
          _closeAllDropdowns(i);
        }
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          title: const Text(
            'Edit Order',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
        body: _availableProducts.isEmpty || _availableSuppliers.isEmpty
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderDetailsCard(),
                const SizedBox(height: 16),
                _buildProductsSection(),
                const SizedBox(height: 16),
                _buildAddProductButton(),
                const SizedBox(height: 16),
                _buildGrandTotalCard(),
                const SizedBox(height: 24),
                _buildSaveButton(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.assignment, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_selectedStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _selectedStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildReadOnlyField('Order ID', widget.order.orderId),
            const SizedBox(height: 12),
            
            _buildSupplierDropdown(),
            const SizedBox(height: 12),
            
            _buildDateField(
              controller: _orderDateController,
              label: 'Order Date',
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                const Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Spacer(),
                Text(
                  '${_productControllers.length} items',
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _productControllers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) => _buildProductCard(index),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(int index) {
    return GestureDetector(
      onTap: () => _closeAllDropdowns(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Product ${index + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                if (_productControllers.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeProduct(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildProductDropdown(index),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildNumberFormField(
                    controller: _productControllers[index].quantityController,
                    label: 'Quantity',
                    icon: Icons.straighten,
                    onChanged: (_) => _calculateNetQtyFromQtyAndPcs(index),
                    isInteger: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUomDropdown(index),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildNumberFormField(
                    controller: _productControllers[index].rateController,
                    label: 'Rate',
                    icon: Icons.currency_rupee,
                    onChanged: (_) => _calculateAmount(index),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberFormField(
                    controller: _productControllers[index].pcsController,
                    label: 'PCS',
                    icon: Icons.inventory_2,
                    onChanged: (_) => _calculateNetQtyFromQtyAndPcs(index),
                    isInteger: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildNumberFormField(
                    controller: _productControllers[index].netQtyController,
                    label: 'Net Qty',
                    icon: Icons.balance,
                    onChanged: (_) => _onNetQtyChanged(index),
                    isInteger: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberFormField(
                    controller: _productControllers[index].amountController,
                    label: 'Amount',
                    icon: Icons.currency_rupee,
                    enabled: false,
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            _buildDateField(
              controller: _productControllers[index].requiredByController,
              label: 'Required By',
              icon: Icons.event,
            ),
            
            // ✅ NEW: API-based dropdown fields
            const SizedBox(height: 12),
            _buildSearchableColorField(index),
            
            const SizedBox(height: 12),
            _buildSearchableTypeField(index),
            
            const SizedBox(height: 12),
            _buildSearchableDesignField(index),
          ],
        ),
      ),
    );
  }
  Widget _buildSearchableTypeField(int index) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Type (Optional)',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _productControllers[index].typeController,
        decoration: InputDecoration(
          hintText: 'Search types...',
          prefixIcon: Icon(Icons.category, color: const Color(0xFF3B82F6)),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_productControllers[index].typeController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _productControllers[index].typeController.clear();
                      _productControllers[index].selectedType = null;
                      _productControllers[index].typeSearchQuery = '';
                      _productControllers[index].showTypeDropdown = false;
                    });
                  },
                ),
              Icon(Icons.arrow_drop_down),
              SizedBox(width: 8),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          setState(() {
            _productControllers[index].typeSearchQuery = value;
            _productControllers[index].selectedType = value.isEmpty ? null : value;
          });
        },
        onTap: () {
          setState(() {
            _productControllers[index].showTypeDropdown = true;
            // Close other dropdowns
            _productControllers[index].showColorDropdown = false;
            _productControllers[index].showDesignDropdown = false;
          });
        },
      ),
      
      if (_productControllers[index].showTypeDropdown) ...[
        SizedBox(height: 4),
        AnimatedBuilder(
          animation: _typesController,
          builder: (context, child) {
            if (_typesController.isLoading) {
              return _buildDropdownLoadingContainer('Loading types...');
            }
            
            if (_typesController.hasError) {
              return _buildDropdownErrorContainer('Error loading types');
            }
            
            final filteredTypes = _getFilteredTypes(index);
            
            if (filteredTypes.isEmpty) {
              return _buildDropdownEmptyContainer('No types found');
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
                itemBuilder: (context, typeIndex) {
                  final type = filteredTypes[typeIndex];
                  final isSelected = _productControllers[index].selectedType == type;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _productControllers[index].selectedType = type;
                        _productControllers[index].typeController.text = type;
                        _productControllers[index].typeSearchQuery = type;
                        _productControllers[index].showTypeDropdown = false;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : null,
                        border: typeIndex > 0 ? Border(top: BorderSide(color: Colors.grey[200]!)) : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              type,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

    // ✅ Helper method to close all dropdowns when tapping outside
  void _closeAllDropdowns(int index) {
    setState(() {
      _productControllers[index].showColorDropdown = false;
      _productControllers[index].showTypeDropdown = false;
      _productControllers[index].showDesignDropdown = false;
    });
  }

  // ✅ NEW: Searchable Color Field with API
  Widget _buildSearchableColorField(int index) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Color (Optional)',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _productControllers[index].colorController,
        decoration: InputDecoration(
          hintText: 'Search colors...',
          prefixIcon: Icon(Icons.color_lens, color: const Color(0xFF3B82F6)),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_productControllers[index].colorController.text.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.clear, size: 20),
                  onPressed: () {
                    setState(() {
                      _productControllers[index].colorController.clear();
                      _productControllers[index].selectedColor = null;
                      _productControllers[index].colorSearchQuery = '';
                      _productControllers[index].showColorDropdown = false;
                    });
                  },
                ),
              Icon(Icons.arrow_drop_down),
              SizedBox(width: 8),
            ],
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onChanged: (value) {
          setState(() {
            _productControllers[index].colorSearchQuery = value;
            _productControllers[index].selectedColor = value.isEmpty ? null : value;
          });
        },
        onTap: () {
          setState(() {
            _productControllers[index].showColorDropdown = true;
            // Close other dropdowns
            _productControllers[index].showTypeDropdown = false;
            _productControllers[index].showDesignDropdown = false;
          });
        },
      ),
      
      if (_productControllers[index].showColorDropdown) ...[
        SizedBox(height: 4),
        AnimatedBuilder(
          animation: _colorsController,
          builder: (context, child) {
            if (_colorsController.isLoading) {
              return _buildDropdownLoadingContainer('Loading colors...');
            }
            
            if (_colorsController.hasError) {
              return _buildDropdownErrorContainer('Error loading colors');
            }
            
            final filteredColors = _getFilteredColors(index);
            
            if (filteredColors.isEmpty) {
              return _buildDropdownEmptyContainer('No colors found');
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
                itemBuilder: (context, colorIndex) {
                  final color = filteredColors[colorIndex];
                  final isSelected = _productControllers[index].selectedColor == color;
                  
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _productControllers[index].selectedColor = color;
                        _productControllers[index].colorController.text = color;
                        _productControllers[index].colorSearchQuery = color;
                        _productControllers[index].showColorDropdown = false;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : null,
                        border: colorIndex > 0 ? Border(top: BorderSide(color: Colors.grey[200]!)) : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              color,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  // ✅ NEW: Searchable Design Field with API
  Widget _buildSearchableDesignField(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _productControllers[index].designController,
          decoration: InputDecoration(
            hintText: 'Search designs...',
            prefixIcon: Icon(Icons.brush, color: const Color(0xFF3B82F6)),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_productControllers[index].designController.text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.clear, size: 20),
                    onPressed: () {
                      setState(() {
                        _productControllers[index].designController.clear();
                        _productControllers[index].selectedDesign = null;
                        _productControllers[index].designSearchQuery = '';
                        _productControllers[index].showDesignDropdown = false;
                      });
                    },
                  ),
                Icon(Icons.arrow_drop_down),
                SizedBox(width: 8),
              ],
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onChanged: (value) {
            setState(() {
              _productControllers[index].designSearchQuery = value;
              _productControllers[index].selectedDesign = value.isEmpty ? null : value;
            });
          },
          onTap: () {
            setState(() {
              _productControllers[index].showDesignDropdown = true;
              // Close other dropdowns
              _productControllers[index].showColorDropdown = false;
              _productControllers[index].showTypeDropdown = false;
            });
          },
        ),
        
        if (_productControllers[index].showDesignDropdown) ...[
          SizedBox(height: 4),
          AnimatedBuilder(
            animation: _designsController,
            builder: (context, child) {
              if (_designsController.isLoading) {
                return _buildDropdownLoadingContainer('Loading designs...');
              }
              
              if (_designsController.hasError) {
                return _buildDropdownErrorContainer('Error loading designs');
              }
              
              final filteredDesigns = _getFilteredDesigns(index);
              
              if (filteredDesigns.isEmpty) {
                return _buildDropdownEmptyContainer('No designs found');
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
                  itemBuilder: (context, designIndex) {
                    final design = filteredDesigns[designIndex];
                    final isSelected = _productControllers[index].selectedDesign == design;
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _productControllers[index].selectedDesign = design;
                          _productControllers[index].designController.text = design;
                          _productControllers[index].designSearchQuery = design;
                          _productControllers[index].showDesignDropdown = false;
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue.shade50 : null,
                          border: designIndex > 0 ? Border(top: BorderSide(color: Colors.grey[200]!)) : null,
                        ),
                        child: Row(
                          children: [
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                design,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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

  // ✅ NEW: Filter methods for dropdowns
  List<String> _getFilteredColors(int index) {
    final query = _productControllers[index].colorSearchQuery;
    if (query.isEmpty) return _colorsController.colors;
    return _colorsController.colors
        .where((color) => color.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<String> _getFilteredTypes(int index) {
    final query = _productControllers[index].typeSearchQuery;
    if (query.isEmpty) return _typesController.textileTypes;
    return _typesController.textileTypes
        .where((type) => type.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<String> _getFilteredDesigns(int index) {
    final query = _productControllers[index].designSearchQuery;
    if (query.isEmpty) return _designsController.designs;
    return _designsController.designs
        .where((design) => design.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // ✅ NEW: Helper widgets for dropdown states
  Widget _buildDropdownLoadingContainer(String message) {
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

  Widget _buildDropdownErrorContainer(String message) {
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

  Widget _buildDropdownEmptyContainer(String message) {
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

  Widget _buildProductDropdown(int index) {
    final selectedProductName = _productControllers[index].selectedProductName;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: const Icon(Icons.shopping_bag, color: Color(0xFF3B82F6)),
        title: Text(
          selectedProductName.isEmpty ? 'Select Product' : selectedProductName,
          style: TextStyle(
            color: selectedProductName.isEmpty ? Colors.grey : Colors.black,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () => _showProductSearchDialog(index),
      ),
    );
  }

  Future<void> _showProductSearchDialog(int index) async {
    TextEditingController searchController = TextEditingController();
    List<Datum> filteredProducts = List.from(_availableProducts);
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Select Product',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filteredProducts = _availableProducts
                              .where((product) => product.name
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, listIndex) {
                          final product = filteredProducts[listIndex];
                          final isSelected = product.name == _productControllers[index].selectedProductName;
                          
                          return ListTile(
                            title: Text(
                              product.name,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF3B82F6) : Colors.black,
                              ),
                            ),
                            leading: isSelected 
                                ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6))
                                : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            onTap: () {
                              this.setState(() {
                                _productControllers[index].selectedProductName = product.name;
                                _productControllers[index].productController.text = product.name;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSupplierDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListTile(
        leading: const Icon(Icons.business, color: Color(0xFF3B82F6)),
        title: Text(
          _selectedSupplierName.isEmpty ? 'Select Supplier' : _selectedSupplierName,
          style: TextStyle(
            color: _selectedSupplierName.isEmpty ? Colors.grey : Colors.black,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.arrow_drop_down),
        onTap: () => _showSupplierSearchDialog(),
      ),
    );
  }

  Future<void> _showSupplierSearchDialog() async {
    TextEditingController searchController = TextEditingController();
    List<Supplier> filteredSuppliers = List.from(_availableSuppliers);
    
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                height: MediaQuery.of(context).size.height * 0.7,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.business, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 8),
                        const Text(
                          'Select Supplier',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search suppliers...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setDialogState(() {
                          filteredSuppliers = _availableSuppliers
                              .where((supplier) => supplier.supplierName
                                  .toLowerCase()
                                  .contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = filteredSuppliers[index];
                          final isSelected = supplier.supplierId == _selectedSupplierId;
                          
                          return ListTile(
                            title: Text(
                              supplier.supplierName,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF3B82F6) : Colors.black,
                              ),
                            ),
                            subtitle: Text('ID: ${supplier.supplierId}'),
                            leading: isSelected 
                                ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6))
                                : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
                            onTap: () {
                              this.setState(() {
                                _selectedSupplierId = supplier.supplierId;
                                _selectedSupplierName = supplier.supplierName;
                              });
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGrandTotalCard() {
    return Card(
      elevation: 2,
      color: const Color(0xFF3B82F6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.calculate, color: Colors.white),
            const SizedBox(width: 12),
            const Text(
              'Grand Total:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            Text(
              '₹${_editedOrder.grandTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddProductButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _addNewProduct,
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          padding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }

  Widget _buildNumberFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool enabled = true,
    bool isInteger = false,
    void Function(String)? onChanged,
    Color? backgroundColor,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: isInteger ? TextInputType.number : const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
      inputFormatters: isInteger 
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: enabled ? const Color(0xFF3B82F6) : Colors.grey),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: backgroundColor != null,
        fillColor: backgroundColor,
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      validator: (value) {
        if (value?.isEmpty ?? true) return '$label is required';
        if (double.tryParse(value!) == null) return 'Enter a valid number';
        if (label == 'Quantity' || label == 'Rate') {
          final numValue = double.parse(value);
          if (numValue <= 0) return '$label must be greater than 0';
        }
        return null;
      },
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _selectDate(controller),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
        suffixIcon: const Icon(Icons.arrow_drop_down),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value?.isEmpty ?? true ? '$label is required' : null,
    );
  }

  Widget _buildUomDropdown(int index) {
    final selected = _productControllers[index].selectedUom;

    return DropdownButtonFormField<OrderModel.Uom>(
      isExpanded: true,
      value: selected,
      decoration: InputDecoration(
        labelText: 'UOM',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: [
        DropdownMenuItem(
          value: OrderModel.Uom.NOS,
          child: Text('NOS'),
        ),
        DropdownMenuItem(
          value: OrderModel.Uom.METER,
          child: Text('METER'),
        ),
      ],
      onChanged: (value) {
        if (value != null && value != selected) {
          setState(() {
            _productControllers[index].selectedUom = value;
          });
          print('UOM changed for product ${index + 1}: ${_getUomDisplayText(selected)} → ${_getUomDisplayText(value)}');
        }
      },
      validator: (value) => value == null ? 'UOM is required' : null,
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'converted':
        return const Color(0xFF10B981);
      case 'draft':
        return const Color(0xFFF59E0B);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getUomDisplayText(OrderModel.Uom uom) {
    switch (uom) {
      case OrderModel.Uom.NOS:
        return 'Nos';
      case OrderModel.Uom.METER:
        return 'Meter';
      default:
        return '';
    }
  }
}

// ✅ UPDATED: ProductControllers class with new dropdown fields
class ProductControllers {
  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController rateController;
  final TextEditingController pcsController;
  final TextEditingController netQtyController;
  final TextEditingController amountController;
  final TextEditingController requiredByController;
  
  // ✅ Dropdown controllers
  final TextEditingController colorController;
  final TextEditingController typeController;
  final TextEditingController designController;
  
  OrderModel.Uom selectedUom;
  String selectedProductName;
  
  // ✅ Selected values
  String? selectedColor;
  String? selectedType;
  String? selectedDesign;

  // ✅ NEW: Dropdown states
  bool showColorDropdown;
  bool showTypeDropdown;
  bool showDesignDropdown;
  String colorSearchQuery;
  String typeSearchQuery;
  String designSearchQuery;

  ProductControllers({
    required this.productController,
    required this.quantityController,
    required this.rateController,
    required this.pcsController,
    required this.netQtyController,
    required this.amountController,
    required this.requiredByController,
    required this.colorController,
    required this.typeController,
    required this.designController,
    required this.selectedUom,
    required this.selectedProductName,
    this.selectedColor,
    this.selectedType,
    this.selectedDesign,
    // ✅ NEW: Required dropdown state parameters
    required this.showColorDropdown,
    required this.showTypeDropdown,
    required this.showDesignDropdown,
    required this.colorSearchQuery,
    required this.typeSearchQuery,
    required this.designSearchQuery,
  });

  void dispose() {
    productController.dispose();
    quantityController.dispose();
    rateController.dispose();
    pcsController.dispose();
    netQtyController.dispose();
    amountController.dispose();
    requiredByController.dispose();
    colorController.dispose();
    typeController.dispose();
    designController.dispose();
  }
}