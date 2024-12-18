import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/cupertino.dart';
import 'payment_screen.dart';

class OrderScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String deliveryMethod;
  final int deliveryFee;
  final String deliveryRequest;

  const OrderScreen({
    Key? key,
    required this.cartItems,
    required this.deliveryMethod,
    required this.deliveryFee,
    required this.deliveryRequest,
  }) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'ko_KR', symbol: '₩');

  String selectedPaymentMethod = "밥심머니";
  String selectedCoupon = "적용된 쿠폰 없음";
  int discountAmount = 0;
  String deliveryRequest = "문 앞에 놓고 벨 눌러주세요";
  String deliveryAddress = "서울특별시 관악구 관악로 145";
  String additionalAddress = "4층 지역상권활성화과";
  TimeOfDay deliveryTime = const TimeOfDay(hour: 0, minute: 0);
  String contactNumber = "010-1234-5678";

  int calculateTotal() {
    final int itemTotal = widget.cartItems.fold<int>(
        0,
        (total, item) =>
            total + (item['price'] as int) * (item['quantity'] as int));
    return itemTotal + widget.deliveryFee - discountAmount;
  }

  @override
  Widget build(BuildContext context) {
    final int itemTotal = widget.cartItems.fold<int>(
        0,
        (total, item) =>
            total + (item['price'] as int) * (item['quantity'] as int));
    final totalPrice = calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text('주문확인'),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.delivery_dining, // 실제 배달 아이콘
                  color: Colors.red, // 아이콘 색상
                  size: 24, // 아이콘 크기
                ),
                const SizedBox(width: 8), // 아이콘과 텍스트 사이 공백
                Text(
                  "${widget.deliveryMethod}", // 배달 방식 텍스트
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildInfoButton(
              label: "배달주소 확인",
              value: "$deliveryAddress",
              onTap: () {
                _showEditDialog("배달주소 수정", deliveryAddress, (newValue) {
                  setState(() => deliveryAddress = newValue);
                });
              },
            ),
            _buildInfoButton(
              label: "추가 주소 확인",
              value: additionalAddress,
              onTap: () {
                _showEditDialog("추가 주소 수정", additionalAddress, (newValue) {
                  setState(() => additionalAddress = newValue);
                });
              },
            ),
            _buildInfoButton(
              label: "배달 요청사항 확인",
              value: deliveryRequest,
              onTap: () {
                _showEditDialog("배달 요청사항 수정", deliveryRequest, (newValue) {
                  setState(() => deliveryRequest = newValue);
                });
              },
            ),
            _buildInfoButton(
              label: "연락처 확인",
              value: contactNumber,
              onTap: () {
                _showEditDialog("연락처 수정", contactNumber, (newValue) {
                  setState(() => contactNumber = newValue);
                });
              },
            ),
            _buildInfoButton(
              label: "희망 배달 시간 확인",
              value: deliveryTime.format(context),
              onTap: () {
                _showCupertinoTimePicker();
              },
            ),
            const Divider(thickness: 2),
            const SizedBox(height: 8),
            const Text(
              "결제 정보",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            ListTile(
              title: const Text("결제 수단 선택"),
              trailing: DropdownButton<String>(
                value: selectedPaymentMethod,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedPaymentMethod = newValue!;
                  });
                },
                items: ["밥심머니", "신용/체크", "기타"]
                    .map((method) => DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        ))
                    .toList(),
              ),
            ),
            ListTile(
              title: const Text("할인 쿠폰 선택"),
              trailing: DropdownButton<String>(
                value: selectedCoupon,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedCoupon = newValue!;
                    discountAmount = _getDiscount(newValue);
                  });
                },
                items: ["적용된 쿠폰 없음", "웰컴 쿠폰 (2,000원 할인)", "첫 구매 할인 (3,000원 할인)"]
                    .map((coupon) {
                  return DropdownMenuItem(
                    value: coupon,
                    child: Text(coupon),
                  );
                }).toList(),
              ),
            ),
            const Divider(thickness: 2),
            _buildPriceDetails(totalPrice),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      paymentMethod: selectedPaymentMethod,
                      paymentAmount: totalPrice.toDouble(),
                      receiverName: "장창호",
                      receiverPhone: contactNumber,
                      zip: "12345",
                      address1: deliveryAddress,
                      address2: additionalAddress,
                      deliveryRequest: deliveryRequest,
                      couponApplied: selectedCoupon,
                      deliveryType: widget.deliveryMethod,
                      orderAmount:
                          (calculateTotal() - widget.deliveryFee).toDouble(),
                      deliveryFee: widget.deliveryFee.toDouble(),
                      couponDiscount: discountAmount.toDouble(),
                      totalAmount: totalPrice.toDouble(),
                      cartItems: widget.cartItems,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.payment),
              label: Text(
                "${currencyFormatter.format(totalPrice)} 결제하기",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
      String title, String currentValue, Function(String) onSave) {
    final TextEditingController controller =
        TextEditingController(text: currentValue);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: "새로운 값을 입력해주세요"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("취소"),
          ),
          TextButton(
            onPressed: () {
              onSave(controller.text);
              Navigator.pop(context);
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }

  void _showCupertinoTimePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SizedBox(
          height: 250,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.time,
            initialDateTime:
                DateTime(2024, 1, 1, deliveryTime.hour, deliveryTime.minute),
            onDateTimeChanged: (DateTime newTime) {
              setState(() {
                deliveryTime =
                    TimeOfDay(hour: newTime.hour, minute: newTime.minute);
              });
            },
          ),
        );
      },
    );
  }

  int _getDiscount(String coupon) {
    if (coupon.contains("웰컴 쿠폰")) {
      return 2000;
    } else if (coupon.contains("첫 구매 할인")) {
      return 3000;
    }
    return 0;
  }

  Widget _buildInfoButton({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          backgroundColor: Colors.red[50], // 연한 빨강 배경
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // 둥근 모서리
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                overflow: TextOverflow.ellipsis, // 길 경우 생략
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails(int totalPrice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPriceRow("주문 금액", calculateTotal() - widget.deliveryFee),
        _buildPriceRow("배달 팁", widget.deliveryFee),
        _buildPriceRow("할인 금액", -discountAmount),
        const Divider(thickness: 1),
        _buildPriceRow("총 결제 금액", totalPrice, isBold: true),
      ],
    );
  }

  Widget _buildPriceRow(String label, int price, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            currencyFormatter.format(price),
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
