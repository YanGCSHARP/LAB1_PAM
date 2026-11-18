# WalletMate API

Backend WalletMate на основе шаблона курса PAM — порт на .NET 9 Minimal API.
Из шаблона взяты без изменений JWT-аутентификация (`Auth.cs`), единый формат
ошибок и middleware (`Errors.cs`), загрузка файлов (`Files.cs`) и приём
пагинации из примера `Notes.cs`. Сущности WalletMate добавлены по рецепту
шаблона: таблица в `Db.cs`, файл по образцу `Notes.cs`, маршруты в `Program.cs`.

## Запуск

```bash
cd backend
dotnet run
```

Нужен .NET SDK 9. База `app.db` (SQLite) и папка `uploads/` создаются сами;
в пустую базу записывается демо-аккаунт **`demo@walletmate.md` / `Demo1234`**
с тремя счетами, операциями за прошлый и текущий месяц и пятью бюджетами.

| Переменная | По умолчанию | Назначение |
|---|---|---|
| `PORT` | `8080` | порт сервера |
| `JWT_SECRET` | `dev-secret-change-me` | ключ подписи JWT; в release задаётся обязательно |
| `DB_PATH` | `app.db` | файл базы |
| `UPLOADS_DIR` | `uploads` | папка загруженных файлов |
| `SEED_DEMO` | `true` | `false` — стартовать с пустой базой |

## Структура

```
Program.cs       запуск, все маршруты, middleware                  шаблон + маршруты WalletMate
Db.cs            схема SQLite, хелпер Cmd()                        шаблон + 3 таблицы
Auth.cs          register / login / me, PBKDF2, JWT HS256          шаблон
Errors.cs        формат {"error":{code,message}}, middleware       шаблон + код CONFLICT
Files.cs         загрузка и выдача файлов                          шаблон
Notes.cs         пример сущности                                   шаблон
Money.cs         деньги в копейках, справочники валют и категорий  WalletMate
Accounts.cs      счета, баланс считается SQL-запросом              WalletMate
Transactions.cs  операции, фильтры и пагинация                     WalletMate
Budgets.cs       бюджеты, потраченная сумма считается SQL-запросом WalletMate
Profile.cs       имя, валюта по умолчанию, аватар                  WalletMate
Seed.cs          демо-аккаунт                                      WalletMate
Tests/           интеграционные тесты (xUnit + WebApplicationFactory)
```

## Маршруты

Все маршруты, кроме `/health`, `/auth/*` и `GET /files/{id}`, требуют
`Authorization: Bearer <token>`. Списки отвечают в формате шаблона
`{items, page, limit, total}`, `limit` — от 1 до 100.

| Метод и путь | Что делает |
|---|---|
| `POST /auth/register`, `POST /auth/login`, `GET /me` | аккаунт и JWT (шаблон) |
| `GET /profile`, `PUT /profile` | профиль: `displayName`, `defaultCurrency`, `avatarFileId` |
| `GET /accounts`, `POST /accounts` | счета пользователя с вычисленным `balance` |
| `GET /accounts/{id}`, `PUT /accounts/{id}`, `DELETE /accounts/{id}` | один счёт; удаление забирает его операции |
| `GET /transactions?page&limit&search&type&category&accountId&from&to` | операции, новые сверху |
| `POST /transactions`, `GET/PUT/DELETE /transactions/{id}` | CRUD операции |
| `GET /budgets?month=YYYY-MM`, `POST /budgets` | бюджеты с вычисленным `spentAmount` |
| `GET/PUT/DELETE /budgets/{id}` | один бюджет |
| `POST /files`, `GET /files/{id}` | загрузка и выдача файла (шаблон), используется для аватара |

## Правила

- Деньги хранятся в целых копейках (`INTEGER`), API принимает и отдаёт
  десятичные суммы не больше двух знаков после запятой.
- Чужая запись неотличима от несуществующей: `404 NOT_FOUND`.
- Повтор названия счёта (без учёта регистра, в том числе кириллицы) и второй
  бюджет на ту же категорию и месяц — `409 CONFLICT`.
- Сумма > 0 и ≤ 1 000 000, категория должна подходить к типу операции,
  дата — не позже завтрашнего дня, заметка — до 200 символов.
- `spentAmount` бюджета учитывает только счета в валюте по умолчанию из профиля.

## Тесты

```bash
cd backend/Tests
dotnet test
```

Сервер поднимается в памяти на временной базе; отдельный запуск не нужен.
