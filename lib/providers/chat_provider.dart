import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class ChatProvider with ChangeNotifier {
  final String _apiUrl = const String.fromEnvironment('API_BASE_URL');

  String? _sessionId;
  int _topK = 1;
  int get topK => _topK;

  void setTopK(int value) {
    _topK = value.clamp(1, 10);
    notifyListeners();
  }

  final List<String> _allPrompts = [
    "What is the best way to prepare the land before planting rice?",
    "How many kilos of rice seeds do I need to plant one hectare?",
    "What is the difference between direct seeding and transplanting rice?",
    "How do I know if my rice is ready to be harvested?",
    "How can I control the golden kuhol (apple snail) in my rice field?",
    "Why is it important to dry rice properly immediately after harvesting?",
    "What is the best fertilizer combination to use to make rice grains heavier?",
    "How do I control weeds in my rice field without using too much chemical spray?",
    "How much water does my rice field need during the growing stage?",
    "What is the best distance or spacing for planting cacao trees?",
    "Why do young cacao trees need shade trees like bananas or coconut?",
    "How do I know by looking if a cacao pod is ripe and ready for harvest?",
    "What is the proper way to cut a cacao pod from the tree without damaging the branch?",
    "How do I ferment cacao beans?",
    "What should I do if my growing cacao pods turn black and rot?",
  ];

  List<String> _currentPrompts = [];
  List<String> get currentPrompts => _currentPrompts;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ChatProvider() {
    newSession();
  }

  void _generateRandomPrompts() {
    final random = Random();
    final shuffled = List<String>.from(_allPrompts)..shuffle(random);
    _currentPrompts = shuffled.take(4).toList();
  }

  void newSession() {
    _sessionId = null;
    _messages.clear();
    _messages.add(
      ChatMessage(
        text: "Hi! I'm Agri-Pinoy AI. Ask me how to plant common Pinoy crops!",
        isUser: false,
        timestamp: DateTime.now(),
        isFallback: false,
      ),
    );
    _generateRandomPrompts();
    notifyListeners();
  }

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    _messages.add(
      ChatMessage(
        text: userText,
        isUser: true,
        timestamp: DateTime.now(),
        isFallback: false,
      ),
    );
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      await _fetchRealApiResponse(userText);
    } catch (e) {
      _messages.add(
        ChatMessage(
          text: "Connection Error: $e",
          isUser: false,
          timestamp: DateTime.now(),
          isFallback: true, // Treat network errors as a fallback scenario too
        ),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  // Future<void> _fetchMockResponse() async {
  //   await Future.delayed(const Duration(seconds: 2));

  //   String mockAnswer =
  //       "### 🌱 **Potato Cultivation Guide**\n\n"
  //       "Hello! Based on the data, here is the optimal plan:\n\n"
  //       "**1. 🧪 Fertilizer Recommendations:**\n"
  //       "   *   Use **Sulfate of Potash (SOP)** instead of Muriate (MOP).\n"
  //       "   *   📉 *Nitrogen:* Reduce usage if you planted legumes previously.\n\n"
  //       "**2. 📏 Planting Strategy:**\n"
  //       "   *   **Depth:** 10-15cm deep.\n"
  //       "   *   **Spacing:** 30cm between plants.\n\n"
  //       "💡 **Pro Tip:** Ensure adequate water supply during the *tuber bulking* stage!";

  //   _messages.add(
  //     ChatMessage(
  //       text: mockAnswer,
  //       isUser: false,
  //       relatedCrops: ["Rice", "Maize", "Potatoes"],
  //       timestamp: DateTime.now(),
  //       isFallback: true,
  //     ),
  //   );
  // }

  Future<void> _fetchRealApiResponse(String query) async {
    try {
      final Map<String, dynamic> payload = {
        "message": query,
        "top_k": _topK,
        "include_context": true,
      };
      if (_sessionId != null) {
        payload["session_id"] = _sessionId;
      }

      print("╔══ REQUEST ════════════════════════════");
      print("║ top_k   : $_topK");
      print("║ payload : ${jsonEncode(payload)}");
      print("╚═══════════════════════════════════════");

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      print("╔══ RESPONSE ═══════════════════════════");
      print("║ status  : ${response.statusCode}");
      print("║ top_k   : $_topK");
      print("║ body    : ${response.body}");
      print("╚═══════════════════════════════════════");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['session_id'] != null) {
          _sessionId = data['session_id'];
        }

        final String botAnswer = data['answer'];
        final List<String> crops = data['crops_used'] != null
            ? List<String>.from(data['crops_used'])
            : [];
        final List<String> chunks = [];
        if (data['context'] != null) {
          final RegExp exp = RegExp(r'^# (.+)$', multiLine: true);
          final matches = exp.allMatches(data['context'] as String);
          for (final m in matches) {
            if (m.group(1) != null) chunks.add(m.group(1)!);
          }
        }
        final String lowerAnswer = botAnswer.toLowerCase();
        bool isFallback = false;
        if (lowerAnswer.contains("can't find information") ||
            lowerAnswer.contains("i don't have information") ||
            lowerAnswer.contains("not mentioned in the provided context") ||
            lowerAnswer.contains("i cannot answer") ||
            lowerAnswer.contains("does not contain information") ||
            lowerAnswer.contains("i don't know") ||
            lowerAnswer.contains("there is no crop information") ||
            lowerAnswer.contains("There is no crop information") ||
            lowerAnswer.contains("I don't have information") ||
            lowerAnswer.contains("I have no information") ||
            lowerAnswer.contains("unfortunately") ||
            lowerAnswer.contains("unfortunately, there is no information") ||
            lowerAnswer.contains(
              "Unfortunately, I don't have any information",
            ) ||
            lowerAnswer.contains(
              "unfortunately, the provided crop information",
            ) ||
            lowerAnswer.contains("but the crop information provided") ||
            lowerAnswer.contains("i'm afraid the information provided") ||
            lowerAnswer.contains("i'm afraid the crop information provided") ||
            lowerAnswer.contains(
              "are not explicitly mentioned in the provided crop information",
            ) ||
            lowerAnswer.contains('There is no information') ||
            lowerAnswer.contains("There's no information provided") ||
            lowerAnswer.contains("There's no information") ||
            lowerAnswer.contains("I don't see any information") ||
            lowerAnswer.contains("I couldn't find any information") ||
            lowerAnswer.contains("there's no information") ||
            lowerAnswer.contains("there's no mention") ||
            lowerAnswer.contains("there is no mention") ||
            lowerAnswer.contains("there is no information")) {
          isFallback = true;
        }
        _messages.add(
          ChatMessage(
            text: botAnswer,
            isUser: false,
            relatedCrops: crops,
            checkedChunks: chunks,
            timestamp: DateTime.now(),
            isFallback: isFallback,
          ),
        );
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }
}
