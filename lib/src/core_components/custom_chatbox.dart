import 'package:adiubear/src/core_components/custom_theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatBox extends StatelessWidget {
  final String message;
  final bool isCurrentUser;

  const ChatBox({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    bool isDarkMode =
        Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: isCurrentUser
            ? (isDarkMode ? Colors.green.shade600 : Colors.green.shade500)
            : (isDarkMode ? Colors.grey.shade900 : Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
      child: Text(
        message,
        style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
      ),
    );
  }
}
