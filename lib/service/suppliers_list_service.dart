import 'dart:convert';
import 'package:calicut_textile_app/modal/supplier_list._modaldart';
import 'package:http/http.dart' as http;

class SuppliersListService {
  final String baseUrl = 
  'https://calicuttextiles.tbo365.cloud/api/method/calicut_textiles.api.auth.get_all_supplier_details';
  Future<List<Supplier>> getSuppliers({required int page, required int pageSize}) async {
    final url = Uri.parse('$baseUrl?page=$page&page_size=$pageSize');

    
    try {
      final response = await http.get(url);
     

      if (response.statusCode == 200) {
       
        SuppliersList suppliersList = SuppliersList.fromJson(json.decode(response.body));
        return suppliersList.message.suppliers;
      } else {
        throw Exception('Failed to load suppliers. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      
      throw Exception('Error fetching suppliers: $e');
    }
  }
}
