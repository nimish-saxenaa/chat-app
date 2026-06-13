import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class CreateUsernameScreen extends StatefulWidget {
  const CreateUsernameScreen({super.key});

  @override
  State<CreateUsernameScreen> createState() => _CreateUsernameScreenState();
}

class _CreateUsernameScreenState extends State<CreateUsernameScreen> {
  FocusNode nameFocus = FocusNode();
  FocusNode usernameFocus = FocusNode();
  bool isNameFocused = false;
  bool isUsernameFocused = false;
  TextEditingController usernameController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  final _fire = FirebaseFirestore.instance;
  User? currentUser;
  bool usernameAvailable = false;
  Timer? _debounce;
  Future<bool> checkUsername(String fieldValue) async {
    var maybeUser = await _fire.collection('uids').doc(fieldValue.trim()).get();
    if (maybeUser.exists) {
      return false;
    } else {
      return true;
    }
  }

  void updateFocus() {
    setState(() {
      isNameFocused = nameFocus.hasFocus;
      isUsernameFocused = usernameFocus.hasFocus;
    });
  }

  void showUnavailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Invalid'),
          content: Text('This username is unavailable'),
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
  void initState() {
    // TODO: implement initState
    super.initState();
    nameFocus.addListener(updateFocus);
    usernameFocus.addListener(updateFocus);
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
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 7.5),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),

            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              border: Border.all(
                width: 1,
                color: isNameFocused
                    ? Colors.white.withAlpha(100)
                    : Color(0xff14161c),
              ),
              borderRadius: BorderRadius.circular((50)),
            ),
            child: TextField(
              keyboardType: TextInputType.text,
              cursorColor: Colors.white,
              controller: nameController,
              focusNode: nameFocus,
              decoration: InputDecoration(
                hint: Text(
                  "Enter a Name",
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                icon: Icon(Icons.person),
                border: InputBorder.none,
              ),
              style: TextStyle(),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 15, vertical: 7.5),
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              border: Border.all(
                width: 1,
                color: isUsernameFocused
                    ? Colors.white.withAlpha(100)
                    : Color(0xff14161c),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    focusNode: usernameFocus,
                    keyboardType: TextInputType.text,
                    onChanged: (fieldValue) {
                      _debounce?.cancel();

                      if (fieldValue.trim().isEmpty) {
                        setState(() {
                          usernameAvailable = false;
                        });
                        return;
                      }

                      _debounce = Timer(
                        const Duration(milliseconds: 500),
                        () async {
                          final result = await checkUsername(fieldValue);

                          if (!mounted) return;

                          setState(() {
                            usernameAvailable = result;
                          });
                        },
                      );
                    },
                    cursorColor: Colors.white,
                    controller: usernameController,
                    decoration: InputDecoration(
                      hint: Text(
                        "Enter a Username",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      icon: Icon(Icons.person),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(),
                  ),
                ),
                ?usernameController.text != ""
                    ? AnimatedSwitcher(
                        duration: Duration(milliseconds: 0),
                        child: usernameAvailable
                            ? Icon(
                                Icons.check,
                                color: Colors.lightGreen,
                                weight: 1500,
                              )
                            : Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                weight: 1500,
                              ),
                      )
                    : null,
              ],
            ),
          ),

          InkWell(
            onTap: () {
              if (usernameAvailable && usernameController.text.isNotEmpty) {
                final auth = FirebaseAuth.instance;
                currentUser = auth.currentUser!;
                nameController.text.isNotEmpty
                    ? _fire.collection('users').doc(currentUser?.uid).set({
                        'name': nameController.text.trim(),
                        'username': usernameController.text.trim(),
                      }, SetOptions(merge: true))
                    : _fire.collection('users').doc(currentUser?.uid).set({
                        'name': 'Empty',
                        'username': usernameController.text.trim(),
                      }, SetOptions(merge: true));
                _fire
                    .collection('uids')
                    .doc(usernameController.text.trim())
                    .set({'uid': currentUser?.uid}, SetOptions(merge: true));
              } else {
                showUnavailableDialog(context);
              }
            },
            child: Container(
              width: MediaQuery.widthOf(context),
              margin: EdgeInsets.all(15),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: usernameAvailable && usernameController.text.isNotEmpty
                    ? Color(0xffbb6dce)
                    : Color(0xff26282e), //,
                borderRadius: BorderRadius.circular((50)),
              ),
              child: Text(
                "Create Username",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight:
                      usernameAvailable && usernameController.text.isNotEmpty
                      ? FontWeight.w600
                      : FontWeight.w100,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}