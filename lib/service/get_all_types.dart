import 'dart:convert';
import 'package:calicut_textile_app/modal/get_all_types_modal.dart';
import 'package:http/http.dart' as http;

class TextileTypesService {
  static const String baseUrl = 'https://erp.calicuttextiles.com';
  static const String endpoint = '/api/method/calicut_textiles.api.auth.get_all_types';

  // // Headers for authentication
  // static Map<String, String> get _headers => {
  //   'Cookie': 'full_name=najath; sid=04e59d3fd1527fa2a878ee2a4072d2e095cc46dfcfbec292e911ee3a; system_user=yes; user_id=najath%40gmail.com; user_image=',
  //   'Content-Type': 'application/json',
  // };

  /// Fetches all textile types from the API
  static Future<TextileTypesResponse> getAllTypes() async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(uri, );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return TextileTypesResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load textile types: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching textile types: $e');
    }
  }

  /// Alternative method using http.Request (as in your original code)
  static Future<TextileTypesResponse> getAllTypesWithRequest() async {
    try {
      var request = http.Request('GET', Uri.parse('$baseUrl$endpoint'));
      
      http.StreamedResponse response = await request.send();
      
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final jsonData = json.decode(responseBody);
        return TextileTypesResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load textile types: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching textile types: $e');
    }
  }
}

