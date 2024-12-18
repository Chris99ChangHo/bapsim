import 'package:flutter/material.dart';
import 'package:bapsim/screens/recommendation_result_screen.dart';

class DishRecommendationScreen extends StatefulWidget {
  const DishRecommendationScreen({Key? key}) : super(key: key);

  @override
  _DishRecommendationScreenState createState() =>
      _DishRecommendationScreenState();
}

class _DishRecommendationScreenState extends State<DishRecommendationScreen> {
  final TextEditingController dishController = TextEditingController();
  List<String> currentDishes = [];
  bool includeSoupOption = false;
  bool veganOnly = false;
  int numRecommendations = 0;
  String selectedSeason = '';

  void addDish() {
    String inputDish = dishController.text.trim();
    if (inputDish.isNotEmpty && !currentDishes.contains(inputDish)) {
      setState(() {
        currentDishes.add(inputDish);
        dishController.clear();
      });
    }
  }

  void removeDish(String dish) {
    setState(() {
      currentDishes.remove(dish);
    });
  }

  void recommendDishes() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecommendationResultPage(
          userDishes: currentDishes,
          numRecommendations: numRecommendations,
          includeSoupOption: includeSoupOption,
          selectedSeason: selectedSeason,
          veganOnly: veganOnly,
        ),
      ),
    );
  }

  void skipCustomization() {
    setState(() {
      includeSoupOption = true;
      veganOnly = false;
      selectedSeason = '사계절';
      numRecommendations = 5;
    });
    recommendDishes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('추천받기'),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 설명 박스
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Tip! 원하는 반찬 옵션을 추가하고 밥심에게 추천받아요!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14, // 폰트 크기를 조정
                    color: Colors.red,
                  ),
                  overflow: TextOverflow.ellipsis, // 한 줄 안에 맞추기
                ),
              ),
              const SizedBox(height: 20),

              // 반찬 입력 섹션
              const Text('현재 보유 중인 반찬을 입력하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: dishController,
                      decoration: InputDecoration(
                        hintText: '반찬 이름을 입력하세요',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        filled: true,
                        fillColor: Colors.red[50],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white, // 텍스트 색상 변경
                    ),
                    onPressed: addDish,
                    child: const Text('추가'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8.0,
                children: currentDishes
                    .map((dish) => Chip(
                          label: Text(dish),
                          backgroundColor: Colors.red[50],
                          deleteIconColor: Colors.red,
                          labelStyle: const TextStyle(color: Colors.black),
                          onDeleted: () => removeDish(dish),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // 구분선 추가
              const Divider(thickness: 1.0),

              // 추가 옵션 섹션
              const Text('추가 옵션을 선택하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('국이나 찌개 추천받기'),
                      value: includeSoupOption,
                      onChanged: (value) {
                        setState(() {
                          includeSoupOption = value ?? false;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: CheckboxListTile(
                      title: const Text('비건 메뉴로 추천받기'),
                      value: veganOnly,
                      onChanged: (value) {
                        setState(() {
                          veganOnly = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 구분선 추가
              const Divider(thickness: 1.0),

              // 추천 반찬 개수 선택 섹션
              const Text('추천될 반찬의 개수를 선택하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildOptionButton("3첩", 3, numRecommendations == 3),
                  _buildOptionButton("5첩", 5, numRecommendations == 5),
                  _buildOptionButton("7첩", 7, numRecommendations == 7),
                ],
              ),
              const SizedBox(height: 20),

              // 구분선 추가
              const Divider(thickness: 1.0),

              // 계절 선택 섹션
              const Text('원하는 계절의 반찬 선택하기',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['봄', '여름', '가을', '겨울', '사계절']
                    .map((season) =>
                        _buildSeasonButton(season, selectedSeason == season))
                    .toList(),
              ),
              const SizedBox(height: 30),

              // 추천받기 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: recommendDishes,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.restaurant, color: Colors.red, size: 30),
                    SizedBox(width: 10),
                    Text(
                      '추천받기',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 건너뛰기 버튼
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  side: const BorderSide(color: Colors.grey),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: skipCustomization,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.skip_next, color: Colors.grey, size: 30),
                    SizedBox(width: 10),
                    Text(
                      '건너뛰기',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionButton(String text, int value, bool isSelected) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.red : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          numRecommendations = value;
        });
      },
      child: Text(text),
    );
  }

  Widget _buildSeasonButton(String season, bool isSelected) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.red : Colors.grey[300],
        foregroundColor: isSelected ? Colors.white : Colors.black,
      ),
      onPressed: () {
        setState(() {
          selectedSeason = season;
        });
      },
      child: Text(season),
    );
  }
}
