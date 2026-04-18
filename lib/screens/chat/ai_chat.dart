import 'package:flutter/material.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 대화 내용을 담아둘 리스트 (기본 인사말과 더미 데이터 세팅)
  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text': '안녕하세요, 홍길동님! SafePill AI 상담사 필봇입니다. 어떤 도움이 필요하신가요? 약물 복용 방법이나 상극 정보가 궁금하시다면 언제든 물어봐 주세요.'
    },
    {
      'isUser': true,
      'text': '타이레놀이랑 감기약을 같이 먹어도 괜찮을까요?'
    },
    {
      'isUser': false,
      'text': '네, 타이레놀과 일반적인 종합 감기약은 같이 복용하셔도 큰 무리가 없습니다. 하지만 감기약 성분에 아세트아미노펜이 중복으로 포함되어 있을 수 있으니, 하루 권장 복용량을 넘지 않도록 주의해야 합니다. 제가 두 약품의 상세 DUR 정보를 확인해 드릴까요?'
    },
  ];

  // 메시지 전송 기능
  void _sendMessage() {
    if (_textController.text.trim().isEmpty) return;

    setState(() {
      // 1. 내가 보낸 메시지 화면에 추가
      _messages.add({'isUser': true, 'text': _textController.text});
      _textController.clear();
    });

    // 스크롤 맨 아래로 내리기
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });

    // 2. 1.5초 뒤에 AI가 대답하는 척 (더미 응답 추가)
    Future.delayed(const Duration(milliseconds: 1500), () {
      setState(() {
        _messages.add({
          'isUser': false,
          'text': 'AI 분석 중입니다... 더 정확한 처방을 위해서는 전문의와 상담하시는 것을 권장합니다 😊'
        });
      });
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // 전체 배경색
      body: Column(
        children: [
          // 1. 상단 AI 프로필 헤더 (홈 화면과 완벽 동일한 스타일 적용!)
          Container(
            padding: const EdgeInsets.only(top: 70, left: 20, right: 20, bottom: 30),
            decoration: const BoxDecoration(
              color: Color(0xFF2A8DE5), // 그라데이션 제거하고 통일!
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25), 
                bottomRight: Radius.circular(25)
              ),
            ),
            child: Row(
              children: [
                // AI 로고 아바타 (초록색 온라인 뱃지 포함)
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 50, height: 50,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.smart_toy, color: Color(0xFF2A8DE5), size: 28),
                    ),
                    Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 15),
                // AI 이름 및 상태
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PillBot (필봇)', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 2),
                    Text('24시간 건강 지키미', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // 2. 대화창 (말풍선 리스트) 영역
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['isUser'];

                return _buildChatBubble(message['text'], isUser);
              },
            ),
          ),

          // 3. 하단 메시지 입력창 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea( // 아이폰 하단 홈 바에 안 가려지게 보호
              top: false,
              child: Row(
                children: [
                  // 입력 텍스트 필드
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '궁금한 내용을 입력하세요...',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                        filled: true,
                        fillColor: const Color(0xFFF1F3F5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (value) => _sendMessage(), // 키보드 엔터 치면 전송
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 전송 버튼 (그라데이션)
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 45, height: 45,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2A8DE5), Color(0xFF00BFA5)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- UI 재사용 컴포넌트: 말풍선 그리기 ---
  Widget _buildChatBubble(String text, bool isUser) {
    return Align(
      // 내가 보낸 건 오른쪽, AI가 보낸 건 왼쪽 정렬
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        // 최대 너비 제한을 둬서 글자가 너무 길면 알아서 줄바꿈 되게 설정
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2A8DE5) : const Color(0xFFF0F7FF),
          // 말풍선 꼬리 디테일! (내가 보낸 건 오른쪽 아래가 뾰족, AI는 왼쪽 아래가 뾰족)
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 5, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 14,
            height: 1.4, // 줄간격 살짝 넓혀서 가독성 업!
            color: isUser ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}