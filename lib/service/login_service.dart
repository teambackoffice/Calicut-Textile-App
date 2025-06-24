// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginService {
  final String baseUrl = 'https://calicuttextiles.tbo365.cloud/api/method/calicut_textiles.api.auth.user_login';

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl?usr=$username&pwd=$password');
  

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
       
        final responseData = jsonDecode(response.body);
        // Assuming your API returns { "message": "Logged in Successfully" }
        // You can customize this condition based on your API response structure
        return responseData['message']['success_key'] == 1;

      } else {
        return false;
      }
    } catch (e) {
     
      return false;
    }
  }
}
