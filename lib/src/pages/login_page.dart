import 'package:adiubear/src/authentication/authentication_sevice.dart';
import 'package:adiubear/src/core_components/custom_textfield.dart';
import 'package:adiubear/src/core_components/custom_button.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final void Function()? onTap;

  LoginPage({
    super.key,
    required this.onTap,
  });

  void login(BuildContext context) async {
    final authService = AuthenticationService();

    try {
      await authService.signInWithEmailPassword(
        _emailController.text,
        _passwordController.text,
      );
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.message_rounded,
            size: 60,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(
            height: 50,
          ),
          Text(
            "Welcome Back!",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontSize: 16,
            ),
          ),
          const SizedBox(
            height: 25,
          ),
          CustomTextField(
            hintText: "Enter your email",
            obscureText: false,
            controller: _emailController,
          ),
          const SizedBox(
            height: 10,
          ),
          CustomTextField(
            hintText: "Enter your password",
            obscureText: true,
            controller: _passwordController,
          ),
          const SizedBox(
            height: 25,
          ),
          CustomButton(
            name: "Login",
            onTap: () => login(context),
          ),
          const SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Not a member? ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  "Register now",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
