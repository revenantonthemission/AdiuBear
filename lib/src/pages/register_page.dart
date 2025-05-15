import 'package:adiubear/src/authentication/authentication_gate.dart';
import 'package:adiubear/src/authentication/authentication_sevice.dart';
import 'package:flutter/material.dart';
import 'package:adiubear/src/core_components/custom_textfield.dart';
import 'package:adiubear/src/core_components/custom_button.dart';

class RegisterPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _pwConfirmController = TextEditingController();

  final void Function()? onTap;

  RegisterPage({
    super.key,
    required this.onTap,
  });

  void register(BuildContext context) {
    final _auth = AuthenticationService();
    if (_passwordController.text == _pwConfirmController.text) {
      try {
        _auth.signUpWithEmailPassword(
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
    } else {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text("Passwords do not match!"),
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
            "Make a new account",
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
            height: 10,
          ),
          CustomTextField(
            hintText: "Confirm your password",
            obscureText: true,
            controller: _pwConfirmController,
          ),
          const SizedBox(
            height: 25,
          ),
          CustomButton(
            name: "Register",
            onTap: () => register(context),
          ),
          const SizedBox(
            height: 25,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Already have an account? ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              GestureDetector(
                onTap: onTap,
                child: Text(
                  "Login now",
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
