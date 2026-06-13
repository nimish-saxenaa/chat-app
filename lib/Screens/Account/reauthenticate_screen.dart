
import 'package:chat_app/Screens/Account/value_edit_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReAuthenticateScreen extends StatelessWidget {
  ReAuthenticateScreen({super.key});
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController valueController = TextEditingController();

  void showInvalidDialog(BuildContext context, String textToShow) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Invalid'),
          content: Text(textToShow),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
              },
              child: Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify")),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: EdgeInsets.all(15),
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(20),
                border: Border.all(
                  width: 1,
                  color: Colors.white.withAlpha(100),
                ),
                borderRadius: BorderRadius.circular((50)),
              ),
              child: TextField(
                obscureText: true,
                autofocus: true,
                keyboardType: TextInputType.text,
                cursorColor: Colors.white,
                controller: valueController,
                decoration: InputDecoration(
                  label: Text("Current Password"),
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  icon: Icon(Icons.lock),
                  border: InputBorder.none,
                ),
                style: TextStyle(),
              ),
            ),
            Expanded(child: SizedBox()),
            Padding(
              padding: const EdgeInsets.all(15),
              child: InkWell(
                onTap: () async {
                  final credential = EmailAuthProvider.credential(
                    email: currentUser!.email!,
                    password: valueController.text.trim(),
                  );
                  try {
                    await currentUser!.reauthenticateWithCredential(credential);
                    if (!context.mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ValueEditScreen(
                          icon: Icons.email,
                          label: 'Email',
                          value: currentUser!.email!, currentUser: currentUser!,
                        ),
                      ),
                    );
                  } on FirebaseAuthException catch (e) {
                    if (!context.mounted) return;
                    showInvalidDialog(context, e.message.toString());
                  }
                },
                child: Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.all(7.5),
                  decoration: BoxDecoration(
                    color: Color(0xffbb6dce),
                    borderRadius: BorderRadius.circular((50)),
                  ),
                  child: Text(
                    "Next",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}