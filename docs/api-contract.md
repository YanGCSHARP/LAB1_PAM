# Контракт API WalletMate

Документ разворачивает раздел 6 `CLAUDE.md` и добавляет примеры запросов и ответов.
**Это зеркало раздела 6** — при изменении контракта правятся оба файла одновременно,
а также реализации на клиенте и на сервере.

---

## Общее

| | |
|---|---|
| Base URL (Android-эмулятор) | `http://10.0.2.2:5099/api` |
| Base URL (веб / десктоп) | `http://localhost:5099/api` |
| Формат | JSON, `Content-Type: application/json; charset=utf-8` |
| Даты | ISO-8601 в UTC (`2026-09-14T18:25:00Z`) в обе стороны |
| Деньги | число с двумя знаками после запятой, никогда не строка |
| Идентификаторы | guid в строковом виде |
| Авторизация | `Authorization: Bearer <token>` для всех эндпоинтов, кроме `/auth/register` и `/auth/login` |
| Срок жизни токена | 7 дней, HS256 |

Интерактивная документация — Swagger UI на `http://localhost:5099/swagger`
(включён только в Development), с кнопкой **Authorize** для Bearer-токена.

---

## Auth

### POST `/auth/register`

Создаёт пользователя и сразу возвращает токен.

**Запрос**

```json
{
  "email": "ion.rusu@student.utm.md",
  "password": "Student2026",
  "displayName": "Ion Rusu"
}
```

**Ответ `201 Created`**

```json
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI5ZjNh...",
  "expiresAt": "2026-09-21T18:25:00Z",
  "user": {
    "id": "9f3a1c20-5d4e-4b18-9d2a-7c6b1f0e3a55",
    "email": "ion.rusu@student.utm.md",
    "displayName": "Ion Rusu",
    "defaultCurrency": "MDL",
    "avatarUrl": null
  }
}
```

**Ошибки:** `400` — невалидный email или слабый пароль; `409` — email уже занят.

### POST `/auth/login`

**Запрос**

```json
{ "email": "demo@walletmate.md", "password": "Demo1234" }
```

**Ответ `200 OK`** — то же тело, что у регистрации.

**Ошибки:** `401` — неверная пара email / пароль (без уточнения, что именно неверно).

### GET `/auth/me`

Возвращает текущего пользователя по токену. Используется на старте приложения,
чтобы проверить сохранённый токен.

**Ответ `200 OK`**

```json
{
  "id": "9f3a1c20-5d4e-4b18-9d2a-7c6b1f0e3a55",
  "email": "demo@walletmate.md",
  "displayName": "Demo User",
  "defaultCurrency": "MDL",
  "avatarUrl": "/uploads/avatars/9f3a1c20.jpg"
}
```

**Ошибки:** `401` — токен отсутствует, повреждён или просрочен.

---

## Accounts

Все операции работают только со счетами текущего пользователя. Обращение к чужому
счёту возвращает `404` (существование чужих записей не раскрывается).

### GET `/accounts`

**Ответ `200 OK`**

```json
[
  { "id": "1b8f...", "name": "Карта Maib", "currency": "MDL", "balance": 4210.50 },
  { "id": "2c9a...", "name": "Наличные",   "currency": "MDL", "balance": 780.00 },
  { "id": "3d7e...", "name": "Сбережения", "currency": "EUR", "balance": 350.00 }
]
```

### POST `/accounts`

**Запрос**

```json
{ "name": "Карта Maib", "currency": "MDL", "initialBalance": 4000.00 }
```

**Ответ `201 Created`**, заголовок `Location: /api/accounts/1b8f...`

```json
{ "id": "1b8f...", "name": "Карта Maib", "currency": "MDL", "balance": 4000.00 }
```

`initialBalance` необязателен (по умолчанию `0`) и сохраняется как стартовая
корректировка баланса; дальше баланс считается из транзакций.

### GET `/accounts/{id}`

**Ответ `200 OK`** — один объект `Account`. **Ошибки:** `404`.

### PUT `/accounts/{id}`

**Запрос**

```json
{ "name": "Карта Maib (основная)", "currency": "MDL" }
```

**Ответ `200 OK`** — обновлённый объект. **Ошибки:** `400`, `404`.

### DELETE `/accounts/{id}`

**Ответ `204 No Content`.** Каскадно удаляет транзакции счёта — в UI обязательно
подтверждение с указанием количества удаляемых операций.

---

## Transactions

### GET `/transactions`

**Параметры запроса**

| Параметр | Тип | По умолчанию | Описание |
|---|---|---|---|
| `accountId` | guid | — | Фильтр по счёту |
| `category` | string | — | Ключ категории из справочника |
| `type` | `income` \| `expense` | — | Тип операции |
| `from` | date (UTC) | — | Начало периода включительно |
| `to` | date (UTC) | — | Конец периода включительно |
| `search` | string | — | Подстрока в заметке, регистронезависимо |
| `page` | int | `1` | Номер страницы, с единицы |
| `pageSize` | int | `20` | Размер страницы, максимум `100` |

Сортировка — по `date` убыванию.

**Пример**

```http
GET /api/transactions?type=expense&category=food&from=2026-09-01T00:00:00Z&to=2026-09-30T23:59:59Z&page=1&pageSize=20
```

**Ответ `200 OK`**

```json
{
  "items": [
    {
      "id": "7a1c...",
      "accountId": "1b8f...",
      "amount": 249.90,
      "type": "expense",
      "category": "food",
      "date": "2026-09-14T18:25:00Z",
      "note": "Продукты на неделю"
    },
    {
      "id": "7a1d...",
      "accountId": "2c9a...",
      "amount": 85.00,
      "type": "expense",
      "category": "food",
      "date": "2026-09-12T09:10:00Z",
      "note": null
    }
  ],
  "page": 1,
  "pageSize": 20,
  "totalItems": 34,
  "totalPages": 2
}
```

### POST `/transactions`

**Запрос**

```json
{
  "accountId": "1b8f...",
  "amount": 249.90,
  "type": "expense",
  "category": "food",
  "date": "2026-09-14T18:25:00Z",
  "note": "Продукты на неделю"
}
```

**Ответ `201 Created`** — созданная транзакция.

**Ошибки:** `400` — сумма ≤ 0, категория вне справочника, дата в будущем больше чем
на сутки; `404` — счёт не найден или принадлежит другому пользователю.

### GET `/transactions/{id}`

**Ответ `200 OK`** — один объект `Transaction`. **Ошибки:** `404`.

### PUT `/transactions/{id}`

Тело — как у `POST`. **Ответ `200 OK`** — обновлённая транзакция.

### DELETE `/transactions/{id}`

**Ответ `204 No Content`.**

---

## Budgets

### GET `/budgets`

**Параметры:** `month` в формате `YYYY-MM` (по умолчанию — текущий месяц).
`spentAmount` и `progress` считает сервер.

```http
GET /api/budgets?month=2026-09
```

**Ответ `200 OK`**

```json
[
  { "id": "b101...", "category": "food",          "limitAmount": 1300.00, "month": "2026-09", "spentAmount": 1200.00, "progress": 0.923 },
  { "id": "b102...", "category": "transport",     "limitAmount": 600.00,  "month": "2026-09", "spentAmount": 640.00,  "progress": 1.067 },
  { "id": "b103...", "category": "entertainment", "limitAmount": 500.00,  "month": "2026-09", "spentAmount": 180.00,  "progress": 0.360 }
]
```

### POST `/budgets`

**Запрос**

```json
{ "category": "food", "limitAmount": 1300.00, "month": "2026-09" }
```

**Ответ `201 Created`** — созданный бюджет с `spentAmount` и `progress`.

**Ошибки:** `400` — лимит ≤ 0 или неверный формат месяца;
`409` — бюджет на эту категорию и месяц уже существует.

### GET `/budgets/{id}` · PUT `/budgets/{id}` · DELETE `/budgets/{id}`

`GET` → `200 OK` с объектом бюджета, `PUT` принимает то же тело, что `POST`,
и возвращает `200 OK`, `DELETE` → `204 No Content`.

---

## Dashboard

### GET `/dashboard/summary`

Агрегат для панели: считается на сервере, чтобы клиент не пересчитывал те же суммы.

```http
GET /api/dashboard/summary?month=2026-09
```

**Ответ `200 OK`**

```json
{
  "accounts": [
    { "id": "1b8f...", "name": "Карта Maib", "currency": "MDL", "balance": 4210.50 },
    { "id": "2c9a...", "name": "Наличные",   "currency": "MDL", "balance": 780.00 }
  ],
  "totalIncome": 8000.00,
  "totalExpense": 3789.50,
  "byCategory": [
    { "category": "food",      "amount": 1200.00, "share": 0.317 },
    { "category": "transport", "amount": 640.00,  "share": 0.169 },
    { "category": "housing",   "amount": 1500.00, "share": 0.396 },
    { "category": "other",     "amount": 449.50,  "share": 0.118 }
  ],
  "budgets": [
    { "category": "food",      "limitAmount": 1300.00, "spentAmount": 1200.00, "progress": 0.923 },
    { "category": "transport", "limitAmount": 600.00,  "spentAmount": 640.00,  "progress": 1.067 }
  ]
}
```

---

## Загрузка аватара

### POST `/users/me/avatar`

`multipart/form-data`, поле `file`: только `image/jpeg` и `image/png`, размер ≤ 2 МБ.

**Ответ `200 OK`**

```json
{ "avatarUrl": "/uploads/avatars/9f3a1c20.jpg" }
```

**Ошибки:** `400` — неподдерживаемый тип файла или превышен размер.

---

## Формат ошибок

Все ошибки возвращаются в формате RFC 7807 ProblemDetails.

**`400 Bad Request` — ошибки валидации по полям**

```json
{
  "type": "https://httpstatuses.io/400",
  "title": "Validation failed",
  "status": 400,
  "errors": {
    "amount": ["Amount must be greater than zero"],
    "category": ["Category is required"]
  }
}
```

Клиент раскладывает `errors` по полям формы и показывает текст под соответствующим
полем через `errorText`.

**`401 Unauthorized`**

```json
{ "type": "https://httpstatuses.io/401", "title": "Unauthorized", "status": 401,
  "detail": "Token is missing or expired" }
```

**`403 Forbidden`**

```json
{ "type": "https://httpstatuses.io/403", "title": "Forbidden", "status": 403,
  "detail": "Resource belongs to another user" }
```

**`404 Not Found`**

```json
{ "type": "https://httpstatuses.io/404", "title": "Not found", "status": 404,
  "detail": "Transaction 7a1c... was not found" }
```

**`409 Conflict`**

```json
{ "type": "https://httpstatuses.io/409", "title": "Budget already exists", "status": 409,
  "detail": "Budget for category food and month 2026-09 already exists" }
```

**`500 Internal Server Error`**

```json
{ "type": "https://httpstatuses.io/500", "title": "Internal server error", "status": 500,
  "detail": "Unexpected error. Request id: 0HN7GK3M1F9PL" }
```

Подробности исключения наружу не отдаются — только идентификатор запроса,
по которому ошибку можно найти в логах.

### Сводка кодов

| Код | Когда |
|---|---|
| `200` | Успешное чтение или обновление |
| `201` | Ресурс создан, `Location` указывает на него |
| `204` | Успешное удаление |
| `400` | Ошибка валидации входных данных |
| `401` | Токен отсутствует, повреждён или просрочен |
| `403` | Доступ к чужому ресурсу |
| `404` | Ресурс не найден |
| `409` | Конфликт: занятый email, дубликат бюджета на категорию и месяц |
| `500` | Внутренняя ошибка сервера |
