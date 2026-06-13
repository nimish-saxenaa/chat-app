import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

String getWhen(Timestamp? ts) {
  if (ts == null) {
    return "";
  }
  DateTime timeStamp = ts.toDate();

  DateTime now = DateTime.now();
  int difference = now.difference(timeStamp).inHours;
  if (now.day == timeStamp.day) {
    return DateFormat('h:mm a').format(timeStamp);
  } else if (difference < 48) {
    return 'Yesterday';
  } else {
    return DateFormat('d/M/y').format(timeStamp);
  }
}

bool isSameDay({required Timestamp now, required Timestamp prev}) {
  if (now == prev) {
    return false;
  } else {
    if (now.toDate().day == prev.toDate().day &&
        now.toDate().month == prev.toDate().month &&
        now.toDate().year == prev.toDate().year) {
      return true;
    } else {
      return false;
    }
  }
}

Future<String> getChatId(String uid1, String uid2) async {
  List uids = [uid1, uid2];
  uids.sort();
  return "${uids[0]}_${uids[1]}";
}

Future<String> getName(String uid) async {
  var userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  var name = userData['name'];
  return name ?? await getUsernameWithUid(uid);
}

Future<String> getUid(String user) async {
  var uidData = await FirebaseFirestore.instance
      .collection('uids')
      .doc(user)
      .get();
  return uidData['uid'];
}

Future<String> getCurrentUsername() async {
  var uid = FirebaseAuth.instance.currentUser?.uid;
  var userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  return userData['username'];
}

Future<String> getUsernameWithUid(String uid) async {
  var userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  return userData['username'];
}

Future<Map<String, String>> getUserDataWithUid(String uid) async {
  var userData = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();
  return {'username': userData['username'], 'name': userData['name']};
}
