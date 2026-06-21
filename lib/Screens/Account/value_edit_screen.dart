import 'package:chat_app/Screens/Account/email_verification_screen.dart';
import 'package:chat_app/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ValueEditScreen extends StatelessWidget {
  ValueEditScreen({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.currentUser,
  });
  final String label;
  final String value;
  final IconData icon;
  final User currentUser;
  final TextEditingController valueController = TextEditingController();

  Future<void> updateValue(String label) async {
    final fire = FirebaseFirestore.instance;
    WriteBatch updateBatch = fire.batch();
    switch (label) {
      case 'Name':
        var userRef = fire.collection('users').doc(currentUser.uid);
        var allChatsWithUser = await fire
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .get();
        updateBatch.set(userRef, {
          'name': valueController.text.trim(),
        }, SetOptions(merge: true));
        for (var doc in allChatsWithUser.docs) {
          updateBatch.set(doc.reference, {
            currentUser.uid: {'name': valueController.text.trim()},
          }, SetOptions(merge: true));
          updateBatch.set(doc.reference, {
            currentUser.uid: {'name': valueController.text.trim()},
          }, SetOptions(merge: true));
        }
        break;

      case 'Username':
        var uids = fire.collection('uids').doc(await getCurrentUsername());
        var userRef = fire.collection('users').doc(currentUser.uid);
        var allChatsWithUser = await fire
            .collection('chats')
            .where('participants', arrayContains: currentUser.uid)
            .get();
        updateBatch.set(userRef, {
          'username': valueController.text.trim().toLowerCase(),
        }, SetOptions(merge: true));
        for (var doc in allChatsWithUser.docs) {
          updateBatch.set(doc.reference, {
            currentUser.uid: {
              'username': valueController.text.trim().toLowerCase(),
            },
          }, SetOptions(merge: true));
        }
        uids.delete();
        var newUid = fire.collection('uids').doc(valueController.text.trim());
        updateBatch.set(newUid, {
          'uid': currentUser.uid,
        }, SetOptions(merge: true));
        break;

      case 'Email':
        currentUser.verifyBeforeUpdateEmail(
          valueController.text.trim().toLowerCase(),
        );
        break;
    }
    await updateBatch.commit();
  }

  @override
  Widget build(BuildContext context) {
    valueController.text = value;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.popUntil(context, ModalRoute.withName('/profile'));
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: Text("Edit $label"),
      ),
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
                autofocus: true,
                keyboardType: TextInputType.text,
                cursorColor: Colors.white,
                controller: valueController,
                decoration: InputDecoration(
                  label: Text("Your $label"),
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  icon: Icon(icon),
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
                  await updateValue(label);
                  if (!context.mounted) return;
                  if (label == "Email") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmailVerificationScreen(
                          newEmail: valueController.text.trim().toLowerCase(),
                        ),
                      ),
                    );
                  } else {
                    Navigator.popUntil(
                      context,
                      ModalRoute.withName('/profile'),
                    );
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
                    "Save",
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

/*

 */
