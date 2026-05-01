#define WIN32_LEAN_AND_MEAN
#include <windows.h>



BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    (void)hinstDLL;
    (void)fdwReason;
    (void)lpvReserved;
    return TRUE;
}

__declspec(dllexport) HRESULT WINAPI GetErrorInfo(void **ppObject)
{
    if (ppObject)
        *ppObject = NULL;
    return S_FALSE;
}
