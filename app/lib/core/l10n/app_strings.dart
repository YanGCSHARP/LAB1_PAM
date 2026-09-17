/// All user-facing Russian strings in one place.
///
/// The project specification asks for `intl`/ARB localization; at this stage
/// the screens are static, so the strings live here and `intl` is used only for
/// money and date formatting. Moving to ARB later means replacing the bodies of
/// this file with `AppLocalizations` lookups, not editing every screen.
abstract final class AppStrings {
  // Common
  static const String appName = 'WalletMate';
  static const String save = 'Сохранить';
  static const String cancel = 'Отмена';
  static const String delete = 'Удалить';
  static const String edit = 'Изменить';
  static const String add = 'Добавить';
  static const String back = 'Назад';

  // Bottom navigation
  static const String navDashboard = 'Панель';
  static const String navTransactions = 'Транзакции';
  static const String navBudgets = 'Бюджеты';
  static const String navProfile = 'Профиль';

  // Auth
  static const String loginTitle = 'Вход';
  static const String loginSubtitle = 'Рады видеть снова';
  static const String registerTitle = 'Регистрация';
  static const String registerSubtitle = 'Создайте аккаунт за минуту';
  static const String tagline = 'Куда делись деньги в этом месяце?';
  static const String email = 'Email';
  static const String password = 'Пароль';
  static const String passwordConfirm = 'Повторите пароль';
  static const String displayName = 'Имя';
  static const String signIn = 'Войти';
  static const String signUp = 'Создать аккаунт';
  static const String forgotPassword = 'Забыли пароль?';
  static const String noAccountYet = 'Нет аккаунта? ';
  static const String alreadyHaveAccount = 'Уже есть аккаунт? ';
  static const String signInAction = 'Войти';
  static const String signUpAction = 'Зарегистрироваться';
  static const String emailHint = 'you@example.com';
  static const String displayNameHint = 'Как к вам обращаться';

  // Money
  static const String income = 'Доход';
  static const String expense = 'Расход';
}
