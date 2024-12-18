import 'package:bapsim/screens/BapsimPlus_screen.dart';
import 'package:bapsim/screens/store_list_screen.dart' as StoreListPackage;
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:bapsim/screens/dish_recommendation_screen.dart';
import 'package:bapsim/screens/cart_screen.dart';
import 'package:bapsim/screens/mypage_screen.dart';
import 'package:bapsim/screens/map_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.red),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '관악구 관악로 145',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black, fontSize: 16),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MapScreen(
                      latitude: 37.4783, // 예: 관악구청 위도
                      longitude: 126.9516, // 예: 관악구청 경도
                      storeName: '현재 위치', // 임시 이름
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const MyPageScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart, color: Colors.black),
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => CartScreen(cartItems: []),
              ));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // 검색창
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: '오늘은 뭐 먹지?',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Tip 섹션
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Tip! 밥심 AI에게 원하는 반찬을 추천받아보세요!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.red,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 추천 버튼 섹션
              Column(
                children: [
                  SizedBox(
                    width: double.infinity, // 버튼이 화면 전체를 채우도록 설정
                    child: _buildRecommendationButton(
                      context,
                      Icons.restaurant,
                      '밥상을 부탁해',
                      '밥심 AI에게 내 밥상 맡기기',
                      const DishRecommendationScreen(), // 추천 화면으로 이동
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _buildRecommendationButton(
                      context,
                      Icons.chat,
                      '밥심 PLUS+',
                      '밥심 AI에게 내 식단 물어보기',
                      const BapsimPlusScreen(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: _buildRecommendationButton(
                      context,
                      Icons.shopping_bag,
                      '직접 고를게요',
                      '반찬가게에서 내가 직접 담기',
                      const StoreListPackage.StoreListScreen(), // 가게 조회 화면으로 이동
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 광고 슬라이드
              _buildAdCarousel(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.grey,
        selectedIconTheme: const IconThemeData(size: 30),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '찜',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: '주문내역',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '내 밥심',
          ),
        ],
      ),
    );
  }

  // 추천 버튼 빌더
  Widget _buildRecommendationButton(BuildContext context, IconData icon,
      String title, String subtitle, Widget? navigateTo) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 20), // 버튼 높이 유지
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // 둥근 모서리
        ),
        elevation: 2, // 버튼 그림자
      ),
      onPressed: () {
        if (navigateTo != null) {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => navigateTo));
        }
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양쪽 정렬
        children: [
          // 좌측 아이콘
          Padding(
            padding: const EdgeInsets.only(left: 16), // 좌측 고정된 여백 증가
            child: Icon(icon, size: 40, color: Colors.white), // 아이콘 크기
          ),

          // 텍스트 영역 (가운데 정렬)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center, // 텍스트 가운데 정렬
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold), // Bold 제목
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.normal), // 부제목
                ),
              ],
            ),
          ),

          // 우측 화살표
          Padding(
            padding: const EdgeInsets.only(right: 16), // 우측 고정된 여백 증가
            child: const Icon(Icons.arrow_forward_ios,
                size: 20, color: Colors.white), // 화살표 크기
          ),
        ],
      ),
    );
  }

  // 광고 슬라이드 빌더
  Widget _buildAdCarousel(BuildContext context) {
    final List<Map<String, String>> adData = [
      {
        "title": "들기름 볶음김치",
        "text": "나야, 들기름. 고소한 풍미가 가득한 볶음김치입니다. 입맛 없을 때 강력 추천!",
        "image":
            "https://postfiles.pstatic.net/MjAyNDAzMDhfNTAg/MDAxNzA5ODI0NDE4NTUz.deN-yprvuSR6nPDnd5ty3rHT7WGHarZyAzOGZftc2QYg.nDKB8TQ0xbCfMGYtBoa2Z1zGSSGk31HiiDtVsew_0tUg.JPEG/2C7A8288_copy.jpg?type=w966",
      },
      {
        "title": "소고기 미역국",
        "text": "상원맘의 필살기! 소고기와 미역을 듬뿍 넣어 깊고 진한 맛을 자랑하는 미역국입니다. 든든한 한 끼로 추천!",
        "image":
            "https://postfiles.pstatic.net/MjAyNDA4MDJfMTk2/MDAxNzIyNTY3NjI3NTEx.pP62jHnEatSB6T6VKmxLPPnqH0AKUVotRJ5A_epTsMIg.kyri-GfIkbm4RitNdU8wghKiJV7Psd7SerbjD7k-kaUg.JPEG/SE-69873cd9-a2b9-4f1c-befb-fdd8e4dd6c3a.jpg?type=w966",
      },
      {
        "title": "가성비갑 갈비찜",
        "text": "동욱이네 공동구매 동공구! 다 함께 구매해서 저렴한 가격에 즐기는 갈비찜입니다. 가족 식사로 추천드려요!",
        "image":
            "https://postfiles.pstatic.net/MjAyNDAyMDhfOTIg/MDAxNzA3NDAwNjExNTY0.KrTqD12ncw-pcPK_1VhOTYwN4I5BpEjp_-hyGM9grUkg.XNzq56XrX6SdNiZd-VVS9-Z6oPyvRy9VDCTcbwCT1-Qg.JPEG.cgs121/SE-5bcdc4b0-9743-49bf-8086-d4741f179870.jpg?type=w773",
      },
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 200.0,
        autoPlay: true,
        enlargeCenterPage: true,
        autoPlayInterval: const Duration(seconds: 3),
      ),
      items: adData.map((ad) {
        return GestureDetector(
          onTap: () {
            // 팝업 다이얼로그로 자세한 내용 표시
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(ad["title"]!),
                content: Text(ad["text"]!),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('닫기'),
                  ),
                ],
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // 배경 이미지
                Image.network(
                  ad["image"]!,
                  fit: BoxFit.cover,
                  width: MediaQuery.of(context).size.width,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset(
                      'assets/images/placeholder.png',
                      fit: BoxFit.cover,
                    );
                  },
                ),
                // 제목 텍스트
                Positioned(
                  bottom: 10,
                  left: 10, // 좌측 하단에 위치
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    color: Colors.black.withOpacity(0.5), // 반투명 배경
                    child: Text(
                      ad["title"]!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
