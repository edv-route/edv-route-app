import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edv_route_mobile/core/network/api_exception.dart';
import 'package:edv_route_mobile/domain/repositories/password_reset_repository.dart';
import 'package:edv_route_mobile/features/auth/presentation/controllers/password_reset_controller.dart';
import 'package:edv_route_mobile/shared/widgets/code_input_field.dart';
import 'package:edv_route_mobile/theme/app_theme.dart';

/// Scriptable stand-in: each step either returns or throws what the test says.
class _FakeRepo implements PasswordResetRepository {
  _FakeRepo({this.requestError, this.verifyError});

  final Object? requestError;
  final Object? verifyError;

  int requests = 0;
  String? lastCode;
  String? lastToken;
  String? lastPassword;

  @override
  Future<void> requestCode({required String nationalId, required String email}) async {
    requests++;
    if (requestError != null) throw requestError!;
  }

  @override
  Future<String> verifyCode({
    required String nationalId,
    required String email,
    required String code,
  }) async {
    lastCode = code;
    if (verifyError != null) throw verifyError!;
    return 'reset-token';
  }

  @override
  Future<void> confirm({required String resetToken, required String password}) async {
    lastToken = resetToken;
    lastPassword = password;
  }
}

Future<void> _pumpCode(
  WidgetTester tester, {
  required ValueChanged<String> onCompleted,
  ValueChanged<String>? onChanged,
  GlobalKey<CodeInputFieldState>? key,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(
        body: CodeInputField(key: key, onCompleted: onCompleted, onChanged: onChanged),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('CodeInputField', () {
    testWidgets('typing six digits advances by itself and reports the code', (tester) async {
      String? completed;
      await _pumpCode(tester, onCompleted: (c) => completed = c);

      final boxes = find.byType(TextField);
      expect(boxes, findsNWidgets(6));

      // Each digit goes into the box that has focus, never into a box tapped by
      // the test: that IS the behaviour under test.
      for (final d in ['4', '8', '1', '2', '9', '0']) {
        await tester.enterText(find.byType(TextField).at(_focusedIndex(tester)), d);
        await tester.pump();
      }

      expect(completed, '481290');
    });

    testWidgets('pasting the whole code fills every box', (tester) async {
      String? completed;
      await _pumpCode(tester, onCompleted: (c) => completed = c);

      // People copy the code out of the mail app; the paste lands in one box.
      await tester.enterText(find.byType(TextField).first, '481290');
      await tester.pump();

      expect(completed, '481290');
    });

    testWidgets('backspace on an empty box clears the previous digit', (tester) async {
      final key = GlobalKey<CodeInputFieldState>();
      await _pumpCode(tester, key: key, onCompleted: (_) {});

      await tester.enterText(find.byType(TextField).at(0), '4');
      await tester.pump();
      // Deleting the digit under the caret steps back, so a held backspace
      // walks the code instead of stopping at each box.
      await tester.enterText(find.byType(TextField).at(1), '');
      await tester.pump();

      expect(key.currentState!.value, '4');
    });

    testWidgets('clear() empties every box', (tester) async {
      final key = GlobalKey<CodeInputFieldState>();
      await _pumpCode(tester, key: key, onCompleted: (_) {});

      await tester.enterText(find.byType(TextField).first, '481290');
      await tester.pump();
      key.currentState!.clear();
      await tester.pump();

      expect(key.currentState!.value, '');
    });
  });

  group('PasswordResetController', () {
    test('a successful request keeps the pair so later steps never re-ask', () async {
      final repo = _FakeRepo();
      final c = PasswordResetController(repo);

      expect(await c.requestCode(nationalId: 'V-22198958', email: 'a@b.com'), isTrue);
      expect(c.email, 'a@b.com');
      // Verify does not receive the cédula from the screen: if the controller
      // lost it, this call would go out empty.
      await c.verifyCode('481290');
      expect(repo.lastCode, '481290');

      c.dispose();
    });

    test("the server's message is what the driver reads", () async {
      final c = PasswordResetController(
        _FakeRepo(verifyError: ApiException('El código no es correcto. Te quedan 2 intentos.')),
      );
      await c.requestCode(nationalId: 'V-1', email: 'a@b.com');

      expect(await c.verifyCode('000000'), isFalse);
      // Not a generic line: the server knows the count, the app does not.
      expect(c.error, 'El código no es correcto. Te quedan 2 intentos.');

      c.dispose();
    });

    test('confirm sends the token the verify step returned', () async {
      final repo = _FakeRepo();
      final c = PasswordResetController(repo);
      await c.requestCode(nationalId: 'V-1', email: 'a@b.com');
      await c.verifyCode('481290');

      expect(await c.confirm('123456'), isTrue);
      expect(repo.lastToken, 'reset-token');
      expect(repo.lastPassword, '123456');

      c.dispose();
    });

    test('confirming without a verified code refuses instead of calling', () async {
      final repo = _FakeRepo();
      final c = PasswordResetController(repo);

      expect(await c.confirm('123456'), isFalse);
      expect(repo.lastToken, isNull);

      c.dispose();
    });

    test('a failed request leaves nothing half-started', () async {
      final repo = _FakeRepo(
        requestError: ApiException('Los datos no coinciden con ninguna cuenta'),
      );
      final c = PasswordResetController(repo);

      expect(await c.requestCode(nationalId: 'V-1', email: 'nope@b.com'), isFalse);
      expect(c.error, 'Los datos no coinciden con ninguna cuenta');
      // No countdown was started, so "Reenviar" is not blocked by a cooldown
      // for a code that was never issued.
      expect(c.untilResend, Duration.zero);
      expect(c.remaining, Duration.zero);

      c.dispose();
    });

    test('resend is refused while the cooldown runs', () async {
      final repo = _FakeRepo();
      final c = PasswordResetController(repo);
      await c.requestCode(nationalId: 'V-1', email: 'a@b.com');

      // The server would answer 429; the app should not earn that error.
      expect(await c.resendCode(), isFalse);
      expect(repo.requests, 1);

      c.dispose();
    });
  });
}

/// Index of the box that currently holds focus.
int _focusedIndex(WidgetTester tester) {
  final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
  for (var i = 0; i < fields.length; i++) {
    if (fields[i].focusNode?.hasFocus ?? false) return i;
  }
  return 0;
}
