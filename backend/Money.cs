// WalletMate: dictionaries of the data model and the money conversion.
//
// The API speaks decimal amounts with at most two digits after the point;
// the database stores whole cents. Every amount crosses this boundary here.

namespace PamBackend;

public static class Money
{
    /// <summary>The largest amount one operation or limit may carry.</summary>
    public const decimal MaxAmount = 1_000_000m;

    public static long ToCents(decimal amount) => (long)(amount * 100m);

    public static decimal FromCents(long cents) => cents / 100m;

    /// <summary>
    /// Checks a client amount: positive, at most two decimals, not above
    /// <see cref="MaxAmount"/>. Returns the error text or null when valid.
    /// </summary>
    public static string? ValidatePositive(decimal? amount, string field)
    {
        if (amount is null) return $"Поле {field} обязательно";
        if (amount <= 0) return "Сумма должна быть больше нуля";
        if (amount > MaxAmount) return "Сумма не может быть больше 1 000 000";
        if (decimal.Round(amount.Value, 2) != amount) return "Не больше двух знаков после запятой";
        return null;
    }
}

public static class Catalog
{
    public static readonly string[] Currencies = ["MDL", "EUR", "USD"];

    public static readonly string[] AccountKinds = ["card", "cash", "savings"];

    /// <summary>Category keys by transaction type, as in docs/er-diagram.md.
    /// Labels are the client's business; the server only checks the key.</summary>
    public static readonly Dictionary<string, string[]> Categories = new()
    {
        ["expense"] =
        [
            "food", "transport", "housing", "utilities", "health",
            "education", "entertainment", "shopping", "other",
        ],
        ["income"] = ["salary", "scholarship", "freelance", "gift", "other"],
    };

    public static bool IsCategory(string type, string category) =>
        Categories.TryGetValue(type, out var keys) && keys.Contains(category);

    /// <summary>`YYYY-MM`, the month key of budgets and filters.</summary>
    public static bool IsMonth(string? value) =>
        value is { Length: 7 } &&
        DateTime.TryParseExact(value + "-01", "yyyy-MM-dd", null,
            System.Globalization.DateTimeStyles.None, out _);
}
