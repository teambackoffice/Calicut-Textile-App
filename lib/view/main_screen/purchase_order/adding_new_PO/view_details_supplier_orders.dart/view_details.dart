import 'package:flutter/material.dart';
import 'package:calicut_textile_app/modal/get_supplier_orders.dart';

class ViewDetailsSupplierOrder extends StatelessWidget {
  final List<Product> product;
  final List<Order> orders;

  const ViewDetailsSupplierOrder({
    super.key,
    required this.product,
    required this.orders,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Product Details"),
      ),
      body: product.isEmpty
          ? const Center(child: Text("No product data available."))
          : ListView.builder(
              itemCount: product.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) {
                final item = product[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product ,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildDetail("Qty", item.quantity.toString()),
                            _buildDetail("Rate", "₹${item.rate.toStringAsFixed(2)}"),
                            _buildDetail("Amount", "₹${item.amount.toStringAsFixed(2)}"),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (item.uom != null)
                          _buildDetail("UOM", item.uom.toString()),
                        
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildDetail(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
