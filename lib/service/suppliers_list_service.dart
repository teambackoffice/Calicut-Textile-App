import 'dart:convert';
import 'package:calicut_textile_app/modal/supplier_list_modal.dart';
import 'package:http/http.dart' as http;

class SuppliersListService {
  final String baseUrl = 'https://erp.calicuttextiles.com/api/method/calicut_textiles.api.auth.get_all_supplier_details_with_searh';
  
  

  Future<SuppliersResponse> getSuppliers({
    required int page,
    required int pageSize,
    String? supplierName,
    String? supplierGroup,
    String? supplierId,
  }) async {
    // Build query parameters
    Map<String, String> queryParams = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
    };

    // Add optional search parameters
    if (supplierName != null && supplierName.isNotEmpty) {
      queryParams['supplier_name'] = supplierName;
    }
    if (supplierGroup != null && supplierGroup.isNotEmpty) {
      queryParams['supplier_group'] = supplierGroup;
    }
    if (supplierId != null && supplierId.isNotEmpty) {
      queryParams['supplier_id'] = supplierId;
    }

    final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

    try {
      final request = http.Request('GET', uri);
   
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();



      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        return SuppliersResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load suppliers. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching suppliers: $e');
    }
  }
}
