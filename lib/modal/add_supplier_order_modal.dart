import 'dart:convert';
import 'package:intl/intl.dart';

SupplierOrderModal supplierOrderModalFromJson(String str) => SupplierOrderModal.fromJson(json.decode(str));

String supplierOrderModalToJson(SupplierOrderModal data) => json.encode(data.toJson());

class SupplierOrderModal {
    String? apiKey;
    String supplier;
    String orderDate;
    int grandTotal;
    List<Product> products;

    SupplierOrderModal({
         this.apiKey,
        required this.supplier,
        required this.orderDate,
        required this.grandTotal,
        required this.products,
    });

    factory SupplierOrderModal.fromJson(Map<String, dynamic> json) => SupplierOrderModal(
        apiKey: json["api_key"],
        supplier: json["supplier"],
        orderDate: json["order_date"],
        grandTotal: json["grand_total"],
        products: List<Product>.from(json["products"].map((x) => Product.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "api_key": apiKey,
        "supplier": supplier,
        "order_date": orderDate,
        "grand_total": grandTotal,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
    };
}

// Updated Product class in add_supplier_order_modal.dart
class Product {
  final String product;
  final int qty;
  final double? pcs;          // Add pcs field
  final double? netQty;    // Add netQty field
  final String? uom;
  final int rate;
  final int amount;
  final String? color;     // Add color field
  final DateTime? requiredDate;

  Product({
    required this.product,
    required this.qty,
    this.pcs,              // Optional pcs
    this.netQty,           // Optional netQty
    this.uom,
    required this.rate,
    required this.amount,
    this.color,            // Optional color
    this.requiredDate,
  });

  // Convert to JSON for API call
  Map<String, dynamic> toJson() {
    return {
      'product': product,
      'qty': qty,
      'pcs': pcs ?? 0,
      'net_qty': netQty ?? 0.0,
      'uom': uom ?? "Nos",
      'rate': rate,
      'amount': amount,
      'color': color,
      'required_date': requiredDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };
  }

  // Create from JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      product: json['product'] ?? '',
      qty: json['qty'] ?? 0,
      pcs: json['pcs'],
      netQty: json['net_qty']?.toDouble(),
      uom: json['uom'],
      rate: json['rate'] ?? 0,
      amount: json['amount'] ?? 0,
      color: json['color'],
      requiredDate: json['required_date'] != null 
          ? DateTime.tryParse(json['required_date']) 
          : null,
    );
  }
}