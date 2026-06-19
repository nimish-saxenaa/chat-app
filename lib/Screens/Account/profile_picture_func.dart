import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

Future<String> picker(ImageSource src) async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: src);
  File file = File(image!.path);
  return file.path;
}

Future<String> uploader(File file, String uid) async {
  final storageRef = FirebaseStorage.instance
      .ref()
      .child('profile_pictures')
      .child(uid);
  await storageRef.putFile(file);
  return await storageRef.getDownloadURL();
}

Future<File> cropImage(String imagePath) async {
  CroppedFile? croppedFile = await ImageCropper().cropImage(sourcePath: imagePath, aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1));
  return File(croppedFile!.path);
}

Future<void> saver(String url, String uid) async {
  var userRef = FirebaseFirestore.instance
      .collection('users')
      .doc(uid);
  await userRef.set({'profile': url}, SetOptions(merge: true));
}

void showCustomBox(String e, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Error'),
        content: Text(e),
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