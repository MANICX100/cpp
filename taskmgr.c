#include <windows.h>
#include <sddl.h>
#include <cstdio>

int main()
{
    // Define the command to run (Task Manager)
    TCHAR cmd[] = TEXT("taskmgr.exe");

    // Create the startup information and process information structures
    STARTUPINFO si;
    PROCESS_INFORMATION pi;

    // Initialize the startup information structure
    ZeroMemory(&si, sizeof(si));
    si.cb = sizeof(si);

    // Initialize the process information structure
    ZeroMemory(&pi, sizeof(pi));

    // Set the low integrity level attribute
    DWORD dwIntegrityLevel = SECURITY_MANDATORY_LOW_RID;
    TOKEN_MANDATORY_LABEL TIL = { 0 };
    HANDLE hToken = NULL;
    if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY | TOKEN_ADJUST_DEFAULT, &hToken))
    {
        if (GetTokenInformation(hToken, TokenIntegrityLevel, &TIL, sizeof(TIL), NULL))
        {
            PSID pSid = NULL;
            if (ConvertStringSidToSid(TEXT("S-1-16-4096"), &pSid))
            {
                TIL.Label.Attributes = SE_GROUP_INTEGRITY;
                TIL.Label.Sid = pSid;
                if (SetTokenInformation(hToken, TokenIntegrityLevel, &TIL, sizeof(TOKEN_MANDATORY_LABEL) + GetLengthSid(TIL.Label.Sid)))
                {
                    // Token information set successfully
                }
                LocalFree(pSid);
            }
        }
        CloseHandle(hToken);
    }

    // Create the process with low integrity level
    if (!CreateProcess(NULL, cmd, NULL, NULL, FALSE, CREATE_NO_WINDOW | CREATE_UNICODE_ENVIRONMENT, NULL, NULL, &si, &pi))
    {
        printf("CreateProcess failed (%d).\n", GetLastError());
        return 1;
    }

    // Wait for the process to exit
    WaitForSingleObject(pi.hProcess, INFINITE);

    // Close process and thread handles
    CloseHandle(pi.hProcess);
    CloseHandle(pi.hThread);

    return 0;
}
