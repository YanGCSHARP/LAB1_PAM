# WalletMate

Приложение для учёта личных финансов: несколько счетов, доходы и расходы по категориям,
месячные бюджеты с порогом предупреждения и общая панель со структурой трат.

Отвечает на вопрос **«куда делись деньги в этом месяце?»**.

> **Статус:** этап L1 — спецификация. Кода приложения пока нет.

---

## Что умеет (план)

- Несколько счетов в разных валютах, баланс считается из транзакций
- Транзакции с категорией, счётом, датой и заметкой; поиск и фильтры по категории,
  типу и периоду
- Месячные бюджеты по категориям с прогрессом расходования
- Панель: балансы счетов, структура расходов по категориям в виде диаграммы,
  выделение категорий, превысивших 90% бюджета
- Работа offline с синхронизацией при появлении сети

---

## Стек

**Мобильное приложение**

| | |
|---|---|
| Framework | Flutter, Dart |
| UI | Material 3, светлая и тёмная темы |
| Навигация | go_router |
| State | Riverpod |
| Сеть | dio + JWT interceptor |
| Локальная БД | drift (SQLite) |
| Графики | fl_chart |
| Тесты | flutter_test, mocktail, integration_test |

**Backend**

| | |
|---|---|
| Платформа | ASP.NET Core Web API (.NET LTS) |
| ORM | EF Core |
| БД | SQLite (dev) / PostgreSQL (docker) |
| Auth | JWT Bearer |
| Документация | Swagger UI |
| Ошибки | ProblemDetails (RFC 7807) |

---

## Структура репозитория

```
walletmate/
├── app/          # Flutter-приложение
├── backend/      # .NET Web API
└── docs/         # спецификация, ER-диаграмма, контракт API, отчёты
```

---

## Модель данных

| Сущность | Поля |
|---|---|
| `User` | id, email, passwordHash, displayName, defaultCurrency, avatarUrl |
| `Account` | id, userId, name, currency, balance |
| `Transaction` | id, accountId, amount, type (income/expense), category, date, note |
| `Budget` | id, userId, category, limitAmount, month |

Подробнее — [`docs/er-diagram.md`](docs/er-diagram.md) и
[`docs/api-contract.md`](docs/api-contract.md).

---

## Экраны

1. Вход / регистрация
2. Общая панель
3. Список транзакций
4. Карточка транзакции
5. Форма транзакции
6. Мои счета
7. Месячные бюджеты
8. Профиль

Карта навигации — [`docs/screens.md`](docs/screens.md).

---

## План разработки

Проект строится инкрементально, каждый этап — отдельная ветка `lab/LN`,
мерж в `main` через `--no-ff` и тег `LN`.

| Этап | Содержание | Статус |
|---|---|---|
| L1 | Спецификация, ER-диаграмма, карта экранов, контракт API | в работе |
| L2 | Статические экраны на Material 3 | — |
| L3 | Навигация (go_router), формы с валидацией | — |
| L4 | State management + Repository с mock-данными | — |
| L5 | .NET backend, REST-интеграция, JWT | — |
| L6 | Offline-персистентность, тесты, release-сборка | — |

---

## Запуск

> Появится начиная с L2.

**Приложение**

```bash
cd app
flutter pub get
flutter run
```

**Backend**

```bash
cd backend
dotnet restore
dotnet ef database update --project src/WalletMate.Api
dotnet run --project src/WalletMate.Api
```

Swagger будет доступен на `http://localhost:5099/swagger`.

---

## Автор

Yang Alexandru
