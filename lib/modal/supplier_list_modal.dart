// To parse this JSON data, do
//
//     final suppliersList = suppliersListFromJson(jsonString);

import 'dart:convert';

SuppliersList suppliersListFromJson(String str) => SuppliersList.fromJson(json.decode(str));

String suppliersListToJson(SuppliersList data) => json.encode(data.toJson());

class SuppliersList {
    Message message;

    SuppliersList({
        required this.message,
    });

    factory SuppliersList.fromJson(Map<String, dynamic> json) => SuppliersList(
        message: Message.fromJson(json["message"]),
    );

    Map<String, dynamic> toJson() => {
        "message": message.toJson(),
    };
}

class Message {
    List<Supplier> suppliers;
    int page;
    int pageSize;
    int totalSuppliers;
    int totalPages;

    Message({
        required this.suppliers,
        required this.page,
        required this.pageSize,
        required this.totalSuppliers,
        required this.totalPages,
    });

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        suppliers: List<Supplier>.from(json["suppliers"].map((x) => Supplier.fromJson(x))),
        page: json["page"],
        pageSize: json["page_size"],
        totalSuppliers: json["total_suppliers"],
        totalPages: json["total_pages"],
    );

    Map<String, dynamic> toJson() => {
        "suppliers": List<dynamic>.from(suppliers.map((x) => x.toJson())),
        "page": page,
        "page_size": pageSize,
        "total_suppliers": totalSuppliers,
        "total_pages": totalPages,
    };
}

class Supplier {
    String supplierId;
    String supplierName;
    dynamic address;

    Supplier({
        required this.supplierId,
        required this.supplierName,
        required this.address,
    });

    factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
        supplierId: json["supplier_id"],
        supplierName: json["supplier_name"],
        address: json["address"],
    );

    Map<String, dynamic> toJson() => {
        "supplier_id": supplierId,
        "supplier_name": supplierName,
        "address": address,
    };
}
