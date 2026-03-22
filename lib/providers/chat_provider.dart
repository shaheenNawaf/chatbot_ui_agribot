import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class ChatProvider with ChangeNotifier {
  // ==========================================================
  // ⚙️ CONFIGURATION AREA
  // ==========================================================
  static const bool _useMockData = false;
  final String _apiUrl = "http://165.22.247.173:8000/chat";
  // final String _apiUrl = "http://192.168.1.34:8000/chat";

  String? _sessionId;
  int _topK = 1;
  int get topK => _topK;

  void setTopK(int value) {
    _topK = value.clamp(1, 5);
    notifyListeners();
  }

  final List<String> _allPrompts = [
    "What is the best fertilizer for Cavendish bananas?",
    "How can I prevent Panama disease in my banana plantation?",
    "How do I induce flowering in mango trees during the off-season?",
    "What are the early signs of mango pulp weevil infestation?",
    "How do I control coconut scale insect infestations?",
    "What is the recommended spacing for planting hybrid coconuts?",
    "What is the ideal soil pH for planting sugarcane?",
    "How can I manage stem borer pests in my sugarcane field?",
    "What are the shade requirements for growing cacao seedlings?",
    "How do I treat black pod rot in cacao trees?",
    "What are the best practices for harvesting and drying abaca fibers?",
    "When is the best time to plant yellow corn for maximum yield?",
    "What is the proper way to cure onions after harvesting?",
    "What is the recommended fertilizer schedule for MD2 pineapples?",
  ];

  List<String> _currentPrompts = [];
  List<String> get currentPrompts => _currentPrompts;

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Constructor runs once on app start
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
      if (_useMockData) {
        await _fetchMockResponse();
      } else {
        await _fetchRealApiResponse(userText);
      }
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

  Future<void> _fetchMockResponse() async {
    await Future.delayed(const Duration(seconds: 2));

    String mockAnswer =
        "### 🌱 **Potato Cultivation Guide**\n\n"
        "Hello! Based on the data, here is the optimal plan:\n\n"
        "**1. 🧪 Fertilizer Recommendations:**\n"
        "   *   Use **Sulfate of Potash (SOP)** instead of Muriate (MOP).\n"
        "   *   📉 *Nitrogen:* Reduce usage if you planted legumes previously.\n\n"
        "**2. 📏 Planting Strategy:**\n"
        "   *   **Depth:** 10-15cm deep.\n"
        "   *   **Spacing:** 30cm between plants.\n\n"
        "💡 **Pro Tip:** Ensure adequate water supply during the *tuber bulking* stage!";

    _messages.add(
      ChatMessage(
        text: mockAnswer,
        isUser: false,
        relatedCrops: ["Rice", "Maize", "Potatoes"],
        timestamp: DateTime.now(),
        isFallback: true,
      ),
    );
  }

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

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['session_id'] != null) {
          _sessionId = data['session_id'];
        }

        final String botAnswer = data['answer'];
        final List<String> crops = data['crops_used'] != null
            ? List<String>.from(data['crops_used'])
            : [];
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
            lowerAnswer.contains("i'm afraid the crop information provided")) {
          isFallback = true;
        }
        _messages.add(
          ChatMessage(
            text: botAnswer,
            isUser: false,
            relatedCrops: crops,
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
