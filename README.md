# WalletMate

Приложение для учёта личных финансов: несколько счетов, доходы и расходы по категориям,
месячные бюджеты с порогом предупреждения и общая панель со структурой трат.

Отвечает на вопрос **«куда делись деньги в этом месяце?»**.

| | |
|---|---|
| Тема | **T7 — WalletMate (личные финансы)**, уровень сложности «повышенный» |
| Автор | Yang Alexandru, группа `TI-236` |

> **Статус:** проект готов (L1–L6): собственный backend на шаблоне курса,
> REST и JWT, офлайн-копия данных на устройстве, release-сборка. Материалы к
> защите — [`docs/defense.md`](docs/defense.md).

**Аудитория:** студенты и молодые специалисты — нерегулярный доход, небольшие суммы,
часть трат наличными, которых банковское приложение не видит.

---

## Что умеет

- Несколько счетов в разных валютах, баланс считается из транзакций
- Транзакции с категорией, счётом, датой и заметкой; поиск и фильтры по категории,
  типу и периоду
- Месячные бюджеты по категориям с прогрессом расходования
- Панель: балансы счетов, структура расходов по категориям в виде диаграммы,
  выделение категорий, превысивших 90% бюджета
- Без сети: последние загруженные данные открываются с устройства, изменения
  ждут соединения

---

## Стек

**Мобильное приложение**

| | |
|---|---|
| Framework | Flutter, Dart |
| UI | Material 3, светлая и тёмная темы |
| Навигация | go_router |
| State | Riverpod |
| Сеть | dio + JWT interceptor, токен в flutter_secure_storage |
| Локальная БД | drift (SQLite) |
| Графики | fl_chart |
| Тесты | flutter_test, mocktail, integration_test |

**Backend**

| | |
|---|---|
| Основа | шаблон backend-а курса PAM, порт .NET 9 Minimal API |
| БД | SQLite через Microsoft.Data.Sqlite, параметризованный SQL без ORM |
| Auth | JWT HS256 и пароли PBKDF2 из шаблона |
| Ошибки | формат шаблона `{"error": {"code", "message"}}` |
| Тесты | xUnit + WebApplicationFactory |

---

## Структура репозитория

```
walletmate/
├── .editorconfig
├── .gitignore
├── app/                        # Flutter-приложение (с L2)
│   ├── lib/
│   │   ├── core/               # theme, router, widgets, utils, data (mock-бэкенд), state
│   │   └── features/           # auth, dashboard, transactions, accounts, budgets, profile
│   └── test/                   # unit- и widget-тесты
├── backend/                    # шаблон курса + сущности WalletMate (с L5)
│   ├── *.cs                    # Program, Db, Auth, Errors, Files, Accounts, …
│   └── Tests/                  # интеграционные тесты API
└── docs/
    ├── screens.md              # карта экранов и переходов
    ├── er-diagram.md           # модель данных
    ├── api-contract.md         # контракт REST API
    └── reports/                # отчёты по лабораторным L1–L6
```

Внутри каждой feature — слои `domain/` (модели и расчёты), `data/`
(интерфейс репозитория, его REST- и mock-реализации), `application/`
(провайдеры Riverpod) и `presentation/` (экраны).

---

## Модель данных

| Сущность | Поля |
|---|---|
| `User` | id, email, passwordHash, displayName, defaultCurrency, avatarUrl |
| `Account` | id, userId, name, currency, kind, initialBalance; balance — вычисляемый |
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
| [`docs/reports/L3.md`](docs/reports/L3.md) | Отчёт по этапу L3 |
| [`docs/reports/L4.md`](docs/reports/L4.md) | Отчёт по этапу L4 |
| [`docs/reports/L5.md`](docs/reports/L5.md) | Отчёт по этапу L5 |
| [`docs/reports/L6.md`](docs/reports/L6.md) | Отчёт по этапу L6 |
| [`docs/defense.md`](docs/defense.md) | План защиты: сценарий показа и вопросы |
| [`backend/README.md`](backend/README.md) | Маршруты, правила и запуск backend-а |

---

## План разработки

Проект строится инкрементально, каждый этап — отдельная ветка `lab/LN`,
мерж в `main` через `--no-ff` и тег `LN`.

| Этап | Содержание | Статус |
|---|---|---|
| L1 | Спецификация, ER-диаграмма, карта экранов, контракт API | готово |
| L2 | Статические экраны на Material 3 | готово |
| L3 | Навигация (go_router), формы с валидацией | готово |
| L4 | State management + Repository с mock-данными | готово |
| L5 | .NET backend, REST-интеграция, JWT | готово |
| L6 | Offline-персистентность, тесты, release-сборка | готово |

---

## Запуск

Сначала backend (нужен .NET SDK 9). База `app.db` и папка `uploads/`
создаются сами, в пустую базу записывается демо-аккаунт
**`demo@walletmate.md` / `Demo1234`**.

```bash
cd backend
dotnet run
```

Сервер слушает `http://localhost:8080` (порт — переменная `PORT`).

Потом приложение:

```bash
cd app
flutter pub get
flutter run
```

Адрес API по умолчанию — `localhost:8080`, из эмулятора Android —
`10.0.2.2:8080`. Телефон в той же сети:
`flutter run --dart-define=API_URL=http://<IP компьютера>:8080`.
Без сервера, на демо-данных в памяти: `flutter run --dart-define=USE_MOCKS=true`.

Тесты: `cd app && flutter test` (сервер не нужен) и
`cd backend/Tests && dotnet test`.

Если что-то не так:

- **Порт 8080 занят** другим сервером (например, backend-ом другой
  лабораторной) — `dotnet run` падает с «address already in use», а
  приложение незаметно ходит на чужой сервер. Запустите на другом порту
  (`$env:PORT = '8081'; dotnet run` в PowerShell) и передайте его приложению:
  `flutter run --dart-define=API_URL=http://10.0.2.2:8081`.
- **В эмуляторе не печатает клавиатура компьютера** — в настройках AVD
  выключена аппаратная клавиатура. В `~/.android/avd/<имя>.avd/config.ini`
  поставьте `hw.keyboard=yes` и перезапустите эмулятор с `--cold`.

---

## Без сети

Каждая успешная загрузка профиля, счетов, операций и бюджетов сохраняется на
устройстве (`shared_preferences`). Если сервер недоступен, приложение
открывается под тем же аккаунтом, показывает сохранённую копию и плашку «Нет
соединения. Показаны сохранённые данные, изменения недоступны.» Сохранение,
удаление и загрузка аватара требуют сети. Выход из аккаунта стирает копию.

---

## Release-сборка

Android (APK, Dart-код обфусцирован, символы для разбора сбоев — в
`build/symbols`, их не публикуют):

```bash
cd app
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/symbols --dart-define=API_URL=http://<адрес сервера>:8080
```

Файлы — в `app/build/app/outputs/flutter-apk/`. Подпись берётся из
`app/android/key.properties` (в git не попадает, образец —
`key.properties.example`). Без него release подписывается отладочным ключом:
для проверки этого хватает, для публикации нет.

Backend:

```bash
cd backend
dotnet publish -c Release -o publish
cd publish
set JWT_SECRET=<длинная случайная строка>
dotnet PamBackend.dll
```

В release секрет JWT задаётся обязательно: значение по умолчанию из шаблона
годится только для лабораторной.

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
