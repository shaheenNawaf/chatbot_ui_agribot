import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';

class ChatProvider with ChangeNotifier {
  // Thank you Gemini, here's where you go in @khesir
  // ==========================================================
  // ⚙️ CONFIGURATION AREA (The "One-Liner" Changes)
  // ==========================================================

  // 1. SETTING: Change this to 'false' when your API is live!
  static const bool _useMockData = false;

  // 2. API URL:
  // For Web/Edge Localhost: "http://127.0.0.1:8000/chat"
  // For Real Online API:    "https://api.agri-pinoy.com/chat"
  final String _apiUrl = "https://thesisv2.onrender.com/chat";

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Kamusta! Ako si Agri-Pinoy Bot. Ask me how to plant your crops.",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ];

  List<ChatMessage> get messages => _messages;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // 1. Add User Message to UI immediately
    _messages.add(
      ChatMessage(text: userText, isUser: true, timestamp: DateTime.now()),
    );
    notifyListeners();

    // 2. Process Request (Mock or Real)
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
        ),
      );
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchMockResponse() async {
    await Future.delayed(
      const Duration(seconds: 2),
    ); // network delay kunyari pi

    String mockAnswer =
        "### 🌱 **Patatas Cultivation Guide**\n\n"
        "Hello! Based on the data, here is the optimal plan:\n\n"
        "**1. 🧪 Fertilizer Recommendations:**\n"
        "   *   Use **Sulfate of Potash (SOP)** instead of Muriate (MOP).\n"
        "   *   📉 *Nitrogen:* Reduce usage if you planted legumes previously.\n\n"
        "**2. 📏 Planting Strategy:**\n"
        "   *   **Depth:** 10-15cm deep.\n"
        "   *   **Spacing:** 30cm between plants.\n\n"
        "💡 **Pro Tip:** Ensure adequate water supply during the *tuber bulking* stage!";

    List<String> mockCrops = ["Rice", "Maize", "Potatoes"];

    _messages.add(
      ChatMessage(
        text: mockAnswer,
        isUser: false,
        relatedCrops: mockCrops,
        timestamp: DateTime.now(),
      ),
    );
  }

  // FOR THE REAL API NA
  Future<void> _fetchRealApiResponse(String query) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "message": query,
          "top_k": 3,
          "include_context": true,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final String botAnswer = data['answer'];
        // Handle cases where 'crops_used' might be null in the JSON
        final List<String> crops = data['crops_used'] != null
            ? List<String>.from(data['crops_used'])
            : [];

        _messages.add(
          ChatMessage(
            text: botAnswer,
            isUser: false,
            relatedCrops: crops,
            timestamp: DateTime.now(),
          ),
        );
      } else {
        throw Exception("Server returned ${response.statusCode}");
      }
    } catch (e) {
      rethrow; // Pass error to main try-catch block
    }
  }
}
