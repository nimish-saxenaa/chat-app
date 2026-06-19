import 'package:chat_app/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  const NewChatScreen({
    super.key,
    required this.userUid,
    required this.otherUid,
    required this.otherUsername,
  });
  final String userUid;
  final String otherUid;
  final String otherUsername;

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final TextEditingController controller = TextEditingController();

  Future<String> saveAndUpdate() async {
    final newChatRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(await getChatId(widget.userUid, widget.otherUid));
    WriteBatch batch = FirebaseFirestore.instance.batch();

    var messageRef = newChatRef.collection('messages').doc();

    batch.set(messageRef, {
      'text': controller.text,
      'whoSent': widget.userUid,
      'timeStamp': FieldValue.serverTimestamp(),
      'isRead' : false
    });
    var userData = await getUserDataWithUid(widget.userUid);
    var otherUserData = await getUserDataWithUid(widget.otherUid);
    batch.set(newChatRef, {
      'users': [
        userData['name'], userData['username'], otherUserData['name'], otherUserData['username']
      ],
      'participants': [widget.userUid, widget.otherUid],
      'lastMessage': controller.text,
      'lastTime': FieldValue.serverTimestamp(),
      'lastSender': widget.userUid,
      'unReadCount': {
        widget.otherUid: FieldValue.increment(1),
        widget.userUid: 0,
      },
      widget.userUid: {
        'name': userData['name'],
        'username': userData['username'],
        'profile' : userData['profile']
      },
      widget.otherUid: {
        'name': otherUserData['name'],
        'username': otherUserData['username'],
        'profile' : otherUserData['profile']
      },
    }, SetOptions(merge: true));
    await batch.commit();
    return newChatRef.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("@ ${widget.otherUsername}")),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Send Your First Message!",
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 60,
                    margin: EdgeInsets.only(
                      left: 15,
                      top: 5,
                      right: 5,
                      bottom: 5,
                    ),
                    padding: EdgeInsets.only(
                      left: 25,
                      top: 5,
                      right: 15,
                      bottom: 5,
                    ),

                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.all(Radius.circular(100)),
                    ),
                    child: TextField(
                      autofocus: true,
                      controller: controller,
                      decoration: InputDecoration(
                        hint: Text(
                          "Type Your Message...",
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    final newChatRef = FirebaseFirestore.instance
                        .collection('chats')
                        .doc(await getChatId(widget.userUid, widget.otherUid));
                    WriteBatch batch = FirebaseFirestore.instance.batch();

                    var messageRef = newChatRef.collection('messages').doc();

                    batch.set(messageRef, {
                      'text': controller.text,
                      'whoSent': widget.userUid,
                      'timeStamp': FieldValue.serverTimestamp(),
                      'isRead' : false
                    });
                    var userData = await getUserDataWithUid(widget.userUid);
                    var otherUserData = await getUserDataWithUid(widget.otherUid);
                    batch.set(newChatRef, {
                      'users': [
                        userData['name'], userData['username'], otherUserData['name'], otherUserData['username']
                      ],
                      'participants': [widget.userUid, widget.otherUid],
                      'lastMessage': controller.text,
                      'lastTime': FieldValue.serverTimestamp(),
                      'lastSender': widget.userUid,
                      'unReadCount': {
                        widget.otherUid: FieldValue.increment(1),
                        widget.userUid: 0,
                      },
                      widget.userUid: {
                        'name': userData['name'],
                        'username': userData['username'],
                        'profile' : userData['profile']
                      },
                      widget.otherUid: {
                        'name': otherUserData['name'],
                        'username': otherUserData['username'],
                        'profile' : otherUserData['profile']
                      },
                    }, SetOptions(merge: true));
                    await batch.commit();
                    controller.clear();

                    if (!context.mounted) return;
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return ChatScreen(
                            chatId: newChatRef.id,
                            userUid: widget.userUid,
                            otherUid: widget.otherUid,
                            otherUsername: widget.otherUsername, profilePic: otherUserData['profile'],
                          );
                        },
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(right: 15, left: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      color: Color(0xffbb6dce),
                    ),
                    width: 60,
                    height: 60,
                    child: Icon(Icons.send, size: 30),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
