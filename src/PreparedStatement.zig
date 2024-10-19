//! ZSqlite.PreparedStatement
//!
//! Author : farey0
//!
//!

//                               ----------------   Declarations   ----------------

pub const C = @import("C.zig");

const Config = @import("Config");

pub fn PreparedStatement(comptime paramCount: usize) type {
    return struct {
        const Self = @This();

        pub const Error = error{
            SqliteError,
        };

        pub const StringLifetime = C.StringLifetime;

        preparedStatement: *C.PreparedStatement = undefined,

        pub fn Step(self: Self, comptime ExpectRow: bool) Error!blk: {
            if (ExpectRow) break :blk bool else break :blk void;
        } {
            if (ExpectRow) {
                const ret = C.Step(self.preparedStatement);

                if (ret == C.Row) return true else if (ret == C.Done) return false else return Error.SqliteError;
            } else {
                if (C.Step(self.preparedStatement) != C.Done) return Error.SqliteError;
            }
        }

        pub fn Finalize(self: *Self) Error!void {
            if (C.Finalize(self.preparedStatement) != C.Success) return Error.SqliteError;

            self.preparedStatement = undefined;
        }

        pub fn Reset(self: Self) Error!void {
            if (C.Reset(self.preparedStatement) != C.Success) return Error.SqliteError;
        }

        pub fn Read(self: Self, comptime T: type) Error!T {
            const TInfo = @typeInfo(T);

            if (TInfo != .@"struct")
                @compileError("T must be a struct");

            const DataCount = C.GetDataCount(self.preparedStatement);

            if (DataCount != TInfo.@"struct".fields.len)
                @panic("T must have " ++ @import("std").fmt.comptimePrint("{d}", .{TInfo.@"struct".fields.len}) ++ " fields");

            var out: T = undefined;

            inline for (TInfo.@"struct".fields, 0..) |field, i| {
                @field(out, field.name) = try self.ReadColumn(field.type, i);
            }

            return out;
        }

        pub fn ReadColumn(self: Self, comptime T: type, index: usize) Error!T {
            switch (@typeInfo(T)) {
                .pointer => |pointer| {
                    if (pointer.child != u8) @compileError("Unsupported array type");
                    if (pointer.is_const != true) @compileError("Pointer must be const");

                    const len = C.GetColumnLen(self.preparedStatement, @intCast(index));

                    const text = C.GetColumnText(self.preparedStatement, @intCast(index));

                    return text[0..@as(usize, @intCast(len))];
                },
                .int => {
                    return @intCast(C.GetColumnInt(self.preparedStatement, @intCast(index)));
                },
                else => @compileError("Unsupported type : " ++ @typeName(T) ++ " | " ++ @tagName(@typeInfo(T))),
            }
        }

        // bind all the values of a tuple to the prepared statement
        pub fn Bind(self: Self, comptime stringLifetime: StringLifetime, value: anytype) Error!void {
            const TInfo = @typeInfo(@TypeOf(value));

            if (TInfo != .@"struct" and !TInfo.@"struct".is_tuple)
                @compileError("value must be a tuple");

            if (TInfo.@"struct".fields.len != paramCount)
                @compileError("value must have " ++ @import("std").fmt.comptimePrint("{d}", .{paramCount}) ++ " fields");

            inline for (value, 1..) |val, i| {
                const valInfo = @typeInfo(@TypeOf(val));
                const T = @TypeOf(val);

                switch (valInfo) {
                    .int => {
                        if (C.BindInt(self.preparedStatement, i, @intCast(val)) != C.Success) return Error.SqliteError;
                    },
                    .float => {
                        if (C.BindDouble(self.preparedStatement, i, @floatCast(val)) != C.Success) return Error.SqliteError;
                    },
                    .null => {
                        if (C.BindNull(self.preparedStatement, i) != C.Success) return Error.SqliteError;
                    },
                    .pointer => |pointer| {
                        if (pointer.child == u8) {
                            if (C.BindText(self.preparedStatement, i, val.ptr, @intCast(val.len), stringLifetime.toC()) != C.Success)
                                return Error.SqliteError;
                        } else {
                            const TChildInfo = @typeInfo(pointer.child);

                            if ((TChildInfo == .pointer and TChildInfo.pointer.child == u8) or (TChildInfo == .array and TChildInfo.array.child == u8)) {
                                if (C.BindText(self.preparedStatement, i, val.*[0..].ptr, @intCast(val.*[0..].len), stringLifetime.toC()) != C.Success) {
                                    return Error.SqliteError;
                                }
                            } else @compileError("Unsupported pointer type " ++ @typeName(T) ++ " | " ++ @tagName(@typeInfo(T)));
                        }
                    },
                    .array => |arr| {
                        if (arr.child != u8) @compileError("Unsupported array type " ++ @typeName(T) ++ " | " ++ @tagName(@typeInfo(T)));

                        if (C.BindText(self.preparedStatement, i, val.ptr, @intCast(val.len), stringLifetime.toC()) != C.Success)
                            return Error.SqliteError;
                    },
                    else => @compileError("Unsupported type : " ++ @typeName(T) ++ " | " ++ @tagName(@typeInfo(T))),
                }
            }
        }

        // does a Bind & Step, and a reset before if needed
        pub fn Query(self: Self, comptime stringLifetime: StringLifetime, value: anytype) Error!void {
            try self.Bind(stringLifetime, value);
        }

        pub fn Execute(self: Self, comptime stringLifetime: StringLifetime, value: anytype) Error!void {
            try self.Bind(stringLifetime, value);
            try self.Step(false);
        }
    };
}

//                               ----------------      Members     ----------------

//                               ----------------      Public      ----------------

//                               ---------------- Getters/Setters  ----------------

//                               ----------------      Private     ----------------

//                               ----------------      Tests       ----------------
