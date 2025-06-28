import 'dart:convert';
import 'package:intl/intl.dart';

SupplierOrderModal supplierOrderModalFromJson(String str) => SupplierOrderModal.fromJson(json.decode(str));

String supplierOrderModalToJson(SupplierOrderModal data) => json.encode(data.toJson());

class SupplierOrderModal {
    String? apiKey;
    String supplier;
    String orderDate;
    double grandTotal; // Changed from int to double for better precision
    List<Product> products;
    List<String>? imagePaths; // Added for image uploads

    SupplierOrderModal({
        this.apiKey,
        required this.supplier,
        required this.orderDate,
        required this.grandTotal,
        required this.products,
        this.imagePaths, // Optional image paths
    });

    factory SupplierOrderModal.fromJson(Map<String, dynamic> json) => SupplierOrderModal(
        apiKey: json["api_key"],
        supplier: json["supplier"],
        orderDate: json["order_date"],
        grandTotal: (json["grand_total"] ?? 0).toDouble(),
        products: List<Product>.from(json["products"].map((x) => Product.fromJson(x))),
        imagePaths: json["image_paths"] != null 
            ? List<String>.from(json["image_paths"]) 
            : null,
    );

    Map<String, dynamic> toJson() => {
        "api_key": apiKey,
        "supplier": supplier,
        "order_date": orderDate,
        "grand_total": grandTotal,
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
        "image_paths": imagePaths,
    };

    // Helper method to calculate total from products
    double calculateGrandTotal() {
        return products.fold(0.0, (sum, product) => sum + product.amount);
    }

    // Helper method to add image path
    void addImagePath(String imagePath) {
        imagePaths ??= [];
        imagePaths!.add(imagePath);
    }

    // Helper method to remove image path
    void removeImagePath(String imagePath) {
        imagePaths?.remove(imagePath);
    }

    // Helper method to clear all image paths
    void clearImagePaths() {
        imagePaths?.clear();
    }
}

// Updated Product class
class Product {
    final String product;
    final int qty;
    final double? pcs;
    final double? netQty;
    final String? uom;
    final double rate; // Changed from int to double
    final double amount; // Changed from int to double
    final String? color;
    final DateTime? requiredDate;

    Product({
        required this.product,
        required this.qty,
        this.pcs,
        this.netQty,
        this.uom,
        required this.rate,
        required this.amount,
        this.color,
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
            'color': color ?? '',
            'required_date': requiredDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };
    }

    // Create from JSON
    factory Product.fromJson(Map<String, dynamic> json) {
        return Product(
            product: json['product'] ?? '',
            qty: (json['qty'] ?? 0).toInt(),
            pcs: json['pcs']?.toDouble(),
            netQty: json['net_qty']?.toDouble(),
            uom: json['uom'],
            rate: (json['rate'] ?? 0).toDouble(),
            amount: (json['amount'] ?? 0).toDouble(),
            color: json['color'],
            requiredDate: json['required_date'] != null 
                ? DateTime.tryParse(json['required_date']) 
                : null,
        );
    }

    // Helper method to calculate amount based on qty and rate
    static double calculateAmount(int qty, double rate) {
        return qty * rate;
    }

    // Create a copy of the product with updated values
    Product copyWith({
        String? product,
        int? qty,
        double? pcs,
        double? netQty,
        String? uom,
        double? rate,
        double? amount,
        String? color,
        DateTime? requiredDate,
    }) {
        return Product(
            product: product ?? this.product,
            qty: qty ?? this.qty,
            pcs: pcs ?? this.pcs,
            netQty: netQty ?? this.netQty,
            uom: uom ?? this.uom,
            rate: rate ?? this.rate,
            amount: amount ?? this.amount,
            color: color ?? this.color,
            requiredDate: requiredDate ?? this.requiredDate,
        );
    }
}