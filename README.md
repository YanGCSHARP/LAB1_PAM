# WalletMate

Приложение для учёта личных финансов: несколько счетов, доходы и расходы по категориям,
месячные бюджеты с порогом предупреждения и общая панель со структурой трат.

Отвечает на вопрос **«куда делись деньги в этом месяце?»**.

| | |
|---|---|
| Дисциплина | Программирование мобильных приложений (PAM), UTM / FCIM / ISA, 2026–2027 |
| Тема | **T7 — WalletMate (личные финансы)**, уровень сложности «повышенный» |
| Автор | Yang Alexandru, группа `TI-236` |

> **Статус:** этап L1 — спецификация. Кода приложения пока нет.

**Аудитория:** студенты и молодые специалисты — нерегулярный доход, небольшие суммы,
часть трат наличными, которых банковское приложение не видит.

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
├── .editorconfig
├── .gitignore
├── app/                        # Flutter-приложение (появится на L2)
│   ├── lib/
│   │   ├── core/               # theme, router, widgets, utils, network, db
│   │   └── features/           # auth, dashboard, transactions, accounts, budgets, profile
│   └── test/                   # unit- и widget-тесты
├── backend/                    # .NET Web API (появится на L5)
│   ├── src/WalletMate.Api/     # Controllers, Entities, Dtos, Data, Services
│   ├── tests/WalletMate.Api.Tests/
│   └── docker-compose.yml
└── docs/
    ├── screens.md              # карта экранов и переходов
    ├── er-diagram.md           # модель данных
    ├── api-contract.md         # контракт REST API
    └── reports/                # отчёты по лабораторным L1–L6
```

Внутри каждой feature — слои `presentation/`, `domain/`, `data/`.

---

## Модель данных

| Сущность | Поля |
|---|---|
| `User` | id, email, passwordHash, displayName, defaultCurrency, avatarUrl |
| `Account` | id, userId, name, currency, balance |
| `Transaction` | id, accountId, amount, type (income/expense), category, date, note |
| `Budget` | id, userId, category, limitAmount, month |

Баланс счёта и прогресс бюджета не хранятся, а считаются из транзакций.
Подробнее — [`docs/er-diagram.md`](docs/er-diagram.md) и
[`docs/api-contract.md`](docs/api-contract.md).

---

## Экраны

Восемь обязательных экранов; четыре из них — вкладки нижней навигации.

| # | Экран | Назначение |
|---|---|---|
| 1 | Вход / регистрация | Аутентификация по email и паролю, создание аккаунта |
| 2 | Общая панель | Балансы счетов, структура расходов на диаграмме, состояние бюджетов |
| 3 | Список транзакций | Операции с группировкой по датам, поиск и фильтры |
| 4 | Карточка транзакции | Детали одной операции, кнопки «Изменить» и «Удалить» |
| 5 | Форма транзакции | Создание и редактирование операции |
| 6 | Мои счета | Список счетов и форма счёта |
| 7 | Месячные бюджеты | Лимиты по категориям с прогрессом и форма бюджета |
| 8 | Профиль | Данные пользователя, валюта по умолчанию, тема, выход |

Маршруты, переходы и карта навигации — [`docs/screens.md`](docs/screens.md).

---

## Документация

| Документ | Содержание |
|---|---|
| [`docs/screens.md`](docs/screens.md) | Карта экранов, маршруты, переходы, состояния |
| [`docs/er-diagram.md`](docs/er-diagram.md) | Модель данных, связи, индексы, справочник категорий |
| [`docs/api-contract.md`](docs/api-contract.md) | Контракт REST API с примерами и форматом ошибок |
| [`docs/reports/L1.md`](docs/reports/L1.md) | Отчёт по этапу L1 |

---

## План разработки

Проект строится инкрементально, каждый этап — отдельная ветка `lab/LN`,
мерж в `main` через `--no-ff` и тег `LN`.

| Этап | Содержание | Статус |
|---|---|---|
| L1 | Спецификация, ER-диаграмма, карта экранов, контракт API | готово |
| L2 | Статические экраны на Material 3 | — |
| L3 | Навигация (go_router), формы с валидацией | — |
| L4 | State management + Repository с mock-данными | — |
| L5 | .NET backend, REST-интеграция, JWT | — |
| L6 | Offline-персистентность, тесты, release-сборка | — |

---

## Запуск

> ⚠️ Команды ниже приведены заранее и **пока не работают**: каталога `app/` нет
> до этапа L2, каталога `backend/` — до L5.

**Приложение** (с L2)

```bash
cd app
flutter pub get
flutter run
```

**Backend** (с L5)

```bash
cd backend
dotnet restore
dotnet ef database update --project src/WalletMate.Api
dotnet run --project src/WalletMate.Api
```

Swagger будет доступен на `http://localhost:5099/swagger`,
демо-учётка — `demo@walletmate.md` / `Demo1234`.

---

## Разработка

Один этап — одна ветка `lab/LN`, атомарные коммиты (Conventional Commits,
scope `app` или `api`), мерж в `main` через `--no-ff` и тег `LN`.
Перед каждым коммитом: `dart format .`, `flutter analyze`, `flutter test`.

Секреты в репозиторий не попадают: `.env`, `appsettings.Development.json`,
`key.properties` и keystore перечислены в `.gitignore`, в репозитории лежат
только `*.example`-шаблоны.

---

## Автор

Yang Alexandru, группа `____`
UTM / FCIM / ISA, дисциплина PAM, 2026–2027
