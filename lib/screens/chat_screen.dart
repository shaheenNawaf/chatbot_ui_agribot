import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/chat_provider.dart';
import '../models/message_model.dart';
import '../widgets/onboarding_modal.dart';
import '../widgets/google_form_modal.dart';
import '../services/device_id_service.dart';

class ChatScreen extends StatefulWidget {
  final bool onboardingComplete;
  final bool showWelcomeModal;

  const ChatScreen({
    super.key,
    this.onboardingComplete = false,
    this.showWelcomeModal = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showFeedbackBanner = false;

  @override
  void initState() {
    super.initState();

    // Always show the feedback banner on every launch
    _checkFeedbackBanner();

    if (!widget.onboardingComplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        OnboardingModal.showIfRequired(context);
      });
    }

    // Show the welcome modal after eval, then snackbar after dismissal
    if (widget.showWelcomeModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showWelcomeModal();
      });
    }
  }

  Future<void> _checkFeedbackBanner() async {
    setState(() => _showFeedbackBanner = true);
  }

  void _dismissBanner() {
    setState(() => _showFeedbackBanner = false);
  }

  Future<void> _openFeedbackForm() async {
    final deviceId = await DeviceIdService.getDeviceId();
    if (mounted) {
      await GoogleFormModal.show(context, deviceId: deviceId);
      // Banner stays visible — only X dismisses it for the session
    }
  }

  Future<void> _showWelcomeModal() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.grass,
                  color: Color(0xFF2E7D32),
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "You're all set! 🎉",
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2E7D32),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "Thanks for completing the evaluation! You can now chat freely with Agri-Pinoy AI — ask anything about your crops.",
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showQuickPromptSnackbar();
                  },
                  child: Text(
                    "Start Chatting",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickPromptSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tip: Tap a quick prompt below or type your question to get started!',
                style: GoogleFonts.roboto(fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final Map<int, String> options = {
              1: "Concise",
              3: "Balanced",
              5: "Deep",
              10: "Ultra-Deep",
            };

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AI Response Depth",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF2E7D32),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Choose how detailed you want my answers to be.",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 25),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double fontSize = constraints.maxWidth < 320
                          ? 11
                          : 13;
                      return Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          children: options.entries.map((entry) {
                            bool isSelected = chatProvider.topK == entry.key;
                            return Expanded(
                              child: InkWell(
                                onTap: () => chatProvider.setTopK(entry.key),
                                borderRadius: BorderRadius.circular(15),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF2E7D32)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Text(
                                    entry.value,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.roboto(
                                      fontSize: fontSize,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 25),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chatProvider.topK == 1
                          ? "👋 Concise: Fast and short output."
                          : chatProvider.topK == 3
                          ? "⚖️ Balanced: A mix of explanation and direct tips."
                          : chatProvider.topK == 5
                          ? "📚 Deep: Comprehensive guide with technical details."
                          : "🧠 Ultra-Deep: Even more detailed responses",
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: const Color(0xFF2E7D32),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
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
                const Text(
                  "Your Pinoy Farming Assistant",
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.feedback_outlined, color: Colors.white),
            tooltip: "Feedback Form",
            onPressed: _openFeedbackForm,
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            tooltip: "Settings",
            onPressed: () => _showSettingsSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
            tooltip: "New Chat",
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).newSession();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showFeedbackBanner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.green[50],
              child: Row(
                children: [
                  const Text('🌾', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Enjoying Agri-Pinoy? Fill out our short feedback form!',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _openFeedbackForm,
                    child: Text(
                      'Open Form',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismissBanner,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.green[700],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(
                  context,
                  chatProvider.messages[index],
                );
              },
            ),
          ),
          if (chatProvider.isLoading)
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
          if (chatProvider.messages.length == 1 && !chatProvider.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Prompts:',
                    style: GoogleFonts.roboto(
                      color: Colors.green[800],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          if (chatProvider.messages.length == 1 && !chatProvider.isLoading)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: chatProvider.currentPrompts.map((prompt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2E7D32),
                        side: BorderSide(color: Colors.green[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        backgroundColor: Colors.white,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () {
                        chatProvider.sendMessage(prompt);
                      },
                      child: Text(
                        prompt,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.left,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Start typing here...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) {
                      chatProvider.sendMessage(val);
                      _controller.clear();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFF2E7D32),
                  radius: 24,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: () {
                      chatProvider.sendMessage(_controller.text);
                      _controller.clear();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg) {
    bool isUser = msg.isUser;
    bool isFallback = msg.isFallback;
    bool hasTags = msg.relatedCrops != null && msg.relatedCrops!.isNotEmpty;
    Color bubbleColor = isUser
        ? const Color(0xFF43A047)
        : (isFallback ? Colors.orange.shade50 : Colors.white);

    final double maxBubbleWidth = MediaQuery.of(context).size.width * 0.75;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: maxBubbleWidth),
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
            if (hasTags) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 8),
              Text(
                "🌾 Relevant Crops:",
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: msg.relatedCrops!.map((crop) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green[100]!),
                    ),
                    child: Text(
                      crop,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (msg.checkedChunks != null && msg.checkedChunks!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey[200]),
              const SizedBox(height: 8),
              Text(
                "📦 Checked Chunks:",
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  color: Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: msg.checkedChunks!.map((chunk) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Text(
                      chunk,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            if (isFallback) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: Text(
                    "Start New Chat",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                  onPressed: () {
                    Provider.of<ChatProvider>(
                      context,
                      listen: false,
                    ).newSession();
                  },
                ),
              ),
            ],
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
          ],
        ),
      ),
    );
  }
}
