import 'package:bapsim/cart_notifier.dart';
import 'package:bapsim/order_history.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:bapsim/screens/cart_screen.dart';

final NumberFormat currencyFormatter =
    NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '마이페이지',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            // 사용자 정보 추가
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "이름: 장창호", // 사용자 이름
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "이메일: ckdgh4641@syu.ac.kr", // 사용자 이메일
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "전화번호: 010-1234-5678", // 사용자 전화번호
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 2),
            const SizedBox(height: 16),
            const Text(
              '주문 내역',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            OrderHistory.completedOrders.isEmpty
                ? const Center(
                    child: Text(
                      '주문 내역이 없습니다.',
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: OrderHistory.completedOrders.length,
                    itemBuilder: (context, index) {
                      final order = OrderHistory.completedOrders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "주문 날짜: ${order['orderDate']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "배달 방식: ${order['deliveryType']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "결제 방법: ${order['paymentMethod']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "배송지: ${order['deliveryAddress']}"
                                    .replaceAll(',', '\n'), // ','를 '\n'으로 변경
                                style: const TextStyle(fontSize: 14),
                                softWrap: true, // 줄바꿈 허용
                                maxLines: null, // 제한 없음
                                overflow:
                                    TextOverflow.visible, // 텍스트 초과 시 보이도록 설정
                              ),
                              Text(
                                "요청 사항: ${order['deliveryRequest']}",
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                "총 결제 금액: ${currencyFormatter.format(order['totalAmount'])}", // ₩ 포함하여 포맷팅
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final cartNotifier =
                                      Provider.of<CartNotifier>(context,
                                          listen: false);
                                  final selectedOrder =
                                      OrderHistory.completedOrders[index];
                                  final itemsToReorder =
                                      List<Map<String, dynamic>>.from(
                                          selectedOrder['items']);

                                  // 장바구니에 데이터 추가
                                  for (var item in itemsToReorder) {
                                    cartNotifier.addItem(item);
                                  }

                                  // 재주문 완료 메시지 다이얼로그 표시
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('재주문 완료'),
                                      content: const Text(
                                          '주문 내역이 장바구니에 추가되었습니다. 장바구니로 이동합니다.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context); // 다이얼로그 닫기
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CartScreen(
                                                        cartItems: cartNotifier
                                                            .cartItems),
                                              ),
                                            );
                                          },
                                          child: const Text('확인'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('재주문'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
