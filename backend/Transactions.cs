// Transactions: incomes and expenses on the user's accounts. Built from the
// Notes.cs template: CRUD + pagination + search, plus the filters of the
// contract (account, category, type, period).
//
// A transaction has no user_id: its owner is the owner of its account, so
// every query joins accounts and filters by a.user_id.

using System.Globalization;
using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Transaction(
    long Id, long AccountId, decimal Amount, string Type, string Category,
    string Date, string? Note, string CreatedAt);

public record TransactionInput(
    long? AccountId, decimal? Amount, string? Type, string? Category,
    DateTimeOffset? Date, string? Note);

public static class Transactions
{
    private const string Select = """
        SELECT t.id, t.account_id, t.amount_cents, t.type, t.category, t.date,
               t.note, t.created_at
        FROM transactions t
        JOIN accounts a ON a.id = t.account_id
        """;

    private static Transaction Read(SqliteDataReader r) => new(
        r.GetInt64(0), r.GetInt64(1), Money.FromCents(r.GetInt64(2)), r.GetString(3),
        r.GetString(4), r.GetString(5), r.IsDBNull(6) ? null : r.GetString(6), r.GetString(7));

    /// <summary>Dates are stored as UTC in one fixed format, so comparing the
    /// strings in SQL compares the moments.</summary>
    internal static string StoreDate(DateTimeOffset date) =>
        date.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", CultureInfo.InvariantCulture);

    private static Transaction? Find(SqliteConnection conn, long userId, long id)
    {
        using var cmd = conn.Cmd($"{Select} WHERE t.id = $id AND a.user_id = $userId",
            ("$id", id), ("$userId", userId));
        using var reader = cmd.ExecuteReader();
        return reader.Read() ? Read(reader) : null;
    }

    /// <summary>Shared checks of create and update; returns the error or null.</summary>
    private static IResult? Validate(SqliteConnection conn, long userId, TransactionInput input)
    {
        if (Money.ValidatePositive(input.Amount, "amount") is { } amountError)
            return Errors.Validation(amountError);
        if (input.Type is not ("income" or "expense"))
            return Errors.Validation("Тип операции должен быть income или expense");
        if (input.Category is null || !Catalog.IsCategory(input.Type, input.Category))
            return Errors.Validation("Категория не подходит к типу операции");
        if (input.Date is null) return Errors.Validation("Укажите дату операции");
        if (input.Date > DateTimeOffset.UtcNow.AddDays(1))
            return Errors.Validation("Дата не может быть позже завтрашнего дня");
        if (input.Note is { Length: > 200 })
            return Errors.Validation("Заметка — не больше 200 символов");
        // Someone else's account answers exactly like a missing one.
        if (input.AccountId is null || Accounts.Find(conn, userId, input.AccountId.Value) is null)
            return Errors.NotFound("Счёт не найден");
        return null;
    }

    /// <summary>
    /// GET /transactions?page&amp;limit&amp;search&amp;type&amp;category&amp;accountId&amp;from&amp;to
    /// -> {items, page, limit, total}, newest first. `from`/`to` are ISO-8601
    /// moments, both inclusive; `search` looks in the note.
    /// </summary>
    public static IResult List(HttpContext context,
        int page = 1, int limit = 20, string search = "",
        string? type = null, string? category = null, long? accountId = null,
        DateTimeOffset? from = null, DateTimeOffset? to = null)
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);

        var where = new List<string> { "a.user_id = $userId", "COALESCE(t.note, '') LIKE $pattern" };
        var args = new List<(string, object?)>
        {
            ("$userId", Auth.CurrentUserId(context)), ("$pattern", $"%{search}%"),
        };
        if (type is not null) { where.Add("t.type = $type"); args.Add(("$type", type)); }
        if (category is not null) { where.Add("t.category = $category"); args.Add(("$category", category)); }
        if (accountId is not null) { where.Add("t.account_id = $accountId"); args.Add(("$accountId", accountId)); }
        if (from is not null) { where.Add("t.date >= $from"); args.Add(("$from", StoreDate(from.Value))); }
        if (to is not null) { where.Add("t.date <= $to"); args.Add(("$to", StoreDate(to.Value))); }
        var filter = string.Join(" AND ", where);

        using var conn = Db.Open();
        long total;
        using (var count = conn.Cmd(
                   $"SELECT COUNT(*) FROM transactions t JOIN accounts a ON a.id = t.account_id WHERE {filter}",
                   [.. args]))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<Transaction>();
        using var cmd = conn.Cmd(
            $"{Select} WHERE {filter} ORDER BY t.date DESC, t.id DESC LIMIT $limit OFFSET $offset",
            [.. args, ("$limit", limit), ("$offset", (page - 1) * limit)]);
        using var reader = cmd.ExecuteReader();
        while (reader.Read()) items.Add(Read(reader));

        return Results.Json(new { items, page, limit, total });
    }

    /// <summary>POST /transactions {accountId, amount, type, category, date, note} -> 201</summary>
    public static IResult Create(HttpContext context, TransactionInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        if (Validate(conn, userId, input) is { } error) return error;

        using (var insert = conn.Cmd(
                   "INSERT INTO transactions (account_id, amount_cents, type, category, date, note, created_at) " +
                   "VALUES ($accountId, $amount, $type, $category, $date, $note, $createdAt)",
                   ("$accountId", input.AccountId), ("$amount", Money.ToCents(input.Amount!.Value)),
                   ("$type", input.Type), ("$category", input.Category),
                   ("$date", StoreDate(input.Date!.Value)), ("$note", Errors.Trimmed(input.Note)),
                   ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }
        var transaction = Find(conn, userId, conn.LastInsertRowId())!;
        return Results.Created($"/transactions/{transaction.Id}", transaction);
    }

    /// <summary>GET /transactions/{id} -> 200 | 404</summary>
    public static IResult GetOne(HttpContext context, long id)
    {
        using var conn = Db.Open();
        var transaction = Find(conn, Auth.CurrentUserId(context), id);
        return transaction is null ? Errors.NotFound("Операция не найдена") : Results.Json(transaction);
    }

    /// <summary>PUT /transactions/{id} - body as for POST -> 200 | 404</summary>
    public static IResult Update(HttpContext context, long id, TransactionInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        if (Find(conn, userId, id) is null) return Errors.NotFound("Операция не найдена");
        if (Validate(conn, userId, input) is { } error) return error;

        using (var update = conn.Cmd(
                   "UPDATE transactions SET account_id = $accountId, amount_cents = $amount, " +
                   "type = $type, category = $category, date = $date, note = $note WHERE id = $id",
                   ("$accountId", input.AccountId), ("$amount", Money.ToCents(input.Amount!.Value)),
                   ("$type", input.Type), ("$category", input.Category),
                   ("$date", StoreDate(input.Date!.Value)), ("$note", Errors.Trimmed(input.Note)),
                   ("$id", id)))
        {
            update.ExecuteNonQuery();
        }
        return Results.Json(Find(conn, userId, id)!);
    }

    /// <summary>DELETE /transactions/{id} -> 204 | 404</summary>
    public static IResult Delete(HttpContext context, long id)
    {
        using var conn = Db.Open();
        if (Find(conn, Auth.CurrentUserId(context), id) is null)
            return Errors.NotFound("Операция не найдена");

        using var delete = conn.Cmd("DELETE FROM transactions WHERE id = $id", ("$id", id));
        delete.ExecuteNonQuery();
        return Results.NoContent();
    }
}
