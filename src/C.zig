const c = @cImport({
    @cInclude("sqlite3.h");
});

pub const Success = c.SQLITE_OK;
pub const Row = c.SQLITE_ROW;
pub const Done = c.SQLITE_DONE;

// Connection Related

pub const Connection = c.sqlite3;

pub const OpenReadOnly = c.SQLITE_OPEN_READONLY;
pub const OpenReadWrite = c.SQLITE_OPEN_READWRITE;
pub const OpenCreate = c.SQLITE_OPEN_CREATE;
pub const OpenUri = c.SQLITE_OPEN_URI;
pub const OpenMemory = c.SQLITE_OPEN_MEMORY;
pub const OpenNoMutex = c.SQLITE_OPEN_NOMUTEX;
pub const OpenMutex = c.SQLITE_OPEN_FULLMUTEX;

pub const Open = c.sqlite3_open_v2;
pub const GetErrMsg = c.sqlite3_errmsg;
pub const Close = c.sqlite3_close;
pub const Execute = c.sqlite3_exec;

// Statement Related

pub const PreparedStatement = c.sqlite3_stmt;

pub const Prepare = c.sqlite3_prepare_v2;
pub const Step = c.sqlite3_step;
pub const Finalize = c.sqlite3_finalize;
pub const Reset = c.sqlite3_reset;

pub const BindInt = c.sqlite3_bind_int64;
pub const BindText = c.sqlite3_bind_text;
pub const BindNull = c.sqlite3_bind_null;
pub const BindDouble = c.sqlite3_bind_double;

pub const GetColumnLen = c.sqlite3_column_bytes;
pub const GetColumnInt = c.sqlite3_column_int64;
pub const GetColumnText = c.sqlite3_column_text;

pub const GetDataCount = c.sqlite3_data_count;

pub const StringLifetime = enum {
    Static, // means that the string/blob is valid for the duration of the query
    Copy, // means that the string/blob will be copied before the query by Sqlite

    pub fn toC(self: StringLifetime) c.sqlite3_destructor_type {
        if (self == .Static) return c.SQLITE_STATIC else return c.SQLITE_TRANSIENT;
    }
};
