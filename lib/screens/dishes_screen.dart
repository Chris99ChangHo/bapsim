import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DishesScreen extends StatefulWidget {
  final int storeId;

  const DishesScreen({Key? key, required this.storeId}) : super(key: key);

  @override
  _DishesScreenState createState() => _DishesScreenState();
}

class _DishesScreenState extends State<DishesScreen> {
  late Future<List<Map<String, dynamic>>> _dishes;

  // 서버 주소 수정 (10.0.2.2 사용)
  static const String baseUrl = 'http://10.0.2.2:5000';

  Future<List<Map<String, dynamic>>> fetchDishesForStore(int storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/stores/$storeId/dishes'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        throw Exception(
            'Failed to fetch dishes. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching dishes: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _dishes = fetchDishesForStore(widget.storeId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('반찬 리스트'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _dishes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('반찬 데이터를 불러오는 데 실패했습니다: ${snapshot.error}'),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('해당 가게에 등록된 반찬이 없습니다.'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final dish = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    leading: dish['image_url'] != null &&
                            dish['image_url'].isNotEmpty
                        ? Image.network(
                            dish['image_url'],
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported, size: 50),
                    title: Text(dish['name']),
                    subtitle: Text(
                        '조리법: ${dish['cooking_method']}\n가격: ₩${dish['price']}'),
                    isThreeLine: true,
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
