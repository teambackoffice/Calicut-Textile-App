// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LoginService {
  final String baseUrl = 'http://127.0.0.1:8000/api/method/calicut_textiles.auth.user_login';

  Future<bool> login(String username, String password) async {
    final url = Uri.parse('$baseUrl?usr=$username&pwd=$password');
    print(url);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        print("Response = $username & $password && $response");
        final responseData = jsonDecode(response.body);
        // Assuming your API returns { "message": "Logged in Successfully" }
        // You can customize this condition based on your API response structure
        return responseData['message'] == 'Logged in Successfully';
      } else {
        return false;
      }
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }
}
