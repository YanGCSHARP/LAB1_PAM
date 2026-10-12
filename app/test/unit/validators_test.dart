import 'package:flutter_test/flutter_test.dart';
import 'package:walletmate/core/validation/validators.dart';

void main() {
  group('email', () {
    test('accepts a regular address, ignoring surrounding spaces', () {
      expect(Validators.email('demo@walletmate.md'), isNull);
      expect(Validators.email('  ion.rusu@student.utm.md '), isNull);
    });

    test('rejects empty input with a "required" message', () {
      expect(Validators.email(null), 'Введите email');
      expect(Validators.email('   '), 'Введите email');
    });

    test('rejects malformed addresses', () {
      for (final value in [
        'demo',
        'demo@',
        '@walletmate.md',
        'demo@walletmate',
        'demo@walletmate.m',
        'de mo@walletmate.md',
        'demo@@walletmate.md',
      ]) {
        expect(Validators.email(value), isNotNull, reason: value);
      }
    });

    test('rejects an address longer than 254 characters', () {
      final local = 'a' * 250;
      expect(Validators.email('$local@x.md'), isNotNull);
    });
  });

  group('loginPassword', () {
    test('only checks presence', () {
      expect(Validators.loginPassword(''), 'Введите пароль');
      expect(Validators.loginPassword(null), 'Введите пароль');
      expect(Validators.loginPassword('1'), isNull);
    });
  });

  group('newPassword', () {
    test('accepts the passwords from the API contract', () {
      expect(Validators.newPassword('Demo1234'), isNull);
      expect(Validators.newPassword('Student2026'), isNull);
    });

    test('accepts Cyrillic letters', () {
      expect(Validators.newPassword('пароль2026'), isNull);
    });

    test('requires 8 characters — 7 fail, 8 pass', () {
      expect(Validators.newPassword('Demo123'), 'Минимум 8 символов');
      expect(Validators.newPassword('Demo1234'), isNull);
    });

    test('requires both a letter and a digit', () {
      expect(Validators.newPassword('12345678'), isNotNull);
      expect(Validators.newPassword('abcdefgh'), isNotNull);
    });

    test('rejects spaces and empty input', () {
      expect(Validators.newPassword('Demo 1234'), isNotNull);
      expect(Validators.newPassword(''), 'Придумайте пароль');
    });
  });

  group('passwordConfirmation', () {
    test('must match exactly', () {
      expect(Validators.passwordConfirmation('Demo1234', 'Demo1234'), isNull);
      expect(
        Validators.passwordConfirmation('demo1234', 'Demo1234'),
        'Пароли не совпадают',
      );
      expect(
        Validators.passwordConfirmation('', 'Demo1234'),
        'Повторите пароль',
      );
    });
  });

  group('displayName', () {
    test('1–100 characters after trimming', () {
      expect(Validators.displayName('Ion'), isNull);
      expect(Validators.displayName('И'), isNull);
      expect(Validators.displayName('   '), 'Введите имя');
      expect(Validators.displayName('a' * 100), isNull);
      expect(Validators.displayName('a' * 101), isNotNull);
    });
  });

  group('accountName', () {
    test('1–50 characters', () {
      expect(Validators.accountName('Карта Maib'), isNull);
      expect(Validators.accountName(''), 'Введите название счёта');
      expect(Validators.accountName('a' * 50), isNull);
      expect(Validators.accountName('a' * 51), isNotNull);
    });

    test('must be unique, ignoring case and spaces', () {
      const taken = ['Наличные', 'Сбережения'];
      expect(
        Validators.accountName(' наличные ', takenNames: taken),
        'Счёт с таким названием уже есть',
      );
      expect(Validators.accountName('Карта', takenNames: taken), isNull);
    });
  });

  group('openingBalance', () {
    test('is optional', () {
      expect(Validators.openingBalance(null), isNull);
      expect(Validators.openingBalance(''), isNull);
    });

    test('accepts zero and a negative balance', () {
      expect(Validators.openingBalance('0'), isNull);
      expect(Validators.openingBalance('-1 500,00'), isNull);
      expect(Validators.openingBalance('−250'), isNull);
    });

    test('rejects text and too many decimals', () {
      expect(Validators.openingBalance('abc'), isNotNull);
      expect(Validators.openingBalance('10,555'), isNotNull);
    });
  });

  group('amount', () {
    test('accepts ru and dot notation with up to two decimals', () {
      for (final value in [
        '125',
        '125,5',
        '125,50',
        '125.50',
        '1 234,50',
        '1 234,50',
        '1 234,50',
        '0,01',
      ]) {
        expect(Validators.amount(value), isNull, reason: value);
      }
    });

    test('rejects empty input', () {
      expect(Validators.amount(''), 'Введите сумму');
      expect(Validators.amount(null), 'Введите сумму');
    });

    test('must be strictly greater than zero', () {
      expect(Validators.amount('0'), 'Сумма должна быть больше нуля');
      expect(Validators.amount('0,00'), 'Сумма должна быть больше нуля');
      expect(Validators.amount('-5'), 'Сумма должна быть больше нуля');
    });

    test('allows at most two decimals', () {
      expect(
        Validators.amount('10,555'),
        'Не больше двух знаков после запятой',
      );
    });

    test('caps at 1 000 000 inclusive', () {
      expect(Validators.amount('1000000'), isNull);
      expect(Validators.amount('1000000,01'), 'Не больше 1 000 000');
    });

    test('rejects things that are not a number', () {
      for (final value in ['abc', '1,2,3', '1.2.3', ',', '12a', '1e5']) {
        expect(Validators.amount(value), isNotNull, reason: value);
      }
    });
  });

  group('budgetLimit', () {
    test('follows the amount rules with its own messages', () {
      expect(Validators.budgetLimit('1300'), isNull);
      expect(Validators.budgetLimit(''), 'Введите лимит');
      expect(Validators.budgetLimit('0'), 'Лимит должен быть больше нуля');
      expect(Validators.budgetLimit('2000000'), isNotNull);
    });
  });

  group('note', () {
    test('is optional and capped at 200 characters', () {
      expect(Validators.note(null), isNull);
      expect(Validators.note(''), isNull);
      expect(Validators.note('a' * 200), isNull);
      expect(Validators.note('a' * 201), 'Не длиннее 200 символов');
    });
  });

  group('selected', () {
    test('fails on null and on an empty string', () {
      expect(Validators.selected(null, 'Выберите счёт'), 'Выберите счёт');
      expect(Validators.selected('', 'Выберите счёт'), 'Выберите счёт');
      expect(Validators.selected('acc-1', 'Выберите счёт'), isNull);
    });
  });

  group('transactionDate', () {
    final now = DateTime(2026, 9, 18, 15, 30);

    test('is required', () {
      expect(Validators.transactionDate(null, now: now), 'Выберите дату');
    });

    test('accepts the past, today and tomorrow', () {
      expect(Validators.transactionDate(DateTime(2020), now: now), isNull);
      expect(
        Validators.transactionDate(DateTime(2026, 9, 18), now: now),
        isNull,
      );
      expect(
        Validators.transactionDate(DateTime(2026, 9, 19, 23, 59), now: now),
        isNull,
      );
    });

    test('rejects the day after tomorrow', () {
      expect(
        Validators.transactionDate(DateTime(2026, 9, 20), now: now),
        isNotNull,
      );
    });

    test('rolls over month ends', () {
      final endOfMonth = DateTime(2026, 9, 30);
      expect(
        Validators.transactionDate(DateTime(2026, 10), now: endOfMonth),
        isNull,
      );
      expect(
        Validators.transactionDate(DateTime(2026, 10, 2), now: endOfMonth),
        isNotNull,
      );
    });
  });

  group('budgetUnique', () {
    final taken = {Validators.budgetKey('food', '2026-09')};

    test('rejects a second budget for the same category and month', () {
      expect(
        Validators.budgetUnique('food', '2026-09', taken: taken),
        isNotNull,
      );
    });

    test('allows the same category in another month', () {
      expect(Validators.budgetUnique('food', '2026-10', taken: taken), isNull);
      expect(
        Validators.budgetUnique('transport', '2026-09', taken: taken),
        isNull,
      );
    });

    test('leaves a missing category to the "required" rule', () {
      expect(Validators.budgetUnique(null, '2026-09', taken: taken), isNull);
    });
  });

  group('parseAmount', () {
    test('reads ru and dot notation', () {
      expect(Validators.parseAmount('1 234,50'), 1234.5);
      expect(Validators.parseAmount('1234.5'), 1234.5);
      expect(Validators.parseAmount('−20'), -20);
    });

    test('returns null for anything else', () {
      expect(Validators.parseAmount(null), isNull);
      expect(Validators.parseAmount(''), isNull);
      expect(Validators.parseAmount('abc'), isNull);
      expect(Validators.parseAmount('1e5'), isNull);
    });
  });
}
