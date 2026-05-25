import 'package:flutter/material.dart';
import '../../services/api_client.dart';
import '../../services/chat_api.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatApi _chatApi = ChatApi();
  int? _sessionId;
  bool _isSending = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'text':
          '안녕하세요, 홍길동님! SafePill AI 상담사 필봇입니다. 어떤 도움이 필요하신가요? 약물 복용 방법이나 상극 정보가 궁금하시다면 언제든 물어봐 주세요.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _ensureSession();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _ensureSession() async {
    try {
      final sessions = await _chatApi.getSessions();
      final session = sessions.isNotEmpty
          ? sessions.first
          : await _chatApi.createSession();
      if (mounted) {
        setState(() => _sessionId = session.sessionId);
        final serverMessages = await _chatApi.getMessages(session.sessionId);
        if (mounted && serverMessages.isNotEmpty) {
          setState(() {
            _messages
              ..clear()
              ..addAll(
                serverMessages.map(
                  (message) => {
                    'isUser': message.senderRole == ChatSenderRole.user,
                    'text': message.contents,
                  },
                ),
              );
          });
        }
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('채팅 세션 연결 실패: ${e.message}')));
      }
    }
  }

  Future<void> _sendMessage() async {
    final question = _textController.text.trim();
    if (question.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add({'isUser': true, 'text': question});
      _textController.clear();
    });
    _scrollToBottom();

    try {
      var sessionId = _sessionId;
      if (sessionId == null) {
        final session = await _chatApi.createSession();
        sessionId = session.sessionId;
        if (mounted) {
          setState(() => _sessionId = sessionId);
        }
      }
      final answer = await _chatApi.ask(
        sessionId: sessionId,
        question: question,
      );
      if (mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'text': answer.assistantMessage.contents,
          });
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({'isUser': false, 'text': '상담 요청 실패: ${e.message}'});
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!_scrollController.hasClients) {
        return;
      }
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
            padding: const EdgeInsets.only(
              top: 70,
              left: 20,
              right: 20,
              bottom: 30,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF2A8DE5), // 그라데이션 제거하고 통일!
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                // AI 로고 아바타 (초록색 온라인 뱃지 포함)
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.smart_toy,
                        color: Color(0xFF2A8DE5),
                        size: 28,
                      ),
                    ),
                    Container(
                      width: 14,
                      height: 14,
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
                    Text(
                      'PillBot (필봇)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '24시간 건강 지키미',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
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
                final isUser = message['isUser'] as bool;

                return _buildChatBubble(message['text'] as String, isUser);
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                '필봇이 답변을 준비 중입니다...',
                style: TextStyle(color: Colors.grey),
              ),
            ),

          // 3. 하단 메시지 입력창 영역
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[200]!)),
            ),
            child: SafeArea(
              // 아이폰 하단 홈 바에 안 가려지게 보호
              top: false,
              child: Row(
                children: [
                  // 입력 텍스트 필드
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: '궁금한 내용을 입력하세요...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF1F3F5),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
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
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2A8DE5), Color(0xFF00BFA5)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
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
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF2A8DE5) : const Color(0xFFF0F7FF),
          // 말풍선 꼬리 디테일! (내가 보낸 건 오른쪽 아래가 뾰족, AI는 왼쪽 아래가 뾰족)
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser
                ? const Radius.circular(18)
                : const Radius.circular(4),
            bottomRight: isUser
                ? const Radius.circular(4)
                : const Radius.circular(18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
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
