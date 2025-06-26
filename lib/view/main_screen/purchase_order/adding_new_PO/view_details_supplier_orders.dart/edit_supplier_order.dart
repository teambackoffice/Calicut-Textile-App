import 'package:calicut_textile_app/controller/product_controller.dart';
import 'package:calicut_textile_app/controller/supplier_list_controller.dart';
import 'package:calicut_textile_app/service/edit_supplier_order_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:calicut_textile_app/modal/get_supplier_orders.dart' as OrderModel;
import 'package:calicut_textile_app/modal/product_list_model.dart';
import 'package:calicut_textile_app/modal/supplier_list._modaldart';
import 'package:calicut_textile_app/modal/add_product_modal.dart' as AddProductModel;

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
    _selectedSupplierId = _editedOrder.supplier;
    _selectedSupplierName = _editedOrder.supplierName;

    // Initialize product controllers
    _productControllers = _editedOrder.products.map((product) {
      return ProductControllers(
        productController: TextEditingController(text: product.product),
        quantityController: TextEditingController(text: product.quantity.toString()),
        rateController: TextEditingController(text: product.rate.toString()),
        pcsController: TextEditingController(text: product.pcs.toString()),
        netQtyController: TextEditingController(text: product.netQty.toString()),
        amountController: TextEditingController(text: product.amount.toString()),
        requiredByController: TextEditingController(
            text: "${product.requiredBy.day}/${product.requiredBy.month}/${product.requiredBy.year}"),
        selectedUom: product.uom!,
        selectedProductName: product.product,
      );
    }).toList();

    // Ensure calculations are correct on initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (int i = 0; i < _productControllers.length; i++) {
        _calculateNetQtyFromQtyAndPcs(i);
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
      
      // Validate selected products exist in the list
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
    final pcs = int.tryParse(_productControllers[index].pcsController.text) ?? 0;
    
    // Calculate net_qty = qty * pcs (this is just a helper calculation)
    final netQty = quantity * pcs;
    _productControllers[index].netQtyController.text = netQty.toString();
    
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
        selectedUom: OrderModel.Uom.UNIT,
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
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      controller.text = "${picked.day}/${picked.month}/${picked.year}";
    }
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate()) return;

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
          rate: double.tryParse(controller.rateController.text)!,
          pcs: double.tryParse(controller.pcsController.text),
          netQty: double.tryParse(controller.netQtyController.text)!,
          amount: double.tryParse(controller.amountController.text)!,
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
        Navigator.pop(context, true); // Return true to indicate success
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

  void _showCreateProductDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateProductDialog(
        onProductCreated: (productName) {
          // Refresh products list and select the new product
          Provider.of<ProductListController>(context, listen: false)
              .fetchProducts()
              .then((_) {
            if (mounted) {
              setState(() {
                _availableProducts = Provider.of<ProductListController>(context, listen: false).products;
              });
            }
          });
        },
      ),
    );
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
          
          // Calculation Info Card
          
            
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
                  '',
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
          
          // Product Dropdown with Create Option
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
                  // Net Qty is now editable
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberFormField(
                  controller: _productControllers[index].amountController,
                  label: 'Amount ',
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
    // Ensure selected product exists in available products or set to null
    String? validSelectedProduct;
    if (_productControllers[index].selectedProductName.isNotEmpty) {
      final productExists = _availableProducts.any(
        (product) => product.name == _productControllers[index].selectedProductName
      );
      if (productExists) {
        validSelectedProduct = _productControllers[index].selectedProductName;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: validSelectedProduct,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  prefixIcon: const Icon(Icons.shopping_bag, color: Color(0xFF3B82F6)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: [
                  ..._availableProducts.map((product) => DropdownMenuItem(
                    value: product.name,
                    child: Text(product.name),
                  )),
                   
                ],
                onChanged: (value) {
                  if (value == 'CREATE_NEW') {
                    _showCreateProductDialog();
                  } else if (value != null) {
                    setState(() {
                      _productControllers[index].selectedProductName = value;
                      _productControllers[index].productController.text = value;
                      
                      // Auto-fill rate if available from product data
                      final selectedProduct = _availableProducts.firstWhere(
                        (product) => product.name == value,
                        orElse: () => _availableProducts.first,
                      );
                      _productControllers[index].rateController.text = selectedProduct.rate.toString();
                      
                      // Convert UOM from string to enum
                      _productControllers[index].selectedUom = _convertStringToUom(selectedProduct.uom ?? 'Unit');
                    });
                    // Call calculate net qty after setState to update all calculations
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _calculateNetQtyFromQtyAndPcs(index);
                    });
                  }
                },
                validator: (value) => value == null || value.isEmpty || value == 'CREATE_NEW' ? 'Product is required' : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSupplierDropdown() {
    // Ensure selected supplier exists in available suppliers or set to null
    String? validSelectedSupplier;
    if (_selectedSupplierId.isNotEmpty) {
      final supplierExists = _availableSuppliers.any(
        (supplier) => supplier.supplierName == _selectedSupplierId
      );
      if (supplierExists) {
        validSelectedSupplier = _selectedSupplierId;
      }
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      
      // value: widget.order.supplier,
      decoration: InputDecoration(
        labelText: 'Supplier',
        prefixIcon: const Icon(Icons.business, color: Color(0xFF3B82F6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        helperStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
      ),
      hint: const Text('Select Supplier'),
      items: _availableSuppliers.map((supplier) => DropdownMenuItem(
        value: supplier.supplierId, // This is actually the supplier ID
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              supplier.supplierName, // Display supplier name
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            
          ],
        ),
      )).toList(),
      onChanged: (value) {
        if (value != null) {
          final selectedSupplier = _availableSuppliers.firstWhere(
            (supplier) => supplier.supplierId == value, // value is the supplier ID
          );
          setState(() {
            _selectedSupplierId = value; // Store the ID
            _selectedSupplierName = selectedSupplier.supplierName; // Store the name
          });
        }
      },
      validator: (value) => value == null ? 'Supplier is required' : null,
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
    void Function(String)? onChanged,
    Color? backgroundColor,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: TextInputType.number,
      onChanged: onChanged,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
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
    return DropdownButtonFormField<OrderModel.Uom>(
      value: _productControllers[index].selectedUom,
      decoration: InputDecoration(
        labelText: 'UOM',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: OrderModel.Uom.values
          .where((uom) => uom != OrderModel.Uom.EMPTY)
          .map((uom) => DropdownMenuItem(
                value: uom,
                child: Text(_getUomDisplayText(uom)),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _productControllers[index].selectedUom = value!;
        });
      },
    );
  }

  Widget _buildStatusDropdown() {
    final statuses = ['draft', 'converted', 'cancelled'];
    return DropdownButtonFormField<String>(
      value: _selectedStatus.toLowerCase(),
      decoration: InputDecoration(
        labelText: 'Status',
        prefixIcon: const Icon(Icons.flag, color: Color(0xFF3B82F6)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: statuses
          .map((status) => DropdownMenuItem(
                value: status,
                child: Text(status.toUpperCase()),
              ))
          .toList(),
      onChanged: (value) {
        setState(() {
          _selectedStatus = value!;
        });
      },
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
      case OrderModel.Uom.KG:
        return 'Kg';
      case OrderModel.Uom.NOS:
        return 'Nos';
      case OrderModel.Uom.UNIT:
        return 'Unit';
      case OrderModel.Uom.EMPTY:
        return '';
    }
  }

  OrderModel.Uom _convertStringToUom(String uomString) {
    switch (uomString.toLowerCase()) {
      case 'kg':
        return OrderModel.Uom.KG;
      case 'nos':
        return OrderModel.Uom.NOS;
      case 'unit':
        return OrderModel.Uom.UNIT;
      default:
        return OrderModel.Uom.UNIT;
    }
  }
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

class CreateProductDialog extends StatefulWidget {
  final Function(String) onProductCreated;

  const CreateProductDialog({
    super.key,
    required this.onProductCreated,
  });

  @override
  State<CreateProductDialog> createState() => _CreateProductDialogState();
}

class _CreateProductDialogState extends State<CreateProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _rateController = TextEditingController();
  final _colorController = TextEditingController();
  String _selectedUom = 'Unit';
  bool _isLoading = false;

  @override
  void dispose() {
    _productNameController.dispose();
    _qtyController.dispose();
    _rateController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final qty = double.tryParse(_qtyController.text) ?? 0;
      final rate = double.tryParse(_rateController.text) ?? 0;
      final amount = qty * rate; // This will be recalculated based on net_qty in the edit page

      // You'll need to implement the API key retrieval
      // For now, using a placeholder
      final product = AddProductModel.Product(
        productName: _productNameController.text,
        qty: qty.toString(),
        rate: rate.toString(),
        amount: amount.toString(),
        color: _colorController.text,
        uom: _selectedUom,
        imagePaths: [], // Empty for now
        api_key: 'your_api_key', // Implement API key retrieval
      );

      final result = await Provider.of<ProductListController>(context, listen: false)
          .addProduct(addProductModel: product, context: context);

      if (result == true) {
        widget.onProductCreated(_productNameController.text);
        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating product: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Product'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _productNameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Product name is required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _colorController,
                decoration: const InputDecoration(
                  labelText: 'Color',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Color is required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedUom,
                decoration: const InputDecoration(
                  labelText: 'UOM',
                  border: OutlineInputBorder(),
                ),
                items: ['Unit', 'Kg', 'Nos'].map((uom) => DropdownMenuItem(
                  value: uom,
                  child: Text(uom),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUom = value!;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
             