import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:uuid/uuid.dart';

import '../models/user_model.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    try {
      print('Starting signUp with email: $email, username: $username, name: $name');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        print('User created with uid: ${user.uid}');
        await user.updateDisplayName(name);

        final userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
        );

        print('Saving user to Firestore: users/${user.uid}');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        print('User saved successfully');

        print('Creating public profile for uid: ${user.uid}');
        await updatePublicProfile(user.uid, username, name);

        const uuid = Uuid();
        final listId = uuid.v4();
        print('Creating default list: lists/$listId');
        final mainList = {
          'id': listId,
          'name': 'Основной',
          'ownerId': user.uid,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'members': {user.uid: 'owner'},
          'sharedLists': [],
        };
        await _firestore.collection('lists').doc(listId).set(mainList);

        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('lists')
            .doc(listId)
            .set({
          'listId': listId,
          'addedAt': Timestamp.now(),
        });
        print('Default list created successfully');
      } else {
        print('User creation failed: user is null');
        throw Exception('User creation failed: user is null');
      }
    } catch (e) {
      print('SignUp error: $e');
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> updatePublicProfile(String userId, String username, String name) async {
    try {
      print('Creating public profile for userId: $userId, username: $username, name: $name');
      await _firestore.collection('public_profiles').doc(userId).set({
        'username': username,
        'name': name,
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));
      print('Public profile created successfully');
    } catch (e) {
      print('Failed to update public profile: $e');
      throw Exception('Failed to update public profile: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      print('Starting login with email: $email');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Login successful');
    } catch (e) {
      print('Login error: $e');
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      print('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('Password reset email sent');
    } catch (e) {
      print('Reset password error: $e');
      throw Exception('Failed to send reset email: $e');
    }
  }

  Future<void> signOut() async {
    try {
      print('Signing out');
      await _auth.signOut();
      print('Sign out successful');
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Failed to sign out: $e');
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}