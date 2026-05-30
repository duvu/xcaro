import 'package:flutter/foundation.dart';

class ChatMessage {
  final String senderId;
  final String content;
  final String timestamp;

  ChatMessage({
    required this.senderId,
    required this.content,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        senderId: json['sender_id'] as String? ?? '',
        content: json['content'] as String? ?? '',
        timestamp: json['timestamp'] as String? ?? '',
      );
}

class ChatProvider extends ChangeNotifier {
  final List<ChatMessage> _messages = [];

  List<ChatMessage> get messages => List.unmodifiable(_messages);

  void addMessage(Map<String, dynamic> json) {
    _messages.add(ChatMessage.fromJson(json));
    notifyListeners();
  }

  void clear() {
    _messages.clear();
    notifyListeners();
  }
}
