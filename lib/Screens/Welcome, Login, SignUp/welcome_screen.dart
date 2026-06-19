import 'package:flutter/material.dart';

import '../../customwidgets.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double availableHeight = screenHeight - keyboardHeight;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          //LOGO
          Hero(
            tag: 'logo',
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset(
                'assets/logo.png',
                height: availableHeight * 0.18,
              ),
            ),
          ),
          //Title
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              "Chatly - Live Chatting App",
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800),
            ),
          ),

          BigPurpleButton(
            onTap: () {
              Navigator.pushNamed(context, 'Login');
            },
            text: 'Log in',
          ),
          BigPurpleButton(
            onTap: () {
              Navigator.pushNamed(context, 'SignUp');
            },
            text: 'Sign Up',
          ),
        ],
      ),
    );
  }
}