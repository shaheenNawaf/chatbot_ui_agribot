import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/message_model.dart';
import '../widgets/onboarding_modal.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
              10: "Test",
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
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: options.entries.map((entry) {
                          bool isSelected = chatProvider.topK == entry.key;
                          return InkWell(
                            onTap: () => chatProvider.setTopK(entry.key),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
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
                                style: GoogleFonts.roboto(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey[700],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
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
                          : "Test",
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      OnboardingModal.showIfRequired(context);
    });
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
                const Text(
                  "Pinoy-Agriculture AI Chat",
                  style: TextStyle(fontSize: 10, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
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

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
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
