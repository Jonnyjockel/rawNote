; ============================================================
; rawNote.inc — constants, types, and imports for rawNote
; Native note-taking app, 100% x86-64 assembly (ANSI API, ML64).
; ============================================================

; ---- imports ----
includelib kernel32.lib
includelib user32.lib
includelib gdi32.lib
includelib shell32.lib
includelib comctl32.lib
includelib uxtheme.lib

; ---- window styles ----
WS_OVERLAPPEDWINDOW EQU 00CF0000h
WS_VISIBLE           EQU 10000000h
WS_CHILD             EQU 40000000h
WS_VSCROLL           EQU 00200000h
WS_HSCROLL           EQU 00100000h
WS_BORDER            EQU 00800000h
WS_CAPTION           EQU 00C00000h
WS_SYSMENU           EQU 00080000h
WS_POPUP             EQU 80000000h
WS_THICKFRAME        EQU 00040000h
WS_MINIMIZEBOX       EQU 00020000h
WS_MAXIMIZEBOX       EQU 00010000h
WS_EX_CLIENTEDGE     EQU 00000200h
WS_EX_TOPMOST        EQU 00000008h

; ---- edit / list styles ----
ES_MULTILINE         EQU 0004h
ES_AUTOVSCROLL       EQU 0040h
ES_AUTOHSCROLL       EQU 0080h
ES_WANTRETURN        EQU 1000h
SS_CENTERIMAGE       EQU 0200h
LBS_NOTIFY           EQU 0001h
LBS_NOINTEGRALHEIGHT EQU 0100h

; ---- messages ----
WM_CREATE        EQU 0001h
WM_DESTROY       EQU 0002h
WM_SIZE          EQU 0005h
WM_CLOSE         EQU 0010h
WM_COMMAND       EQU 0111h
WM_KEYDOWN       EQU 0100h
WM_CONTEXTMENU   EQU 007Bh
WM_LBUTTONDOWN   EQU 0201h
WM_LBUTTONUP     EQU 0202h
WM_MOUSEWHEEL    EQU 020Ah
WM_VSCROLL       EQU 0115h
WM_SYSCOMMAND    EQU 0112h
WM_DRAWITEM      EQU 002Bh
WM_ERASEBKGND    EQU 0014h
WM_NCPAINT       EQU 0085h
WM_NCHITTEST     EQU 0084h
WM_SETREDRAW     EQU 000Bh
WM_SETFONT       EQU 0030h
HTCLIENT         EQU 1

; ---- owner control colors ----
WM_CTLCOLOREDIT    EQU 0133h
WM_CTLCOLORLISTBOX EQU 0134h
WM_CTLCOLORBTN     EQU 0135h
WM_CTLCOLORSTATIC  EQU 0138h

; ---- status bar colors ----
SB_SETBKCOLOR   EQU 0405h
SB_SETTEXTCOLOR EQU 040Ch

; ---- scroll info -------
SB_HORZ      EQU 0
SB_VERT      EQU 1
SB_BOTH      EQU 3
SIF_RANGE    EQU 1
SIF_PAGE     EQU 2
SIF_POS      EQU 4
SIF_ALL      EQU 17h
SM_CXVSCROLL EQU 2
SM_CYHSCROLL EQU 3

; ---- listbox messages ----
LB_ADDSTRING     EQU 0180h
LB_RESETCONTENT  EQU 0184h
LB_SETCURSEL     EQU 0186h
LB_GETCURSEL     EQU 0188h
LB_GETTEXT       EQU 0189h
LB_GETCOUNT      EQU 018Bh
LB_SELECTSTRING  EQU 018Ch
LB_GETITEMHEIGHT EQU 01A1h
LB_ITEMFROMPOINT EQU 01A9h
GWLP_WNDPROC     EQU -4

; ---- notifications ----
LBN_SELCHANGE EQU 1
LBN_DBLCLK EQU 2
EN_CHANGE  EQU 0300h
ENM_CHANGE EQU 1

; ---- status bar ----
SB_SETTEXT EQU 0401h
SB_LINEUP    EQU 0
SB_LINEDOWN  EQU 1
SC_MINIMIZE  EQU 0F020h
SC_RESTORE   EQU 0F120h
SC_MAXIMIZE  EQU 0F030h
SC_CLOSE     EQU 0F060h
HTCAPTION    EQU 2
BS_PUSHBUTTON EQU 0000h
BS_FLAT       EQU 8000h
BS_OWNERDRAW  EQU 000Bh
DT_CENTER     EQU 1
DT_VCENTER    EQU 4
DT_SINGLELINE EQU 20h
DT_NOCLIP     EQU 100h
TRANSPARENT   EQU 1

; ---- rich edit -------
EM_SETBKGNDCOLOR   EQU 0443h
EM_SETCHARFORMAT   EQU 0444h
EM_SETEVENTMASK    EQU 0445h
EM_SETPARAFORMAT   EQU 0447h
EM_SETSEL          EQU 00B1h
EM_LINESCROLL      EQU 04B6h
EM_CHARFROMPOS     EQU 0427h
EM_EXGETSEL        EQU 0434h
EM_EXSETSEL        EQU 0437h
EM_SCROLLCARET     EQU 0431h
EM_GETSCROLLPOS    EQU 04DDh
EM_SETSCROLLPOS    EQU 04DEh
EM_EXLIMITTEXT     EQU 0435h
CFM_BOLD           EQU 00000001h
CFM_ITALIC         EQU 00000002h
CFM_UNDERLINE      EQU 00000004h
CFM_COLOR          EQU 40000000h
CFM_FACE           EQU 20000000h
CFM_SIZE           EQU 80000000h
CFM_BACKCOLOR      EQU 04000000h
CFE_BOLD           EQU 00000001h
CFE_ITALIC         EQU 00000002h
CFE_UNDERLINE      EQU 00000004h
SCF_SELECTION      EQU 0001h
SCF_ALL            EQU 0004h

; ---- class / icon / color ----
CS_HREDRAW       EQU 2
CS_VREDRAW       EQU 1
IDI_APPLICATION  EQU 32512
IDI_MAIN          EQU 101
IDC_ARROW        EQU 32512
COLOR_WINDOW     EQU 5
COLOR_BTNFACE    EQU 15
DEFAULT_GUI_FONT EQU 17
VK_CONTROL       EQU 11h
VK_RETURN        EQU 0Dh

CW_USEDEFAULT EQU 80000000h
SW_SHOW       EQU 5
SW_SHOWNORMAL EQU 1
SW_RESTORE    EQU 9
CP_UTF8       EQU 65001

MB_OK              EQU 0
MB_YESNO           EQU 4
MB_YESNOCANCEL     EQU 3
MB_ICONINFORMATION EQU 40h
MB_ICONQUESTION    EQU 20h
MB_ICONERROR       EQU 10h
IDABORT            EQU 3
IDCANCEL           EQU 2
IDYES              EQU 6
IDNO               EQU 7

; ---- files ----
GENERIC_READ             EQU 80000000h
GENERIC_WRITE            EQU 40000000h
FILE_SHARE_READ          EQU 1
OPEN_EXISTING            EQU 3
CREATE_ALWAYS            EQU 2
CREATE_NEW               EQU 1
OPEN_ALWAYS              EQU 4
FILE_APPEND_DATA         EQU 4
FILE_ATTRIBUTE_NORMAL    EQU 80h
FILE_ATTRIBUTE_DIRECTORY EQU 10h
INVALID_HANDLE_VALUE     EQU -1

; ---- menu -------
MF_STRING EQU 0
MF_POPUP  EQU 10h
TPM_RIGHTBUTTON EQU 2
TPM_LEFTBUTTON  EQU 0
TPM_TOPALIGN    EQU 0
TPM_LEFTALIGN   EQU 0

; ---- accelerators ----
FVIRTKEY EQU 1
FCONTROL EQU 8

; ---- common controls ----
ICC_STANDARD_CLASSES EQU 40h
ICC_BAR_CLASSES      EQU 4

; ---- menu ids ----
IDM_NEW       EQU 1001
IDM_SAVE      EQU 1002
IDM_RENAME    EQU 1003
IDM_DELETE    EQU 1004
IDM_OPENVAULT EQU 1005
IDM_EXIT      EQU 1006
IDM_ABOUT     EQU 1007

; ---- child control ids ----
IDC_SEARCH      EQU 2001
IDC_LIST        EQU 2002
IDC_EDITOR      EQU 2003
IDC_STATUS      EQU 2004
IDC_PROMPT_EDIT EQU 2005
IDC_PROMPT_OK   EQU 2006
IDC_PROMPT_CANCEL EQU 2007
IDC_BTN_FILE    EQU 2008
IDC_BTN_NOTE    EQU 2009
IDC_BTN_MIN     EQU 2010
IDC_BTN_RESTORE EQU 2011
IDC_BTN_CLOSE   EQU 2012

; ---- types ----
WNDCLASSEXA STRUCT
    cbSize          DWORD ?
    style           DWORD ?
    lpfnWndProc     QWORD ?
    cbClsExtra      DWORD ?
    cbWndExtra      DWORD ?
    hInstance       QWORD ?
    hIcon           QWORD ?
    hCursor         QWORD ?
    hbrBackground   QWORD ?
    lpszMenuName    QWORD ?
    lpszClassName   QWORD ?
    hIconSm         QWORD ?
WNDCLASSEXA ENDS

WMSG STRUCT
    hwnd    QWORD ?
    message DWORD ?
    pad1    DWORD ?
    wParam  QWORD ?
    lParam  QWORD ?
    time    DWORD ?
    pad2    DWORD ?
    ptX     DWORD ?
    ptY     DWORD ?
WMSG ENDS

INITCCEX STRUCT
    dwSize DWORD ?
    dwICC  DWORD ?
INITCCEX ENDS

ACCEL STRUCT
    fVirt BYTE ?
    pad_  BYTE ?
    key   WORD ?
    cmd   WORD ?
ACCEL ENDS

WIN32_FIND_DATAA STRUCT
    dwFileAttributes    DWORD ?
    ftCreationTime      DWORD 2 DUP (?)
    ftLastAccessTime    DWORD 2 DUP (?)
    ftLastWriteTime     DWORD 2 DUP (?)
    nFileSizeHigh       DWORD ?
    nFileSizeLow        DWORD ?
    dwReserved0         DWORD ?
    dwReserved1         DWORD ?
    cFileName           BYTE 260 DUP (?)
    cAlternateFileName  BYTE 14 DUP (?)
WIN32_FIND_DATAA ENDS

RECT STRUCT
    left   DWORD ?
    top    DWORD ?
    right  DWORD ?
    bottom DWORD ?
RECT ENDS

SCROLLINFO STRUCT
    cbSize    DWORD ?
    fMask     DWORD ?
    nMin      DWORD ?
    nMax      DWORD ?
    nPage     DWORD ?
    nPos      DWORD ?
    nTrackPos DWORD ?
SCROLLINFO ENDS

CHARRANGE STRUCT
    cpMin DWORD ?
    cpMax DWORD ?
CHARRANGE ENDS

POINT STRUCT
    x DWORD ?
    y DWORD ?
POINT ENDS

DRAWITEMSTRUCT STRUCT
    CtlType    DWORD ?
    CtlID      DWORD ?
    itemID     DWORD ?
    itemAction DWORD ?
    itemState  DWORD ?
    pad_       DWORD ?
    hwndItem   QWORD ?
    hDC        QWORD ?
    rcItem     RECT <>
    itemData   QWORD ?
DRAWITEMSTRUCT ENDS

CHARFORMAT2W STRUCT
    cbSize          DWORD ?
    dwMask          DWORD ?
    dwEffects       DWORD ?
    yHeight         DWORD ?
    yOffset         DWORD ?
    crTextColor     DWORD ?
    bCharSet        BYTE ?
    bPitchAndFamily BYTE ?
    szFaceName      WORD 32 DUP (?)
    wWeight         WORD ?
    sSpacing        WORD ?
    pad2w           WORD ?
    crBackColor     DWORD ?
    lcid            DWORD ?
    dwReserved      DWORD ?
    sStyle          WORD ?
    wKerning        WORD ?
    bUnderlineType  BYTE ?
    bAnimation      BYTE ?
    bRevAuthor      BYTE ?
    bUnderlineColor BYTE ?
CHARFORMAT2W ENDS

; ---- externs ----
EXTERN GetModuleHandleA: PROC
EXTERN GetModuleFileNameA: PROC
EXTERN CreateFileA: PROC
EXTERN ReadFile: PROC
EXTERN WriteFile: PROC
EXTERN CloseHandle: PROC
EXTERN GetFileSizeEx: PROC
EXTERN FindFirstFileA: PROC
EXTERN FindNextFileA: PROC
EXTERN FindClose: PROC
EXTERN DeleteFileA: PROC
EXTERN MoveFileA: PROC
EXTERN CreateDirectoryA: PROC
EXTERN GetProcessHeap: PROC
EXTERN HeapAlloc: PROC
EXTERN HeapFree: PROC
EXTERN lstrlenA: PROC
EXTERN lstrcpyA: PROC
EXTERN lstrcatA: PROC
EXTERN WritePrivateProfileStringA: PROC
EXTERN GetPrivateProfileIntA: PROC
EXTERN GetPrivateProfileStringA: PROC
EXTERN ExitProcess: PROC

EXTERN RegisterClassExA: PROC
EXTERN CreateWindowExA: PROC
EXTERN ShowWindow: PROC
EXTERN UpdateWindow: PROC
EXTERN GetMessageA: PROC
EXTERN TranslateMessage: PROC
EXTERN DispatchMessageA: PROC
EXTERN DefWindowProcA: PROC
EXTERN PostQuitMessage: PROC
EXTERN DestroyWindow: PROC
EXTERN MessageBoxA: PROC
EXTERN LoadCursorA: PROC
EXTERN LoadIconA: PROC
EXTERN MoveWindow: PROC
EXTERN SetMenu: PROC
EXTERN ScreenToClient: PROC
EXTERN IsZoomed: PROC
EXTERN RoundRect: PROC
EXTERN DrawTextA: PROC
EXTERN DrawTextW: PROC
EXTERN SetBkMode: PROC
EXTERN SelectObject: PROC
EXTERN CreateMenu: PROC
EXTERN CreatePopupMenu: PROC
EXTERN AppendMenuA: PROC
EXTERN TrackPopupMenu: PROC
EXTERN SendMessageA: PROC
EXTERN SetWindowLongPtrA: PROC
EXTERN CallWindowProcA: PROC
EXTERN GetWindowTextLengthA: PROC
EXTERN GetWindowTextA: PROC
EXTERN SetWindowTextA: PROC
EXTERN EnableWindow: PROC
EXTERN wsprintfA: PROC
EXTERN CreateAcceleratorTableA: PROC
EXTERN TranslateAcceleratorA: PROC
EXTERN GetAsyncKeyState: PROC

EXTERN InitCommonControlsEx: PROC
EXTERN ShellExecuteA: PROC
EXTERN SetWindowTheme: PROC
EXTERN GetStockObject: PROC
EXTERN CreateFontA: PROC
EXTERN CreateSolidBrush: PROC
EXTERN SetTextColor: PROC
EXTERN SetBkColor: PROC
EXTERN FillRect: PROC
EXTERN GetClientRect: PROC
EXTERN InvalidateRect: PROC
EXTERN GetWindowDC: PROC
EXTERN ReleaseDC: PROC
EXTERN GetScrollInfo: PROC
EXTERN GetSystemMetrics: PROC
EXTERN GetWindowRect: PROC
EXTERN ShowScrollBar: PROC
EXTERN LoadLibraryA: PROC
EXTERN MultiByteToWideChar: PROC
EXTERN WideCharToMultiByte: PROC
EXTERN GetWindowTextLengthW: PROC
EXTERN GetWindowTextW: PROC
EXTERN SetWindowTextW: PROC
