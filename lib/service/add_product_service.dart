import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:calicut_textile_app/modal/add_product_modal.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ProductService {
  static const String baseUrl = 'https://calicuttextiles.tbo365.cloud/api/method/calicut_textiles.api.auth.create_product';
  

  

  static Future<bool?> createProduct({
    required Product product,
    required BuildContext context,
  }) async {
    final uri = Uri.parse(baseUrl);
    print(uri);
     // Get API key from secure storage
    final apiKey = await const FlutterSecureStorage().read(key: 'api_key');
    
   
   
    
    final jsonmodel = jsonEncode(product.toMap());
    
    
    try {
      var request = http.MultipartRequest('POST', uri)
      
        ..fields['product_name'] = product.productName
        ..fields['qty'] = product.qty
        ..fields['rate'] = product.rate
        ..fields['amount'] = product.amount
        ..fields['color'] = product.color!
        ..fields['uom'] = product.uom
        ..fields['api_key'] = product.api_key!;

      // Add image files
      for (int i = 0; i < product.imagePaths!.length; i++) {
        if (product.imagePaths![i].isNotEmpty) {
          request.files.add(
            await http.MultipartFile.fromPath(
              'image_${i + 1}',
              product.imagePaths![i],
            ),
          );
        }
      }
      print('Request Fields:');
request.fields.forEach((key, value) {
 
});

print('Attached Files:');
for (var file in request.files) {

}

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
     

      if (response.statusCode == 200 || response.statusCode == 201) {
        log("response.body : $response.body");
        
        _showSnackbar(context, 'Product created successfully!', Colors.green);
        return true;
      } else if (response.statusCode == 400) {
        final result = jsonDecode(responseBody);
        final String errorMessage = result['message'] ?? 'Bad request error occurred';
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
      print('Error creating product: $e');
      
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