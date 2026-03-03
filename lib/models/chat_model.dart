class ChatMessage {
  final String text;
  final DateTime timestamp;
  final bool isMe;

  ChatMessage({
    required this.text,
    required this.timestamp,
    required this.isMe,
  });
}
