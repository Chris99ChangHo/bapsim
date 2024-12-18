import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:bapsim/screens/cart_screen.dart';

class RecommendationResultPage extends StatefulWidget {
  final List<String> userDishes;
  final int numRecommendations;
  final bool includeSoupOption;
  final String selectedSeason;
  final bool veganOnly;

  const RecommendationResultPage({
    Key? key,
    required this.userDishes,
    required this.numRecommendations,
    required this.includeSoupOption,
    required this.selectedSeason,
    required this.veganOnly,
  }) : super(key: key);

  @override
  _RecommendationResultPageState createState() =>
      _RecommendationResultPageState();
}

class _RecommendationResultPageState extends State<RecommendationResultPage> {
  late Future<List<Map<String, dynamic>>> recommendations;
  Set<int> selectedItems = {}; // 선택된 반찬의 인덱스 저장
  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'ko_KR', symbol: '₩'); // 통화 포맷 설정

  @override
  void initState() {
    super.initState();
    recommendations = fetchRecommendations();
  }

  Future<List<Map<String, dynamic>>> fetchRecommendations() async {
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_dishes': widget.userDishes,
          'include_soup_option': widget.includeSoupOption,
          'num_recommendations': widget.numRecommendations,
          'selected_season': widget.selectedSeason,
          'vegan_only': widget.veganOnly,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is List) {
          return data.map((item) {
            return {
              'name': item['name'] ?? 'Unknown',
              'image_url': item['image_url'] ?? '',
              'store_name': item['store_name'] ?? 'Unknown Store',
              'price': item['price'] != null
                  ? int.parse(item['price'].toString())
                  : 0,
            };
          }).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load recommendations');
      }
    } catch (e) {
      print('Error fetching recommendations: $e');
      return [];
    }
  }

  int calculateTotal(List<Map<String, dynamic>> dishes) {
    return dishes.fold<int>(0, (total, dish) => total + (dish['price'] as int));
  }

  // 선택된 반찬 총액 계산
  int calculateSelectedTotal(List<Map<String, dynamic>> dishes) {
    return selectedItems.fold<int>(
        0, (total, index) => total + (dishes[index]['price'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추천결과'),
        backgroundColor: Colors.red,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: recommendations,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '추천 결과를 가져오는 중 오류가 발생했습니다.',
                style: const TextStyle(fontSize: 16, color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                '추천 결과가 없습니다.',
                style: TextStyle(fontSize: 16),
              ),
            );
          } else {
            final allDishes = snapshot.data!;
            final totalPrice = calculateTotal(allDishes);

            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: allDishes.length,
                    itemBuilder: (context, index) {
                      final dish = allDishes[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          height: 150,
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // 이미지
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: dish['image_url'].isNotEmpty
                                      ? DecorationImage(
                                          image:
                                              NetworkImage(dish['image_url']),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: Colors.grey[200],
                                ),
                                child: dish['image_url'].isEmpty
                                    ? const Icon(Icons.image,
                                        size: 40, color: Colors.grey)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              // 텍스트
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      dish['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "가게: ${dish['store_name']}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "가격: ${currencyFormatter.format(dish['price'])}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 선택 체크박스
                              Checkbox(
                                value: selectedItems.contains(index),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedItems.add(index);
                                    } else {
                                      selectedItems.remove(index);
                                    }
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "총액: ${currencyFormatter.format(calculateSelectedTotal(allDishes))}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 24),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // 선택된 반찬만 장바구니로 이동
                          List<Map<String, dynamic>> selectedCartItems =
                              allDishes
                                  .where((dish) => selectedItems
                                      .contains(allDishes.indexOf(dish)))
                                  .toList();

                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => CartScreen(
                              cartItems: selectedCartItems.map((dish) {
                                return {
                                  ...dish,
                                  'quantity': 1,
                                };
                              }).toList(),
                            ),
                          ));
                        },
                        child: const Text(
                          "장바구니에 담기",
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
