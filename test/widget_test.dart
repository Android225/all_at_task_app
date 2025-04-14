import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:all_at_task/main.dart';
import 'package:all_at_task/data/repositories/auth_repository.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {

    final authRepository = AuthRepository();

    await tester.pumpWidget(MyApp(authRepository: authRepository));

    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
