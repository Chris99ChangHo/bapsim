import 'package:bapsim/screens/dishes_screen.dart';
import 'package:bapsim/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StoreListScreen extends StatefulWidget {
  const StoreListScreen({Key? key}) : super(key: key);

  @override
  _StoreListScreenState createState() => _StoreListScreenState();
}

class _StoreListScreenState extends State<StoreListScreen> {
  late Future<List<Map<String, dynamic>>> _stores;
  static const String baseUrl = 'http://10.0.2.2:5000';

  Future<List<Map<String, dynamic>>> fetchStores() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/fetch_stores'));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
            'Failed to fetch stores. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching stores: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _stores = fetchStores();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('가게 목록'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _stores,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('데이터를 불러오는 데 실패했습니다: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('등록된 가게가 없습니다.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final store = snapshot.data![index];
                return Card(
                  elevation: 4,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: store['image_url'] != null &&
                              store['image_url'].isNotEmpty
                          ? Image.network(store['image_url'],
                              width: 70, height: 70, fit: BoxFit.cover)
                          : const Icon(Icons.store,
                              size: 50, color: Colors.grey),
                    ),
                    title: Text(store['name'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    subtitle: Text(store['location'],
                        style: const TextStyle(fontSize: 14)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.map, color: Colors.blue),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => MapScreen(
                                  latitude: store['latitude'],
                                  longitude: store['longitude'],
                                  storeName: store['name'],
                                ),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon:
                              const Icon(Icons.restaurant, color: Colors.green),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DishesScreen(storeId: store['id']),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
