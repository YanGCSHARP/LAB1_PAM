/// Field validators of every form in the app.
///
/// Each one follows the `FormField.validator` contract: `null` means valid,
/// a string is the message shown under the field. They are pure functions of
/// their input, so they are unit-tested without pumping a single widget.
///
/// Limits mirror `docs/er-diagram.md`, so a value accepted here is also
/// accepted by the backend once it lands on L5.
abstract final class Validators {
  static const int passwordMinLength = 8;
  static const int emailMaxLength = 254;
  static const int displayNameMaxLength = 100;
  static const int accountNameMaxLength = 50;
  static const int noteMaxLength = 200;

  /// Upper bound of a single transaction, an opening balance and a budget.
  static const double maxAmount = 1000000;

  static final RegExp _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');
  static final RegExp _letter = RegExp(r'[A-Za-zА-Яа-яЁё]');
  static final RegExp _digit = RegExp(r'\d');

  /// Spaces a user or [NumberFormat] may put between digit groups: a plain
  /// space, a no-break space and the narrow no-break space of the ru locale.
  static final RegExp _groupSeparators = RegExp('[   ]');
  static final RegExp _number = RegExp(r'^-?\d+(\.\d+)?$');

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  static String? email(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Введите email';
    }
    if (text.length > emailMaxLength || !_email.hasMatch(text)) {
      return 'Неверный формат email, например you@example.com';
    }
    return null;
  }

  /// Password on the sign-in form: only presence is checked. Repeating the
  /// strength rules here would tell a stranger what the policy is.
  static String? loginPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Введите пароль';
    }
    return null;
  }

  /// Password chosen at registration: at least 8 characters with a letter
  /// and a digit, as in the API contract (`Demo1234`).
  static String? newPassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Придумайте пароль';
    }
    if (text.contains(' ')) {
      return 'Пароль не должен содержать пробелов';
    }
    if (text.length < passwordMinLength) {
      return 'Минимум $passwordMinLength символов';
    }
    if (!_letter.hasMatch(text) || !_digit.hasMatch(text)) {
      return 'Нужны хотя бы одна буква и одна цифра';
    }
    return null;
  }

  static String? passwordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Повторите пароль';
    }
    if (value != password) {
      return 'Пароли не совпадают';
    }
    return null;
  }

  static String? displayName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Введите имя';
    }
    if (text.length > displayNameMaxLength) {
      return 'Не длиннее $displayNameMaxLength символов';
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Accounts
  // ---------------------------------------------------------------------------

  /// Account names are unique per user; [takenNames] are the names of the
  /// user's other accounts, compared case-insensitively.
  static String? accountName(
    String? value, {
    Iterable<String> takenNames = const [],
  }) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Введите название счёта';
    }
    if (text.length > accountNameMaxLength) {
      return 'Не длиннее $accountNameMaxLength символов';
    }
    final normalized = text.toLowerCase();
    if (takenNames.any((name) => name.trim().toLowerCase() == normalized)) {
      return 'Счёт с таким названием уже есть';
    }
    return null;
  }

  /// Opening balance of an account. Optional — empty means zero — and may be
  /// negative: a credit card starts in debt.
  static String? openingBalance(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    return _amountShape(value, allowNegative: true);
  }

  // ---------------------------------------------------------------------------
  // Transactions and budgets
  // ---------------------------------------------------------------------------

  /// Transaction amount: strictly positive — the direction is carried by the
  /// income/expense switch, never by a minus sign.
  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите сумму';
    }
    final shapeError = _amountShape(value, allowNegative: false);
    if (shapeError != null) {
      return shapeError;
    }
    if (parseAmount(value)! <= 0) {
      return 'Сумма должна быть больше нуля';
    }
    return null;
  }

  static String? budgetLimit(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Введите лимит';
    }
    final shapeError = _amountShape(value, allowNegative: false);
    if (shapeError != null) {
      return shapeError;
    }
    if (parseAmount(value)! <= 0) {
      return 'Лимит должен быть больше нуля';
    }
    return null;
  }

  static String? note(String? value) {
    if (value != null && value.trim().length > noteMaxLength) {
      return 'Не длиннее $noteMaxLength символов';
    }
    return null;
  }

  /// A choice made through a picker — category, account, month.
  static String? selected(Object? value, String message) {
    if (value == null || (value is String && value.isEmpty)) {
      return message;
    }
    return null;
  }

  /// Operation date: required and not later than tomorrow. One day of slack
  /// covers a time zone ahead of the server, as in the data model.
  static String? transactionDate(DateTime? value, {DateTime? now}) {
    if (value == null) {
      return 'Выберите дату';
    }
    final today = now ?? DateTime.now();
    final latest = DateTime(today.year, today.month, today.day + 1);
    final day = DateTime(value.year, value.month, value.day);
    if (day.isAfter(latest)) {
      return 'Дата не может быть позже завтрашнего дня';
    }
    return null;
  }

  /// One budget per category and month; [taken] holds `category|YYYY-MM`
  /// pairs of the user's other budgets.
  static String? budgetUnique(
    String? category,
    String month, {
    required Set<String> taken,
  }) {
    if (category == null) {
      return null;
    }
    if (taken.contains(budgetKey(category, month))) {
      return 'На этот месяц бюджет по категории уже есть';
    }
    return null;
  }

  static String budgetKey(String category, String month) => '$category|$month';

  // ---------------------------------------------------------------------------
  // Parsing
  // ---------------------------------------------------------------------------

  /// Reads an amount typed in the ru format (`1 234,50`) or with a dot.
  /// Returns `null` for anything that is not a number.
  static double? parseAmount(String? value) {
    if (value == null) {
      return null;
    }
    final normalized = _normalize(value);
    if (!_number.hasMatch(normalized)) {
      return null;
    }
    return double.tryParse(normalized);
  }

  static String _normalize(String value) => value
      .trim()
      .replaceAll(_groupSeparators, '')
      .replaceAll(',', '.')
      .replaceAll('−', '-');

  static String? _amountShape(String value, {required bool allowNegative}) {
    final normalized = _normalize(value);
    if (!_number.hasMatch(normalized)) {
      return 'Введите число, например 125,50';
    }
    if (!allowNegative && normalized.startsWith('-')) {
      return 'Сумма должна быть больше нуля';
    }
    final dot = normalized.indexOf('.');
    if (dot != -1 && normalized.length - dot - 1 > 2) {
      return 'Не больше двух знаков после запятой';
    }
    if (double.parse(normalized).abs() > maxAmount) {
      return 'Не больше 1 000 000';
    }
    return null;
  }
}
