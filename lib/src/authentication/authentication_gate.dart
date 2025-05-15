import 'package:adiubear/src/authentication/assure_login.dart';
import 'package:adiubear/src/pages/home.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthenticationGate extends StatelessWidget {
  const AuthenticationGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: StreamBuilder(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return HomePage();
        } else {
          return const AssureLogin();
        }
      },
    ));
  }
}
