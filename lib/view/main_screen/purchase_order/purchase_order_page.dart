import 'package:calicut_textile_app/controller/get_supplier_orders_controller.dart';
import 'package:calicut_textile_app/modal/get_supplier_orders.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/create_purchase_order.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/view_details_supplier_orders.dart/edit_supplier_order.dart';
import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/view_details_supplier_orders.dart/view_details.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';

class PurchaseOrderPage extends StatefulWidget {
  const PurchaseOrderPage({super.key});

  @override
  State<PurchaseOrderPage> createState() => _PurchaseOrderPageState();
}

class _PurchaseOrderPageState extends State<PurchaseOrderPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final TextEditingController _searchController = TextEditingController();
  
  // Filter variables
  String _selectedDateFilter = 'This Month';
  String? _selectedStatus;
  DateTime? _customDate;
  bool _showFilters = false;
  
  // List of available date filters
  final List<String> _dateFilters = [
    'Today',
    'This Week', 
    'This Month',
    'Custom'
  ];
  
  // List of available status filters
  final List<String> _statusFilters = [
    'Draft',
    'Submitted', // Note: keeping original spelling from your code
    
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _animationController.forward();
    
    // Initialize data loading after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SupplierOrderController>(context, listen: false)
          .loadSupplierOrders();
    });
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      // Trigger rebuild to apply search filter
    });
  }

  // Filter orders based on search, date, and status
 // Filter orders based on search, date, and status
List<dynamic> _getFilteredOrders(List<dynamic> orders) {
  List<dynamic> filteredOrders = orders;
  
  // Apply search filter (search by both supplier name and supplier ID)
  if (_searchController.text.isNotEmpty) {
    final searchTerm = _searchController.text.toLowerCase();
    filteredOrders = filteredOrders.where((order) {
      final supplierName = (order.supplierName ?? '').toLowerCase();
      final supplierId = order.supplier.toLowerCase();
      
      // Print search terms for debugging
      print('Search Term: $searchTerm');
      print('Supplier Name: $supplierName');
      print('Supplier ID: $supplierId');
      print('Name Match: ${supplierName.contains(searchTerm)}');
      print('ID Match: ${supplierId.contains(searchTerm)}');
      
      return supplierName.contains(searchTerm) || supplierId.contains(searchTerm);
    }).toList();
  }
  
  // Apply date filter
  filteredOrders = filteredOrders.where((order) {
    return _isOrderInDateRange(order);
  }).toList();
  
  // Apply status filter
  if (_selectedStatus != null) {
    filteredOrders = filteredOrders.where((order) {
      return order.status == _selectedStatus;
    }).toList();
  }
  
  return filteredOrders;
}
  bool _isOrderInDateRange(dynamic order) {
  // ✅ Safe null checking for orderDate
  if (order.orderDate == null) return true;
  
  try {
    DateTime orderDate = order.orderDate;
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    switch (_selectedDateFilter) {
      case 'Today':
        DateTime orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
        return orderDay.isAtSameMomentAs(today);
        
      case 'This Week':
        DateTime weekStart = today.subtract(Duration(days: today.weekday - 1));
        DateTime weekEnd = weekStart.add(const Duration(days: 6));
        return orderDate.isAfter(weekStart.subtract(const Duration(days: 1))) &&
               orderDate.isBefore(weekEnd.add(const Duration(days: 1)));
               
      case 'This Month':
        return orderDate.year == now.year && orderDate.month == now.month;
        
      case 'Custom':
        if (_customDate != null) {
          DateTime customDay = DateTime(_customDate!.year, _customDate!.month, _customDate!.day);
          DateTime orderDay = DateTime(orderDate.year, orderDate.month, orderDate.day);
          return orderDay.isAtSameMomentAs(customDay);
        }
        return true;
        
      default:
        return true;
    }
  } catch (e) {
    print('Date parsing error: $e');
    return true; // If date parsing fails, include the order
  }
}
  Future<void> _selectCustomDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _customDate = picked;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedDateFilter = 'This Month';
      _selectedStatus = null;
      _customDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Supplier PO',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
              color: const Color(0xFF1E293B),
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by supplier name or ID..',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF64748B)),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          
          // Filters Section
          if (_showFilters)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Filter
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _dateFilters.map((filter) {
                      final isSelected = _selectedDateFilter == filter;
                      return FilterChip(
                        label: Text(filter),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDateFilter = filter;
                            if (filter == 'Custom') {
                              _selectCustomDate();
                            }
                          });
                        },
                        selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF3B82F6),
                      );
                    }).toList(),
                  ),
                  
                  // Custom date display
                  if (_selectedDateFilter == 'Custom' && _customDate != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Selected Date: ${_formatDate(_customDate.toString())}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Status Filter
                  const Text(
                    'Status',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('All Status'),
                        selected: _selectedStatus == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedStatus = null;
                          });
                        },
                        selectedColor: const Color(0xFF3B82F6).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF3B82F6),
                      ),
                      ..._statusFilters.map((status) {
                        final isSelected = _selectedStatus == status;
                        return FilterChip(
                          label: Text(status),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedStatus = selected ? status : null;
                            });
                          },
                          selectedColor: _getStatusColor(status).withOpacity(0.2),
                          checkmarkColor: _getStatusColor(status),
                        );
                      }).toList(),
                    ],
                  ),
                ],
              ),
            ),
          
          const SizedBox(height: 16),
          
          // Purchase Orders List
          Expanded(
            child: Consumer<SupplierOrderController>(
              builder: (context, controller, child) {
                if (controller.isLoading && controller.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                final filteredOrders = _getFilteredOrders(controller.orders);

                if (filteredOrders.isEmpty && !controller.isLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.orders.isEmpty 
                              ? 'No supplier orders found'
                              : 'No orders match your filters',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (controller.orders.isNotEmpty)
                          TextButton(
                            onPressed: _clearFilters,
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    final controller = Provider.of<SupplierOrderController>(context, listen: false);
                    controller.clearOrders();
                    await controller.loadSupplierOrders();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _animationController,
                          curve: Interval(
                            (index % 5) * 0.1,
                            0.5 + ((index % 5) * 0.1),
                            curve: Curves.easeOutCubic,
                          ),
                        )),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () {
                                // Handle tap - navigate to order details
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child:
                                                    order.supplierName.isNotEmpty ? Text(
                                                      '${order.supplierName}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF1E293B),
                                                      ),
                                                    ): SizedBox()
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(order.status),
                                                      borderRadius: BorderRadius.circular(10),
                                                    ),
                                                    child: Text(
                                                      order.status,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w500,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              Padding(
  padding: const EdgeInsets.only(top: 4),
  child: order.supplier == null ?  SizedBox() :
  
   Text(
    'SO ID: ${order.supplier}',
    style: const TextStyle(
      fontSize: 12,
      color: Color(0xFF64748B),
      fontWeight: FontWeight.w500,
    ),
  ),
),
                                              // Show order date
                                              Padding(
                                                padding: const EdgeInsets.only(top: 4),
                                                child: Text(
                                                  'Date: ${_formatDate(order.orderDate.toString())}',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FAFC),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Total Amount',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '₹${order.grandTotal.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [],
                                        ),
                                        PopupMenuButton<String>(
                                          icon: const Icon(Icons.more_vert),
                                          onSelected: (value) {
                                            if (value == 'Edit') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => EditSupplierOrderPage(order: order),
                                                ),
                                              );
                                            } else if (value == 'View Details') {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => ViewDetailsSupplierOrder(
                                                    product: order.products,
                                                    order: order,
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          itemBuilder: (BuildContext context) {
                                            if (order.status == "Draft") {
                                              return const [
                                                PopupMenuItem<String>(
                                                  value: 'Edit',
                                                  child: Text('Edit'),
                                                ),
                                                PopupMenuItem<String>(
                                                  value: 'View Details',
                                                  child: Text('View Details'),
                                                ),
                                              ];
                                            } else {
                                              return const [
                                                PopupMenuItem<String>(
                                                  value: 'View Details',
                                                  child: Text('View Details'),
                                                ),
                                              ];
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreatePurchaseOrder()),
          );
        },
        backgroundColor: const Color(0xFF3B82F6),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Supplier PO',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'submitted':
        return const Color(0xFF10B981); // Green for submitted
      case 'draft':
        return const Color(0xFFF59E0B); // Yellow for draft
      
      default:
        return const Color(0xFF6B7280); // Gray for unknown
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}