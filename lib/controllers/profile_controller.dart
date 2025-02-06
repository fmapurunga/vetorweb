// controllers/profile_controller.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUserName() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot userData = await _firestore.collection('users').doc(user.uid).get();
        if (userData.exists && userData.data() != null) {
          return userData['name'] as String? ?? '';
        }
      }
      return '';
    } catch (e) {
      return null;
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
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
