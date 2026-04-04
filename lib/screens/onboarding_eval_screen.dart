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
import 'chat_screen.dart';

class OnboardingEvalScreen extends StatefulWidget {
  const OnboardingEvalScreen({super.key});

  @override
  State<OnboardingEvalScreen> createState() => _OnboardingEvalScreenState();
}

class _OnboardingEvalScreenState extends State<OnboardingEvalScreen> {
  static const String _apiUrl = String.fromEnvironment('API_BASE_URL');
  static const int _evalQuestionCount = 10;

  static const List<String> _allPrompts = [
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

  static const Map<String, String> _allExpectedAnswers = {
    "What is the best way to prepare the land before planting rice?":
        "There is no single best method, as the choice between wetland and dryland tillage depends on factors such as water supply, soil characteristics, crop establishment methods, and local resources. Wetland tillage involves tilling saturated or flooded soil, while dryland tillage prepares dry soil to create a firm seedbed and control weeds. Regardless of the method chosen, land preparation should be completed 21 days before transplanting to allow for organic matter decomposition and the eradication of weeds. A well-prepared field is characterized by thoroughly decayed organic materials, a puddled and leveled soil surface, and the elimination of competing weeds.",
    "How many kilos of rice seeds do I need to plant one hectare?":
        "They will need about 20-40 kilos/hectare on a wetbed plot, while 45-65 kilos/hectare on a dapog plot. ",
    "What is the difference between direct seeding and transplanting rice?":
        "Direct Seeding refers to the method of seeds being sown directly in the field, whereas the transplanting involves seedlings raised in seedbeds before planted on the fields",
    "How do I know if my rice is ready to be harvested?":
        "You can tell by gathering a spoonful of grain; if the hulled kernels are clear, translucent, and firm, the crop is ready. Another indicator is when 80-85% of the grains at the upper portion of the panicles are yellowish or straw-colored, or when those at the base are at the hard dough stage. Proper timing prevents losses from shattering, lodging, and pests.",
    "How can I control the golden kuhol (apple snail) in my rice field?":
        "Control GAS (Golden Apple Snail) by handpicking snails during the morning and late afternoon when they are most active or by placing bamboo stakes to easily collect and crush their egg masses. You can also use attractants like gabi or banana leaves and place wire screens on water inlets to prevent hatchlings from entering. Additionally, herding ducks into paddies 30-45 days after transplanting helps reduce the snail population.",
    "Why is it important to dry rice properly immediately after harvesting?":
        "Palay must be dried to a moisture content of 14% or below within 24 hours of harvest to prevent deterioration from heat and relative humidity. Failure to dry properly makes the grain more susceptible to active insects and diseases during storage. Furthermore, improper drying leads to grain fissures, which lowers milling efficiency and the overall market value.",
    "What is the best fertilizer combination to use to make rice grains heavier?":
        "Applying Potassium (K) is essential because it increases leaf area, the percentage of filled grains, and overall grain weight. A recommended basal application for soils deficient in this nutrient is a combination of 20-25 kg Nitrogen (N) and 20-30 kg Potassium (K2O). This can be achieved using one bag of urea mixed with one bag of 0-0-60 fertilizer.",
    "How do I control weeds in my rice field without using too much chemical spray?":
        "Effective non-chemical methods include hand-weeding or using rotary-weeders in straight-row transplanted rice when the soil is soft and saturated. Water management can also suppress weeds if a thin water blanket is introduced before weeds emerge above the soil surface. Proper land preparation, such as puddling and the 'stale seedbed technique,' further prevents weed growth.",
    "How much water does my rice field need during the growing stage?":
        "For medium to heavy-textured soils, the total irrigation requirement is approximately 700 to 1,500 mm of water per cropping season. During the active growing period, a water depth of around 5-7 cm should be maintained. However, shallower depths of 2-3 cm are recommended during the seedling and tillering stages to promote better growth.",
    "What is the best distance or spacing for planting cacao trees?":
        "The most common planting distances depend on the desired density: high density is 1.5 to 2.0 x 6.0 meters (2,300 trees/ha), while low density ranges from 2.5 x 2.5 meters (1,600 trees/ha) to 3 x 2 meters (1,666 trees/ha). If intercropping with coconut or cashew, the density averages about 600 plants per hectare.",
    "Why do young cacao trees need shade trees like bananas or coconut?":
        "Newly planted cocoa trees are particularly sensitive to high light levels and require 75% shade (25% direct sunlight) during their first year to prevent sunburn and planting stress. Ideal companion crops like coconut and banana provide this protection because they have tall trunks and thin canopies that do not defoliate seasonally.",
    "How do I know by looking if a cacao pod is ripe and ready for harvest?":
        "Ripeness is indicated by the color change of the pod; for example, the BR25 variety turns from reddish-green to yellow, while the K1 variety turns from young red to a yellow or orange hue when mature. Harvesting at the correct time is vital to ensure bean size and quality are not reduced.",
    "What is the proper way to cut a cacao pod from the tree without damaging the branch?":
        "To protect the flowering cushions on the tree, you should use secateurs to harvest the pods cleanly and safely. Avoid harvesting green pods or over-ripe pods, as this reduces the size and quality of the beans. ",
    "How do I ferment cacao beans?":
        "During fermentation, use properly constructed wooden boxes with slats, covering the beans with banana leaves and jute bags or cloth rags. It is important to drain the juices (sweatings) from the bean mass and turn the beans after 2 days (48 hours) and again after 4 days (96 hours).",
    "What should I do if my growing cacao pods turn black and rot?":
        "This condition, known as Black Pod Rot, should be managed by frequent harvesting to avoid pathogen spread and by burying or composting all infested, dead, or mummified pods. You should also prune the cacao and shade trees to reduce humidity and ensure the field has a good drainage system to prevent spores from spreading in puddles. ",
  };

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

    setState(() => _ratingSubmitted = true);

    await Future.delayed(const Duration(milliseconds: 1200));

    setState(() {
      _pendingRatingMessageIndex = null;
      _pendingQuestion = null;
      _pendingAnswer = null;
      _selectedRating = null;
      _ratingSubmitted = false;
    });

    if (!(_ratingCompleter?.isCompleted ?? true)) {
      _ratingCompleter!.complete(rating);
    }
  }

  Future<void> _onEvalComplete() async {
    _addBotMessage(
      "Great job! 🎉 You've completed the evaluation. "
      "You can now start chatting with Agri-Pinoy AI!",
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const ChatScreen(
            onboardingComplete: true,
            showWelcomeModal: true, // triggers modal + snackbar sequence
          ),
        ),
        (route) => false,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('onboarding_complete', true);
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (_) => const ChatScreen(onboardingComplete: true),
                  ),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Skip',
              style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
        title: Row(
          children: [
            const Icon(Icons.grass, color: Colors.white),
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
        if (_pendingQuestion != null &&
            _allExpectedAnswers.containsKey(_pendingQuestion)) ...[
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                "📖 Expected Answer (Book)",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.brown[700],
                ),
              ),
              children: [
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.brown[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.brown.shade200),
                  ),
                  child: Text(
                    _allExpectedAnswers[_pendingQuestion!]!,
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: Colors.brown[800],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.green[100]),
          const SizedBox(height: 12),
        ],
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
