import 'dart:convert';
import 'dart:developer';
import 'package:calicut_textile_app/modal/add_supplier_order_modal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class SupplierOrderService {
  static const String baseUrl = 'https://calicuttextiles.tbo365.cloud/api/method/calicut_textiles.api.auth.create_supplier_order';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  static Future<bool?> createSupplierOrder({
    required SupplierOrderModal supplierOrder,
    required BuildContext context,
  }) async {
    final uri = Uri.parse(baseUrl);
    
    // Get API key from secure storage
    final apiKey = await const FlutterSecureStorage().read(key: 'api_key');
    
    // Create products array with all required fields including pcs and net_qty
    final productsArray = supplierOrder.products.map((product) {
      return {
        'product': product.product,
        'qty': product.qty,
        'pcs': product.pcs ?? 0, // Include pcs field
        'net_qty': product.netQty ?? 0.0, // Include net_qty field
        'uom': product.uom ?? "Nos",
        'rate': product.rate,
        'amount': product.amount,
        'color': product.color, // Include color if available
        'required_date': product.requiredDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
      };
    }).toList();
    
    // Create request body with properly structured products
    final requestBody = {
      'api_key': apiKey,
      'supplier': supplierOrder.supplier,
      'order_date': supplierOrder.orderDate,
      'grand_total': supplierOrder.grandTotal,
      'products': productsArray, // Use the properly structured products array
    };
    
    // Debug: Print the actual request body being sent
    print('=== REQUEST BODY DEBUG ===');
    print('Full Request Body: ${jsonEncode(requestBody)}');
    print('Products Array:');
    for (int i = 0; i < productsArray.length; i++) {
      final productData = productsArray[i];
      print('--- Product ${i + 1} ---');
      print('Product Name: ${productData['product']}');
      print('Quantity: ${productData['qty']}');
      print('PCS: ${productData['pcs']}');
      print('Net Qty: ${productData['net_qty']}');
      print('UOM: ${productData['uom']}');
      print('Rate: ${productData['rate']}');
      print('Amount: ${productData['amount']}');
      print('Color: ${productData['color']}');
      print('Required Date: ${productData['required_date']}');
      print('---');
    }
    print('=== END REQUEST BODY DEBUG ===');
    
    try {
      final sid = await _storage.read(key: 'sid');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'sid=$sid', 
        },
        body: jsonEncode(requestBody),
      );
      
      final responseBody = response.body;
      print('Response Status Code: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(responseBody);
        
        // Handle nested message structure
        String successMessage = 'Supplier order created successfully!';
        if (result['message'] != null) {
          if (result['message'] is Map<String, dynamic>) {
            final messageData = result['message'] as Map<String, dynamic>;
            if (messageData['success'] == true) {
              successMessage = messageData['message'] ?? successMessage;
              
              // Print additional success info
              print('=== ORDER CREATED SUCCESSFULLY ===');
              print('Order ID: ${messageData['docname']}');
              print('Employee ID: ${messageData['employee_id']}');
              print('=== END SUCCESS INFO ===');
              
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
      print('Error creating supplier order: $e');
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