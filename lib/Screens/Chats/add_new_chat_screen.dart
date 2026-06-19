import 'dart:async';

import 'package:chat_app/Screens/Chats/chat_screen.dart';
import 'package:chat_app/Screens/Chats/new_chat_screen.dart';
import 'package:chat_app/functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddNewChatScreen extends StatefulWidget {
  const AddNewChatScreen({super.key, required this.userUid});
  final String userUid;
  @override
  State<AddNewChatScreen> createState() => _AddNewChatScreenState();
}

class _AddNewChatScreenState extends State<AddNewChatScreen> {
  bool isFocused = false;
  bool userFound = false;
  bool showProgressIndicator = false;
  Timer? _debounce;
  TextEditingController usernameController = TextEditingController();
  final _fire = FirebaseFirestore.instance;
  Future<bool> searchUserName(String username) async {
    var maybeUser = await _fire.collection('uids').doc(username.trim()).get();
    if (maybeUser.exists) {
      if (maybeUser['uid'] == widget.userUid) return false;
      return true;
    } else {
      return false;
    }
  }

  void showUnavailableDialog(BuildContext context, String textToShow) {
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

  Future<void> goToChatIfChatExists(String userUid, String otherUid) async {
    var otherData = await getUserDataWithUid(otherUid);
    String chatId = await getChatId(userUid, otherUid);
    DocumentSnapshot docSnap = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();
    if (!mounted) return;
    if (docSnap.exists) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            userUid: widget.userUid,
            chatId: chatId,
            otherUid: otherUid,
            otherUsername: usernameController.text.trim(), profilePic: otherData['profile'],
          ),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NewChatScreen(
            userUid: widget.userUid,
            otherUid: otherUid,
            otherUsername: usernameController.text.trim(),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    double availableHeight = screenHeight - keyboardHeight;
    return Scaffold(
      appBar: AppBar(automaticallyImplyLeading: true, title: Text("back"),),

      body: Column(
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
                color: isFocused
                    ? Colors.white.withAlpha(100)
                    : Color(0xff14161c),
              ),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    autofocus: true,
                    keyboardType: TextInputType.text,
                    onChanged: (fieldValue) async {
                      if (fieldValue != "") {
                        showProgressIndicator = true;
                        if (_debounce?.isActive ?? false) {
                          _debounce!.cancel();
                        }
                        _debounce = Timer(
                          Duration(milliseconds: 500),
                          () async {
                            bool result = await searchUserName(fieldValue);

                            if (usernameController.text.trim() !=
                                widget.userUid) {
                              setState(() {
                                userFound = result;
                              });
                            }
                          },
                        );
                        showProgressIndicator = false;
                      } else {
                        setState(() {
                          userFound = false;
                        });
                      }
                    },
                    cursorColor: Colors.white,
                    onTap: () {
                      setState(() {
                        isFocused = true;
                      });
                    },
                    controller: usernameController,
                    decoration: InputDecoration(
                      hint: Text(
                        "Search a Username",
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
                        duration: Duration(milliseconds: 500),
                        child: userFound
                            ? Icon(
                                Icons.check_rounded,
                                color: Colors.lightGreen,
                                weight: 1500,
                              )
                            : Icon(
                                Icons.close_rounded,
                                color: Colors.redAccent,
                                weight: 1500,
                              ),
                      )
                    : null,
              ],
            ),
          ),
          GestureDetector(
            onTap: () async {
              if (userFound) {
                goToChatIfChatExists(
                  widget.userUid,
                  await getUid(usernameController.text.trim()),
                );
              } else {
                if (usernameController.text != "") {
                  showUnavailableDialog(context, "No user found");
                } else {
                  showUnavailableDialog(context, "Please enter a username");
                }
              }
            },
            child: Container(
              width: MediaQuery.widthOf(context),
              margin: EdgeInsets.all(15),
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: userFound ? Color(0xffbb6dce) : Color(0xff26282e),
                borderRadius: BorderRadius.circular((50)),
              ),
              child: Text(
                "Add",
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
