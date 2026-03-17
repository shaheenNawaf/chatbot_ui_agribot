class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? relatedCrops;
  final bool isFallback;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    required this.isFallback,
    this.relatedCrops,
  });
}
