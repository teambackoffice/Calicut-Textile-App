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
    List<String>? imagePaths, // Optional list of image file paths
  }) async {
    try {
      // Get stored authentication data
      final sid = await _storage.read(key: 'sid');
      final fullName = await _storage.read(key: 'full_name');
  
      
      if (sid == null) {
        _showSnackbar(context, 'Authentication required. Please login again.', Colors.red);
        return null;
      }
      
      // Create headers with cookie information
      var headers = {
        'Cookie': 'full_name=${fullName ?? ''}; sid=$sid; '
      };
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse(baseUrl));
      
      // Create products array with all required fields
      final productsArray = supplierOrder.products.map((product) {
        return {
          'product': product.product,
          'qty': product.qty,
          'pcs': product.pcs ?? 0,
          'net_qty': product.netQty ?? 0.0,
          'uom': product.uom ?? "Nos",
          'rate': product.rate,
          'amount': product.amount,
          'color': product.color ?? '',
          'required_date': product.requiredDate?.toIso8601String() ?? DateTime.now().toIso8601String(),
        };
      }).toList();
      
      // Add form fields
      request.fields.addAll({
        'supplier': supplierOrder.supplier,
        'order_date': supplierOrder.orderDate,
        'grand_total': supplierOrder.grandTotal.toString(),
        'products': jsonEncode(productsArray),
      });
      
      // Add image files if provided
      if (imagePaths != null && imagePaths.isNotEmpty) {
        for (int i = 0; i < imagePaths.length; i++) {
          final imagePath = imagePaths[i];
          if (await File(imagePath).exists()) {
            try {
              request.files.add(await http.MultipartFile.fromPath(
                'image_${i + 1}_0', 
                imagePath
              ));
            } catch (e) {
            }
          } else {
          }
        }
      }
      
      // Add headers to request
      request.headers.addAll(headers);
      
      // Debug: Print request details
   
      request.fields.forEach((key, value) {
        if (key == 'products') {
          print('  $key: $value');
          // Pretty print products for better readability
          final products = jsonDecode(value);
          for (int i = 0; i < products.length; i++) {
          }
        } else {
        }
      });
      for (var file in request.files) {
        print('  ${file.field}: ${file.filename}');
      }
      
      // Send request
      http.StreamedResponse response = await request.send();
      
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        
        try {
          final result = jsonDecode(responseBody);
          
          // Handle nested message structure
          String successMessage = 'Supplier order created successfully!';
          if (result['message'] != null) {
            if (result['message'] is Map<String, dynamic>) {
              final messageData = result['message'] as Map<String, dynamic>;
              if (messageData['success'] == true) {
                successMessage = messageData['message'] ?? successMessage;
                
                // Print additional success info
              
                
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
          
        } catch (e) {
          _showSnackbar(context, 'Order created but response parsing failed', Colors.orange);
          return true;
        }
        
      } else if (response.statusCode == 400) {
        final responseBody = await response.stream.bytesToString();
        
        String errorMessage = 'Bad request error occurred';
        try {
          final result = jsonDecode(responseBody);
          if (result['message'] != null) {
            if (result['message'] is Map<String, dynamic>) {
              final messageData = result['message'] as Map<String, dynamic>;
              errorMessage = messageData['message'] ?? messageData['error'] ?? errorMessage;
            } else if (result['message'] is String) {
              errorMessage = result['message'];
            }
          }
        } catch (e) {
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
        final responseBody = await response.stream.bytesToString();
        print('500 Response Body: $responseBody');
        _showSnackbar(context, 'Server error occurred. Please try again later.', Colors.red);
        return null;
        
      } else {
        final responseBody = await response.stream.bytesToString();
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