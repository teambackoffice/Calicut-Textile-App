import 'dart:convert';
import 'package:calicut_textile_app/modal/supplier_list_modal.dart';
import 'package:http/http.dart' as http;

class SuppliersListService {
  final String baseUrl = 'https://calicuttextiles.tbo365.cloud/api/method/calicut_textiles.api.auth.get_all_supplier_details_with_searh';
  
  final Map<String, String> _defaultHeaders = {
    'Cookie': 'full_name=najath; sid=66486d16f52af5e792350c8927a98c361addf3166e3fea20c25d946f; system_user=yes; user_id=najath%40gmail.com; user_image=',
    'Content-Type': 'application/json',
  };

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
    print('API URL: $uri');

    try {
      final request = http.Request('GET', uri);
      request.headers.addAll(_defaultHeaders);
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        return SuppliersResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load suppliers. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Service Error: $e');
      throw Exception('Error fetching suppliers: $e');
    }
  }
}
