import 'dart:convert';
import 'package:calicut_textile_app/modal/get_supplier_orders.dart';
import 'package:http/http.dart' as http;


class SupplierOrderListService {
  final String baseUrl =
      'https://erp.calicuttextiles.com/api/method/calicut_textiles.api.auth.get_all_supplier_orders';

  Future<List<Order>> getSupplierOrders({
    required int page,
    required int pageSize,
  }) async {
    final url = Uri.parse('$baseUrl?page=$page&page_size=$pageSize');

    try {
      final response = await http.get(url);
      print(url);
      print(response.body);

      if (response.statusCode == 200) {
        
        final decoded = json.decode(response.body);
        final ordersList = GetSupplierOrderModal.fromJson(decoded);
        return ordersList.message.orders;
      } else {
        throw Exception('Failed to load supplier orders. Status Code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching supplier orders: $e');

      return [];
    }
  }
}
