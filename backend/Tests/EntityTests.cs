using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;

namespace PamBackend.Tests;

/// <summary>Accounts, transactions, budgets and profile - the WalletMate
/// entities added to the template.</summary>
[Collection("api")]
public class EntityTests(ApiFixture api)
{
    private static decimal Balance(JsonElement account) => account.GetProperty("balance").GetDecimal();

    // ------------------------------------------------------------------ accounts

    [Fact]
    public async Task Balance_is_opening_balance_plus_incomes_minus_expenses()
    {
        var client = await api.NewUser();
        var id = await client.CreateAccount(initialBalance: 100);
        await client.CreateTransaction(id, 50, "income", "salary");
        await client.CreateTransaction(id, 30.25m);

        var account = await (await client.GetAsync($"/accounts/{id}")).Json(HttpStatusCode.OK);
        Assert.Equal(119.75m, Balance(account));
    }

    [Fact]
    public async Task Money_is_summed_in_cents_without_float_drift()
    {
        var client = await api.NewUser();
        var id = await client.CreateAccount();
        foreach (var amount in new[] { 0.7m, 0.1m, 0.1m })
            await client.CreateTransaction(id, amount, "income", "gift");

        var account = await (await client.GetAsync($"/accounts/{id}")).Json(HttpStatusCode.OK);
        Assert.Equal("0.9", account.GetProperty("balance").GetRawText());
    }

    [Fact]
    public async Task Account_names_are_unique_per_user_ignoring_case_in_cyrillic()
    {
        var client = await api.NewUser();
        await client.CreateAccount("Наличные");
        var duplicate = await client.PostAsJsonAsync("/accounts",
            new { name = "наличные", currency = "MDL", kind = "cash" });
        Assert.Equal("CONFLICT", await duplicate.ErrorCode(HttpStatusCode.Conflict));

        // Another user may use the same name.
        var other = await api.NewUser();
        await other.CreateAccount("Наличные");
    }

    [Theory]
    [InlineData("", "MDL", "card")]
    [InlineData("Карта", "XYZ", "card")]
    [InlineData("Карта", "MDL", "crypto")]
    public async Task Account_input_is_validated(string name, string currency, string kind)
    {
        var client = await api.NewUser();
        var response = await client.PostAsJsonAsync("/accounts", new { name, currency, kind });
        Assert.Equal("VALIDATION_ERROR", await response.ErrorCode(HttpStatusCode.BadRequest));
    }

    [Fact]
    public async Task Update_keeps_the_opening_balance()
    {
        var client = await api.NewUser();
        var id = await client.CreateAccount("Карта", initialBalance: 500);
        var updated = await (await client.PutAsJsonAsync($"/accounts/{id}",
                new { name = "Карта Maib", currency = "MDL", kind = "card", initialBalance = 1 }))
            .Json(HttpStatusCode.OK);
        Assert.Equal("Карта Maib", updated.GetProperty("name").GetString());
        Assert.Equal(500m, updated.GetProperty("initialBalance").GetDecimal());
    }

    [Fact]
    public async Task Deleting_an_account_deletes_its_transactions()
    {
        var client = await api.NewUser();
        var keep = await client.CreateAccount("Карта");
        var drop = await client.CreateAccount("Наличные");
        await client.CreateTransaction(keep, 10);
        await client.CreateTransaction(drop, 20);
        await client.CreateTransaction(drop, 30);

        await (await client.DeleteAsync($"/accounts/{drop}")).Json(HttpStatusCode.NoContent);

        var list = await (await client.GetAsync("/transactions")).Json(HttpStatusCode.OK);
        Assert.Equal(1, list.GetProperty("total").GetInt64());
        Assert.Equal("NOT_FOUND", await (await client.GetAsync($"/accounts/{drop}")).ErrorCode(HttpStatusCode.NotFound));
    }

    // ------------------------------------------------------------------ isolation

    [Fact]
    public async Task A_user_cannot_see_or_touch_another_users_records()
    {
        var owner = await api.NewUser();
        var account = await owner.CreateAccount();
        var transaction = await owner.CreateTransaction(account, 10);
        var budget = (await (await owner.PostAsJsonAsync("/budgets",
            new { category = "food", limitAmount = 100, month = "2026-09" })).Json(HttpStatusCode.Created))
            .GetProperty("id").GetInt64();

        var stranger = await api.NewUser();
        foreach (var path in new[] { $"/accounts/{account}", $"/transactions/{transaction}", $"/budgets/{budget}" })
        {
            Assert.Equal("NOT_FOUND", await (await stranger.GetAsync(path)).ErrorCode(HttpStatusCode.NotFound));
            Assert.Equal("NOT_FOUND", await (await stranger.DeleteAsync(path)).ErrorCode(HttpStatusCode.NotFound));
        }

        // Writing onto someone else's account looks exactly like a missing one.
        var foreign = await stranger.PostAsJsonAsync("/transactions", new
        {
            accountId = account, amount = 5, type = "expense", category = "food", date = "2026-09-01T10:00:00Z",
        });
        Assert.Equal("NOT_FOUND", await foreign.ErrorCode(HttpStatusCode.NotFound));

        var mine = await (await stranger.GetAsync("/transactions")).Json(HttpStatusCode.OK);
        Assert.Equal(0, mine.GetProperty("total").GetInt64());
        // The owner's records are intact.
        await (await owner.GetAsync($"/transactions/{transaction}")).Json(HttpStatusCode.OK);
    }

    // ------------------------------------------------------------------ transactions

    [Theory]
    [InlineData(0, "expense", "food", "Сумма должна быть больше нуля")]
    [InlineData(10.555, "expense", "food", "Не больше двух знаков после запятой")]
    [InlineData(2_000_000, "expense", "food", "Сумма не может быть больше 1 000 000")]
    [InlineData(10, "income", "food", "Категория не подходит к типу операции")]
    [InlineData(10, "transfer", "food", "Тип операции должен быть income или expense")]
    public async Task Transaction_input_is_validated(double amount, string type, string category, string message)
    {
        var client = await api.NewUser();
        var account = await client.CreateAccount();
        var response = await client.PostAsJsonAsync("/transactions", new
        {
            accountId = account, amount = (decimal)amount, type, category, date = "2026-09-01T10:00:00Z",
        });
        var body = await response.Json(HttpStatusCode.BadRequest);
        Assert.Equal(message, body.GetProperty("error").GetProperty("message").GetString());
    }

    [Fact]
    public async Task A_transaction_cannot_be_dated_after_tomorrow()
    {
        var client = await api.NewUser();
        var account = await client.CreateAccount();
        var response = await client.PostAsJsonAsync("/transactions", new
        {
            accountId = account, amount = 10, type = "expense", category = "food",
            date = DateTimeOffset.UtcNow.AddDays(3),
        });
        Assert.Equal("VALIDATION_ERROR", await response.ErrorCode(HttpStatusCode.BadRequest));
    }

    [Fact]
    public async Task List_is_paginated_newest_first_and_filtered()
    {
        var client = await api.NewUser();
        var card = await client.CreateAccount("Карта");
        var cash = await client.CreateAccount("Наличные");
        await client.CreateTransaction(card, 10, date: "2026-08-31T23:00:00Z", note: "август");
        await client.CreateTransaction(card, 20, date: "2026-09-02T10:00:00Z", note: "кофе утром");
        await client.CreateTransaction(cash, 30, category: "transport", date: "2026-09-05T10:00:00Z");
        await client.CreateTransaction(card, 40, "income", "salary", "2026-09-10T10:00:00Z");

        var page1 = await (await client.GetAsync("/transactions?limit=3&page=1")).Json(HttpStatusCode.OK);
        Assert.Equal(4, page1.GetProperty("total").GetInt64());
        var amounts = page1.GetProperty("items").EnumerateArray().Select(i => i.GetProperty("amount").GetDecimal());
        Assert.Equal([40m, 30m, 20m], amounts);
        var page2 = await (await client.GetAsync("/transactions?limit=3&page=2")).Json(HttpStatusCode.OK);
        Assert.Single(page2.GetProperty("items").EnumerateArray());

        async Task<long> Count(string query) =>
            (await (await client.GetAsync($"/transactions?{query}")).Json(HttpStatusCode.OK))
            .GetProperty("total").GetInt64();

        Assert.Equal(3, await Count("type=expense"));
        Assert.Equal(1, await Count("category=transport"));
        Assert.Equal(1, await Count($"accountId={cash}"));
        Assert.Equal(3, await Count("from=2026-09-01T00:00:00Z&to=2026-09-30T23:59:59Z"));
        Assert.Equal(1, await Count("search=" + Uri.EscapeDataString("кофе")));
    }

    // ------------------------------------------------------------------ budgets

    [Fact]
    public async Task Budget_spent_counts_expenses_of_its_category_month_and_currency()
    {
        var client = await api.NewUser();
        var mdl = await client.CreateAccount("Карта", "MDL");
        var eur = await client.CreateAccount("Сбережения", "EUR");
        await client.CreateTransaction(mdl, 100, date: "2026-09-03T10:00:00Z");
        await client.CreateTransaction(mdl, 25.50m, date: "2026-09-20T10:00:00Z");
        await client.CreateTransaction(mdl, 70, date: "2026-08-20T10:00:00Z");      // other month
        await client.CreateTransaction(mdl, 40, category: "transport", date: "2026-09-04T10:00:00Z"); // other category
        await client.CreateTransaction(eur, 999, date: "2026-09-05T10:00:00Z");     // other currency

        var budget = await (await client.PostAsJsonAsync("/budgets",
            new { category = "food", limitAmount = 140, month = "2026-09" })).Json(HttpStatusCode.Created);
        Assert.Equal(125.5m, budget.GetProperty("spentAmount").GetDecimal());

        // Switching the default currency switches which accounts count.
        await (await client.PutAsJsonAsync("/profile",
            new { displayName = "Test User", defaultCurrency = "EUR" })).Json(HttpStatusCode.OK);
        var again = await (await client.GetAsync($"/budgets/{budget.GetProperty("id").GetInt64()}")).Json(HttpStatusCode.OK);
        Assert.Equal(999m, again.GetProperty("spentAmount").GetDecimal());
    }

    [Fact]
    public async Task One_budget_per_category_and_month()
    {
        var client = await api.NewUser();
        await (await client.PostAsJsonAsync("/budgets",
            new { category = "food", limitAmount = 100, month = "2026-09" })).Json(HttpStatusCode.Created);
        var duplicate = await client.PostAsJsonAsync("/budgets",
            new { category = "food", limitAmount = 200, month = "2026-09" });
        Assert.Equal("CONFLICT", await duplicate.ErrorCode(HttpStatusCode.Conflict));
        await (await client.PostAsJsonAsync("/budgets",
            new { category = "food", limitAmount = 200, month = "2026-10" })).Json(HttpStatusCode.Created);

        var september = await (await client.GetAsync("/budgets?month=2026-09")).Json(HttpStatusCode.OK);
        Assert.Equal(1, september.GetProperty("total").GetInt64());
    }

    [Theory]
    [InlineData("salary", 100, "2026-09")]
    [InlineData("food", 0, "2026-09")]
    [InlineData("food", 100, "2026-13")]
    public async Task Budget_input_is_validated(string category, decimal limitAmount, string month)
    {
        var client = await api.NewUser();
        var response = await client.PostAsJsonAsync("/budgets", new { category, limitAmount, month });
        Assert.Equal("VALIDATION_ERROR", await response.ErrorCode(HttpStatusCode.BadRequest));
    }

    // ------------------------------------------------------------------ profile

    [Fact]
    public async Task Profile_update_and_avatar_upload()
    {
        var client = await api.NewUser("Ion");
        var profile = await (await client.GetAsync("/profile")).Json(HttpStatusCode.OK);
        Assert.Equal("Ion", profile.GetProperty("displayName").GetString());
        Assert.Equal("MDL", profile.GetProperty("defaultCurrency").GetString());

        // 1x1 GIF through the template's POST /files.
        var gif = Convert.FromBase64String("R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7");
        var form = new MultipartFormDataContent();
        var file = new ByteArrayContent(gif);
        file.Headers.ContentType = new MediaTypeHeaderValue("image/gif");
        form.Add(file, "file", "avatar.gif");
        var uploaded = await (await client.PostAsync("/files", form)).Json(HttpStatusCode.Created);
        var fileId = uploaded.GetProperty("id").GetInt64();

        var updated = await (await client.PutAsJsonAsync("/profile",
            new { displayName = "Ion Rusu", defaultCurrency = "EUR", avatarFileId = fileId })).Json(HttpStatusCode.OK);
        Assert.Equal("Ion Rusu", updated.GetProperty("displayName").GetString());
        Assert.Equal("EUR", updated.GetProperty("defaultCurrency").GetString());
        Assert.Equal($"/files/{fileId}", updated.GetProperty("avatarUrl").GetString());

        // The avatar URL is public, like every file of the template.
        var image = await api.Anonymous().GetAsync($"/files/{fileId}");
        Assert.Equal(HttpStatusCode.OK, image.StatusCode);

        // Someone else's file cannot become my avatar.
        var stranger = await api.NewUser();
        var foreign = await stranger.PutAsJsonAsync("/profile",
            new { displayName = "X", defaultCurrency = "MDL", avatarFileId = fileId });
        Assert.Equal("NOT_FOUND", await foreign.ErrorCode(HttpStatusCode.NotFound));
    }

    [Fact]
    public async Task A_non_image_file_is_not_an_avatar()
    {
        var client = await api.NewUser();
        var form = new MultipartFormDataContent();
        var file = new ByteArrayContent("hello"u8.ToArray());
        file.Headers.ContentType = new MediaTypeHeaderValue("text/plain");
        form.Add(file, "file", "note.txt");
        var uploaded = await (await client.PostAsync("/files", form)).Json(HttpStatusCode.Created);

        var response = await client.PutAsJsonAsync("/profile", new
        {
            displayName = "X", defaultCurrency = "MDL", avatarFileId = uploaded.GetProperty("id").GetInt64(),
        });
        Assert.Equal("VALIDATION_ERROR", await response.ErrorCode(HttpStatusCode.BadRequest));
    }
}
