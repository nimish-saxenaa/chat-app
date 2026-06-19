import 'package:chat_app/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatelessWidget {
  ChatScreen({
    super.key,
    required this.userUid,
    required this.chatId,
    required this.otherUid,
    required this.otherUsername,
    required this.profilePic,
  });
  final String userUid;
  final String otherUid;
  final String chatId;
  final String otherUsername;
  final String? profilePic;
  final TextEditingController controller = TextEditingController();
  final FocusNode textFieldFocus = FocusNode();
  final fire = FirebaseFirestore.instance;
  Future<void> readChat() async {
    var chatRef = fire.collection('chats').doc(chatId);
    chatRef.update({'unReadCount.$userUid': 0});
  }

  Future<void> readUnread(String messageId) async {
    var messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    await messageRef.update({'isRead': true});
  }

  Future<void> saveAndUpdate() async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    var chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

    var messageRef = chatRef.collection('messages').doc();

    batch.set(messageRef, {
      'text': controller.text,
      'whoSent': userUid,
      'timeStamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });

    batch.set(chatRef, {
      'lastMessage': controller.text,
      'lastTime': FieldValue.serverTimestamp(),
      'lastSender': userUid,
      'unReadCount': {otherUid: FieldValue.increment(1)},
    }, SetOptions(merge: true));

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.network(
                profilePic ?? '',
                height: kToolbarHeight-10,
                fit: BoxFit.fill,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/profile.jpg',
                    height: kToolbarHeight-10,
                    fit: BoxFit.fill,
                  );
                },
              ),
            ),
            Text("   $otherUsername"),
          ],
        ),
       bottom: PreferredSize(
         preferredSize: const Size.fromHeight(1),
         child: Container(
           color: Colors.white.withAlpha(30),
           height: 0.5,
         ),
       ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            StreamBuilder(
              stream: fire
                  .collection('chats')
                  .doc(chatId)
                  .collection('messages')
                  .orderBy('timeStamp', descending: true)
                  .snapshots(),
              builder: (context, messageSnapshot) {
                if (messageSnapshot.hasData) {
                  final texts = messageSnapshot.data?.docs;
                  if (texts!.isNotEmpty) {
                    readChat();
                    return Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: texts.length,
                        itemBuilder: (context, index) {
                          String whoSent = texts[index]['whoSent'];
                          final bool isUs = whoSent == userUid ? true : false;
                          final bool isNext;
                          if (index != 0) {
                            isNext = texts[index - 1]['whoSent'] == whoSent
                                ? true
                                : false;
                          } else {
                            isNext = false;
                          }
                          final bool wasPrev;
                          if (index != texts.length - 1) {
                            wasPrev = texts[index + 1]['whoSent'] == whoSent
                                ? true
                                : false;
                          } else {
                            wasPrev = false;
                          }
                          bool areSameDay = isSameDay(
                            now: texts[index]['timeStamp'] ?? Timestamp.now(),
                            prev:
                                texts[index < texts.length - 1
                                    ? index + 1
                                    : index]['timeStamp'] ??
                                Timestamp.now(),
                          );
                          if (!isUs) readUnread(texts[index].id);

                          return ChatBubble(
                            text: texts[index]['text'],
                            isUs: isUs,
                            isNext: isNext,
                            wasPrev: wasPrev,
                            timeStamp:
                                texts[index]['timeStamp'] ?? Timestamp.now(),
                            isSameDay: areSameDay,
                            isRead: texts[index]['isRead'] ?? false,
                          );
                        },
                      ),
                    );
                  }
                  return Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("No Messages...", style: TextStyle(fontSize: 20)),
                      ],
                    ),
                  );
                }

                return CircularProgressIndicator(color: Colors.red);
              },
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
                      focusNode: textFieldFocus,
                      controller: controller,
                      onSubmitted: (String value) async {
                        await saveAndUpdate();
                        controller.clear();
                        textFieldFocus.requestFocus();
                      },
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
                    await saveAndUpdate();
                    controller.clear();
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

class ChatBubble extends StatelessWidget {
  ChatBubble({
    super.key,
    required this.text,
    required this.isUs,
    required this.isNext,
    required this.wasPrev,
    required this.timeStamp,
    required this.isSameDay,
    required this.isRead,
  });
  final bool isSameDay;
  final bool isUs;
  final bool isNext;
  final bool wasPrev;
  final Radius yesRound = Radius.circular(18);
  final Radius noRound = Radius.circular(2);
  final String text;
  final Timestamp timeStamp;
  final bool isRead;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
      child: Column(
        crossAxisAlignment: isUs
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!isSameDay)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    DateFormat('d/M/y').format(timeStamp.toDate()),
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          Material(
            borderRadius: isUs
                ? BorderRadius.only(
                    bottomRight: isNext
                        ? noRound
                        : wasPrev
                        ? yesRound
                        : noRound,
                    topRight: wasPrev ? noRound : yesRound,
                    topLeft: yesRound,
                    bottomLeft: yesRound,
                  )
                : BorderRadius.only(
                    bottomLeft: isNext
                        ? noRound
                        : wasPrev
                        ? yesRound
                        : noRound,
                    topLeft: wasPrev ? noRound : yesRound,
                    topRight: yesRound,
                    bottomRight: yesRound,
                  ),
            color: isUs ? Color(0xffbb6dce) : Color(0xff282c34),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width / 1.8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      text.trim(),
                      style: TextStyle(fontSize: 20),
                      overflow: TextOverflow.visible,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('h:mm a').format(timeStamp.toDate()),
                          style: TextStyle(fontSize: 10),
                        ),
                        if (isUs)
                          Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: Icon(
                              isRead ? Icons.done_all : Icons.done,
                              size: 15,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
