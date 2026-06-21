import 'package:chat_app/Screens/Chats/add_new_chat_screen.dart';
import 'package:chat_app/Screens/Chats/chat_screen.dart';
import 'package:chat_app/Screens/Account/profile_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../functions.dart';

class AllChatsScreen extends StatefulWidget {
  const AllChatsScreen({
    super.key,
    required this.currentUser,
    required this.userData,
  });
  final User? currentUser;
  final Map<String, dynamic> userData;

  @override
  State<AllChatsScreen> createState() => _AllChatsScreenState();
}

class _AllChatsScreenState extends State<AllChatsScreen> {
  late final String userUid = widget.currentUser!.uid;

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
          child: Text(widget.userData['username'], textAlign: TextAlign.center),
        ),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileScreen(currentData: widget.userData),
                  settings: RouteSettings(name: '/profile'),
                ),
              );
            },
            child: Hero(
              tag: 'profile',
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(50),
                child: Image.network(
                  widget.userData['profile'] ?? '',
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
            return const Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.white,
                color: Color(0xffbb6dce),
              ),
            );
          }

          if (chatsSnapshot.hasError || !chatsSnapshot.hasData) {
            return const Center(child: Text("Something went wrong."));
          }

          final chats = chatsSnapshot.data!.docs;

          if (chats.isEmpty) {
            return const Center(child: Text("No Chats"));
          }

          return Column(
            children: [
              // Search bar lifted OUT of ListView
              Container(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),

                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.all(Radius.circular(100)),
                ),
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    hint: Text(
                      "Search Chats...",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),

                    icon: Icon(Icons.search),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(),
                ),
              ),

              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: searchController,
                  builder: (context, value, _) {
                    final query = value.text.trim().toLowerCase();

                    final filteredChats = query.isEmpty
                        ? chats
                        : chats.where((doc) {
                            final data = doc.data();
                            final participants = data['participants'] as List;
                            final otherUid = participants.firstWhere(
                              (uid) => uid != userUid,
                              orElse: () => '',
                            );
                            if (otherUid.isEmpty) return false;

                            final otherName = (data[otherUid]?['name'] ?? '')
                                .toLowerCase();
                            final otherUsername =
                                (data[otherUid]?['username'] ?? '')
                                    .toLowerCase();

                            return otherName.contains(query) ||
                                otherUsername.contains(query);
                          }).toList();

                    if (filteredChats.isEmpty) {
                      return const Center(child: Text("No results found."));
                    }

                    return ListView.builder(
                      itemCount: filteredChats.length,
                      itemBuilder: (context, index) {
                        final doc = filteredChats[index];
                        final data = doc.data();
                        final participants = data['participants'] as List;
                        final otherUid = participants[0] != userUid
                            ? participants[0]
                            : participants[1];

                        return ChatRow(
                          userUid: userUid,
                          id: doc.id,
                          lastSender: data['lastSender'],
                          unReadCount: data['unReadCount']?[userUid],
                          lastTime: data['lastTime'],
                          otherUid: otherUid,
                          lastMessage: data['lastMessage'],
                          otherUsername: data[otherUid]?['username'] ?? '',
                          otherName: data[otherUid]?['name'] ?? '',
                          otherProfile: data[otherUid]?['profile'] ?? '',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
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
                profilePic: otherProfile,
              );
            },
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        width: MediaQuery.widthOf(context),
        height: MediaQuery.widthOf(context) / 5,
        padding: EdgeInsets.symmetric(vertical: 9, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(15)
        ),
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
                padding: const EdgeInsets.only(left: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: otherName, style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                          ),),
                          TextSpan(text: "  @$otherUsername")

                        ]
                      ),
                    ),
                    Text(
                      lastSender == userUid ? "You: $lastMessage" : "$otherUsername: $lastMessage",
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