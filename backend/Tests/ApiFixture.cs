using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;

namespace PamBackend.Tests;

/// <summary>
/// One in-memory server for the whole test run, on a fresh SQLite file in a
/// temp folder. The demo account is seeded as on a real first start.
/// </summary>
public sealed class ApiFixture : IDisposable
{
    private readonly string _dir = Path.Combine(Path.GetTempPath(), $"walletmate-tests-{Guid.NewGuid():N}");
    private readonly WebApplicationFactory<Program> _factory;

    public ApiFixture()
    {
        Directory.CreateDirectory(_dir);
        // Read by Program.cs at startup; must be set before the server is built.
        Environment.SetEnvironmentVariable("DB_PATH", Path.Combine(_dir, "app.db"));
        Environment.SetEnvironmentVariable("UPLOADS_DIR", Path.Combine(_dir, "uploads"));
        Environment.SetEnvironmentVariable("SEED_DEMO", "true");
        _factory = new WebApplicationFactory<Program>();
    }

    public HttpClient Anonymous() => _factory.CreateClient();

    /// <summary>Registers a brand-new user and returns a client carrying their token.</summary>
    public async Task<HttpClient> NewUser(string name = "Test User")
    {
        var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync("/auth/register", new
        {
            email = $"user-{Guid.NewGuid():N}@test.md",
            password = "Secret123",
            name,
        });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", body.GetProperty("token").GetString());
        return client;
    }

    /// <summary>A client signed in as the seeded demo account.</summary>
    public async Task<HttpClient> Demo()
    {
        var client = _factory.CreateClient();
        var response = await client.PostAsJsonAsync("/auth/login",
            new { email = Seed.DemoEmail, password = Seed.DemoPassword });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        client.DefaultRequestHeaders.Authorization =
            new AuthenticationHeaderValue("Bearer", body.GetProperty("token").GetString());
        return client;
    }

    public void Dispose()
    {
        _factory.Dispose();
        Microsoft.Data.Sqlite.SqliteConnection.ClearAllPools();
        try { Directory.Delete(_dir, recursive: true); } catch (IOException) { }
    }
}

[CollectionDefinition("api")]
public sealed class ApiCollection : ICollectionFixture<ApiFixture>;

/// <summary>Small helpers shared by the test classes.</summary>
public static class Http
{
    public static async Task<JsonElement> Json(this HttpResponseMessage response, HttpStatusCode expected)
    {
        var text = await response.Content.ReadAsStringAsync();
        Assert.True(response.StatusCode == expected,
            $"expected {(int)expected}, got {(int)response.StatusCode}: {text}");
        return text.Length == 0 ? default : JsonDocument.Parse(text).RootElement;
    }

    /// <summary>Asserts the template's error shape and returns the code.</summary>
    public static async Task<string> ErrorCode(this HttpResponseMessage response, HttpStatusCode expected)
    {
        var body = await response.Json(expected);
        var error = body.GetProperty("error");
        Assert.False(string.IsNullOrEmpty(error.GetProperty("message").GetString()));
        return error.GetProperty("code").GetString()!;
    }

    public static async Task<long> CreateAccount(this HttpClient client,
        string name = "Карта", string currency = "MDL", decimal initialBalance = 0)
    {
        var body = await (await client.PostAsJsonAsync("/accounts",
            new { name, currency, kind = "card", initialBalance })).Json(HttpStatusCode.Created);
        return body.GetProperty("id").GetInt64();
    }

    public static async Task<long> CreateTransaction(this HttpClient client, long accountId,
        decimal amount, string type = "expense", string category = "food",
        string date = "2026-09-14T10:00:00Z", string? note = null)
    {
        var body = await (await client.PostAsJsonAsync("/transactions",
                new { accountId, amount, type, category, date, note }))
            .Json(HttpStatusCode.Created);
        return body.GetProperty("id").GetInt64();
    }
}
