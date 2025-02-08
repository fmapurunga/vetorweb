// app/controllers/profile_controller.dart
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Variável reativa para armazenar o nome do usuário
  var userName = ''.obs;

  Future<void> loadUserName() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData =
            await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && userData.data() != null) {
          userName.value = userData['name'] as String? ?? '';
        }
      }
    } catch (e) {
      userName.value = '';
      // Você pode exibir um snackbar ou logar o erro aqui, se necessário.
    }
  }

  Future<bool> updateUserName(String name) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set(
          {'name': name},
          SetOptions(merge: true),
        );
        userName.value = name;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}