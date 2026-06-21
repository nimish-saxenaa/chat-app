import 'dart:io';
import 'package:chat_app/custom_widgets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'profile_picture_func.dart';

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
  File? imgUrl;
  bool isUp = false;
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    nameFocus.addListener(updateFocus);
    usernameFocus.addListener(updateFocus);
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.heightOf(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: Hero(
          tag: 'logo',
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/logo.png'),
          ),
        ),
        title: Text("Create Your Profile"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Material(
              child: Hero(
                tag: 'profile',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: isUp
                      ? Image.file(
                          imgUrl!,
                          height: screenHeight * 0.18,
                          width: screenHeight * 0.18,
                          fit: BoxFit.fill,
                        )
                      : Image.asset(
                          'assets/profile.jpg',
                          height: screenHeight * 0.18,
                          width: screenHeight * 0.18,
                          fit: BoxFit.fill,
                        ),
                ),
              ),
            ),
          ),

          TextButton(
            onPressed: () async {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: () async {
                            try {
                              var a = await cropImage(
                                await picker(ImageSource.camera),
                              );

                              setState(() {
                                imgUrl = a;
                                isUp = true;
                              });
                            } catch (e) {
                              if (!context.mounted) return;
                              showCustomBox(e.toString(), context);
                            }
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: Icon(Icons.camera_alt, size: 30),
                                ),
                                Text(
                                  "Camera",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            try {
                              var a = await cropImage(
                                await picker(ImageSource.gallery),
                              );

                              setState(() {
                                imgUrl = a;
                                isUp = true;
                              });
                            } catch (e) {
                              if (!context.mounted) return;
                              showCustomBox(e.toString(), context);
                            }
                            if (!context.mounted) return;
                            Navigator.pop(context);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 15),
                                  child: Icon(Icons.photo, size: 30),
                                ),
                                Text(
                                  "Gallery",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isUp)
                          InkWell(
                            onTap: () async {
                              setState(() {
                                isUp = false;
                              });
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 15),
                                    child: Icon(Icons.delete, size: 30),
                                  ),
                                  Text(
                                    "Delete",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
            child: Text(
              isUp ? "Edit" : "Add a Profile Picture",
              style: TextStyle(
                color: Color(0xffbb6dce),
                decorationColor: Color(0xffbb6dce),
                decoration: TextDecoration.underline,
              ),
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
            onTap: () async {
              if (usernameAvailable && usernameController.text.isNotEmpty) {
                final auth = FirebaseAuth.instance;
                currentUser = auth.currentUser!;
                String? a;
                if (isUp) {
                  a = await uploader(imgUrl!, currentUser!.uid);
                }
                _fire.collection('users').doc(currentUser?.uid).set({
                  'name': nameController.text.isNotEmpty
                      ? nameController.text.trim()
                      : usernameController.text.trim(),
                  'username': usernameController.text.trim().toLowerCase(),
                  'profile': isUp ? a : "",
                }, SetOptions(merge: true));
                _fire
                    .collection('uids')
                    .doc(usernameController.text.trim())
                    .set({'uid': currentUser?.uid}, SetOptions(merge: true));
              } else {
                if (!context.mounted) return;
                customAlertBox('This username is unavailable', context);
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
