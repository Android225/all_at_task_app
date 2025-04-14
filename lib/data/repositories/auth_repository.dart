import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    UserModel user = UserModel(
      uid: cred.user!.uid,
      name: name,
      email: email,
    );

    await _firestore.collection('users').doc(user.uid).set(user.toMap());

    return user;
  }

  Future<UserModel> logIn({
    required String email,
    required String password,
  }) async {
    UserCredential cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    DocumentSnapshot<Map<String, dynamic>> userDoc =
    await _firestore.collection('users').doc(cred.user!.uid).get();

    return UserModel.fromMap(userDoc.data()!);
  }

  Future<void> logOut() async {
    await _auth.signOut();
  }
}
