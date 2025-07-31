import 'dart:convert';

import 'package:calicut_textile_app/view/main_screen/purchase_order/adding_new_PO/create_purchase_order.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PurchaseOrderStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _itemsKey = 'purchase_order_items';
  static const String _supplierKey = 'selected_supplier';
  static const String _dateKey = 'required_date';

  static Future<void> saveItems(List<PurchaseOrderItem> items) async {
    final itemsJson = items
        .map(
          (item) => {
            'itemCode': item.itemCode,
            'itemName': item.itemName,
            'quantity': item.quantity,
            'pcs': item.pcs,
            'netQty': item.netQty,
            'rate': item.rate,
            'color': item.color,
            'type': item.type,
            'design': item.design,
            'uom': item.uom,
            'imageCount': item.imageCount,
            'imagePaths': item.imagePaths,
            'amount': item.amount,
          },
        )
        .toList();

    await _storage.write(key: _itemsKey, value: json.encode(itemsJson));
  }

  static Future<List<PurchaseOrderItem>> loadItems() async {
    final itemsString = await _storage.read(key: _itemsKey);
    if (itemsString == null) return [];

    final itemsJson = json.decode(itemsString) as List;
    return itemsJson
        .map(
          (item) => PurchaseOrderItem(
            itemCode: item['itemCode'],
            itemName: item['itemName'],
            quantity: item['quantity'],
            pcs: item['pcs'],
            netQty: item['netQty'],
            rate: item['rate'],
            color: item['color'],
            type: item['type'],
            design: item['design'],
            uom: item['uom'],
            imageCount: item['imageCount'],
            imagePaths: List<String>.from(item['imagePaths']),
            amount: item['amount'],
          ),
        )
        .toList();
  }

  static Future<void> saveSupplier(
    String? supplierId,
    String? supplierName,
  ) async {
    if (supplierId != null && supplierName != null) {
      await _storage.write(
        key: _supplierKey,
        value: json.encode({'id': supplierId, 'name': supplierName}),
      );
    }
  }

  static Future<Map<String, String>?> loadSupplier() async {
    final supplierString = await _storage.read(key: _supplierKey);
    if (supplierString == null) return null;

    final supplierJson = json.decode(supplierString);
    return {'id': supplierJson['id'], 'name': supplierJson['name']};
  }

  static Future<void> saveRequiredDate(String date) async {
    await _storage.write(key: _dateKey, value: date);
  }

  static Future<String?> loadRequiredDate() async {
    return await _storage.read(key: _dateKey);
  }

  static Future<void> clearAll() async {
    await _storage.delete(key: _itemsKey);
    await _storage.delete(key: _supplierKey);
    await _storage.delete(key: _dateKey);
  }
}
