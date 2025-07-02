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
    _initializeData();
    _loadData();
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
      )).toList(),
    );

    // Initialize order controllers
    _orderDateController = TextEditingController(
        text: "${_editedOrder.orderDate.day}/${_editedOrder.orderDate.month}/${_editedOrder.orderDate.year}");
    _selectedStatus = _editedOrder.status;
    _selectedSupplierId = _editedOrder.supplier!;
    _selectedSupplierName = _editedOrder.supplierName!;

    // Initialize product controllers with proper number formatting and UOM preservation
    _productControllers = _editedOrder.products.map((product) {
      return ProductControllers(
        productController: TextEditingController(text: product.product),
        quantityController: TextEditingController(text: _formatNumber(product.quantity)),
        rateController: TextEditingController(text: product.rate.toString()),
        pcsController: TextEditingController(text: _formatNumber(product.pcs)),
        netQtyController: TextEditingController(text: _formatNumber(product.netQty)),
        amountController: TextEditingController(text: product.amount.toString()),
        requiredByController: TextEditingController(
            text: "${product.requiredBy.day}/${product.requiredBy.month}/${product.requiredBy.year}"),
        // Preserve the original UOM from the fetched data
        selectedUom: product.uom ?? OrderModel.Uom.NOS,
        selectedProductName: product.product,
      );
    }).toList();

    // Ensure calculations are correct on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _productControllers.length; i++) {
        _calculateAmount(i); // Calculate amount based on existing values
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
      
      // Validate selected supplier exists in the list
      final supplierExists = _availableSuppliers.any((supplier) => supplier.supplierName == _selectedSupplierId);
      if (!supplierExists && _availableSuppliers.isNotEmpty) {
        _selectedSupplierId = _availableSuppliers.first.supplierName;
        _selectedSupplierName = _availableSuppliers.first.supplierName;
      }
      
      // Validate selected products exist in the list, but preserve UOM
      for (int i = 0; i < _productControllers.length; i++) {
        final selectedProductName = _productControllers[i].selectedProductName;
        final productExists = _availableProducts.any((product) => product.name == selectedProductName);
        if (!productExists && selectedProductName.isNotEmpty) {
          _productControllers[i].selectedProductName = '';
          // Don't reset UOM here - keep the original fetched UOM
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
    super.dispose();
  }

  void _calculateAmount(int index) {
    final netQty = double.tryParse(_productControllers[index].netQtyController.text) ?? 0;
    final rate = double.tryParse(_productControllers[index].rateController.text) ?? 0;
    
    // Calculate amount = rate * net_qty
    final amount = rate * netQty;
    _productControllers[index].amountController.text = amount.toStringAsFixed(2);
    
    _calculateGrandTotal();
  }

  void _calculateNetQtyFromQtyAndPcs(int index) {
    final quantity = double.tryParse(_productControllers[index].quantityController.text) ?? 0;
    final pcs = double.tryParse(_productControllers[index].pcsController.text) ?? 0;
    
    // Calculate net_qty = qty * pcs
    final netQty = quantity * pcs;
    _productControllers[index].netQtyController.text = _formatNumber(netQty);
    
    // Recalculate amount after net_qty changes
    _calculateAmount(index);
  }

  void _onNetQtyChanged(int index) {
    // When net_qty is manually changed, just recalculate the amount
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
        quantityController: TextEditingController(text: '0'),
        rateController: TextEditingController(text: '0'),
        pcsController: TextEditingController(text: '0'),
        netQtyController: TextEditingController(text: '0'),
        amountController: TextEditingController(text: '0'),
        requiredByController: TextEditingController(),
        selectedUom: OrderModel.Uom.NOS,
        selectedProductName: '',
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
    firstDate: DateTime(today.year, today.month, today.day), // Prevent past dates
    lastDate: DateTime(2030),
  );

  if (picked != null) {
    controller.text = "${picked.day}/${picked.month}/${picked.year}";
  }
}


  bool _validateAllFields() {
    // Check if form validation passes
    if (!_formKey.currentState!.validate()) {
      _showValidationError('Please fill all required fields correctly.');
      return false;
    }

    // Check if supplier is selected
    if (_selectedSupplierId.isEmpty) {
      _showValidationError('Please select a supplier.');
      return false;
    }

    // Check if at least one product is added
    if (_productControllers.isEmpty) {
      _showValidationError('Please add at least one product.');
      return false;
    }

    // Check each product for required fields
    for (int i = 0; i < _productControllers.length; i++) {
      final controller = _productControllers[i];
      
      // Check if product is selected
      if (controller.selectedProductName.isEmpty) {
        _showValidationError('Please select a product for Product ${i + 1}.');
        return false;
      }
      
      // Check if UOM is selected
      if (controller.selectedUom == OrderModel.Uom.NOS) {
        _showValidationError('Please select UOM for Product ${i + 1}.');
        return false;
      }
      
      // Check if required by date is filled
      if (controller.requiredByController.text.isEmpty) {
        _showValidationError('Please select Required By date for Product ${i + 1}.');
        return false;
      }
      
      // Check if quantity is greater than 0
      final quantity = double.tryParse(controller.quantityController.text) ?? 0;
      if (quantity <= 0) {
        _showValidationError('Quantity must be greater than 0 for Product ${i + 1}.');
        return false;
      }
      
      // Check if rate is greater than 0
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
    // Validate all fields before proceeding
    if (!_validateAllFields()) return;

    setState(() => _isLoading = true);

    try {
      // Parse date from string
      final dateParts = _orderDateController.text.split('/');
      if (dateParts.length == 3) {
        _editedOrder.orderDate = DateTime(
          int.parse(dateParts[2]), // year
          int.parse(dateParts[1]), // month
          int.parse(dateParts[0]), // day
        );
      }

      // Update order details
      _editedOrder.supplier = _selectedSupplierId;
      _editedOrder.supplierName = _selectedSupplierName;
      _editedOrder.status = _selectedStatus;

      // Update products from controllers
      _editedOrder.products = _productControllers.map((controller) {
        // Parse required date
        final requiredDateParts = controller.requiredByController.text.split('/');
        DateTime requiredDate = DateTime.now();
        if (requiredDateParts.length == 3) {
          requiredDate = DateTime(
            int.parse(requiredDateParts[2]), // year
            int.parse(requiredDateParts[1]), // month
            int.parse(requiredDateParts[0]), // day
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
        );
      }).toList();

      // Call the update service
      final result = await UpdateSupplierOrderService.updateSupplierOrder(
        order: _editedOrder,
        context: context,
      );

      if (result == true && mounted) {
        // Success is already handled in the service with snackbar
        Navigator.pop(context, true); 
        Provider.of<SupplierOrderController>(context, listen: false).loadSupplierOrders(); // Return true to indicate success
      } else if (result == null && mounted) {
        // Error is already handled in the service with snackbar
        // Stay on the page to allow user to try again
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
    return Scaffold(
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
              // Order Details Card
              _buildOrderDetailsCard(),
              const SizedBox(height: 16),
              
              // Products Section
              _buildProductsSection(),
              
              const SizedBox(height: 16),
              _buildAddProductButton(),
              
              const SizedBox(height: 16),
              
              // Grand Total Card
              _buildGrandTotalCard(),
              
              const SizedBox(height: 24),
              _buildSaveButton(),
              
              const SizedBox(height: 100), // Extra space for FAB
            ],
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
            
            // Order ID (Read-only)
            _buildReadOnlyField('Order ID', widget.order.orderId),
            const SizedBox(height: 12),
            
            // Supplier Dropdown
            _buildSupplierDropdown(),
            const SizedBox(height: 12),
            
            // Order Date
            _buildDateField(
              controller: _orderDateController,
              label: 'Order Date',
              icon: Icons.calendar_today,
            ),
            const SizedBox(height: 12),
            
            // Status Dropdown
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
    return Container(
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
          
          // Product Dropdown
          _buildProductDropdown(index),
          const SizedBox(height: 12),
          
          // Quantity and UOM Row
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
          
          // Rate and PCS Row
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
          
          // Net Qty and Amount Row
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
                  enabled: false, // Amount is calculated
                  backgroundColor: Colors.grey[100],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Required By Date
          _buildDateField(
            controller: _productControllers[index].requiredByController,
            label: 'Required By',
            icon: Icons.event,
          ),
        ],
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
                  // Header
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
                  
                  // Search Field
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
                  
                  // Products List
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
      
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_selectedSupplierName.isNotEmpty)
            
            
          const Icon(Icons.arrow_drop_down),
        ],
      ),
      onTap: () => _showSupplierSearchDialog(),
    ),
  );
}
Future<void> _showSupplierSearchDialog() async {
  TextEditingController searchController = TextEditingController();
  List<Supplier> filteredSuppliers = List.from(_availableSuppliers);
  bool isSearching = false;
  String? searchError;
  
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
                  // Header
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
                  
                  // Search Field
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search suppliers by name or ID...',
                      prefixIcon: isSearching 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: Padding(
                                padding: EdgeInsets.all(12.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                searchController.clear();
                                setDialogState(() {
                                  filteredSuppliers = List.from(_availableSuppliers);
                                  searchError = null;
                                });
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      errorText: searchError,
                    ),
                    onChanged: (value) async {
                      if (value.trim().isEmpty) {
                        setDialogState(() {
                          filteredSuppliers = List.from(_availableSuppliers);
                          searchError = null;
                        });
                        return;
                      }

                      // Debounce search - wait 500ms after user stops typing
                      await Future.delayed(const Duration(milliseconds: 500));
                      
                      // Check if the search query is still the same
                      if (searchController.text.trim() != value.trim()) return;

                      setDialogState(() {
                        isSearching = true;
                        searchError = null;
                      });

                      try {
                        // Create a temporary controller for search
                        final tempController = SuppliersController();
                        
                        // Search using the API
                        await tempController.searchSuppliers(value.trim());
                        
                        if (tempController.hasError) {
                          setDialogState(() {
                            searchError = 'Search failed. Please try again.';
                            isSearching = false;
                          });
                        } else {
                          setDialogState(() {
                            filteredSuppliers = tempController.suppliers;
                            isSearching = false;
                          });
                        }
                      } catch (e) {
                        setDialogState(() {
                          searchError = 'Search failed: ${e.toString()}';
                          isSearching = false;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Results Count
                  if (!isSearching)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${filteredSuppliers.length} suppliers found',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  
                  // Suppliers List
                  Expanded(
                    child: filteredSuppliers.isEmpty && !isSearching
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  searchController.text.isNotEmpty 
                                      ? Icons.search_off 
                                      : Icons.business_outlined,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  searchController.text.isNotEmpty
                                      ? 'No suppliers found for "${searchController.text}"'
                                      : 'No suppliers available',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (searchController.text.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Try searching with different keywords',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 14,
                                    ),
                                  ),
                                ]
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: filteredSuppliers.length,
                            itemBuilder: (context, index) {
                              final supplier = filteredSuppliers[index];
                              final isSelected = supplier.supplierId == _selectedSupplierId;
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: isSelected ? 2 : 0,
                                color: isSelected ? const Color(0xFFEFF6FF) : null,
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: isSelected 
                                        ? const Color(0xFF3B82F6)
                                        : Colors.grey[200],
                                    child: Icon(
                                      isSelected 
                                          ? Icons.check
                                          : Icons.business,
                                      color: isSelected 
                                          ? Colors.white
                                          : Colors.grey[600],
                                    ),
                                  ),
                                  title: Text(
                                    supplier.supplierName,
                                    style: TextStyle(
                                      fontWeight: isSelected 
                                          ? FontWeight.bold 
                                          : FontWeight.w500,
                                      color: isSelected 
                                          ? const Color(0xFF3B82F6) 
                                          : Colors.black,
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'ID: ${supplier.supplierId}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (supplier.supplierGroup.isNotEmpty)
                                        Container(
                                          margin: const EdgeInsets.only(top: 4),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(
                                              color: Colors.blue[200]!,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            supplier.supplierGroup,
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Color(0xFF3B82F6),
                                        )
                                      : const Icon(
                                          Icons.radio_button_unchecked,
                                          color: Colors.grey,
                                        ),
                                  onTap: () {
                                    this.setState(() {
                                      _selectedSupplierId = supplier.supplierId;
                                      _selectedSupplierName = supplier.supplierName;
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  
                  // Bottom actions
                  if (searchController.text.isNotEmpty && !isSearching)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                searchController.clear();
                                setDialogState(() {
                                  filteredSuppliers = List.from(_availableSuppliers);
                                  searchError = null;
                                });
                              },
                              icon: const Icon(Icons.clear),
                              label: const Text('Clear Search'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                // Load more suppliers if needed
                                final supplierController = Provider.of<SuppliersController>(
                                  context, 
                                  listen: false,
                                );
                                if (supplierController.hasMore && !supplierController.isLoading) {
                                  await supplierController.loadMoreSuppliers();
                                  setDialogState(() {
                                    filteredSuppliers = supplierController.suppliers;
                                  });
                                }
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Load More'),
                            ),
                          ),
                        ],
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
    // Don't set to null if it's EMPTY, instead use the actual selected value
    final selectedValue = selected;

    return DropdownButtonFormField<OrderModel.Uom>(
      isExpanded: true,
      value: selectedValue == OrderModel.Uom.NOS ? null : selectedValue,
      decoration: InputDecoration(
        labelText: 'UOM',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      hint: const Text('Select UOM'),
      items: OrderModel.Uom.values
          .where((uom) => uom != OrderModel.Uom.NOS)
          .map((uom) => DropdownMenuItem(
                value: uom,
                child: Text(_getUomDisplayText(uom)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _productControllers[index].selectedUom = value ?? OrderModel.Uom.NOS;
        });
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
      
        return '';
    }
  }

  // OrderModel.Uom _convertStringToUom(String uomString) {
  //   switch (uomString.toLowerCase()) {
  //     case 'kg':
  //       return OrderModel.Uom.KG;
  //     case 'nos':
  //       return OrderModel.Uom.NOS;
  //     case 'unit':
  //       return OrderModel.Uom.UNIT;
  //     case 'box':
  //       return OrderModel.Uom.BOX;
  //     case 'pair':
  //       return OrderModel.Uom.PAIR;
  //     case 'set':
  //       return OrderModel.Uom.SET;
  //     case 'meter':
  //       return OrderModel.Uom.METER;
  //     default:
  //       return OrderModel.Uom.UNIT;
  //   }
  // }
}

class ProductControllers {
  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController rateController;
  final TextEditingController pcsController;
  final TextEditingController netQtyController;
  final TextEditingController amountController;
  final TextEditingController requiredByController;
  OrderModel.Uom selectedUom;
  String selectedProductName;

  ProductControllers({
    required this.productController,
    required this.quantityController,
    required this.rateController,
    required this.pcsController,
    required this.netQtyController,
    required this.amountController,
    required this.requiredByController,
    required this.selectedUom,
    required this.selectedProductName,
  });

  void dispose() {
    productController.dispose();
    quantityController.dispose();
    rateController.dispose();
    pcsController.dispose();
    netQtyController.dispose();
    amountController.dispose();
    requiredByController.dispose();
  }
}