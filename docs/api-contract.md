# Контракт API WalletMate

Контракт сервера с этапа L5. Backend построен на шаблоне курса PAM (порт
.NET 9 Minimal API), поэтому общие правила — формат ошибок, пагинация, JWT,
загрузка файлов — взяты из шаблона, а маршруты WalletMate добавлены по его
рецепту. Реализация — `backend/`, клиент — `app/lib/features/*/data/api_*.dart`.

> На L1 контракт описывал ASP.NET Core с EF Core, ProblemDetails (RFC 7807),
> guid-идентификаторы и префикс `/api`. После выдачи шаблона курса контракт
> приведён к нему: так требует задание L5.

---

## Общее

| | |
|---|---|
| Base URL (веб, десктоп, iOS-симулятор) | `http://localhost:8080` |
| Base URL (Android-эмулятор) | `http://10.0.2.2:8080` |
| Формат | JSON, `Content-Type: application/json` |
| Даты | ISO-8601; сервер хранит и отдаёт UTC (`2026-09-14T18:25:00Z`) |
| Деньги | число, не больше двух знаков после запятой; в базе — целые копейки |
| Идентификаторы | целые числа (`INTEGER PRIMARY KEY`); клиент хранит их строками |
| Авторизация | `Authorization: Bearer <token>` везде, кроме `/health`, `/auth/*` и `GET /files/{id}` |
| Токен | JWT HS256, `sub` — id пользователя, срок жизни 7 дней |
| Порт | переменная `PORT`, по умолчанию `8080` |

### Списки

Все списки — в формате шаблона:

```json
{ "items": [ ... ], "page": 1, "limit": 20, "total": 27 }
```

`page` — с единицы, `limit` — от 1 до 100 (по умолчанию 20). Клиенту нужны все
операции для расчёта балансов и бюджетов, поэтому он читает списки страницами
по 100 до `total`.

### Ошибки

Любая ошибка — в формате шаблона:

```json
{ "error": { "code": "CONFLICT", "message": "Счёт с таким названием уже есть" } }
```

| HTTP | `code` | Когда |
|---|---|---|
| 400 | `VALIDATION_ERROR` | неверные поля, битый JSON, неверные параметры запроса |
| 401 | `UNAUTHORIZED` | нет токена, токен неверный или истёк, неверный пароль при входе |
| 404 | `NOT_FOUND` | записи нет **или она чужая** — эти случаи не различаются |
| 409 | `EMAIL_TAKEN` | регистрация на занятый email (шаблон) |
| 409 | `CONFLICT` | повтор названия счёта, второй бюджет на категорию и месяц (WalletMate) |
| 500 | `INTERNAL` | непредвиденная ошибка сервера |

Сообщения маршрутов шаблона — на английском, маршрутов WalletMate — на
русском, их клиент показывает как есть. Ответы шаблона клиент переводит сам:
`401` при входе → «Неверный email или пароль», `EMAIL_TAKEN` → «Аккаунт с таким
email уже есть». `401` на запросе с токеном завершает сессию.

---

## Auth (шаблон)

### POST `/auth/register`

```json
{ "email": "ion@student.utm.md", "password": "Secret123", "name": "Ion Rusu" }
```

**`201 Created`**

```json
{ "token": "eyJhbGciOi...", "user": { "id": 2, "email": "ion@student.utm.md", "name": "Ion Rusu" } }
```

**Ошибки:** `400` — нет email, пароля или имени; `409 EMAIL_TAKEN`.

### POST `/auth/login`

```json
{ "email": "demo@walletmate.md", "password": "Demo1234" }
```

**`200 OK`** — `{token, user}`, как при регистрации. **Ошибки:** `401`.

### GET `/me`

**`200 OK`** — `{id, email, name}`. Приложение читает расширенный профиль
через `/profile`.

---

## Profile

### GET `/profile`

```json
{
  "id": 1,
  "email": "demo@walletmate.md",
  "displayName": "Ion Rusu",
  "defaultCurrency": "MDL",
  "avatarUrl": "/files/7"
}
```

`avatarUrl` — путь к публичному `GET /files/{id}` или `null`.

### PUT `/profile`

```json
{ "displayName": "Ion Rusu", "defaultCurrency": "EUR", "avatarFileId": 7 }
```

`avatarFileId` — необязательный id из `POST /files`; без него аватар не
меняется. **`200 OK`** — профиль. **Ошибки:** `400` — пустое имя, валюта не
из `MDL`/`EUR`/`USD`, файл не изображение; `404` — файла нет или он чужой.

---

## Accounts

### GET `/accounts?page&limit`

```json
{
  "items": [
    {
      "id": 1,
      "name": "Карта Maib",
      "currency": "MDL",
      "kind": "card",
      "initialBalance": 1250,
      "balance": 10847.2,
      "createdAt": "2026-11-16T10:00:00.0000000Z"
    }
  ],
  "page": 1, "limit": 20, "total": 3
}
```

`balance` = `initialBalance` + доходы − расходы счёта, считается SQL-запросом.
Порядок — по созданию.

### POST `/accounts`

```json
{ "name": "Карта Maib", "currency": "MDL", "kind": "card", "initialBalance": 1250 }
```

**`201 Created`** — счёт. **Ошибки:** `400` — название пустое или длиннее 50,
валюта не из `MDL`/`EUR`/`USD`, `kind` не из `card`/`cash`/`savings`;
`409 CONFLICT` — название уже есть у пользователя (без учёта регистра).

### GET `/accounts/{id}` · PUT `/accounts/{id}` · DELETE `/accounts/{id}`

`PUT` принимает `{name, currency, kind}`: начальный баланс задаётся только при
создании, дальше баланс определяют операции. `DELETE` → `204 No Content` и
**каскадно удаляет операции счёта**; клиент предупреждает об этом в диалоге с
числом операций.

---

## Transactions

### GET `/transactions`

| Параметр | Описание |
|---|---|
| `page`, `limit` | пагинация шаблона |
| `search` | подстрока в заметке |
| `type` | `income` или `expense` |
| `category` | ключ из справочника |
| `accountId` | только этот счёт |
| `from`, `to` | период, ISO-8601, обе границы включительно |

Сортировка — по дате, новые сверху.

```http
GET /transactions?type=expense&category=food&from=2026-11-01T00:00:00Z&to=2026-11-30T23:59:59Z
```

```json
{
  "items": [
    {
      "id": 26,
      "accountId": 2,
      "amount": 132.7,
      "type": "expense",
      "category": "food",
      "date": "2026-11-17T07:50:00Z",
      "note": "Кофе и выпечка",
      "createdAt": "2026-11-16T10:00:00.0000000Z"
    }
  ],
  "page": 1, "limit": 20, "total": 5
}
```

### POST `/transactions` · PUT `/transactions/{id}`

```json
{
  "accountId": 2,
  "amount": 132.70,
  "type": "expense",
  "category": "food",
  "date": "2026-11-17T07:50:00Z",
  "note": "Кофе и выпечка"
}
```

**`201 Created`** / **`200 OK`** — операция. **Ошибки:** `400` — сумма ≤ 0,
больше 1 000 000 или с тремя знаками после запятой; категория не подходит к
типу; дата позже завтрашнего дня; заметка длиннее 200 символов; `404` — счёт
не найден или чужой.

### GET `/transactions/{id}` · DELETE `/transactions/{id}`

`200 OK` с операцией / `204 No Content`; `404` для несуществующей или чужой.

---

## Budgets

### GET `/budgets?month=YYYY-MM&page&limit`

```json
{
  "items": [
    {
      "id": 1,
      "category": "food",
      "limitAmount": 1300,
      "month": "2026-11",
      "spentAmount": 1200,
      "createdAt": "2026-11-16T10:00:00.0000000Z"
    }
  ],
  "page": 1, "limit": 20, "total": 5
}
```

`spentAmount` — расходы категории за месяц по счетам **в валюте по умолчанию**
из профиля; месяц операции берётся по её дате в UTC.

### POST `/budgets` · PUT `/budgets/{id}`

```json
{ "category": "food", "limitAmount": 1300, "month": "2026-11" }
```

**Ошибки:** `400` — категория не из расходов, лимит ≤ 0, месяц не в формате
`YYYY-MM`; `409 CONFLICT` — на эту категорию в этом месяце бюджет уже есть.

### GET `/budgets/{id}` · DELETE `/budgets/{id}`

`200 OK` / `204 No Content`; операции при удалении бюджета не затрагиваются.

---

## Files (шаблон)

### POST `/files`

`multipart/form-data`, поле `file`, не больше 5 МБ. **`201 Created`**:

```json
{ "id": 7, "url": "/files/7", "name": "avatar.jpg", "size": 48213, "mimeType": "image/jpeg" }
```

### GET `/files/{id}`

Публичный: отдаёт байты файла с исходным `Content-Type`, чтобы
`Image.network` показывал аватар по URL без токена.

---

## Сводка маршрутов

| Метод и путь | Auth | Источник |
|---|---|---|
| `GET /health` | — | шаблон |
| `POST /auth/register`, `POST /auth/login` | — | шаблон |
| `GET /me` | да | шаблон |
| `GET /profile`, `PUT /profile` | да | WalletMate |
| `GET/POST /accounts`, `GET/PUT/DELETE /accounts/{id}` | да | WalletMate |
| `GET/POST /transactions`, `GET/PUT/DELETE /transactions/{id}` | да | WalletMate |
| `GET/POST /budgets`, `GET/PUT/DELETE /budgets/{id}` | да | WalletMate |
| `POST /files` | да | шаблон |
| `GET /files/{id}` | — | шаблон |
| `GET/POST /notes`, `GET/PUT/DELETE /notes/{id}` | да | пример шаблона, приложением не используется |
