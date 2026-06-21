import 'package:flutter/material.dart';

class BigPurpleButton extends StatelessWidget {
  const BigPurpleButton({super.key, required this.onTap, required this.text});
  final GestureTapCallback onTap;
  final String text;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: MediaQuery.widthOf(context),
        margin: EdgeInsets.all(15),
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Color(0xffbb6dce),
          borderRadius: BorderRadius.circular((50)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

void customAlertBox(String e, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Invalid'),
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