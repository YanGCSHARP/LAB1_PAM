// Profile: the template's user plus the WalletMate fields - default currency
// and avatar. `GET /me` of the template stays as it is; the app reads and
// edits its profile here.

using Microsoft.Data.Sqlite;

namespace PamBackend;

public record Profile(long Id, string Email, string DisplayName, string DefaultCurrency, string? AvatarUrl);

public record ProfileInput(string? DisplayName, string? DefaultCurrency, long? AvatarFileId);

public static class Profiles
{
    private static Profile? Find(SqliteConnection conn, long userId)
    {
        using var cmd = conn.Cmd(
            "SELECT id, email, name, default_currency, avatar_file_id FROM users WHERE id = $id",
            ("$id", userId));
        using var reader = cmd.ExecuteReader();
        if (!reader.Read()) return null;
        // The avatar is served by the template's public GET /files/{id}.
        var avatarUrl = reader.IsDBNull(4) ? null : $"/files/{reader.GetInt64(4)}";
        return new Profile(reader.GetInt64(0), reader.GetString(1), reader.GetString(2),
            reader.GetString(3), avatarUrl);
    }

    /// <summary>GET /profile -> {id, email, displayName, defaultCurrency, avatarUrl}</summary>
    public static IResult Get(HttpContext context)
    {
        using var conn = Db.Open();
        var profile = Find(conn, Auth.CurrentUserId(context));
        return profile is null ? Errors.Unauthorized() : Results.Json(profile);
    }

    /// <summary>
    /// PUT /profile {displayName, defaultCurrency, avatarFileId?} -> 200 profile.
    /// `avatarFileId` is the id returned by POST /files; null keeps the avatar.
    /// </summary>
    public static IResult Update(HttpContext context, ProfileInput input)
    {
        var name = Errors.Trimmed(input.DisplayName);
        if (name is null) return Errors.Validation("Введите имя");
        if (name.Length > 100) return Errors.Validation("Имя — не больше 100 символов");
        if (!Catalog.Currencies.Contains(input.DefaultCurrency))
            return Errors.Validation("Валюта должна быть MDL, EUR или USD");

        var userId = Auth.CurrentUserId(context);
        using var conn = Db.Open();

        if (input.AvatarFileId is { } fileId)
        {
            using var file = conn.Cmd(
                "SELECT mime_type FROM files WHERE id = $id AND user_id = $userId",
                ("$id", fileId), ("$userId", userId));
            var mimeType = file.ExecuteScalar() as string;
            if (mimeType is null) return Errors.NotFound("Файл не найден");
            if (!mimeType.StartsWith("image/")) return Errors.Validation("Аватар должен быть изображением");
        }

        using (var update = conn.Cmd(
                   "UPDATE users SET name = $name, default_currency = $currency, " +
                   "avatar_file_id = COALESCE($avatar, avatar_file_id) WHERE id = $id",
                   ("$name", name), ("$currency", input.DefaultCurrency),
                   ("$avatar", input.AvatarFileId), ("$id", userId)))
        {
            update.ExecuteNonQuery();
        }
        return Results.Json(Find(conn, userId)!);
    }
}
