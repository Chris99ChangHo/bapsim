import 'package:bapsim/test/item_basket_page.dart';
import 'package:bapsim/test/my_order_list_page.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bapsim/test/constants.dart';
import 'package:bapsim/test/item_details_page.dart';
import 'package:bapsim/models/product.dart';
import 'package:bapsim/screens/dish_recommendation_screen.dart'; // 추가: DishRecommendationPage import

class ItemListPage extends StatefulWidget {
  const ItemListPage({super.key});

  @override
  State<ItemListPage> createState() => _ItemListPageState();
}

class _ItemListPageState extends State<ItemListPage> {
  List<Product> productList = [
    Product(
        productNo: 1,
        productName: "노트북(Laptop)",
        productImageUrl: "https://picsum.photos/id/1/300/300",
        price: 600000),
    Product(
        productNo: 2,
        productName: "스마트폰(Phone)",
        productImageUrl: "https://picsum.photos/id/20/300/300",
        price: 500000),
    Product(
        productNo: 3,
        productName: "머그컵(Cup)",
        productImageUrl: "https://picsum.photos/id/30/300/300",
        price: 15000),
    Product(
        productNo: 4,
        productName: "키보드(Keyboard)",
        productImageUrl: "https://picsum.photos/id/60/300/300",
        price: 50000),
    Product(
        productNo: 5,
        productName: "포도(Grape)",
        productImageUrl: "https://picsum.photos/id/75/200/300",
        price: 75000),
    Product(
        productNo: 6,
        productName: "책(book)",
        productImageUrl: "https://picsum.photos/id/24/200/300",
        price: 24000),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("제품 리스트"), centerTitle: true, actions: [
        IconButton(
          icon: const Icon(
            Icons.account_circle,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const MyOrderListPage();
                },
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.shopping_cart,
          ),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) {
                  return const ItemBasketPage();
                },
              ),
            );
          },
        )
      ]),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: productList.length,
              itemBuilder: (context, index) {
                return productContainer(
                  productNo: productList[index].productNo ?? 0,
                  productName: productList[index].productName ?? "",
                  productImageUrl: productList[index].productImageUrl ?? "",
                  price: productList[index].price ?? 0,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // 반찬 추천 시스템으로 이동
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DishRecommendationScreen(),
                  ),
                );
              },
              child: const Text('반찬 추천 시스템으로 가기'),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: FilledButton(
          onPressed: () {
            // 결제 로직
          },
          child: const Text("결제하기"),
        ),
      ),
    );
  }

  Widget productContainer({
    required int productNo,
    required String productName,
    required String productImageUrl,
    required double price,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) {
            return ItemDetailsPage(
              productNo: productNo,
              productName: productName,
              productImageUrl: productImageUrl,
              price: price,
            );
          },
        ));
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        margin: const EdgeInsets.symmetric(vertical: 5), // 아이템 간의 세로 간격
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey), // 외곽선 추가
          borderRadius: BorderRadius.circular(8), // 모서리 둥글게
        ),
        child: Row(
          children: [
            CachedNetworkImage(
              width: 100, // 이미지의 폭 설정
              height: 100, // 이미지의 높이 설정
              fit: BoxFit.cover,
              imageUrl: productImageUrl,
              placeholder: (context, url) {
                return const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return const Center(
                  child: Text("오류 발생"),
                );
              },
            ),
            const SizedBox(width: 10), // 이미지와 텍스트 간의 간격
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text("${numberFormat.format(price)}원"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
