// To parse this JSON data, do
//
//     final productListModal = productListModalFromJson(jsonString);

import 'dart:convert';

ProductListModal productListModalFromJson(String str) => ProductListModal.fromJson(json.decode(str));

String productListModalToJson(ProductListModal data) => json.encode(data.toJson());

class ProductListModal {
    Message message;

    ProductListModal({
        required this.message,
    });

    factory ProductListModal.fromJson(Map<String, dynamic> json) => ProductListModal(
        message: Message.fromJson(json["message"]),
    );

    Map<String, dynamic> toJson() => {
        "message": message.toJson(),
    };
}

class Message {
    bool success;
    String message;
    List<Datum> data;

    Message({
        required this.success,
        required this.message,
        required this.data,
    });

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        success: json["success"],
        message: json["message"],
        data: List<Datum>.from(json["data"].map((x) => Datum.fromJson(x))),
    );

    Map<String, dynamic> toJson() => {
        "success": success,
        "message": message,
        "data": List<dynamic>.from(data.map((x) => x.toJson())),
    };
}

class Datum {
  String name;
  String productName;
  double rate;
  double quantity;
  double? pcs;      // Optional
  double? netQty;   // Optional
  double amount;
  String? uom;      // Optional

  Datum({
    required this.name,
    required this.productName,
    required this.rate,
    required this.quantity,
    this.pcs,
    this.netQty,
    required this.amount,
    this.uom,
  });

  factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        name: json["name"] ?? '',
        productName: json["product_name"] ?? '',
        rate: (json["rate"] ?? 0).toDouble(),
        quantity: (json["quantity"] ?? 0).toDouble(),
        pcs: json["pcs"] != null ? (json["pcs"] as num).toDouble() : null,
        netQty: json["net_qty"] != null ? (json["net_qty"] as num).toDouble() : null,
        amount: (json["amount"] ?? 0).toDouble(),
        uom: json["uom"], // already nullable
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "product_name": productName,
        "rate": rate,
        "quantity": quantity,
        "pcs": pcs,
        "net_qty": netQty,
        "amount": amount,
        "uom": uom,
      };
}


