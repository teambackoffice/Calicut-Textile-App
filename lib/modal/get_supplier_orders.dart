// To parse this JSON data, do
//
//     final getSupplierOrderModal = getSupplierOrderModalFromJson(jsonString);

import 'dart:convert';

GetSupplierOrderModal getSupplierOrderModalFromJson(String str) => GetSupplierOrderModal.fromJson(json.decode(str));

String getSupplierOrderModalToJson(GetSupplierOrderModal data) => json.encode(data.toJson());

class GetSupplierOrderModal {
    Message message;

    GetSupplierOrderModal({
        required this.message,
    });

    factory GetSupplierOrderModal.fromJson(Map<String, dynamic> json) => GetSupplierOrderModal(
        message: Message.fromJson(json["message"]),
    );

    Map<String, dynamic> toJson() => {
        "message": message.toJson(),
    };
}

class Message {
    List<Order> orders;
    int page;
    int pageSize;
    int totalOrders;
    int totalPages;

    Message({
        required this.orders,
        required this.page,
        required this.pageSize,
        required this.totalOrders,
        required this.totalPages,
    });

    factory Message.fromJson(Map<String, dynamic> json) => Message(
        orders: List<Order>.from(json["orders"].map((x) => Order.fromJson(x))),
        page: json["page"],
        pageSize: json["page_size"],
        totalOrders: json["total_orders"],
        totalPages: json["total_pages"],
    );

    Map<String, dynamic> toJson() => {
        "orders": List<dynamic>.from(orders.map((x) => x.toJson())),
        "page": page,
        "page_size": pageSize,
        "total_orders": totalOrders,
        "total_pages": totalPages,
    };
}

class Order {
  String orderId;
  String supplier;
  String supplierName;
  DateTime orderDate;
  double grandTotal;
  String status;
  List<Product> products;

  Order({
    required this.orderId,
    required this.supplier,
    required this.supplierName,
    required this.orderDate,
    required this.grandTotal,
    required this.status,
    required this.products,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json["order_id"],
        supplier: json["supplier_id"],
        supplierName: json["supplier_name"],
        orderDate: DateTime.parse(json["order_date"]),
        grandTotal: json["grand_total"],
        status: json["status"],
        products: List<Product>.from(
            json["products"].map((x) => Product.fromJson(x))),
      );

  Map<String, dynamic> toJson() => {
        "order_id": orderId,
        "supplier": supplier,
        "order_date":
            "${orderDate.year.toString().padLeft(4, '0')}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}",
        "grand_total": grandTotal,
        "status": status, // ✅ changed here
        "products": List<dynamic>.from(products.map((x) => x.toJson())),
      };
}


class Product {
    String product;
    double quantity;
    Uom? uom;
    double rate;
    double? pcs;
    double? netQty;
    double amount;
    DateTime requiredBy;

    Product({
        required this.product,
        required this.quantity,
        required this.uom,
        required this.rate,
        required this.pcs,
        required this.netQty,
        required this.amount,
        required this.requiredBy,
    });

    factory Product.fromJson(Map<String, dynamic> json) => Product(
        product: json["product"],
        quantity: json["quantity"],
        uom: uomValues.map[json["uom"]]!,
        rate: json["rate"],
        pcs: json["pcs"],
        netQty: json["net_qty"],
        amount: json["amount"],
        requiredBy: DateTime.parse(json["required_by"]),
    );

    Map<String, dynamic> toJson() => {
        "product": product,
        "quantity": quantity,
        "uom": uomValues.reverse[uom],
        "rate": rate,
        "pcs": pcs,
        "net_qty": netQty,
        "amount": amount,
        "required_by": "${requiredBy.year.toString().padLeft(4, '0')}-${requiredBy.month.toString().padLeft(2, '0')}-${requiredBy.day.toString().padLeft(2, '0')}",
    };
}

enum Uom {
  EMPTY,
  KG,
  NOS,
  UNIT,
  BOX,
  PAIR,
  SET,
  METER,
  BARLEYCORN,
  CALIBRE,
  CABLE_LENGTH_UK,
  CABLE_LENGTH_US,
  CABLE_LENGTH,
  CENTIMETER,
  CHAIN,
  DECIMETER,
  ELLS_UK,
  EMS_PICA,
  FATHOM,
  FOOT,
  FURLONG,
  HAND,
  HECTOMETER,
}


final uomValues = EnumValues({
  "": Uom.EMPTY,
  "Kg": Uom.KG,
  "Nos": Uom.NOS,
  "Unit": Uom.UNIT,
  "Box": Uom.BOX,
  "Pair": Uom.PAIR,
  "Set": Uom.SET,
  "Meter": Uom.METER,
  "Barleycorn": Uom.BARLEYCORN,
  "Calibre": Uom.CALIBRE,
  "Cable Length (UK)": Uom.CABLE_LENGTH_UK,
  "Cable Length (US)": Uom.CABLE_LENGTH_US,
  "Cable Length": Uom.CABLE_LENGTH,
  "Centimeter": Uom.CENTIMETER,
  "Chain": Uom.CHAIN,
  "Decimeter": Uom.DECIMETER,
  "Ells (UK)": Uom.ELLS_UK,
  "Ems (Pica)": Uom.EMS_PICA,
  "Fathom": Uom.FATHOM,
  "Foot": Uom.FOOT,
  "Furlong": Uom.FURLONG,
  "Hand": Uom.HAND,
  "Hectometer": Uom.HECTOMETER,
});






class EnumValues<T> {
    Map<String, T> map;
    late Map<T, String> reverseMap;

    EnumValues(this.map);

    Map<T, String> get reverse {
            reverseMap = map.map((k, v) => MapEntry(v, k));
            return reverseMap;
    }
}
