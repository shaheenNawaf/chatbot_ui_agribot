import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../providers/chat_provider.dart';
import '../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _showSettingsSheet(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Settings",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Document Retrieval (top_k)",
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "How many related documents the AI fetches",
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${chatProvider.topK}",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: chatProvider.topK.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    activeColor: const Color(0xFF2E7D32),
                    label: chatProvider.topK.toString(),
                    onChanged: (val) {
                      chatProvider.setTopK(val.round());
                      setSheetState(() {});
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("1 (faster)", style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey)),
                      Text("5 (more context)", style: GoogleFonts.roboto(fontSize: 11, color: Colors.grey)),
                    ],
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
                  "Gabay sa Pagsasaka",
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
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(chatProvider.messages[index]);
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

          // User Input box
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Tanong tungkol sa pananim...",
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

  //Reponse bubble ; with markdown nani for better ux
  Widget _buildMessageBubble(ChatMessage msg) {
    bool isUser = msg.isUser;
    // Check if we have chips to display - tyy
    bool hasTags = msg.relatedCrops != null && msg.relatedCrops!.isNotEmpty;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF43A047) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: isUser ? const Radius.circular(20) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(20),
          ),
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
              selectable: true, // Allows user to copy text
              styleSheet: MarkdownStyleSheet(
                p: GoogleFonts.roboto(
                  color: isUser ? Colors.white : Colors.black87,
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
                  color: isUser
                      ? Colors.white
                      : const Color(0xFF2E7D32), // Green headers for bot
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                listBullet: TextStyle(
                  color: isUser ? Colors.white : const Color(0xFF2E7D32),
                ),
              ),
            ),

            if (hasTags) ...[
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: isUser ? Colors.white24 : Colors.grey[200],
              ),
              const SizedBox(height: 8),
              Text(
                "Related Topics:",
                style: GoogleFonts.roboto(
                  fontSize: 10,
                  color: isUser ? Colors.white70 : Colors.grey[500],
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
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
                      color: isUser
                          ? Colors.white.withOpacity(0.2)
                          : Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUser ? Colors.white30 : Colors.green[100]!,
                      ),
                    ),
                    child: Text(
                      crop,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: isUser ? Colors.white : Colors.green[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
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
