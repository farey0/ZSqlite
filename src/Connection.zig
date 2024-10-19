//! ZSqlite.Connection
//!
//! Author : farey0
//!
//!

//                               ----------------   Declarations   ----------------

pub const Self = @This();

const PreparedStatement = @import("PreparedStatement.zig").PreparedStatement;

pub const C = @import("C.zig");

pub const OpenOptions = struct {
    readonly: bool = false,
    create: bool = true,
    uri: bool = false,
    memory: bool = false,
    nomutex: bool = false,

    pub fn toC(self: OpenOptions) c_int {
        var flags: c_int = 0;
        if (self.readonly) flags |= C.OpenReadOnly else flags |= C.OpenReadWrite;
        if (self.create) flags |= C.OpenCreate;
        if (self.uri) flags |= C.OpenUri;
        if (self.memory) flags |= C.OpenMemory;
        if (self.nomutex) flags |= C.OpenNoMutex else flags |= C.OpenMutex;
        return flags;
    }
};

pub const Error = error{
    SqliteError,
};

//                               ----------------      Members     ----------------

connection: *C.Connection = undefined,

//                               ----------------      Public      ----------------

pub fn Create(path: [:0]const u8, options: OpenOptions) Error!Self {
    var self: Self = .{};

    const ret = C.Open(path.ptr, @ptrCast(&self.connection), options.toC(), null);

    if (ret != C.Success) {
        return Error.SqliteError;
    }

    return self;
}

pub fn GetErrorMessage(self: *Self) error{NoError}![:0]const u8 {
    if (C.GetErrMsg(self.connection)) |err| return @import("std").mem.span(err) else return error.NoError;
}

pub fn Close(self: *Self) Error!void {
    if (C.Close(self.connection) != C.Success) {
        return Error.SqliteError;
    }

    self.connection = undefined;
}

pub fn PrepareStatement(self: *Self, statement: []const u8, comptime paramCount: usize) Error!PreparedStatement(paramCount) {
    var out: PreparedStatement(paramCount) = .{};

    const ret = C.Prepare(self.connection, statement.ptr, @intCast(statement.len), @ptrCast(&out.preparedStatement), null);

    if (ret != C.Success) {
        return Error.SqliteError;
    }

    return out;
}

pub fn Execute(self: *Self, statement: []const u8) Error!void {
    if (C.Execute(self.connection, statement.ptr, null, null, null) != C.Success) return Error.SqliteError;
}

//                               ---------------- Getters/Setters  ----------------

//                               ----------------      Private     ----------------

//                               ----------------      Tests       ----------------
