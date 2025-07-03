import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:calicut_textile_app/modal/add_supplier_order_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SupplierOrderService {
  static const String baseUrl = 'https://erp.calicuttextiles.com/api/method/calicut_textiles.api.auth.create_supplier_order';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<bool?> createSupplierOrder({
    required SupplierOrderModal supplierOrder,
    required BuildContext context,
    List<String>? imagePaths,
  }) async {
    try {
      // Get stored authentication data
      final sid = await _storage.read(key: 'sid');
      final fullName = await _storage.read(key: 'full_name');

      if (sid == null) {
        _showSnackbar(context, 'Authentication required. Please login again.', Colors.red);
        return null;
      }

      // Headers
      var headers = {
        'Cookie': 'full_name=${fullName ?? ''}; sid=$sid; '
      };

      // Multipart request
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));

      // Prepare products array
      final productsArray = supplierOrder.products.map((product) {
        return {
          'product': product.product,
          'qty': product.qty,
          'pcs': product.pcs ?? 0,
          'net_qty': product.netQty ?? 0.0,
          'uom': product.uom ?? "Nos",
          'rate': product.rate,
          'type': product.type,
          'design': product.design,
          'amount': product.amount,
          'color': product.color ?? '',
          'required_date': product.requiredDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };
      }).toList();

      // Form fields
      request.fields.addAll({
        'supplier': supplierOrder.supplier,
        'order_date': supplierOrder.orderDate,
        'grand_total': supplierOrder.grandTotal.toString(),
        'products': jsonEncode(productsArray),
      });

      // Debug: Print request fields
      print("---- Supplier Order Request ----");
      print("Headers: $headers");
      print("Fields:");
      request.fields.forEach((key, value) {
        print("  $key: $value");
      });

      // Attach files
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          final imagePath = imagePaths[i];
          if (await File(imagePath).exists()) {
            try {
              request.files.add(await http.MultipartFile.fromPath(
                'image_${i + 1}_0',
                imagePath,
              ));
              print("Added file: image_${i + 1}_0 => $imagePath");
            } catch (e) {
              print("Error adding file $imagePath: $e");
            }
          } else {
            print("File not found: $imagePath");
          }
        }
      }

      // Headers
      request.headers.addAll(headers);

      // Send request
      print("Sending request to $baseUrl...");
      http.StreamedResponse response = await request.send();
      print("Response Status: ${response.statusCode}");

      final responseBody = await response.stream.bytesToString();
      print("Response Body: $responseBody");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final result = jsonDecode(responseBody);
          print("Decoded Result: $result");

          String successMessage = 'Supplier order created successfully!';
          if (result['message'] != null) {
            if (result['message'] is Map<String, dynamic>) {
              final messageData = result['message'] as Map<String, dynamic>;
              print("Message Data: $messageData");

              if (messageData['success'] == true) {
                successMessage = messageData['message'] ?? successMessage;
              } else {
                final errorMessage = messageData['message'] ?? messageData['error'] ?? 'Unknown error occurred';
                _showSnackbar(context, errorMessage, Colors.red);
                return false;
              }
            } else if (result['message'] is String) {
              successMessage = result['message'];
            }
          }

          print("Final Success Message: $successMessage");
          _showSnackbar(context, successMessage, Colors.green);
          return true;

        } catch (e) {
          print("JSON Decode Error: $e");
          _showSnackbar(context, 'Order created but response parsing failed', Colors.orange);
          return true;
        }
      } else if (response.statusCode == 400) {
        print("Bad Request (400)");
        String errorMessage = 'Bad request error occurred';
        try {
          final result = jsonDecode(responseBody);
          print("Decoded Error Response: $result");
          if (result['message'] != null) {
            if (result['message'] is Map<String, dynamic>) {
              final messageData = result['message'] as Map<String, dynamic>;
              errorMessage = messageData['message'] ?? messageData['error'] ?? errorMessage;
            } else if (result['message'] is String) {
              errorMessage = result['message'];
            }
          }
        } catch (e) {
          print("Error parsing 400 response: $e");
        }
        _showSnackbar(context, errorMessage, Colors.red);
        return null;

      } else if (response.statusCode == 401) {
        print("Unauthorized (401)");
        _showSnackbar(context, 'Authentication failed. Please login again.', Colors.red);
        return null;

      } else if (response.statusCode == 403) {
        print("Forbidden (403)");
        _showSnackbar(context, 'Access forbidden. Check your permissions.', Colors.red);
        return null;

      } else if (response.statusCode == 500) {
        print("Internal Server Error (500): $responseBody");
        _showSnackbar(context, 'Server error occurred. Please try again later.', Colors.red);
        return null;

      } else {
        print("Unexpected Status: ${response.statusCode} => $responseBody");
        final String errorMessage = response.reasonPhrase ?? 'Unknown error occurred';
        _showSnackbar(context, errorMessage, Colors.red);
        return null;
      }

    } catch (e) {
      print("Network Exception: $e");
      _showSnackbar(context, 'Network error: ${e.toString()}', Colors.red);
      return null;
    }
  }

  static void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
