import 'dart:convert';
import 'package:calicut_textile_app/modal/supplier_group_modal.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://calicuttextiles.tbo365.cloud';
  
  // User session data - in a real app, you'd get this from secure storage
  static const Map<String, String> _defaultHeaders = {
    'Cookie': 'full_name=najath; sid=e8ad304e26de3bb1dec429ae7e718978b1d749459adad2055fb58ef9; system_user=yes; user_id=najath%40gmail.com; user_image=',
    'Content-Type': 'application/json',
  };

  Future<ApiResponse<List<SupplierGroup>>> getSupplierGroups() async {
    try {
      final request = http.Request(
        'GET', 
        Uri.parse('$baseUrl/api/method/calicut_textiles.api.auth.get_supplier_groups')
      );
      
      request.headers.addAll(_defaultHeaders);
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        
        // Handle the specific API response structure
        List<dynamic> supplierGroupsJson = [];
        
        if (jsonData is Map<String, dynamic> && jsonData.containsKey('message')) {
          final message = jsonData['message'];
          if (message is Map<String, dynamic> && 
              message.containsKey('success') && 
              message['success'] == true &&
              message.containsKey('data')) {
            final data = message['data'];
            if (data is List<dynamic>) {
              supplierGroupsJson = data;
            }
          }
        }
        
        if (supplierGroupsJson.isEmpty) {
          return ApiResponse.error('No supplier groups found in response');
        }
        
        final supplierGroups = supplierGroupsJson
            .map((json) {
              try {
                if (json is Map<String, dynamic>) {
                  return SupplierGroup.fromJson(json);
                } else {
                  return null;
                }
              } catch (e) {
                print('Error parsing supplier group: $e');
                return null;
              }
            })
            .where((group) => group != null)
            .cast<SupplierGroup>()
            .toList();
            
        return ApiResponse.success(supplierGroups);
      } else {
        return ApiResponse.error('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Additional API methods can be added here
  Future<ApiResponse<SupplierGroup>> getSupplierGroupById(String id) async {
    try {
      final request = http.Request(
        'GET', 
        Uri.parse('$baseUrl/api/method/calicut_textiles.api.auth.get_supplier_group/$id')
      );
      
      request.headers.addAll(_defaultHeaders);
      
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonData = json.decode(responseBody);
        final supplierGroup = SupplierGroup.fromJson(jsonData);
        return ApiResponse.success(supplierGroup);
      } else {
        return ApiResponse.error('HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}
