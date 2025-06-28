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
     double? pcs;           // Added pcs field
  double? netQty; 
    double amount;
    String uom;
  

    Datum({
        required this.name,
        required this.productName,
        required this.rate,
        required this.quantity,
        required this.pcs,           // Optional pcs
        required this.netQty, 
        required this.amount,
        required this.uom,
       
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        name: json["name"],
        productName: json["product_name"],
        rate: json["rate"],
        quantity: json["quantity"],
        pcs: json["pcs"],
        netQty: json["net_qty"],
        amount: json["amount"],
        uom: json["uom"],
     
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
