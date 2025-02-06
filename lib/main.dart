
// main.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:whatsapp_vetor/screens/app_bar_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBfpC9XViZCx18UrfnEWL7YedyzEYc_ZmI",
      authDomain: "vetorwhatsapp280518.firebaseapp.com",
      projectId: "vetorwhatsapp280518",
      storageBucket: "vetorwhatsapp280518.firebasestorage.app",
      messagingSenderId: "744984685370",
      appId: "1:744984685370:web:6a6cb6d989e3de39f6be03",
      measurementId: "G-TJ1T2PPF79",
    )
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light().copyWith(
            scaffoldBackgroundColor: Colors.white,
          ),
          home: snapshot.hasData ? const AppBarScreen() : const LoginScreen(),
          routes: {
            '/home': (context) => const AppBarScreen(),
          },
        );
      },
    );
  }
}
