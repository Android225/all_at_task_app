import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      print('Начинаем регистрацию с email: $email, username: $username, name: $name');
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = userCredential.user;

      if (user != null) {
        print('Пользователь создан с uid: ${user.uid}');
        await user.updateDisplayName(name);

        final userModel = UserModel(
          uid: user.uid,
          name: name,
          email: email,
        );

        print('Сохраняем пользователя в Firestore: users/${user.uid}');
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(userModel.toMap());
        print('Пользователь успешно сохранен');

        print('Создаем публичный профиль для uid: ${user.uid}');
        try {
          await updatePublicProfile(user.uid, username, name);
          print('Публичный профиль успешно создан');
        } catch (e) {
          print('Ошибка при создании публичного профиля: $e');
          throw Exception('Не удалось создать публичный профиль: $e');
        }

        const uuid = Uuid();
        final listId = uuid.v4();
        print('Создаем список по умолчанию: lists/$listId');
        final mainList = {
          'id': listId,
          'name': 'Основной',
          'ownerId': user.uid,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'members': {user.uid: 'admin'}, // Изменено с 'owner' на 'admin'
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
        print('Список по умолчанию успешно создан');
      } else {
        print('Ошибка создания пользователя: пользователь null');
        throw Exception('Ошибка создания пользователя: пользователь null');
      }
    } catch (e) {
      print('Ошибка регистрации: $e');
      throw Exception('Не удалось зарегистрировать: $e');
    }
  }

  Future<void> updatePublicProfile(String userId, String username, String name) async {
    try {
      print('Пытаемся создать публичный профиль для userId: $userId, username: $username, name: $name');
      await _firestore.collection('public_profiles').doc(userId).set({
        'username': username,
        'name': name,
        'createdAt': Timestamp.now(),
      }, SetOptions(merge: true));
      print('Публичный профиль успешно создан в Firestore');
    } catch (e) {
      print('Ошибка обновления публичного профиля: $e');
      throw Exception('Не удалось обновить публичный профиль: $e');
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      print('Начинаем вход с email: $email');
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Вход выполнен успешно');
    } catch (e) {
      print('Ошибка входа: $e');
      throw Exception('Не удалось войти: $e');
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      print('Отправляем письмо для сброса пароля на: $email');
      await _auth.sendPasswordResetEmail(email: email);
      print('Письмо для сброса пароля отправлено');
    } catch (e) {
      print('Ошибка сброса пароля: $e');
      throw Exception('Не удалось отправить письмо для сброса: $e');
    }
  }

  Future<void> signOut() async {
    try {
      print('Выходим из системы');
      await _auth.signOut();
      print('Выход выполнен успешно');
    } catch (e) {
      print('Ошибка выхода: $e');
      throw Exception('Не удалось выйти: $e');
    }
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }
}