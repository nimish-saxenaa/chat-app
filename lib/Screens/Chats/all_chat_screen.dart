import 'package:chat_app/Screens/Chats/add_new_chat_screen.dart';
import 'package:chat_app/Screens/Chats/chat_screen.dart';
import 'package:chat_app/Screens/Account/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../functions.dart';

class AllChatsScreen extends StatelessWidget {
  AllChatsScreen({
    super.key,
    required this.currentUser,
    required this.userData,
  });
  final User? currentUser;
  final Map<String, dynamic> userData;
  late final String userUid = currentUser!.uid;
  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddNewChatScreen(userUid: userUid),
            ),
          );
        },
        backgroundColor: Color(0xff9646ab),
        shape: CircleBorder(side: BorderSide()),
        child: Icon(Icons.person_add_alt_1_rounded),
      ),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 15),
          child: Hero(tag: 'logo', child: Image.asset('assets/logo.png')),
        ),
        title: Center(
          child: Text(userData['username'], textAlign: TextAlign.center),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(currentData: userData),
                  settings: RouteSettings(name: '/profile'),
                ),
              );
            },
            child: Hero(
              tag: 'profile',
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(50),
                child: Image.network(
                  userData['profile'] ?? '',
                  fit: BoxFit.fill,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.asset('assets/profile.jpg', fit: BoxFit.fill);
                  },
                ),
              ),
            ),
          ),
        ],
        actionsPadding: EdgeInsets.all(15),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .orderBy('lastTime', descending: true)
            .where('participants', arrayContains: userUid)
            .snapshots(),
        builder: (context, chatsSnapshot) {
          if (chatsSnapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator(
              backgroundColor: Colors.transparent,
            );
          }
          final chats = chatsSnapshot.data!.docs;
          return chats.isNotEmpty
              ? ListView.builder(
                  itemCount: chats.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 7.5,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 15,
                          vertical: 5,
                        ),

                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.all(Radius.circular(100)),
                        ),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hint: Text(
                              "Search Chats...",
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),

                            icon: Icon(Icons.search),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(),
                        ),
                      );
                    }
                    final oneChat = chats[index - 1].data();
                    final String otherUid =
                        oneChat['participants'][0] != userUid
                        ? oneChat['participants'][0]
                        : oneChat['participants'][1];
                    return ChatRow(
                      userUid: userUid,
                      id: chats[index - 1].id,
                      lastSender: oneChat['lastSender'],
                      unReadCount: oneChat['unReadCount'][userUid],
                      lastTime: oneChat['lastTime'],
                      otherUid: otherUid,
                      lastMessage: oneChat['lastMessage'],
                      otherUsername: oneChat[otherUid]['username'],
                      otherName: oneChat[otherUid]['name'],
                      otherProfile: oneChat[otherUid]['profile'] ?? '',
                    );
                  },
                )
              : Center(child: Text("No Chats"));
        },
      ),
    );
  }
}

class ChatRow extends StatelessWidget {
  const ChatRow({
    super.key,
    required this.id,
    required this.userUid,
    required this.otherUid,
    required this.otherUsername,
    required this.otherName,
    required this.lastSender,
    required this.lastMessage,
    required this.unReadCount,
    required this.lastTime,
    required this.otherProfile,
  });

  final String id;
  final String userUid;
  final String otherUid;
  final String otherUsername;
  final String otherName;
  final String lastSender;
  final String lastMessage;
  final String otherProfile;
  final int unReadCount;
  final Timestamp? lastTime;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return ChatScreen(
                userUid: userUid,
                chatId: id,
                otherUid: otherUid,
                otherUsername: otherUsername,
                profilePic: otherProfile
              );
            },
          ),
        );
      },
      child: Container(
        width: MediaQuery.widthOf(context),
        height: MediaQuery.widthOf(context) / 5,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadiusGeometry.circular(50),
              child: Image.network(
                otherProfile,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset('assets/profile.jpg');
                },
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      lastSender == userUid ? "You: $lastMessage" : lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: unReadCount != 0
                          ? TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            )
                          : TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,

              children: [
                Text("   ${getWhen(lastTime)}"),
                unReadCount != 0
                    ? CircleAvatar(
                        backgroundColor: Color(0xffbb6dd1),
                        radius: 10,
                        child: Text(
                          unReadCount.toString(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: Colors.transparent,
                        radius: 10,
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
