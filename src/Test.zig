const ZSqlite = @import("ZSqlite");
const FLib = @import("FLib");
const Testing = FLib.Testing;

test {
    Testing.ReferenceAll(@This());

    const cwd = @import("std").fs.cwd();
    cwd.deleteTree("test") catch unreachable;
    try cwd.makeDir("test");

    var connection = try ZSqlite.Connection.Create("./test/testdb.sqlite", .{});

    errdefer {
        @import("std").debug.print("err : {s}\n", .{connection.GetErrorMessage() catch unreachable});
    }

    {
        var versionSt = try connection.PrepareStatement("SELECT SQLITE_VERSION()", 0);

        _ = try versionSt.Step(true);

        try @import("std").testing.expectEqualStrings(ZSqlite.Version, try versionSt.ReadColumn([]const u8, 0));

        try versionSt.Finalize();
    }

    {
        try connection.Execute("CREATE TABLE test (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT)");

        var insertSt = try connection.PrepareStatement("INSERT INTO test (name) VALUES (?)", 1);

        try insertSt.Execute(.Copy, .{"hello"});
        try insertSt.Reset();
        try insertSt.Execute(.Copy, .{"world"});

        try insertSt.Finalize();
    }

    {
        const Data = struct {
            id: usize,
            name: []const u8,
        };

        var getSt = try connection.PrepareStatement("SELECT * FROM test", 0);

        try getSt.Query(.Static, .{});

        while (try getSt.Step(true)) {
            const data = try getSt.Read(Data);

            if (data.id == 1)
                try @import("std").testing.expectEqualStrings("hello", data.name);
            if (data.id == 2)
                try @import("std").testing.expectEqualStrings("world", data.name);
        }

        try getSt.Finalize();
    }

    try connection.Close();
}
