class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? relatedCrops; //Maps to the fake api crop list lmao

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.relatedCrops,
  });
}
