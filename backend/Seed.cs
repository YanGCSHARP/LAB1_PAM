// WalletMate: the demo account, filled on the first start of an empty
// database - the same data the app's mock backend shows.
//
// Operations are laid out relative to today: the full previous month and the
// current month up to today, so the dashboard always opens on a month with
// data and nothing is dated in the future.
//
// Demo login: demo@walletmate.md / Demo1234. Set SEED_DEMO=false to start
// with an empty database.

namespace PamBackend;

public static class Seed
{
    public const string DemoEmail = "demo@walletmate.md";
    public const string DemoPassword = "Demo1234";

    /// <summary>One seed operation: account index (1-3), day of month and
    /// wall-clock time instead of a date.</summary>
    private record Entry(int Account, decimal Amount, string Type, string Category,
        int Day, int Hour, int Minute, string Note);

    private static readonly (string Name, string Currency, string Kind, decimal Initial)[] DemoAccounts =
    [
        ("Карта Maib", "MDL", "card", 1250m),
        ("Наличные", "MDL", "cash", 1500m),
        ("Сбережения", "EUR", "savings", 250m),
    ];

    private static readonly Entry[] CurrentMonth =
    [
        new(1, 1600m, "income", "scholarship", 1, 8, 30, "Стипендия УТМ"),
        new(1, 249.90m, "expense", "food", 2, 17, 40, "Продукты, Linella"),
        new(2, 200m, "expense", "transport", 3, 7, 15, "Проездной на троллейбус"),
        new(1, 1500m, "expense", "housing", 4, 10, 0, "Аренда квартиры"),
        new(1, 6400m, "income", "salary", 5, 9, 0, "Зарплата за прошлый месяц"),
        new(1, 420m, "expense", "food", 6, 15, 20, "Закупка на неделю, Kaufland"),
        new(1, 480m, "expense", "utilities", 7, 12, 5, "Свет, вода, интернет"),
        new(1, 140m, "expense", "transport", 8, 21, 50, "Такси домой"),
        new(2, 85m, "expense", "food", 9, 11, 30, "Обед в столовой"),
        new(2, 180m, "expense", "entertainment", 10, 19, 0, "Кино с друзьями"),
        new(2, 120m, "expense", "health", 11, 13, 25, "Аптека"),
        new(1, 300m, "expense", "transport", 12, 8, 45, "Бензин"),
        new(1, 312.40m, "expense", "food", 13, 18, 10, "Продукты, Nr.1"),
        new(1, 420m, "expense", "shopping", 14, 16, 0, "Кроссовки"),
        new(1, 350m, "expense", "education", 15, 14, 30, "Курс английского"),
        new(2, 90m, "expense", "other", 16, 20, 15, "Подарочная открытка и цветы"),
        new(2, 132.70m, "expense", "food", 17, 9, 50, "Кофе и выпечка"),
        new(1, 1200m, "income", "freelance", 18, 11, 0, "Вёрстка лендинга"),
    ];

    private static readonly Entry[] PreviousMonth =
    [
        new(1, 1600m, "income", "scholarship", 1, 8, 30, "Стипендия УТМ"),
        new(1, 380.50m, "expense", "food", 3, 17, 0, "Продукты, Kaufland"),
        new(1, 6200m, "income", "salary", 5, 9, 0, "Зарплата за позапрошлый месяц"),
        new(1, 1500m, "expense", "housing", 7, 10, 0, "Аренда квартиры"),
        new(2, 200m, "expense", "transport", 10, 7, 20, "Проездной на троллейбус"),
        new(2, 260m, "expense", "entertainment", 14, 20, 30, "Концерт в парке"),
        new(1, 890m, "expense", "shopping", 18, 15, 45, "Осенняя куртка"),
        new(3, 100m, "income", "gift", 20, 12, 0, "Подарок на день рождения"),
        new(1, 460m, "expense", "utilities", 28, 11, 10, "Свет, вода, интернет"),
    ];

    /// <summary>Budgets of the current month: with the full month of data
    /// `food` lands in the warning band and `transport` over the limit.</summary>
    private static readonly (string Category, decimal Limit)[] DemoBudgets =
    [
        ("food", 1300m), ("transport", 600m), ("entertainment", 500m),
        ("shopping", 800m), ("health", 400m),
    ];

    /// <summary>Creates the demo account unless the database already has users.</summary>
    public static void Run(DateTime today)
    {
        using var conn = Db.Open();
        using (var any = conn.Cmd("SELECT 1 FROM users LIMIT 1"))
        {
            if (any.ExecuteScalar() is not null) return;
        }
        using (var user = conn.Cmd(
                   "INSERT INTO users (email, password_hash, name, created_at, default_currency) " +
                   "VALUES ($email, $hash, $name, $createdAt, 'MDL')",
                   ("$email", DemoEmail), ("$hash", Auth.HashPassword(DemoPassword)),
                   ("$name", "Ion Rusu"), ("$createdAt", Db.NowIso())))
        {
            user.ExecuteNonQuery();
        }
        var userId = conn.LastInsertRowId();

        var accountIds = new List<long>();
        foreach (var (name, currency, kind, initial) in DemoAccounts)
        {
            using var insert = conn.Cmd(
                "INSERT INTO accounts (user_id, name, currency, kind, initial_balance_cents, created_at) " +
                "VALUES ($userId, $name, $currency, $kind, $initial, $createdAt)",
                ("$userId", userId), ("$name", name), ("$currency", currency), ("$kind", kind),
                ("$initial", Money.ToCents(initial)), ("$createdAt", Db.NowIso()));
            insert.ExecuteNonQuery();
            accountIds.Add(conn.LastInsertRowId());
        }

        var month = new DateTime(today.Year, today.Month, 1);
        var operations = CurrentMonth.Where(e => e.Day <= today.Day).Select(e => (e, month))
            .Concat(PreviousMonth.Select(e => (e, month.AddMonths(-1))))
            .OrderBy(pair => pair.Item2.AddDays(pair.e.Day));
        foreach (var (entry, baseMonth) in operations)
        {
            var day = Math.Min(entry.Day, DateTime.DaysInMonth(baseMonth.Year, baseMonth.Month));
            // Wall-clock time of the server's zone, stored in UTC like every date.
            var local = new DateTime(baseMonth.Year, baseMonth.Month, day, entry.Hour, entry.Minute, 0,
                DateTimeKind.Local);
            using var insert = conn.Cmd(
                "INSERT INTO transactions (account_id, amount_cents, type, category, date, note, created_at) " +
                "VALUES ($accountId, $amount, $type, $category, $date, $note, $createdAt)",
                ("$accountId", accountIds[entry.Account - 1]), ("$amount", Money.ToCents(entry.Amount)),
                ("$type", entry.Type), ("$category", entry.Category),
                ("$date", Transactions.StoreDate(new DateTimeOffset(local))), ("$note", entry.Note),
                ("$createdAt", Db.NowIso()));
            insert.ExecuteNonQuery();
        }

        foreach (var (category, limit) in DemoBudgets)
        {
            using var insert = conn.Cmd(
                "INSERT INTO budgets (user_id, category, limit_cents, month, created_at) " +
                "VALUES ($userId, $category, $limit, $month, $createdAt)",
                ("$userId", userId), ("$category", category), ("$limit", Money.ToCents(limit)),
                ("$month", month.ToString("yyyy-MM")), ("$createdAt", Db.NowIso()));
            insert.ExecuteNonQuery();
        }
    }
}
