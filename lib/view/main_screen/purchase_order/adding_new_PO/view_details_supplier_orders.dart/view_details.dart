import 'package:flutter/material.dart';
import 'package:calicut_textile_app/modal/get_supplier_orders.dart';

class ViewDetailsSupplierOrder extends StatelessWidget {
  final List<Product> product;
  final Order? order;
  final List<Order>? orders;

  const ViewDetailsSupplierOrder({
    super.key,
    required this.product,
     this.order,
     this.orders,
  });

  @override
  Widget build(BuildContext context) {
    // Get grand total from order
   double grandTotal = order!.grandTotal ?? 0; // ✅ Use the specific order
    int totalItems = product.length;
    
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Order Details",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.indigo[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: product.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No product data available",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Order Summary Header
                  _buildOrderSummary(order!), 
                
                // Products List
                Expanded(
                  child: ListView.builder(
                    itemCount: product.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final item = product[index];
                      return _buildProductCard(item, index + 1, grandTotal);
                    },
                  ),
                ),
                
                // Total Summary Footer
                _buildTotalSummary(grandTotal, totalItems),
              ],
            ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo[600]!, Colors.indigo[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.business,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  order.supplierName ?? "Unknown Supplier",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  "Order ID",
                  order.orderId?.toString() ?? "N/A",
                  Icons.receipt_long,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  "Date",
                 order.orderDate?.toString().split(' ')[0] ?? "",
                  Icons.calendar_today,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white70,
          size: 16,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductCard(Product item, int serialNumber, double grandTotal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Product Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.indigo[600],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      serialNumber.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.product ?? "Unknown Product",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      if (item.uom != null)
                        Text(
                          "Unit: ${item.uom}",
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 12,
                //     vertical: 6,
                //   ),
                //   decoration: BoxDecoration(
                //     color: Colors.green[100],
                //     borderRadius: BorderRadius.circular(20),
                //   ),
                //   child: Text(
                //     "₹${grandTotal.toStringAsFixed(2)}",
                //     style: TextStyle(
                //       fontSize: 14,
                //       fontWeight: FontWeight.bold,
                //       color: Colors.green[700],
                //     ),
                //   ),
                // ),
              ],
            ),
          ),
          
          // Product Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // First Row - Quantity Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        "Quantity",
                        (item.quantity ?? 0).toString(),
                        Icons.inventory,
                        Colors.blue,
                      ),
                    ),
                    if (item.pcs != null)
                      Expanded(
                        child: _buildDetailItem(
                          "Pieces",
                          item.pcs.toString(),
                          Icons.apps,
                          Colors.orange,
                        ),
                      ),
                    if (item.netQty != null)
                      Expanded(
                        child: _buildDetailItem(
                          "Net Qty",
                          item.netQty.toString(),
                          Icons.scale,
                          Colors.purple,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Second Row - Price Details
                Row(
                  children: [
                    Expanded(
                      child: _buildDetailItem(
                        "Rate",
                        "₹${(item.rate ?? 0).toStringAsFixed(2)}",
                        Icons.currency_rupee,
                        Colors.green,
                      ),
                    ),
                  order!.products.length == 1 ? Expanded(
                      child: _buildDetailItem(
                        "Total",
                        "₹${grandTotal.toStringAsFixed(2)}",
                        Icons.calculate,
                        Colors.red,
                      ),
                    ):
                  
                   Expanded(
                      child: _buildDetailItem(
                        "Total",
                        "₹${item.amount.toStringAsFixed(2)}",
                        Icons.calculate,
                        Colors.red,
                      ),
                    ),
                    // Empty space for alignment if needed
                    const Expanded(child: SizedBox()),
                  ],
                ),
                

              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildTotalSummary(double grandTotal, int totalItems) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Total Items: $totalItems",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const Text(
                  "Grand Total",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[600]!, Colors.green[700]!],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                "₹${grandTotal.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}