#include <iostream>
#include <Windows.h>
#include <shellapi.h>

const UINT MOD_CTRL_SHIFT = MOD_CONTROL | MOD_SHIFT;
const UINT KEY_ESC = VK_ESCAPE;

int main()
{
    if (!RegisterHotKey(NULL, 1, MOD_CTRL_SHIFT, KEY_ESC)) {
        std::cerr << "Failed to register hotkey" << std::endl;
        return 1;
    }

    MSG msg = { 0 };
    while (GetMessage(&msg, NULL, 0, 0) != 0) {
        if (msg.message == WM_HOTKEY) {
            ShellExecute(NULL, "open", "cmd", "/min /C \"set __COMPAT_LAYER=RUNASINVOKER && start \"\" \"taskmgr.exe\"\"", NULL, SW_HIDE);
        }
    }

    // Unregister the hotkey
    UnregisterHotKey(NULL, 1);

    return 0;
}
