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
  }


  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Supplier Orders',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      body: Column(
        children: [
          // Purchase Orders List
          Expanded(
            child: Consumer<SupplierOrderController>(
              builder: (context, controller, child) {
              
                // final orderproducts = controller.orderproducts;
                // final products = controller.products;




                if (controller.isLoading && controller.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.orders.isEmpty && !controller.isLoading) {
                  return const Center(
                    child: Text(
                      'No supplier orders found',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
  final controller = Provider.of<SupplierOrderController>(context, listen: false);
  controller.clearOrders(); // Reset pagination + orders
  await controller.loadSupplierOrders(); // Load fresh data
},

               
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: controller.orders.length ,
                    itemBuilder: (context, index) {
                        final orders = controller.orders[index];
                      // Load more indicator
                      // if (index == controller.orders.length) {
                      //   if (controller.hasMore && !controller.isLoading) {
                      //     // Trigger load more
                         
                      //     return const Center(child: CircularProgressIndicator());
                      //   }
                      //   return const Padding(
                      //     padding: EdgeInsets.all(16.0),
                      //     child: Center(child: CircularProgressIndicator()),
                      //   );
                      // }
                  
                      final order = controller.orders[index];
                      
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
                                                  Text(
                                                    order.products.isNotEmpty ? order.products.first.product : 'No Product'
                  ,
                                                    style: const TextStyle(
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFF1E293B),
                                                    ),
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
                                              const SizedBox(height: 4),
                                              Text(
                                                'Supplier: ${order.supplierName}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF64748B),
                                                  fontWeight: FontWeight.w500,
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
                                          
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                // const Text(
                                                //   'Outstanding',
                                                //   style: TextStyle(
                                                //     fontSize: 12,
                                                //     color: Color(0xFF64748B),
                                                //     fontWeight: FontWeight.w500,
                                                //   ),
                                                // ),
                                                const SizedBox(height: 4),
                                                // Text(
                                                //   '₹${order.outstandingAmount?.toStringAsFixed(2) ?? '0.00'}',
                                                //   style: const TextStyle(
                                                //     fontSize: 18,
                                                //     fontWeight: FontWeight.bold,
                                                //     color: Color(0xFFEF4444),
                                                //   ),
                                                // ),
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
                                          children: [
                                            
                                          ],
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
      order: order, // ✅ Pass single order object, not a list
    ),
  ),
);
                      }
                    },
                    itemBuilder: (BuildContext context) {
                      // Conditionally build menu items based on order.status
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
          'Create Supplier Order',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'sumbitted':
        return const Color(0xFF10B981); // Green for converted
      case 'draft':
        return const Color(0xFFF59E0B); // Yellow for draft
      case 'cancelled':
        return const Color(0xFFEF4444); // Red for cancelled
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