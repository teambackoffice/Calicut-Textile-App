import 'dart:convert';

import 'package:calicut_textile_app/modal/product_list_model.dart';
import 'package:http/http.dart' as http;

class ProductListService {
  final String baseUrl = 'https://calicuttextiles.tbo365.cloud/api/method/calicut_textiles.api.auth.get_all_products';

  Future<List<Datum>> getProducts() async {
    final url = Uri.parse(baseUrl);
    print(url);
  

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("response : ${response.body}");
        
      
        ProductListModal productListModal = productListModalFromJson(response.body);
        return productListModal.message.data;
      } else {
        throw Exception('Failed to load products. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching products: $e");
      
      throw Exception('Error fetching products: $e');
    }
  }
}
