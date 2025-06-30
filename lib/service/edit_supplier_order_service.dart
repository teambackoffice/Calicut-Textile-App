import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:calicut_textile_app/modal/get_supplier_orders.dart' as OrderModel;

class UpdateSupplierOrderService {
  static const String baseUrl = 'https://erp.calicuttextiles.com/api/method/calicut_textiles.api.auth.update_supplier_order';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static Future<bool?> updateSupplierOrder({
    required OrderModel.Order order,
    required BuildContext context,
  }) async {
    final uri = Uri.parse(baseUrl);
    
    try {
      // Get cookies from secure storage (you might need to adjust this based on your storage)
      // final fullName = await _storage.read(key: 'full_name');
      final sid = await _storage.read(key: 'sid') ;
      // final userId = await _storage.read(key: 'user_id') ?? 'najath%40gmail.com';
      // final userImage = await _storage.read(key: 'user_image') ?? '';

      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Cookie':  'sid=$sid', 
      };

      // Prepare request body
      final requestBody = {
        "so_name": order.orderId,
        "supplier": order.supplier, // This should be the supplier ID, not name
        "order_date": "${order.orderDate.year.toString().padLeft(4, '0')}-${order.orderDate.month.toString().padLeft(2, '0')}-${order.orderDate.day.toString().padLeft(2, '0')}",
        "grand_total": order.grandTotal,
        "products": order.products.map((product) => {
          "product": product.product,
          "qty": product.quantity,
          "uom": _getUomString(product.uom!),
          "rate": product.rate,
          "amount": product.amount,
          "required_date": "${product.requiredBy.year.toString().padLeft(4, '0')}-${product.requiredBy.month.toString().padLeft(2, '0')}-${product.requiredBy.day.toString().padLeft(2, '0')}",
          "pcs": product.pcs,
          "net_qty": product.netQty, // Net qty can now be manually edited
        }).toList(),
      };

      

      // Create and send request
      var request = http.Request('POST', uri);
      request.body = json.encode(requestBody);
      request.headers.addAll(headers);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      log(responseBody);
      
      
     

      if (response.statusCode == 200 || response.statusCode == 201) {
        final result = jsonDecode(responseBody);
        
        // Check if the response indicates success
        if (result['message'] != null) {
          _showSnackbar(context, 'Supplier order updated successfully!', Colors.green);
          return true;
        } else {
          _showSnackbar(context, 'Update completed but response format unexpected', Colors.orange);
          return true;
        }
      } else if (response.statusCode == 400) {
        final result = jsonDecode(responseBody);
        final String errorMessage = result['message'] ?? 'Bad request error occurred';
        _showSnackbar(context, errorMessage, Colors.red);
        return null;
      } else if (response.statusCode == 401) {
        _showSnackbar(context, 'Authentication failed. Please login again.', Colors.red);
        return null;
      } else if (response.statusCode == 403) {
        _showSnackbar(context, 'Access forbidden. Check your permissions.', Colors.red);
        return null;
      } else if (response.statusCode == 404) {
        _showSnackbar(context, 'Supplier order not found.', Colors.red);
        return null;
      } else if (response.statusCode == 500) {
        _showSnackbar(context, 'Server error occurred. Please try again later.', Colors.red);
        return null;
      } else {
        final String errorMessage = response.reasonPhrase ?? 'Unknown error occurred';
        _showSnackbar(context, errorMessage, Colors.red);
        return null;
      }
    } catch (e) {
      print("Error: $e ");
      _showSnackbar(context, 'Network error: ${e.toString()}', Colors.red);
      return null;
    }
  }

 static String _getUomString(OrderModel.Uom uom) {
  switch (uom) {
    case OrderModel.Uom.KG:
      return 'Kg';
    case OrderModel.Uom.NOS:
      return 'Nos';
    case OrderModel.Uom.UNIT:
      return 'Unit';
    case OrderModel.Uom.BOX:
      return 'Box';
    case OrderModel.Uom.PAIR:
      return 'Pair';
    case OrderModel.Uom.SET:
      return 'Set';
    case OrderModel.Uom.METER:
      return 'Meter';
    case OrderModel.Uom.BARLEYCORN:
      return 'Barleycorn';
    case OrderModel.Uom.CALIBRE:
      return 'Calibre';
    case OrderModel.Uom.CABLE_LENGTH_UK:
      return 'Cable Length (UK)';
    case OrderModel.Uom.CABLE_LENGTH_US:
      return 'Cable Length (US)';
    case OrderModel.Uom.CABLE_LENGTH:
      return 'Cable Length';
    case OrderModel.Uom.CENTIMETER:
      return 'Centimeter';
    case OrderModel.Uom.CHAIN:
      return 'Chain';
    case OrderModel.Uom.DECIMETER:
      return 'Decimeter';
    case OrderModel.Uom.ELLS_UK:
      return 'Ells (UK)';
    case OrderModel.Uom.EMS_PICA:
      return 'Ems(Pica)';
    case OrderModel.Uom.FATHOM:
      return 'Fathom';
    case OrderModel.Uom.FOOT:
      return 'Foot';
    case OrderModel.Uom.FURLONG:
      return 'Furlong';
    case OrderModel.Uom.HAND:
      return 'Hand';
    case OrderModel.Uom.HECTOMETER:
      return 'Hectometer';
    case OrderModel.Uom.EMPTY:
    default:
      return '';
  }
}

  static void _showSnackbar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// Alternative service class for use with controller pattern
class UpdateSupplierOrderController extends ChangeNotifier {
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  void setIsLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool?> updateSupplierOrder({
    required OrderModel.Order order,
    required BuildContext context,
  }) async {
    setIsLoading(true);
    _errorMessage = null;

    try {
      final result = await UpdateSupplierOrderService.updateSupplierOrder(
        order: order,
        context: context,
      );
      
      if (result == null) {
        _errorMessage = 'Failed to update supplier order';
      }
      
      return result;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      setIsLoading(false);
    }
  }
}