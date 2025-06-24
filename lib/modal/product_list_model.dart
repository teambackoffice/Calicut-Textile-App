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
    double amount;
    String color;
    String uom;
    dynamic image1;
    dynamic image2;
    dynamic image3;

    Datum({
        required this.name,
        required this.productName,
        required this.rate,
        required this.quantity,
        required this.amount,
        required this.color,
        required this.uom,
        required this.image1,
        required this.image2,
        required this.image3,
    });

    factory Datum.fromJson(Map<String, dynamic> json) => Datum(
        name: json["name"],
        productName: json["product_name"],
        rate: json["rate"],
        quantity: json["quantity"],
        amount: json["amount"],
        color: json["color"],
        uom: json["uom"],
        image1: json["image_1"],
        image2: json["image_2"],
        image3: json["image_3"],
    );

    Map<String, dynamic> toJson() => {
        "name": name,
        "product_name": productName,
        "rate": rate,
        "quantity": quantity,
        "amount": amount,
        "color": color,
        "uom": uom,
        "image_1": image1,
        "image_2": image2,
        "image_3": image3,
    };
}
