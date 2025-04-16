import 'package:all_at_task/presentation/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_at_task/main.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:all_at_task/data/services/service_locator.dart';
import 'package:all_at_task/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'firebase_mock.dart';
import 'widget_test.mocks.dart';

// Генерируем моки для FirebaseAuth
@GenerateMocks([FirebaseAuth, User])
void main() {
  // Мок для FirebaseAuth
  late MockFirebaseAuth mockFirebaseAuth;
  late MockUser mockUser;

  setUp(() async {
    // Настраиваем моки
    mockFirebaseAuth = MockFirebaseAuth();
    mockUser = MockUser();
    when(mockFirebaseAuth.currentUser).thenReturn(null); // Пользователь не авторизован

    // Инициализируем Firebase с моками
    setupFirebaseMocks(mockFirebaseAuth);

    // Инициализируем Firebase перед тестом
    await Firebase.initializeApp();

    // Настраиваем service locator
    setupServiceLocator();
    getIt.registerSingleton<AuthBloc>(AuthBloc());
  });

  tearDown(() {
    // Очищаем getIt после каждого теста
    getIt.reset();
  });

  testWidgets('LoginScreen displays correctly', (WidgetTester tester) async {
    // Рендерим приложение
    await tester.pumpWidget(const MyApp());

    // Даём BLoC обработать AuthCheck (ждём завершения асинхронных операций)
    await tester.pumpAndSettle();

    // Проверяем, что отображается LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);

    // Проверяем наличие заголовка "С возвращением!"
    expect(find.text('С возвращением!'), findsOneWidget);

    // Проверяем наличие поля для email
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);

    // Проверяем наличие кнопки "Войти"
    expect(find.widgetWithText(ElevatedButton, 'Войти'), findsOneWidget);

    // Проверяем наличие ссылки "Забыли пароль?"
    expect(find.text('Забыли пароль?'), findsOneWidget);
  });
}

// Файл firebase_mock.dart для настройки моков Firebase
class FirebaseMock {
  static void setupFirebaseMocks(MockFirebaseAuth mockFirebaseAuth) {
    // Здесь можно добавить дополнительные моки для Firestore, если нужно
  }
}