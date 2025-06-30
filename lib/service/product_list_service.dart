import 'dart:convert';

import 'package:calicut_textile_app/modal/product_list_model.dart';
import 'package:http/http.dart' as http;

class ProductListService {
  final String baseUrl = 'https://erp.calicuttextiles.com/api/method/calicut_textiles.api.auth.get_all_products';

  Future<List<Datum>> getProducts() async {
    final url = Uri.parse(baseUrl);
  

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        
      
        ProductListModal productListModal = productListModalFromJson(response.body);
        return productListModal.message.data;
      } else {
        throw Exception('Failed to load products. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      
      throw Exception('Error fetching products: $e');
    }
  }
}
