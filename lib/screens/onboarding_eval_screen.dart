import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/message_model.dart';
import '../services/device_id_service.dart';
import '../services/supabase_eval_service.dart';
import '../widgets/google_form_modal.dart';
import 'chat_screen.dart';

class OnboardingEvalScreen extends StatefulWidget {
  const OnboardingEvalScreen({super.key});

  @override
  State<OnboardingEvalScreen> createState() => _OnboardingEvalScreenState();
}

class _OnboardingEvalScreenState extends State<OnboardingEvalScreen> {
  static const String _apiUrl = "http://165.22.247.173:8000/chat";
  static const int _evalQuestionCount = 10;

  static const List<String> _allPrompts = [
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

  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  final List<String> _sessionQuestions = [];

  String? _deviceId;
  int _currentQuestionIndex = 0;
  bool _isLoading = false;
  String? _sessionId;

  int? _pendingRatingMessageIndex;

  int? _selectedRating;

  bool _ratingSubmitted = false;

  Completer<int>? _ratingCompleter;

  String? _pendingQuestion;
  String? _pendingAnswer;

  @override
  void initState() {
    super.initState();
    _initEvalSession();
  }

  Future<void> _initEvalSession() async {
    _deviceId = await DeviceIdService.getDeviceId();

    final shuffled = List<String>.from(_allPrompts)..shuffle(Random());
    _sessionQuestions.addAll(shuffled.take(_evalQuestionCount));

    _addBotMessage(
      "Hi! Before you start chatting, I'll ask you $_evalQuestionCount questions "
      "to help our team evaluate my responses. Please rate each one after it appears. 🌾",
    );

    await Future.delayed(const Duration(milliseconds: 600));
    _askNextQuestion();
  }

  // -------------------------------------------------------------------------
  // Message helpers
  // -------------------------------------------------------------------------

  void _addBotMessage(String text, {bool isFallback = false}) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: false,
          timestamp: DateTime.now(),
          isFallback: isFallback,
        ),
      );
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(
        ChatMessage(
          text: text,
          isUser: true,
          timestamp: DateTime.now(),
          isFallback: false,
        ),
      );
    });
    _scrollToBottom();
  }

  // -------------------------------------------------------------------------
  // Eval flow
  // -------------------------------------------------------------------------

  Future<void> _askNextQuestion() async {
    if (_currentQuestionIndex >= _evalQuestionCount) return;

    final question = _sessionQuestions[_currentQuestionIndex];
    _addUserMessage(question);

    setState(() => _isLoading = true);

    String answer;
    try {
      answer = await _fetchAnswer(question);
      _addBotMessage(answer);
    } catch (e) {
      answer = "Connection error: $e";
      _addBotMessage(answer, isFallback: true);
    }

    setState(() => _isLoading = false);

    // Show inline rating below the bot message we just added and await the result.
    final rating = await _showInlineRating(
      question: question,
      answer: answer,
      messageIndex: _messages.length - 1,
    );

    if (rating != null && _deviceId != null) {
      await SupabaseEvalService.saveEvalResponse(
        deviceId: _deviceId!,
        question: question,
        answer: answer,
        rating: rating,
        questionIndex: _currentQuestionIndex + 1,
      );
    }

    _currentQuestionIndex++;

    if (_currentQuestionIndex < _evalQuestionCount) {
      await Future.delayed(const Duration(milliseconds: 400));
      _askNextQuestion();
    } else {
      _onEvalComplete();
    }
  }

  Future<String> _fetchAnswer(String question) async {
    final Map<String, dynamic> payload = {
      "message": question,
      "top_k": 3,
      "include_context": true,
    };
    if (_sessionId != null) payload["session_id"] = _sessionId;

    print("╔══ EVAL REQUEST ════════════════════════");
    print("║ question : $question");
    print("║ payload  : ${jsonEncode(payload)}");
    print("╚════════════════════════════════════════");

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(payload),
    );

    print("╔══ EVAL RESPONSE ═══════════════════════");
    print("║ status : ${response.statusCode}");
    print("║ body   : ${response.body}");
    print("╚════════════════════════════════════════");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['session_id'] != null) _sessionId = data['session_id'];
      return data['answer'] as String;
    }

    throw Exception("Server returned ${response.statusCode}");
  }

  /// Attaches the inline rating widget to [messageIndex] and returns a Future
  /// that resolves with the submitted rating value once the user submits.
  Future<int?> _showInlineRating({
    required String question,
    required String answer,
    required int messageIndex,
  }) {
    _ratingCompleter = Completer<int>();

    setState(() {
      _pendingRatingMessageIndex = messageIndex;
      _pendingQuestion = question;
      _pendingAnswer = answer;
      _selectedRating = null;
      _ratingSubmitted = false;
    });

    _scrollToBottom();
    return _ratingCompleter!.future;
  }

  Future<void> _submitRating() async {
    if (_selectedRating == null) return;

    final rating = _selectedRating!;

    // Show the success animation.
    setState(() => _ratingSubmitted = true);

    // Let the animation play before collapsing the widget.
    await Future.delayed(const Duration(milliseconds: 1500));

    // Hide the inline rating widget.
    setState(() {
      _pendingRatingMessageIndex = null;
      _pendingQuestion = null;
      _pendingAnswer = null;
      _selectedRating = null;
      _ratingSubmitted = false;
    });

    // Resolve the completer so _askNextQuestion can continue.
    if (!(_ratingCompleter?.isCompleted ?? true)) {
      _ratingCompleter!.complete(rating);
    }
  }

  Future<void> _onEvalComplete() async {
    _addBotMessage(
      "Great job! 🎉 You've completed the evaluation. "
      "Please fill out the short form below so we can link your responses.",
    );

    await Future.delayed(const Duration(milliseconds: 600));

    if (mounted) {
      await GoogleFormModal.show(context, deviceId: _deviceId ?? '');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    if (mounted) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const ChatScreen()));
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            const Icon(Icons.agriculture, color: Colors.white),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Agri-Pinoy AI",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Evaluation Mode — ${_currentQuestionIndex.clamp(0, _evalQuestionCount)} of $_evalQuestionCount",
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildProgressBar(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) =>
                  _buildMessageBubble(_messages[index], index),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "Consulting expert data...",
                    style: GoogleFonts.roboto(
                      color: Colors.green[800],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final progress =
        _currentQuestionIndex.clamp(0, _evalQuestionCount) / _evalQuestionCount;
    return LinearProgressIndicator(
      value: progress,
      backgroundColor: Colors.green[100],
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
      minHeight: 4,
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, int index) {
    final bool isUser = msg.isUser;
    final bool isFallback = msg.isFallback;
    final Color bubbleColor = isUser
        ? const Color(0xFF43A047)
        : (isFallback ? Colors.orange.shade50 : Colors.white);

    final bool hasPendingRating =
        !isUser && _pendingRatingMessageIndex == index;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
          border: isFallback
              ? Border.all(color: Colors.orange.shade300, width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: msg.text,
              selectable: true,
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.roboto(
                  color: isUser
                      ? Colors.white
                      : (isFallback ? Colors.orange.shade900 : Colors.black87),
                  fontSize: 15,
                  height: 1.5,
                ),
                strong: GoogleFonts.roboto(
                  color: isUser ? Colors.white : Colors.black,
                  fontWeight: FontWeight.bold,
                ),
                em: GoogleFonts.roboto(
                  color: isUser ? Colors.white70 : Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                h3: GoogleFonts.poppins(
                  color: isUser ? Colors.white : const Color(0xFF2E7D32),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                listBullet: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                DateFormat('h:mm a').format(msg.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: isUser ? Colors.white70 : Colors.grey[400],
                ),
              ),
            ),

            // ---- Inline rating widget ----
            if (hasPendingRating) ...[
              const SizedBox(height: 12),
              Divider(height: 1, color: Colors.green[100]),
              const SizedBox(height: 12),
              _buildInlineRating(),
            ],
          ],
        ),
      ),
    );
  }

  /// Animated switcher between the rating tiles and the saved confirmation.
  Widget _buildInlineRating() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: _ratingSubmitted ? _buildSavedConfirmation() : _buildRatingTiles(),
    );
  }

  Widget _buildRatingTiles() {
    return Column(
      key: const ValueKey('rating_tiles'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "How relevant was that response?",
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "1 = Not relevant  ·  5 = Highly relevant",
          style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey[500]),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(5, (i) {
            final rating = i + 1;
            final isSelected = _selectedRating == rating;
            return GestureDetector(
              onTap: () => setState(() => _selectedRating = rating),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF2E7D32)
                      : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF2E7D32)
                        : Colors.green[200]!,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$rating',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : const Color(0xFF2E7D32),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.green[100],
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _selectedRating == null ? null : _submitRating,
            child: Text(
              "Submit",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSavedConfirmation() {
    return Container(
      key: const ValueKey('saved_confirmation'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: Color(0xFF2E7D32),
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            "Response saved!",
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ],
      ),
    );
  }
}
