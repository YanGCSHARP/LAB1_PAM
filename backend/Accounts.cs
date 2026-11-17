// Accounts: where money is kept - a card, cash, savings. Built from the
// Notes.cs template: CRUD + pagination, scoped per user.
//
// The balance is never stored: it is the opening balance plus incomes minus
// expenses of the account, computed by SQL on every read.

using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Account(
    long Id, string Name, string Currency, string Kind,
    decimal InitialBalance, decimal Balance, string CreatedAt);

public record AccountInput(string? Name, string? Currency, string? Kind, decimal? InitialBalance);

public static class Accounts
{
    private const string Select = """
        SELECT a.id, a.name, a.currency, a.kind, a.initial_balance_cents,
               a.initial_balance_cents + COALESCE(SUM(
                 CASE t.type WHEN 'income' THEN t.amount_cents ELSE -t.amount_cents END), 0),
               a.created_at
        FROM accounts a
        LEFT JOIN transactions t ON t.account_id = a.id
        """;

    private static Account Read(SqliteDataReader r) => new(
        r.GetInt64(0), r.GetString(1), r.GetString(2), r.GetString(3),
        Money.FromCents(r.GetInt64(4)), Money.FromCents(r.GetInt64(5)), r.GetString(6));

    /// <summary>The user's account, or null - someone else's account is
    /// indistinguishable from a missing one.</summary>
    internal static Account? Find(SqliteConnection conn, long userId, long id)
    {
        using var cmd = conn.Cmd(
            $"{Select} WHERE a.id = $id AND a.user_id = $userId GROUP BY a.id",
            ("$id", id), ("$userId", userId));
        using var reader = cmd.ExecuteReader();
        return reader.Read() ? Read(reader) : null;
    }

    /// <summary>
    /// Names are unique per user regardless of case. Compared in C#, not SQL:
    /// SQLite's NOCASE and lower() fold only ASCII, so «наличные» and
    /// «Наличные» would slip through.
    /// </summary>
    private static bool NameTaken(SqliteConnection conn, long userId, string name, long? exceptId)
    {
        using var cmd = conn.Cmd(
            "SELECT name FROM accounts WHERE user_id = $userId AND id IS NOT $exceptId",
            ("$userId", userId), ("$exceptId", exceptId));
        using var reader = cmd.ExecuteReader();
        while (reader.Read())
        {
            if (string.Equals(reader.GetString(0), name, StringComparison.OrdinalIgnoreCase))
                return true;
        }
        return false;
    }

    /// <summary>Shared checks of create and update; returns the error or null.</summary>
    private static IResult? Validate(AccountInput input, out string name)
    {
        name = Errors.Trimmed(input.Name) ?? "";
        if (name.Length == 0) return Errors.Validation("Введите название счёта");
        if (name.Length > 50) return Errors.Validation("Название — не больше 50 символов");
        if (!Catalog.Currencies.Contains(input.Currency))
            return Errors.Validation("Валюта должна быть MDL, EUR или USD");
        if (!Catalog.AccountKinds.Contains(input.Kind))
            return Errors.Validation("Тип счёта должен быть card, cash или savings");
        return null;
    }

    /// <summary>GET /accounts?page=1&amp;limit=20 -> {items, page, limit, total}, oldest first</summary>
    public static IResult List(HttpContext context, int page = 1, int limit = 20)
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();
        long total;
        using (var count = conn.Cmd("SELECT COUNT(*) FROM accounts WHERE user_id = $userId",
                   ("$userId", userId)))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<Account>();
        using var cmd = conn.Cmd(
            $"{Select} WHERE a.user_id = $userId GROUP BY a.id ORDER BY a.id " +
            "LIMIT $limit OFFSET $offset",
            ("$userId", userId), ("$limit", limit), ("$offset", (page - 1) * limit));
        using var reader = cmd.ExecuteReader();
        while (reader.Read()) items.Add(Read(reader));

        return Results.Json(new { items, page, limit, total });
    }

    /// <summary>POST /accounts {name, currency, kind, initialBalance} -> 201 account | 409</summary>
    public static IResult Create(HttpContext context, AccountInput input)
    {
        if (Validate(input, out var name) is { } error) return error;
        var initial = input.InitialBalance ?? 0;
        if (Math.Abs(initial) > Money.MaxAmount || decimal.Round(initial, 2) != initial)
            return Errors.Validation("Некорректный начальный баланс");
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();
        if (NameTaken(conn, userId, name, null))
            return Errors.Conflict("Счёт с таким названием уже есть");

        using (var insert = conn.Cmd(
                   "INSERT INTO accounts (user_id, name, currency, kind, initial_balance_cents, created_at) " +
                   "VALUES ($userId, $name, $currency, $kind, $initial, $createdAt)",
                   ("$userId", userId), ("$name", name), ("$currency", input.Currency),
                   ("$kind", input.Kind), ("$initial", Money.ToCents(initial)),
                   ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }
        var account = Find(conn, userId, conn.LastInsertRowId())!;
        return Results.Created($"/accounts/{account.Id}", account);
    }

    /// <summary>GET /accounts/{id} -> 200 account | 404</summary>
    public static IResult GetOne(HttpContext context, long id)
    {
        using var conn = Db.Open();
        var account = Find(conn, Auth.CurrentUserId(context), id);
        return account is null ? Errors.NotFound("Счёт не найден") : Results.Json(account);
    }

    /// <summary>
    /// PUT /accounts/{id} {name, currency, kind} -> 200 account | 404 | 409.
    /// The opening balance is set once, on creation: after that the balance
    /// is defined by the operations, so `initialBalance` is ignored here.
    /// </summary>
    public static IResult Update(HttpContext context, long id, AccountInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        if (Find(conn, userId, id) is null) return Errors.NotFound("Счёт не найден");
        if (Validate(input, out var name) is { } error) return error;
        if (NameTaken(conn, userId, name, id))
            return Errors.Conflict("Счёт с таким названием уже есть");

        using (var update = conn.Cmd(
                   "UPDATE accounts SET name = $name, currency = $currency, kind = $kind " +
                   "WHERE id = $id",
                   ("$name", name), ("$currency", input.Currency), ("$kind", input.Kind),
                   ("$id", id)))
        {
            update.ExecuteNonQuery();
        }
        return Results.Json(Find(conn, userId, id)!);
    }

    /// <summary>DELETE /accounts/{id} -> 204 | 404. The account's transactions
    /// go with it (ON DELETE CASCADE).</summary>
    public static IResult Delete(HttpContext context, long id)
    {
        using var conn = Db.Open();
        if (Find(conn, Auth.CurrentUserId(context), id) is null)
            return Errors.NotFound("Счёт не найден");

        using var delete = conn.Cmd("DELETE FROM accounts WHERE id = $id", ("$id", id));
        delete.ExecuteNonQuery();
        return Results.NoContent();
    }
}
