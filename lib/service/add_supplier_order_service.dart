import 'dart:convert';
import 'dart:developer';
import 'package:calicut_textile_app/modal/add_supplier_order_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SupplierOrderService {
  static const String baseUrl = 'https://calicuttextiles.tbo365.cloud/api/method/calicut_textiles.api.auth.create_supplier_order';
  
  static Future<bool?> createSupplierOrder({
    required SupplierOrderModal supplierOrder,
    required BuildContext context,
  }) async {
    final uri = Uri.parse(baseUrl);
    
    // Get API key from secure storage
    final apiKey = await const FlutterSecureStorage().read(key: 'api_key');
    
    // Create request body
    final requestBody = {
      'api_key': apiKey,
      'supplier': supplierOrder.supplier,
      'order_date': supplierOrder.orderDate,
      'grand_total': supplierOrder.grandTotal,
      'products': supplierOrder.products
    };
    
    for (int i = 0; i < supplierOrder.products.length; i++) {
      final product = supplierOrder.products[i];
    }
    
    
    
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // Try different API key formats
          'Authorization': apiKey ?? '',
          'X-Frappe-API-Key': apiKey ?? '',
          'Token': apiKey ?? '',
        },
        body: jsonEncode(requestBody),
      );
      
      final responseBody = response.body;
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(responseBody);
        
        // Fix: Handle nested message structure
        String successMessage = 'Supplier order created successfully!';
        if (result['message'] != null) {
          if (result['message'] is Map<String, dynamic>) {
            final messageData = result['message'] as Map<String, dynamic>;
            if (messageData['success'] == true) {
              successMessage = messageData['message'] ?? successMessage;
            } else {
              // Handle error case even with 200 status
              final errorMessage = messageData['message'] ?? messageData['error'] ?? 'Unknown error occurred';
              _showSnackbar(context, errorMessage, Colors.red);
              return false;
            }
          } else if (result['message'] is String) {
            successMessage = result['message'];
          }
        }
        
        _showSnackbar(context, successMessage, Colors.green);
        return true;
      } else if (response.statusCode == 400) {
        final result = jsonDecode(responseBody);
        String errorMessage = 'Bad request error occurred';
        
        if (result['message'] != null) {
          if (result['message'] is Map<String, dynamic>) {
            final messageData = result['message'] as Map<String, dynamic>;
            errorMessage = messageData['message'] ?? messageData['error'] ?? errorMessage;
          } else if (result['message'] is String) {
            errorMessage = result['message'];
          }
        }
        
        _showSnackbar(context, errorMessage, Colors.red);
        return null;
      } else if (response.statusCode == 401) {
        _showSnackbar(context, 'Authentication failed. Please login again.', Colors.red);
        return null;
      } else if (response.statusCode == 403) {
        _showSnackbar(context, 'Access forbidden. Check your permissions.', Colors.red);
        return null;
      } else if (response.statusCode == 500) {
        _showSnackbar(context, 'Server error occurred. Please try again later.', Colors.red);
        return null;
      } else {
        final String errorMessage = response.reasonPhrase ?? 'Unknown error occurred';
        _showSnackbar(context, errorMessage, Colors.red);
        return null;
      }
    } catch (e) {
     
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