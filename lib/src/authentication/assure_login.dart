import 'package:flutter/material.dart';
import 'package:adiubear/src/pages/login_page.dart';
import 'package:adiubear/src/pages/register_page.dart';

class AssureLogin extends StatefulWidget {
  const AssureLogin({super.key});

  @override
  State<StatefulWidget> createState() => _AssureLoginState();
}

class _AssureLoginState extends State<AssureLogin> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginPage(
        onTap: togglePages,
      );
    } else {
      return RegisterPage(
        onTap: togglePages,
      );
    }
  }
}
