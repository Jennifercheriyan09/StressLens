import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessage(
      text: message,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
    });
    _scrollToBottom();
    _controller.clear();

    try {
      final response = await http.post(
        Uri.parse('https://stress-api-lafw.onrender.com/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Extract the 'response' field from the JSON
        final botResponse = responseData['reply'] as String?;

        if (botResponse != null) {
          final botMessage = ChatMessage(
            text: botResponse,
            sender: MessageSender.bot,
            timestamp: DateTime.now(),
          );

          setState(() {
            _messages.add(botMessage);
          });
          _scrollToBottom();
        } else {
          _handleError('No response from the bot.');
        }
      } else {
        _handleError('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  void _handleError(String error) {
    final errorMessage = ChatMessage(
      text: error,
      sender: MessageSender.system,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(errorMessage);
    });
    _scrollToBottom();
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

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Type your message...',
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: const Color(0xFF0B3534),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: () => _sendMessage(_controller.text),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.support_agent, color: Color(0xFF0B3534)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Stress Support Bot',
                    style: TextStyle(fontSize: 16)),
                Text('Online',
                    style: TextStyle(fontSize: 12, color: Colors.green[300])),
              ],
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0B3534),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _messages[index].buildMessageBubble();
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}

enum MessageSender { user, bot, system }

class ChatMessage {
  final String text;
  final MessageSender sender;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });

  Widget buildMessageBubble() {
    bool isUser = sender == MessageSender.user;
    bool isSystem = sender == MessageSender.system;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF0B3534)
              : isSystem
              ? Colors.red[100]
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('HH:mm').format(timestamp),
              style: TextStyle(
                color: isUser ? Colors.white70 : Colors.black54,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}