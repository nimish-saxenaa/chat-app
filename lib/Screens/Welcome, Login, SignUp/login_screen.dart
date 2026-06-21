import 'package:chat_app/custom_widgets.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void updateFocus() {
    setState(() {
      isEmailFocused = emailFocus.hasFocus;
      isPassFocused = passFocus.hasFocus;
    });
  }

  FocusNode emailFocus = FocusNode();
  FocusNode passFocus = FocusNode();
  bool isEmailFocused = false;
  bool isPassFocused = false;
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  @override
  void initState() {
    super.initState();
    emailFocus.addListener(updateFocus);
    passFocus.addListener(updateFocus);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double availableHeight = screenHeight - keyboardHeight;
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
          ),
          //EmailField
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 7.5),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              border: Border.all(
                width: 1,
                color: isEmailFocused
                    ? Colors.white.withAlpha(100)
                    : Color(0xff14161c),
              ),
              borderRadius: BorderRadius.circular((50)),
            ),
            child: TextField(
              keyboardType: TextInputType.text,
              cursorColor: Colors.white,
              controller: emailController,
              focusNode: emailFocus,
              decoration: InputDecoration(
                hint: Text(
                  "Enter Your Email",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                icon: Icon(Icons.person),
                border: InputBorder.none,
              ),
              style: TextStyle(),
            ),
          ),
          //PassField
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 7.5),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              border: Border.all(
                width: 1,
                color: isPassFocused
                    ? Colors.white.withAlpha(100)
                    : Color(0xff14161c),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: TextField(
              keyboardType: TextInputType.text,
              cursorColor: Colors.white,
              obscureText: true,
              controller: passController,
              focusNode: passFocus,
              enableSuggestions: false,
              autocorrect: false,
              decoration: InputDecoration(
                hint: Text(
                  "Enter Your Password",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),

                icon: Icon(Icons.lock_outline_rounded),
                border: InputBorder.none,
              ),
              style: TextStyle(),
            ),
          ),
          //SignUpInstead?
          Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "New User?  ",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
                InkWell(
                  onTap: () {
                    Navigator.pushReplacementNamed(context, 'SignUp');
                  },
                  child: Text(
                    "Sign Up!",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xffbb6dce),
                      decoration: TextDecoration.underline,
                      decorationColor: Color(0xffbb6dce),
                      decorationThickness: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
          //Login
          BigPurpleButton(
            onTap: () async {
              final auth = FirebaseAuth.instance;
              try {
                await auth.signInWithEmailAndPassword(
                  email: emailController.text,
                  password: passController.text,
                );
                if (!context.mounted) return;
                Navigator.pop(context);
              } on FirebaseAuthException catch (e) {
                customAlertBox(e.toString(), context);
              }
            },
            text: 'Log in',
          ),
        ],
      ),
    );
  }
}
