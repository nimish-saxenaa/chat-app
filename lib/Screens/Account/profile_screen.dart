import 'package:chat_app/Screens/Account/profile_picture_func.dart';
import 'package:chat_app/Screens/Account/reauthenticate_screen.dart';
import 'package:chat_app/Screens/Account/value_edit_screen.dart';
import 'package:chat_app/functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.currentData});
  final Map<String, dynamic>? currentData;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late User currentUser = FirebaseAuth.instance.currentUser!;
  late Map<String, dynamic>? userData = widget.currentData;

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Do you want to log out?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
              },
              child: Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context); // close dialog

                await FirebaseAuth.instance.signOut();

                if (!context.mounted) return;

                Navigator.pop(context); // pop ProfileScreen
              },
              child: Text('Yes', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> deleter() async {
    final profileRef = FirebaseStorage.instance.refFromURL(
      userData?['profile'],
    );
    await profileRef.delete();
  }

  void setData() async {
    userData = await getUserDataWithUid(currentUser.uid);
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    setData();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.heightOf(context);
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(vertical: screenHeight / 20),
              child: Material(
                child: InkWell(
                  onTap: () async {
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
                                    await saver(
                                      await uploader(
                                        await cropImage(
                                          await picker(ImageSource.camera),
                                        ),
                                        currentUser.uid,
                                      ),
                                      currentUser.uid,
                                    );
                                    setData();
                                  } catch (e) {
                                    if(!context.mounted) return;
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
                                        padding: const EdgeInsets.only(
                                          right: 15,
                                        ),
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
                                    await saver(
                                      await uploader(
                                        await cropImage(
                                          await picker(ImageSource.gallery),
                                        ),
                                        currentUser.uid,
                                      ),
                                      currentUser.uid,
                                    );
                                    setData();
                                  } catch (e) {
                                    if(!context.mounted) return;
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
                                        padding: const EdgeInsets.only(
                                          right: 15,
                                        ),
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
                              InkWell(
                                onTap: () async {
                                  await deleter();
                                  setData();
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          right: 15,
                                        ),
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
                  child: Hero(
                    tag: 'profile',
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Image.network(
                        userData?['profile'] ?? '',
                        height: screenHeight * 0.18,
                        width: screenHeight * 0.18,
                        fit: BoxFit.fill,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/profile.jpg',
                            height: screenHeight * 0.18,
                            width: screenHeight * 0.18,
                            fit: BoxFit.fill,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            EditRow(
              icon: Icons.person,
              label: 'Name',
              value: userData?['name'] ?? "",
              currentUser: currentUser,
            ),
            EditRow(
              icon: Icons.alternate_email,
              label: 'Username',
              value: userData?['username'] ?? "",
              currentUser: currentUser,
            ),
            EditRow(
              icon: Icons.email,
              label: 'Email',
              value: currentUser.email!,
              currentUser: currentUser,
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                vertical: screenHeight / 20,
                horizontal: 20,
              ),
              child: InkWell(
                onTap: () {
                  showLogoutDialog(context);
                },
                child: Container(
                  width: double.maxFinite,
                  padding: EdgeInsets.all(7.5),
                  decoration: BoxDecoration(
                    color: Color(0xffbb6dce),
                    borderRadius: BorderRadius.circular((50)),
                  ),
                  child: Text(
                    "Log Out",
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

class EditRow extends StatelessWidget {
  const EditRow({
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
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
            child: Icon(icon, size: 30),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  value,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(80),
            onTap: () {
              if (label == 'Email') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ReAuthenticateScreen()),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ValueEditScreen(
                    label: label,
                    value: value == 'Empty' ? "" : value,
                    icon: icon,
                    currentUser: currentUser,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              child: Icon(Icons.edit, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
