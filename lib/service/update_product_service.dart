import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class UpdateProductService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final String url =
      'https://erp.calicuttextiles.com/api/method/calicut_textiles.api.auth.update_product';

  Future<Map<String, dynamic>> updateProduct({
    required String productName,
    required String newProductName,
    required String uom,
  }) async {
    // Get sid from secure storage
    final sid = await _secureStorage.read(key: 'sid');
    if (sid == null) {
      throw Exception("Session ID (sid) not found. Please login again.");
    }

    final headers = {'Content-Type': 'application/json', 'Cookie': 'sid=$sid'};

    final body = json.encode({
      "product_name": productName,
      "new_product_name": newProductName,
      "uom": uom,
    });

    final request = http.Request('POST', Uri.parse(url))
      ..headers.addAll(headers)
      ..body = body;

    final response = await request.send();

    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(responseBody);
    } else {
      throw Exception("Failed to update product: ${response.reasonPhrase}");
    }
  }
}
