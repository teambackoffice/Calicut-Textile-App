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

class Product {
    String product;
    int qty;
    String uom;
    int rate;
    int amount;
    DateTime requiredDate;

    Product({
        required this.product,
        required this.qty,
        required this.uom,
        required this.rate,
        required this.amount,
        required this.requiredDate,
    });

    factory Product.fromJson(Map<String, dynamic> json) => Product(
        product: json["product"],
        qty: json["qty"],
        uom: json["uom"],
        rate: json["rate"],
        amount: json["amount"],
        requiredDate: DateTime.parse(json["required_date"]),
    );

    Map<String, dynamic> toJson() {
        // Debug print to check the date values
        
        // Use DateFormat for more reliable date formatting
        final dateFormatter = DateFormat('yyyy-MM-dd');
        final formattedDate = dateFormatter.format(requiredDate);
        
        
        return {
            "product": product,
            "qty": qty,
            "uom": uom,
            "rate": rate,
            "amount": amount,
            "required_date": formattedDate,
        };
    }
}