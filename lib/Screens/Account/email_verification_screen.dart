import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, required this.newEmail});
  final String newEmail;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? timer;

  Future<void> checkEmailVerified() async {
    try {
      await FirebaseAuth.instance.currentUser?.reload();

      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        timer?.cancel();

        if (!mounted) return;

        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);

        return;
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-token-expired') {
        timer?.cancel();

        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            return AlertDialog(
              title: const Text('Email Updated'),
              content: const Text(
                'Your email has been updated successfully.\n\n'
                'Please sign in again using your new email.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Ok', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );

        if (!mounted) return;

        Navigator.of(
          context,
          rootNavigator: true,
        ).popUntil((route) => route.isFirst);
      }
    }
  }

  void startChecking() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      await checkEmailVerified();
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    startChecking();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Confirm Your Email")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            backgroundColor: Colors.white,
            color: Color(0xffbb6dce),
          ),
        ],
      ),
    );
  }
}
