using System.Net;
using System.Net.Http.Json;

namespace PamBackend.Tests;

/// <summary>What the template provides must keep working after the
/// WalletMate entities were added: auth, the error shape, files.</summary>
[Collection("api")]
public class AuthAndTemplateTests(ApiFixture api)
{
    [Fact]
    public async Task Health_answers_ok()
    {
        var body = await (await api.Anonymous().GetAsync("/health")).Json(HttpStatusCode.OK);
        Assert.Equal("ok", body.GetProperty("status").GetString());
    }

    [Fact]
    public async Task Unknown_route_is_404_in_the_standard_shape()
    {
        var code = await (await api.Anonymous().GetAsync("/no-such-route")).ErrorCode(HttpStatusCode.NotFound);
        Assert.Equal("NOT_FOUND", code);
    }

    [Theory]
    [InlineData("/accounts")]
    [InlineData("/transactions")]
    [InlineData("/budgets")]
    [InlineData("/profile")]
    public async Task Every_entity_route_needs_a_token(string path)
    {
        var code = await (await api.Anonymous().GetAsync(path)).ErrorCode(HttpStatusCode.Unauthorized);
        Assert.Equal("UNAUTHORIZED", code);
    }

    [Fact]
    public async Task A_forged_token_is_rejected()
    {
        var client = api.Anonymous();
        client.DefaultRequestHeaders.Add("Authorization",
            "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiZXhwIjo0MTAyNDQ0ODAwfQ.forged");
        Assert.Equal("UNAUTHORIZED", await (await client.GetAsync("/accounts")).ErrorCode(HttpStatusCode.Unauthorized));
    }

    [Fact]
    public async Task Register_then_login_then_me()
    {
        var client = api.Anonymous();
        var email = $"ion-{Guid.NewGuid():N}@test.md";
        await (await client.PostAsJsonAsync("/auth/register",
            new { email, password = "Secret123", name = "Ion" })).Json(HttpStatusCode.Created);

        var duplicate = await client.PostAsJsonAsync("/auth/register",
            new { email, password = "Other123", name = "Ion" });
        Assert.Equal("EMAIL_TAKEN", await duplicate.ErrorCode(HttpStatusCode.Conflict));

        var wrong = await client.PostAsJsonAsync("/auth/login", new { email, password = "nope" });
        Assert.Equal("UNAUTHORIZED", await wrong.ErrorCode(HttpStatusCode.Unauthorized));

        var login = await (await client.PostAsJsonAsync("/auth/login",
            new { email, password = "Secret123" })).Json(HttpStatusCode.OK);
        client.DefaultRequestHeaders.Add("Authorization", $"Bearer {login.GetProperty("token").GetString()}");
        var me = await (await client.GetAsync("/me")).Json(HttpStatusCode.OK);
        Assert.Equal(email, me.GetProperty("email").GetString());
    }

    [Fact]
    public async Task Malformed_json_is_a_validation_error_not_a_500()
    {
        var client = await api.NewUser();
        var response = await client.PostAsync("/accounts",
            new StringContent("{\"name\": ", System.Text.Encoding.UTF8, "application/json"));
        Assert.Equal("VALIDATION_ERROR", await response.ErrorCode(HttpStatusCode.BadRequest));
    }

    [Fact]
    public async Task Demo_account_is_seeded_without_future_dates()
    {
        var client = await api.Demo();

        var accounts = await (await client.GetAsync("/accounts")).Json(HttpStatusCode.OK);
        Assert.Equal(3, accounts.GetProperty("total").GetInt64());

        var month = DateTime.Now.ToString("yyyy-MM");
        var budgets = await (await client.GetAsync($"/budgets?month={month}")).Json(HttpStatusCode.OK);
        Assert.Equal(5, budgets.GetProperty("total").GetInt64());

        var transactions = await (await client.GetAsync("/transactions?limit=100")).Json(HttpStatusCode.OK);
        Assert.True(transactions.GetProperty("total").GetInt64() >= 9);
        foreach (var item in transactions.GetProperty("items").EnumerateArray())
        {
            Assert.True(DateTimeOffset.Parse(item.GetProperty("date").GetString()!) <= DateTimeOffset.UtcNow);
        }
    }
}
