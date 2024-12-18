import 'package:flutter/material.dart';
import 'package:bapsim/screens/order_screen.dart'; // 주문하기 화면 import
import 'package:intl/intl.dart'; // 통화 포맷을 위한 intl 패키지
import 'package:provider/provider.dart'; // Provider 패키지 import
import 'package:bapsim/cart_notifier.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;

  const CartScreen({Key? key, required this.cartItems}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'ko_KR', symbol: '₩'); // 통화 포맷 설정

  String deliveryMethod = "모아배달"; // 기본 배달 방식
  TextEditingController deliveryRequestController =
      TextEditingController(); // 배달 요청사항 컨트롤러

  List<Map<String, dynamic>> searchResults = []; // 검색 결과 저장
  TextEditingController searchController = TextEditingController();

  int calculateTotal() {
    return widget.cartItems.fold<int>(
        0,
        (total, item) =>
            total + (item['price'] as int) * (item['quantity'] as int));
  }

  void updateQuantity(int index, int delta) {
    setState(() {
      widget.cartItems[index]['quantity'] += delta;
      if (widget.cartItems[index]['quantity'] < 1) {
        widget.cartItems[index]['quantity'] = 1; // 최소 수량 1로 제한
      }
    });
  }

  void deleteItem(int index) {
    setState(() {
      widget.cartItems.removeAt(index);
    });
  }

  void addItemToCart(Map<String, dynamic> item) {
    setState(() {
      widget.cartItems.add(item);
    });
  }

  Future<List<Map<String, dynamic>>> fetchSearchResults(String query) async {
    // 여기에 검색 API 호출 로직 추가
    // 샘플 데이터를 반환하도록 구현
    return [
      {
        'name': '새로운 반찬 1',
        'image_url': '',
        'price': 5000,
        'quantity': 1,
      },
      {
        'name': '새로운 반찬 2',
        'image_url': '',
        'price': 7000,
        'quantity': 1,
      },
    ];
  }

  void searchItems(String query) async {
    final results = await fetchSearchResults(query);
    setState(() {
      searchResults = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    final deliveryFee = deliveryMethod == "모아배달" ? 1000 : 3000;
    final totalPrice = calculateTotal() + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('장바구니'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearchDialog();
            },
          ),
        ],
      ),
      body: widget.cartItems.isEmpty
          ? const Center(
              child: Text(
                '장바구니가 비어 있습니다.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          height: 150,
                          child: Row(
                            children: [
                              // 이미지
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: item['image_url'] != null &&
                                          item['image_url'].isNotEmpty
                                      ? DecorationImage(
                                          image:
                                              NetworkImage(item['image_url']),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: Colors.grey[200],
                                ),
                                child: item['image_url'] == null ||
                                        item['image_url'].isEmpty
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
                                      item['name'],
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "가격: ${currencyFormatter.format(item['price'])}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "수량: ${item['quantity']}",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // 수량 조절 및 삭제 버튼
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () => updateQuantity(index, 1),
                                    ),
                                  ),
                                  Flexible(
                                    child: IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () =>
                                          updateQuantity(index, -1),
                                    ),
                                  ),
                                  Flexible(
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () => deleteItem(index),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 배달 방식 선택 UI
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "배달방식을 선택해주세요",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildDeliveryOption(
                              "모아배달",
                              "6000원 / 현재 6명\n현재 배달비: 1000원",
                              Icons.people,
                              Colors.red,
                            ),
                            const SizedBox(width: 16),
                            _buildDeliveryOption(
                              "일반배달",
                              "3000원\n신속한 배달 원해요",
                              Icons.flash_on,
                              Colors.grey,
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),

                // 주문하기 버튼
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.white,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OrderScreen(
                            cartItems: widget.cartItems,
                            deliveryMethod: deliveryMethod,
                            deliveryFee: deliveryFee,
                            deliveryRequest: deliveryRequestController.text,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(60),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.shopping_cart),
                    label: Text(
                      "${currencyFormatter.format(totalPrice)} 주문하기",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('반찬 검색'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: searchController,
              decoration: const InputDecoration(
                labelText: '반찬 이름 검색',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => searchItems(value),
            ),
            const SizedBox(height: 10),
            searchResults.isNotEmpty
                ? Expanded(
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        return ListTile(
                          title: Text(item['name']),
                          subtitle: Text(
                            "가격: ${currencyFormatter.format(item['price'])}",
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              addItemToCart(item);
                              Navigator.pop(context); // 추가 후 다이얼로그 닫기
                            },
                          ),
                        );
                      },
                    ),
                  )
                : const Text('검색 결과가 없습니다.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOption(
      String method, String description, IconData icon, Color color) {
    final bool isSelected = deliveryMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            deliveryMethod = method;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : color, size: 30),
              const SizedBox(height: 8),
              Text(
                method,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // 제목 폰트 크기
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black54,
                  fontSize: 14, // 설명 폰트 크기
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
