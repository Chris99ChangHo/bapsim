import 'package:http/http.dart' as http;
import 'dart:convert';

class DatabaseService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  // Fetch all stores
  static Future<List<Map<String, dynamic>>> fetchStores() async {
    final response = await http.get(Uri.parse('$baseUrl/stores'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load stores');
    }
  }

  // Fetch dishes for a specific store
  static Future<List<Map<String, dynamic>>> fetchDishesForStore(
      int storeId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/stores/$storeId/dishes'));

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load dishes for store $storeId');
    }
  }
}
