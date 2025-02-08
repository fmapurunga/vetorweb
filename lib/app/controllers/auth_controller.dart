// app/controllers/auth_controller.dart
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Variável reativa que representa o usuário autenticado (pode ser nula)
  Rxn<User> firebaseUser = Rxn<User>();

  @override
  void onInit() {
    super.onInit();
    // Vincula a variável reativa ao stream de autenticação do Firebase
    firebaseUser.bindStream(_auth.authStateChanges());
  }

  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } catch (e) {
      return "Erro ao fazer login, e-mail ou senha inválidos";
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}