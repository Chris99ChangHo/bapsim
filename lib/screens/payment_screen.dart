import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // 통화 포맷을 위한 intl 패키지
import 'package:bapsim/order_history.dart';
import 'package:bapsim/screens/cart_screen.dart';

class PaymentScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String paymentMethod;
  final double paymentAmount;
  final String receiverName;
  final String receiverPhone;
  final String zip;
  final String address1;
  final String address2;
  final String deliveryRequest;
  final String couponApplied;
  final String deliveryType;
  final double orderAmount;
  final double deliveryFee;
  final double couponDiscount;
  final double totalAmount;

  const PaymentScreen({
    Key? key,
    required this.cartItems,
    required this.paymentMethod,
    required this.paymentAmount,
    required this.receiverName,
    required this.receiverPhone,
    required this.zip,
    required this.address1,
    required this.address2,
    required this.deliveryRequest,
    required this.couponApplied,
    required this.deliveryType,
    required this.orderAmount,
    required this.deliveryFee,
    required this.couponDiscount,
    required this.totalAmount,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final NumberFormat currencyFormatter =
      NumberFormat.currency(locale: 'ko_KR', symbol: '₩');
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('결제확인'),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "결제 정보",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow("결제 방법", widget.paymentMethod),
                  _buildInfoRow("배달 방식", widget.deliveryType),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 16),
                  const Text(
                    "결제 상세 정보",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                      "주문 금액", currencyFormatter.format(widget.orderAmount)),
                  _buildInfoRow(
                      "배달 팁", currencyFormatter.format(widget.deliveryFee)),
                  if (widget.couponDiscount > 0)
                    _buildInfoRow("할인 금액",
                        "- ${currencyFormatter.format(widget.couponDiscount)}"),
                  const Divider(thickness: 1.5),
                  _buildInfoRow(
                      "총 결제 금액", currencyFormatter.format(widget.totalAmount)),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 16),
                  const Text(
                    "배송 정보",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(height: 16),
                  _buildShippingInfo(),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _confirmPayment,
                      icon: const Icon(Icons.payment),
                      label: const Text(
                        "결제 완료",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(60), // 버튼 높이 설정
                        backgroundColor: Colors.red, // 배경색
                        foregroundColor: Colors.white, // 텍스트 및 아이콘 색상
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12), // 모서리 둥글게
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ],
      ),
    );
  }

  Widget _buildShippingInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50], // 연한 빨강 배경
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "받는 사람: ${widget.receiverName} (${widget.receiverPhone})",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "주소: ${widget.address1}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "상세주소: ${widget.address2}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "우편번호: ${widget.zip}",
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            "배달 요청 사항: ${widget.deliveryRequest}",
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _confirmPayment() {
    setState(() {
      isLoading = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isLoading = false;
      });

      // 주문 정보 저장
      OrderHistory.completedOrders.add({
        'orderDate': DateTime.now().toString().substring(0, 10), // 현재 날짜
        'items': widget.cartItems, // 주문한 반찬 데이터 리스트를 저장
        'deliveryType': widget.deliveryType, // 배달 방식
        'paymentMethod': widget.paymentMethod, // 결제 수단
        'deliveryAddress': "${widget.address1}, ${widget.address2}", // 배송 주소
        'deliveryRequest': widget.deliveryRequest, // 배달 요청사항
        'totalAmount': widget.totalAmount, // 총 결제 금액
      });

      // 결제 완료 메시지
      _showConfirmationDialog(context);
    });
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("결제 완료"),
        content: const Text("결제가 성공적으로 완료되었습니다."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }
}
