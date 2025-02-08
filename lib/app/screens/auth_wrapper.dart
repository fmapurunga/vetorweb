// app/screens/auth_wrapper.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'app_bar_screen.dart';
import 'login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Enquanto o stream estiver carregando, exibe um indicador
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        // Se o usuário estiver autenticado, navega para a tela principal
        if (snapshot.hasData) {
          // Opcional: você pode usar Get.offAllNamed(Routes.HOME) para remover
          // a tela de login da pilha de navegação
          return const AppBarScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}