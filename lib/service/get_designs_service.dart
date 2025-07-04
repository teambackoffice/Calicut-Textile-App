import 'dart:convert';
import 'package:calicut_textile_app/modal/get_designs.dart';
import 'package:http/http.dart' as http;

class DesignsService {
  static const String baseUrl = 'https://erp.calicuttextiles.com';
  static const String endpoint = '/api/method/calicut_textiles.api.auth.get_all_designs';

  // Headers for authentication
  

  /// Fetches all designs from the API
  static Future<DesignsResponse> getAllDesigns() async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(uri,);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return DesignsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load designs: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching designs: $e');
    }
  }

  /// Alternative method using http.Request (as in your original code)
  static Future<DesignsResponse> getAllDesignsWithRequest() async {
    try {
      var request = http.Request('GET', Uri.parse('$baseUrl$endpoint'));
      
      http.StreamedResponse response = await request.send();
      
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final jsonData = json.decode(responseBody);
        return DesignsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load designs: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching designs: $e');
    }
  }
}
