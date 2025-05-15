import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class GeminiChatView extends StatefulWidget {
  const GeminiChatView({super.key});

  @override
  _GeminiChatViewState createState() => _GeminiChatViewState();
}

class _GeminiChatViewState extends State<GeminiChatView> {
  final _chatController = InMemoryChatController();
  final _uuid = const Uuid();
  final _currentUserId = 'user1'; // Your user's ID
  final _geminiUserId = 'gemini'; // A unique ID for the Gemini model

  // Replace with your actual Gemini service logic
  final _geminiService = GeminiService();

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _handleMessageSend(String text) async {
    // 1. Add the user's message to the UI immediately
    final userMessage = TextMessage(
      id: _uuid.v4(),
      authorId: _currentUserId,
      createdAt: DateTime.now().toUtc(),
      text: text,
    );
    _chatController.insertMessage(userMessage);

    // 2. Show a loading indicator (optional, but good UX)
    // You might add a system message or change the UI in some way

    try {
      // 3. Send the user's message to the Gemini service
      // This service will handle sending to the Gemini API and getting the response
      final geminiResponseText = await _geminiService.sendMessage(
        text,
        _chatController.messages, // Pass the message history
      );

      // 4. Add Gemini's response to the UI
      final geminiMessage = TextMessage(
        id: _uuid.v4(),
        authorId: _geminiUserId,
        createdAt: DateTime.now().toUtc(),
        text: geminiResponseText,
      );
      _chatController.insertMessage(geminiMessage);
    } catch (e) {
      // Handle errors (e.g., show an error message in the UI)
      print('Error sending message to Gemini: $e');
    } finally {
      // 5. Hide the loading indicator
    }
  }

  // In a real app, you would fetch user data for resolveUser
  Future<User> _resolveUser(UserID id) async {
    if (id == _currentUserId) {
      return const User(id: 'user1', name: 'You');
    } else if (id == _geminiUserId) {
      return const User(id: 'gemini', name: 'Gemini');
    }
    return User(id: id, name: 'Unknown User');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        chatController: _chatController,
        currentUserId: _currentUserId,
        onMessageSend: _handleMessageSend,
        resolveUser: _resolveUser,
      ),
    );
  }
}

// Placeholder for your Gemini service logic
// This would handle API calls, history management on the server side, etc.
class GeminiService {
  Future<String> sendMessage(String message, List<Message> history) async {
    // In a real implementation, you would call your backend service here
    // which in turn interacts with the Gemini API.
    // You would send 'message' and 'history' to your backend.
    // The backend would send these to the Gemini API and return the response.

    // Simulate a delay and a response from Gemini
    await Future.delayed(const Duration(seconds: 1));
    return 'This is a response from Gemini to: "$message"';
  }
}