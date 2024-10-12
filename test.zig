const c = @cImport({
    @cInclude("sqlite3.h");
});

pub fn main() !void {
    @import("std").debug.print("{s}", .{c.SQLITE_VERSION});
}
