import 'package:flutter/material.dart';

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
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
          ),

          InkWell(
            onTap: (){
              Navigator.pushNamed(context, 'Login');
            },
            child: Container(
              width: MediaQuery.widthOf(context),
              margin: EdgeInsets.all(15),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xffbb6dce),
                borderRadius: BorderRadius.circular((50)),
              ),
              child: Text(
                "Log in",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          InkWell(
            onTap: (){
              Navigator.pushNamed(context, 'SignUp');
            },
            child: Container(
              width: MediaQuery.widthOf(context),
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Color(0xffbb6dce),
                borderRadius: BorderRadius.circular((50)),
              ),
              child: Text(
                "Sign Up",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
