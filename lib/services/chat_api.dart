import 'dart:convert';

import 'api_client.dart';

enum ChatSenderRole {
  user,
  system,
}

class ChatSession {
  final int sessionId;
  final DateTime? startedAt;
  final DateTime? createdAt;

  ChatSession({required this.sessionId, this.startedAt, this.createdAt});

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: (json['sessionId'] as num).toInt(),
      startedAt: _parseDateTime(json['startedAt'] as String?),
      createdAt: _parseDateTime(json['createdAt'] as String?),
    );
  }
}

class ChatMessage {
  final int messageId;
  final int sessionId;
  final ChatSenderRole senderRole;
  final String contents;
  final DateTime? createdAt;

  ChatMessage({
    required this.messageId,
    required this.sessionId,
    required this.senderRole,
    required this.contents,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = json['senderRole']?.toString().toLowerCase();
    return ChatMessage(
      messageId: (json['messageId'] as num).toInt(),
      sessionId: (json['sessionId'] as num).toInt(),
      senderRole: role == 'user'
          ? ChatSenderRole.user
          : ChatSenderRole.system,
      contents: json['contents'] as String? ?? '',
      createdAt: _parseDateTime(json['createdAt'] as String?),
    );
  }
}

class ChatAnswer {
  final ChatMessage userMessage;
  final ChatMessage assistantMessage;
  final List<String> referencedPills;
  final bool fallback;

  ChatAnswer({
    required this.userMessage,
    required this.assistantMessage,
    this.referencedPills = const [],
    this.fallback = false,
  });

  factory ChatAnswer.fromJson(Map<String, dynamic> json) {
    return ChatAnswer(
      userMessage: ChatMessage.fromJson(
        json['userMessage'] as Map<String, dynamic>,
      ),
      assistantMessage: ChatMessage.fromJson(
        json['assistantMessage'] as Map<String, dynamic>,
      ),
      referencedPills: (json['referencedPills'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      fallback: json['fallback'] as bool? ?? false,
    );
  }
}

class ChatApi {
  ChatApi({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ChatSession> createSession() async {
    final response = await _apiClient.post('/api/chats/sessions', auth: true);
    return ChatSession.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ChatSession>> getSessions() async {
    final response = await _apiClient.get('/api/chats/sessions', auth: true);
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => ChatSession.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ChatMessage>> getMessages(int sessionId) async {
    final response = await _apiClient.get(
      '/api/chats/sessions/$sessionId/messages',
      auth: true,
    );
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatAnswer> ask({
    required int sessionId,
    required String question,
    bool useMyCabinet = true,
    List<String> identifiedPills = const [],
  }) async {
    final response = await _apiClient.post(
      '/api/chats/sessions/$sessionId/messages',
      auth: true,
      body: {
        'question': question,
        'useMyCabinet': useMyCabinet,
        'identifiedPills': identifiedPills,
      },
    );
    return ChatAnswer.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }
}

DateTime? _parseDateTime(String? value) {
  return value == null || value.isEmpty ? null : DateTime.tryParse(value);
}
