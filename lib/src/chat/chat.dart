import 'package:adiubear/src/models/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:adiubear/src/pages/settings_page.dart';
import 'package:adiubear/src/pages/settings_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:adiubear/src/core_components/custom_theme.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /*
[
  {
    'email': rwrf2@gmail.com,
    'id': user1,
  },
  {
    'email': rj89@gmail.com,
    'id': user2,
  },
]
   */
  Stream<List<Map<String, dynamic>>> getUsersStream() {
    return _firestore.collection('Users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Future<void> sendMessage(String receiverId, String message) async {
    final senderID = _auth.currentUser!.uid;
    final senderEmail = _auth.currentUser!.email;
    final timeStamp = Timestamp.now();

    Message newMessage = Message(
      senderID: senderID,
      senderEmail: senderEmail!,
      receiverID: receiverId,
      message: message,
      timestamp: timeStamp,
    );

    List<String> ids = [senderID, receiverId];
    ids.sort();
    String chatRoomID = ids.join('_');
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  Stream<QuerySnapshot> getMessages(String userID, String otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = ids.join('_');
    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy("timestamp", descending: false)
        .snapshots();
  }

  /// Sends a message to Gemini, stores the user message, calls the Gemini API, and stores the bot response.
  Future<void> sendMessageToGemini(String message) async {
    final userId = _auth.currentUser!.uid;
    // Store user message
    await sendMessage('gemini', message);
    // Call Gemini API
    final aiResponse = await getGeminiResponse(message);
    // Send bot message back to user
    await sendBotMessage(userId, aiResponse);
  }

  /// Calls the Gemini API to get a response for the given prompt.
  Future<String> getGeminiResponse(String prompt) async {
    final model = FirebaseVertexAI.instance.generativeModel(
        model: 'gemini-2.0-flash',
        systemInstruction: Content.text(
            'You are a compassionate and knowledgeable AI parenting assistant. Your role is to support caregivers with practical advice, emotional reassurance, and evidence-based parenting strategies.You specialize in child development, positive discipline, and effective communication with children from infancy to adolescence. Always respond with empathy and encouragement, without judgment. Provide suggestions that are age-appropriate and culturally sensitive. When asked about medical or mental health concerns, remind the user to consult a licensed professional.Your tone should be warm, supportive, and clear. Include real-life examples when helpful, and avoid using overly technical language unless specifically requested. Never promote physical punishment, biased views, or advice that may harm a child\'s well-being. Your goal is to empower and uplift caregivers on their parenting journey.'));
    final chat = model.startChat();
    final response = await chat.sendMessage(Content.text(prompt));
    return response.text!;
  }

  /// Sends a bot-generated message directly to Firestore.
  Future<void> sendBotMessage(String userId, String message) async {
    const botId = 'gemini';
    const botEmail = 'gemini@google.com';
    final timeStamp = Timestamp.now();

    Message botMessage = Message(
      senderID: botId,
      senderEmail: botEmail,
      receiverID: userId,
      message: message,
      timestamp: timeStamp,
    );
    List<String> ids = [botId, userId];
    ids.sort();
    String chatRoomID = ids.join('_');
    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomID)
        .collection('messages')
        .add(botMessage.toMap());
  }
}
