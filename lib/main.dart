import 'package:chat_app/Screens/Welcome, Login, SignUp/login_screen.dart';
import 'package:chat_app/Screens/Welcome,%20Login,%20SignUp/signup_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/Screens/Chats/all_chat_screen.dart';
import 'package:chat_app/Screens/Welcome,%20Login,%20SignUp/welcome_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'Screens/Account/create_username_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ChatlyApp());
}

class ChatlyApp extends StatelessWidget {
  const ChatlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xff14161c),
        fontFamily: 'Poppins',
        colorScheme: ColorScheme(
          brightness: Brightness.dark,
          primary: const Color(0xff14161c),
          onPrimary: Colors.white,
          secondary: const Color(0xff14161c),
          onSecondary: Colors.white,
          error: Colors.white,
          onError: Colors.white,
          surface: const Color(0xff14161c),
          onSurface: Colors.white,
        ),
      ),
      home: AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                backgroundColor: Colors.transparent,
              ),
            ),
          );
        }
        if (authSnapshot.data != null) {
          final user = authSnapshot.data!;
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Colors.transparent,
                    ),
                  ),
                );
              }
              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final data = userSnapshot.data!.data() as Map<String, dynamic>;
                if (data['username'] != null) {
                  return AllChatsScreen(userData: data, currentUser: user);
                }
              }
              return const CreateUsernameScreen();
            },
          );
        }
        return const AuthFlow();
      },
    );
  }
}

class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return Navigator(
      initialRoute: 'Welcome',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case 'Welcome':
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());

          case 'Login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());

          case 'SignUp':
            return MaterialPageRoute(builder: (_) => const SignUpScreen());

          default:
            return MaterialPageRoute(builder: (_) => const WelcomeScreen());
        }
      },
    );
  }
}

/*
initialRoute: 'AuthGate',
      routes: {
        'AuthGate': (context) => const AuthGate(),
        'Login': (context) => const LoginScreen(),
        'SignUp': (context) => const SignUpScreen(),
      },










      class AuthFlow extends StatelessWidget {
  const AuthFlow({super.key});

  @override
  Widget build(BuildContext context) {
    return
  }
}
 */
