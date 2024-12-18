import 'package:flutter/material.dart';

class BapsimPlusScreen extends StatefulWidget {
  const BapsimPlusScreen({Key? key}) : super(key: key);

  @override
  State<BapsimPlusScreen> createState() => _BapsimPlusScreenState();
}

class _BapsimPlusScreenState extends State<BapsimPlusScreen> {
  final TextEditingController _inputController = TextEditingController();
  final List<Map<String, String>> _chatMessages = [];

  @override
  void initState() {
    super.initState();
    // 디폴트 메시지 설정
    _inputController.text = '밥심플러스에게 궁금한 걸 물어보세요!';
  }

  void _sendMessage() {
    final userMessage = _inputController.text.trim();
    if (userMessage.isEmpty) return;

    setState(() {
      _chatMessages.add({"user": userMessage});
      _chatMessages.add({"ai": "밥심 AI의 응답 메시지"}); // 임시 AI 응답
    });

    _inputController.clear(); // 입력 필드 초기화
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('밥심 PLUS+'),
        backgroundColor: Colors.red,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _chatMessages.length,
              itemBuilder: (context, index) {
                final message = _chatMessages[index];
                final isUserMessage = message.containsKey('user');
                return Align(
                  alignment: isUserMessage
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isUserMessage ? Colors.red[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      message[isUserMessage ? 'user' : 'ai']!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    decoration: InputDecoration(
                      hintText: '질문을 입력하세요...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('전송'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
