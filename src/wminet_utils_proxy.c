#define WIN32_LEAN_AND_MEAN
#include <windows.h>



BOOL WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
    (void)hinstDLL;
    (void)fdwReason;
    (void)lpvReserved;
    return TRUE;
}

/*
 * Windows API: HRESULT WINAPI GetErrorInfo(ULONG dwReserved, IErrorInfo **ppErrorInfo)
 * (declared in <oleauto.h>; we use void** to avoid pulling in the OLE chain).
 *
 * On x86_64 the args land in rcx (dwReserved, must be 0 per spec) and rdx
 * (out-pointer). Earlier versions of this stub used a 1-arg signature, which
 * happened to work because Roon's .NET caller always passes dwReserved=0 —
 * but a non-zero reserved would segfault on the spurious *((void*)1)=NULL.
 */
__declspec(dllexport) HRESULT WINAPI GetErrorInfo(ULONG dwReserved, void **ppErrorInfo)
{
    (void)dwReserved;
    if (ppErrorInfo)
        *ppErrorInfo = NULL;
    return S_FALSE;
}
