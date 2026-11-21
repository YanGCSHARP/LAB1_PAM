// Budgets: a monthly spending limit per category. Built from the Notes.cs
// template: CRUD + pagination, scoped per user, filterable by month.
//
// `spentAmount` is computed on every read: the expenses of the budget's
// category and month on the user's accounts in their default currency -
// amounts in other currencies are never mixed in.

using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Budget(
    long Id, string Category, decimal LimitAmount, string Month,
    decimal SpentAmount, string CreatedAt);

public record BudgetInput(string? Category, decimal? LimitAmount, string? Month);

public static class Budgets
{
    // The month of an operation is taken from its UTC date - the same day
    // boundary for every client, whatever its time zone.
    private const string Select = """
        SELECT b.id, b.category, b.limit_cents, b.month,
               (SELECT COALESCE(SUM(t.amount_cents), 0)
                  FROM transactions t
                  JOIN accounts a ON a.id = t.account_id
                  JOIN users u ON u.id = a.user_id
                 WHERE a.user_id = b.user_id AND a.currency = u.default_currency
                   AND t.type = 'expense' AND t.category = b.category
                   AND substr(t.date, 1, 7) = b.month),
               b.created_at
        FROM budgets b
        """;

    private static Budget Read(SqliteDataReader r) => new(
        r.GetInt64(0), r.GetString(1), Money.FromCents(r.GetInt64(2)), r.GetString(3),
        Money.FromCents(r.GetInt64(4)), r.GetString(5));

    private static Budget? Find(SqliteConnection conn, long userId, long id)
    {
        using var cmd = conn.Cmd($"{Select} WHERE b.id = $id AND b.user_id = $userId",
            ("$id", id), ("$userId", userId));
        using var reader = cmd.ExecuteReader();
        return reader.Read() ? Read(reader) : null;
    }

    private static bool Taken(SqliteConnection conn, long userId, string category, string month, long? exceptId)
    {
        using var cmd = conn.Cmd(
            "SELECT 1 FROM budgets WHERE user_id = $userId AND category = $category " +
            "AND month = $month AND id IS NOT $exceptId",
            ("$userId", userId), ("$category", category), ("$month", month), ("$exceptId", exceptId));
        return cmd.ExecuteScalar() is not null;
    }

    private static IResult? Validate(BudgetInput input)
    {
        // Budgets limit spending, so only expense categories qualify.
        if (input.Category is null || !Catalog.IsCategory("expense", input.Category))
            return Errors.Validation("Выберите категорию расходов");
        if (Money.ValidatePositive(input.LimitAmount, "limitAmount") is { } error)
            return Errors.Validation(error.Replace("Сумма", "Лимит"));
        if (!Catalog.IsMonth(input.Month)) return Errors.Validation("Месяц в формате ГГГГ-ММ");
        return null;
    }

    /// <summary>GET /budgets?month=2026-09&amp;page&amp;limit -> {items, page, limit, total}</summary>
    public static IResult List(HttpContext context, int page = 1, int limit = 20, string? month = null)
    {
        page = Math.Max(page, 1);
        limit = Math.Clamp(limit, 1, 100);
        var userId = Auth.CurrentUserId(context);
        const string where = "b.user_id = $userId AND ($month IS NULL OR b.month = $month)";

        using var conn = Db.Open();
        long total;
        using (var count = conn.Cmd($"SELECT COUNT(*) FROM budgets b WHERE {where}",
                   ("$userId", userId), ("$month", month)))
        {
            total = (long)count.ExecuteScalar()!;
        }

        var items = new List<Budget>();
        using var cmd = conn.Cmd(
            $"{Select} WHERE {where} ORDER BY b.month DESC, b.id LIMIT $limit OFFSET $offset",
            ("$userId", userId), ("$month", month), ("$limit", limit), ("$offset", (page - 1) * limit));
        using var reader = cmd.ExecuteReader();
        while (reader.Read()) items.Add(Read(reader));

        return Results.Json(new { items, page, limit, total });
    }

    /// <summary>POST /budgets {category, limitAmount, month} -> 201 | 409</summary>
    public static IResult Create(HttpContext context, BudgetInput input)
    {
        if (Validate(input) is { } error) return error;
        var userId = Auth.CurrentUserId(context);

        using var conn = Db.Open();
        if (Taken(conn, userId, input.Category!, input.Month!, null))
            return Errors.Conflict("На эту категорию в этом месяце бюджет уже есть");

        using (var insert = conn.Cmd(
                   "INSERT INTO budgets (user_id, category, limit_cents, month, created_at) " +
                   "VALUES ($userId, $category, $limit, $month, $createdAt)",
                   ("$userId", userId), ("$category", input.Category),
                   ("$limit", Money.ToCents(input.LimitAmount!.Value)), ("$month", input.Month),
                   ("$createdAt", Db.NowIso())))
        {
            insert.ExecuteNonQuery();
        }
        var budget = Find(conn, userId, conn.LastInsertRowId())!;
        return Results.Created($"/budgets/{budget.Id}", budget);
    }

    /// <summary>GET /budgets/{id} -> 200 | 404</summary>
    public static IResult GetOne(HttpContext context, long id)
    {
        using var conn = Db.Open();
        var budget = Find(conn, Auth.CurrentUserId(context), id);
        return budget is null ? Errors.NotFound("Бюджет не найден") : Results.Json(budget);
    }

    /// <summary>PUT /budgets/{id} - body as for POST -> 200 | 404 | 409</summary>
    public static IResult Update(HttpContext context, long id, BudgetInput input)
    {
        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();
        if (Find(conn, userId, id) is null) return Errors.NotFound("Бюджет не найден");
        if (Validate(input) is { } error) return error;
        if (Taken(conn, userId, input.Category!, input.Month!, id))
            return Errors.Conflict("На эту категорию в этом месяце бюджет уже есть");

        using (var update = conn.Cmd(
                   "UPDATE budgets SET category = $category, limit_cents = $limit, month = $month " +
                   "WHERE id = $id",
                   ("$category", input.Category), ("$limit", Money.ToCents(input.LimitAmount!.Value)),
                   ("$month", input.Month), ("$id", id)))
        {
            update.ExecuteNonQuery();
        }
        return Results.Json(Find(conn, userId, id)!);
    }

    /// <summary>DELETE /budgets/{id} -> 204 | 404. Operations are not touched.</summary>
    public static IResult Delete(HttpContext context, long id)
    {
        using var conn = Db.Open();
        if (Find(conn, Auth.CurrentUserId(context), id) is null)
            return Errors.NotFound("Бюджет не найден");

        using var delete = conn.Cmd("DELETE FROM budgets WHERE id = $id", ("$id", id));
        delete.ExecuteNonQuery();
        return Results.NoContent();
    }
}
