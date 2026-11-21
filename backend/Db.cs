// SQLite setup. The database file is created automatically on first start.
//
// To add your own entity: add a CREATE TABLE below, then copy the pattern
// of Notes.cs for its routes.
//
// WalletMate tables: accounts, transactions, budgets. Money is stored in
// INTEGER cents - never REAL - so 0.1 + 0.2 stays 0.30 and a budget spent to
// exactly 90 % is 90 %, not 89.99 %. The API speaks decimal amounts; the
// conversion lives in Money.cs.

using Microsoft.Data.Sqlite;

namespace PamBackend;

public static class Db
{
    private static string _connectionString = "";

    /// <summary>Creates the database (and its schema) on first run.</summary>
    public static void Init(string path)
    {
        _connectionString = $"Data Source={path}";
        using var conn = Open();
        using var cmd = conn.CreateCommand();
        cmd.CommandText = """
            CREATE TABLE IF NOT EXISTS users (
              id            INTEGER PRIMARY KEY AUTOINCREMENT,
              email         TEXT    NOT NULL UNIQUE,
              password_hash TEXT    NOT NULL,
              name          TEXT    NOT NULL,
              created_at    TEXT    NOT NULL,
              -- WalletMate: profile fields on top of the template's user.
              default_currency TEXT NOT NULL DEFAULT 'MDL',
              avatar_file_id   INTEGER REFERENCES files (id)
            );

            CREATE TABLE IF NOT EXISTS notes (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id    INTEGER NOT NULL REFERENCES users (id),
              title      TEXT    NOT NULL,
              content    TEXT    NOT NULL DEFAULT '',
              created_at TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS files (
              id         INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id    INTEGER NOT NULL REFERENCES users (id),
              name       TEXT    NOT NULL,
              mime_type  TEXT    NOT NULL,
              size       INTEGER NOT NULL,
              path       TEXT    NOT NULL,
              created_at TEXT    NOT NULL
            );

            CREATE TABLE IF NOT EXISTS accounts (
              id                    INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id               INTEGER NOT NULL REFERENCES users (id),
              name                  TEXT    NOT NULL,
              currency              TEXT    NOT NULL,
              kind                  TEXT    NOT NULL,
              initial_balance_cents INTEGER NOT NULL DEFAULT 0,
              created_at            TEXT    NOT NULL,
              UNIQUE (user_id, name)
            );

            CREATE TABLE IF NOT EXISTS transactions (
              id           INTEGER PRIMARY KEY AUTOINCREMENT,
              account_id   INTEGER NOT NULL REFERENCES accounts (id) ON DELETE CASCADE,
              amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
              type         TEXT    NOT NULL CHECK (type IN ('income', 'expense')),
              category     TEXT    NOT NULL,
              date         TEXT    NOT NULL,
              note         TEXT,
              created_at   TEXT    NOT NULL
            );
            CREATE INDEX IF NOT EXISTS ix_transactions_account_date
              ON transactions (account_id, date);

            CREATE TABLE IF NOT EXISTS budgets (
              id          INTEGER PRIMARY KEY AUTOINCREMENT,
              user_id     INTEGER NOT NULL REFERENCES users (id),
              category    TEXT    NOT NULL,
              limit_cents INTEGER NOT NULL CHECK (limit_cents > 0),
              month       TEXT    NOT NULL,
              created_at  TEXT    NOT NULL,
              UNIQUE (user_id, category, month)
            );
            """;
        cmd.ExecuteNonQuery();
    }

    /// <summary>
    /// Opens a connection for one request. Always wrap it in `using` -
    /// Microsoft.Data.Sqlite pools connections, so this is cheap.
    /// </summary>
    public static SqliteConnection Open()
    {
        var conn = new SqliteConnection(_connectionString);
        conn.Open();
        // SQLite leaves foreign keys off per connection; ON DELETE CASCADE
        // (an account takes its transactions with it) needs them on.
        using var pragma = conn.CreateCommand();
        pragma.CommandText = "PRAGMA foreign_keys = ON";
        pragma.ExecuteNonQuery();
        return conn;
    }

    /// <summary>Current UTC time in ISO-8601, the format used for all timestamps.</summary>
    public static string NowIso() => DateTime.UtcNow.ToString("o");
}

/// <summary>
/// Two small helpers that keep the ADO.NET boilerplate out of the handlers
/// (the equivalent of Dart's `db.select(sql, args)`).
/// </summary>
public static class SqliteExtensions
{
    /// <summary>A parameterized command in one call. NEVER interpolate user
    /// input into the SQL string itself - always use parameters.</summary>
    public static SqliteCommand Cmd(this SqliteConnection conn, string sql,
        params (string Name, object? Value)[] args)
    {
        var cmd = conn.CreateCommand();
        cmd.CommandText = sql;
        foreach (var (name, value) in args)
            cmd.Parameters.AddWithValue(name, value ?? DBNull.Value);
        return cmd;
    }

    /// <summary>The id generated by the last INSERT on this connection.</summary>
    public static long LastInsertRowId(this SqliteConnection conn)
    {
        using var cmd = conn.Cmd("SELECT last_insert_rowid()");
        return (long)cmd.ExecuteScalar()!;
    }
}
