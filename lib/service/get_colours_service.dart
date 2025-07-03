import 'dart:convert';
import 'package:calicut_textile_app/modal/get_colours_modal.dart';
import 'package:http/http.dart' as http;

class ColorsService {
  static const String baseUrl = 'https://calicuttextiles.tbo365.cloud';
  static const String endpoint = '/api/method/calicut_textiles.api.auth.get_all_colours';

  // Headers for authentication
  

  /// Fetches all colors from the API
  static Future<ColorsResponse> getAllColors() async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final response = await http.get(uri,);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return ColorsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load colors: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching colors: $e');
    }
  }

  /// Alternative method using http.Request (as in your original code)
  static Future<ColorsResponse> getAllColorsWithRequest() async {
    try {
      var request = http.Request('GET', Uri.parse('$baseUrl$endpoint'));
      
      http.StreamedResponse response = await request.send();
      
      if (response.statusCode == 200) {
        String responseBody = await response.stream.bytesToString();
        final jsonData = json.decode(responseBody);
        return ColorsResponse.fromJson(jsonData);
      } else {
        throw Exception('Failed to load colors: ${response.reasonPhrase}');
      }
    } catch (e) {
      throw Exception('Error fetching colors: $e');
    }
  }
}