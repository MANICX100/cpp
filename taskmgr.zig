const std = @import("std");
const windows = std.os.windows;
const ole32 = windows.ole32;
const advapi32 = windows.advapi32;

const CP_UTF8 = 65001;

pub fn main() !void {
    try runTaskManagerWithLowestTrustLevel();
}

fn runTaskManagerWithLowestTrustLevel() !void {
    const advapi32_dll = "advapi32.dll";
    const ole32_dll = "ole32.dll";
    const advapi32_dll_wide = try std.unicode.utf8ToWide(advapi32_dll);
    const ole32_dll_wide = try std.unicode.utf8ToWide(ole32_dll);
    try windows.kernel32.LoadLibraryW(&advapi32_dll_wide.items[0]);
    try windows.kernel32.LoadLibraryW(&ole32_dll_wide.items[0]);

    const userToken = try getCurrentUserToken();
    defer windows.kernel32.CloseHandle(userToken);

    const restrictedToken = try createRestrictedToken(userToken);
    defer windows.kernel32.CloseHandle(restrictedToken);

    try createProcessWithToken(restrictedToken);
}

fn getCurrentUserToken() !windows.HANDLE {
    var token: windows.HANDLE = undefined;
    const process = windows.kernel32.GetCurrentProcess();
    if (windows.kernel32.OpenProcessToken(process, windows.TOKEN_ALL_ACCESS, &token) == 0) {
        return windows.GetLastError();
    }
    return token;
}

fn createRestrictedToken(primaryToken: windows.HANDLE) !windows.HANDLE {
    var restrictedToken: windows.HANDLE = undefined;
    if (advapi32.CreateRestrictedToken(primaryToken, windows.DISABLE_MAX_PRIVILEGE, 0, null, 0, null, 0, null, &restrictedToken) == 0) {
        return windows.GetLastError();
    }
    return restrictedToken;
}

fn createProcessWithToken(token: windows.HANDLE) !void {
    var startupInfo: windows.STARTUPINFOW = undefined;
    var processInfo: windows.PROCESS_INFORMATION = undefined;

    startupInfo.cb = @sizeOf(windows.STARTUPINFOW);

    const taskMgrPath = try std.unicode.utf8ToUtf16LeStringLiteral("taskmgr.exe");

    if (advapi32.CreateProcessAsUserW(token, null, taskMgrPath.ptr, null, null, false, windows.CREATE_UNICODE_ENVIRONMENT, null, null, &startupInfo, &processInfo) == 0) {
        return windows.GetLastError();
    }

    _ = windows.kernel32.CloseHandle(processInfo.hProcess);
    _ = windows.kernel32.CloseHandle(processInfo.hThread);
}

pub fn utf8ToWide(s: []const u8) !std.ArrayList(u16) {
    var wide_str = std.ArrayList(u16).init(std.heap.page_allocator);
    const len = MultiByteToWideChar(CP_UTF8, 0, s.ptr, @intCast(i32, s.len), null, 0);
    try wide_str.ensureCapacity(len);
    _ = MultiByteToWideChar(CP_UTF8, 0, s.ptr, @intCast(i32, s.len), wide_str.items.ptr, len);
    wide_str.items.len = len;
    return wide_str;
}

extern fn MultiByteToWideChar(
    CodePage: u32,
    dwFlags: u32,
    lpMultiByteStr: [*]const u8,
    cbMultiByte: i32,
    lpWideCharStr: [*]u16,
    cchWideChar: i32,
) callconv(.C) i32;