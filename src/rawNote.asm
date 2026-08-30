; ============================================================
; rawNote  a minimal note-taking app written 100% in x86-64 assembly
;
; Win32 GUI (ANSI), no C runtime, no resource files. Notes are
; plain .md files in a "vault" folder next to the executable.
;
; Manual calling convention (no INVOKE/ADDR/.IF):
;   args in RCX,RDX,R8,R9 ; shadow space reserved by caller ; result in RAX
; ============================================================

include rawNote.inc

; ---------------- data ----------------
.data

szAppName    DB "rawNote",0
szMainClass  DB "rawNoteMainWnd",0
szPromptClass DB "rawNotePrompt",0
szEditClass  DB "EDIT",0
szListClass  DB "LISTBOX",0
szButtonClass DB "BUTTON",0
szStatusClass DB "STATIC",0
szRichEditClass DB "RICHEDIT50W",0
szMsftedit     DB "Msftedit.dll",0
szDbgLog       DB "debug.log",0

szVaultDirName DB "\vault",0
szBackslash    DB "\",0
szMdWild       DB "\*.md",0
szDotMd        DB ".md",0
szOpen         DB "open",0

szUntitled    DB "Untitled",0
szNewNoteFmt  DB "Untitled %d.md",0
szNoNote      DB "No note open",0
szStatusFmt   DB "%d chars, %d words - %s",0
szFontFace    DB "Segoe UI",0
szIniName     DB "rawNote.ini",0
szFmtD        DB "%d",0
szSecWindow   DB "window",0
szSecNote     DB "note",0
szKeyX        DB "x",0
szKeyY        DB "y",0
szKeyW        DB "w",0
szKeyH        DB "h",0
szKeyLast     DB "last",0

szMenuFile   DB "&File",0
szMenuNote   DB "&Note",0
szNew        DB "New Note",0
szSave       DB "Save",0
szRename     DB "&Rename...",0
szDelete     DB "&Delete",0
szOpenVault  DB "&Open Vault Folder",0
szExit       DB "E&xit",0
szAbout      DB "&About",0

szAboutTitle   DB "About rawNote",0
szAboutText    DB "rawNote - a minimal note-taking app",13,10
               DB "written 100% in x86-64 assembly.",13,10,13,10
               DB "Notes are plain .md files in the vault folder.",0
szDeletePrompt DB "Delete this note permanently?",0
szSavePrompt   DB "Unsaved changes. Save before closing?",00
szRenameTitle  DB "Rename note",0
szLoadError    DB "Could not open that note.",0
szOK           DB "OK",0
szCancel       DB "Cancel",0
szEmpty        DB 0
szBarMin       DB "_",0
szBarRestore   DB "[]",0
szBarClose     DB "X",0
szBarFile      DB "File",0
szBarNote      DB "Note",0
szGlyphClose   WORD 00D7h, 0      ; U+00D7 multiplication sign
szGlyphMin     WORD 2500h, 0      ; U+2500 box drawing horizontal
szGlyphRestore WORD 25A1h, 0      ; U+25A1 white square
BARH           EQU 26

; ---------------- bss ----------------
.data?
hInstance    QWORD ?
hMainWnd     QWORD ?
hList        QWORD ?
gOldListProc QWORD ?
hStatus      QWORD ?
hEditor      QWORD ?
gOldEditProc QWORD ?
hSearch      QWORD ?
hAccel       QWORD ?
hwnd_close   QWORD ?
hwnd_restore QWORD ?
hwnd_min     QWORD ?
hwnd_file    QWORD ?
hwnd_note    QWORD ?
g_hMenu      QWORD ?
gFileMenu    QWORD ?
gNoteMenu    QWORD ?
gContextMenu QWORD ?
gFont        QWORD ?
gBrush       QWORD ?
gBrushList   QWORD ?
gBrushSearch QWORD ?
gBrushStatus QWORD ?
gBrushBtn    QWORD ?
gSmallFont   QWORD ?
g_promptResult  QWORD ?
g_promptDefault QWORD ?
g_promptOk      QWORD ?
hPrompt      QWORD ?
hPromptEdit  QWORD ?

; scratch state (cross-call)
gHwnd   QWORD ?
gMsg    DWORD ?
gWParam QWORD ?
gLParam QWORD ?
gSub    QWORD ?
gFind   QWORD ?
gFileH  QWORD ?
gHeap   QWORD ?
gBuf    QWORD ?
gSize   QWORD ?
gLen    QWORD ?
gBytes  QWORD ?
gDest   QWORD ?
gFn     QWORD ?
gSearchPtr QWORD ?
gMatch  QWORD ?
gLinkBuf  QWORD ?
gLinkHeap QWORD ?
gLinkLen  QWORD ?
gLinkCp   QWORD ?
gLinkName BYTE 260 DUP (?)
gLinkWide WORD 260 DUP (?)
gWheelDir DWORD ?
gPromptTitle QWORD ?
gPromptDef   QWORD ?
gPromptRes   QWORD ?
gChars  DWORD ?
gWords  DWORD ?
gIdx    DWORD ?
gN      DWORD ?
gCw     DWORD ?
gChh    DWORD ?
gLw     DWORD ?
gLh     DWORD ?
gEw     DWORD ?
gSy     DWORD ?
gReadN  DWORD ?
gWritten DWORD ?
gWideBuf QWORD ?
gWsize   QWORD ?
gNoteSrc QWORD ?
gSnHeap  QWORD ?
gUsHeap  QWORD ?
gUsBuf   QWORD ?
gMdGuard QWORD ?
gMdStart QWORD ?
gMdEnd   QWORD ?
gMdText  QWORD ?
gMdHeap  QWORD ?
gMdLen   QWORD ?
gLoading QWORD ?
dirty     QWORD ?

vaultPath   BYTE 512 DUP (?)
currentFile BYTE 260 DUP (?)
gIniPath    BYTE 600 DUP (?)
numBuf      BYTE 32 DUP (?)
pathBuf     BYTE 600 DUP (?)
pathBuf2    BYTE 600 DUP (?)
searchBuf   BYTE 260 DUP (?)
statusBuf   BYTE 512 DUP (?)
renameBuf   BYTE 260 DUP (?)

wc      WNDCLASSEXA <>
msg     WMSG <>
iccx    INITCCEX <>
wc_find WIN32_FIND_DATAA <>
gCf     CHARFORMAT2W <>
gCr     CHARRANGE <>
gScPt   POINT <>
gNcPt   POINT <>
gRect   RECT <>
gDiPtr    QWORD ?
gBtnLabel QWORD ?
gBtnGlyph QWORD ?

; ---------------- code ----------------
.code

; ---------------------------------------------------------------------------
; CountWords(rcx = string) -> rax = word count   (leaf, no calls)
; ---------------------------------------------------------------------------
CountWords PROC
    xor eax, eax
    xor r10d, r10d
    mov rdx, rcx
cw_loop:
    movzx r8d, BYTE PTR [rdx]
    test r8b, r8b
    jz cw_done
    inc rdx
    cmp r8b, 20h
    je cw_space
    cmp r8b, 9
    je cw_space
    cmp r8b, 13
    je cw_space
    cmp r8b, 10
    je cw_space
    test r10d, r10d
    jnz cw_loop
    mov r10d, 1
    inc eax
    jmp cw_loop
cw_space:
    xor r10d, r10d
    jmp cw_loop
cw_done:
    ret
CountWords ENDP

; ---------------------------------------------------------------------------
; CountWordsW(rcx = wide string) -> rax = word count   (leaf, no calls)
; ---------------------------------------------------------------------------
CountWordsW PROC
    xor eax, eax
    xor r10d, r10d
    mov rdx, rcx
cww_loop:
    movzx r8d, WORD PTR [rdx]
    test r8w, r8w
    jz cww_done
    add rdx, 2
    cmp r8w, 20h
    je cww_space
    cmp r8w, 9
    je cww_space
    cmp r8w, 13
    je cww_space
    cmp r8w, 10
    je cww_space
    test r10d, r10d
    jnz cww_loop
    mov r10d, 1
    inc eax
    jmp cww_loop
cww_space:
    xor r10d, r10d
    jmp cww_loop
cww_done:
    ret
CountWordsW ENDP

; ---------------------------------------------------------------------------
; SetNoteText(rcx = utf8 string)  convert UTF-8 -> UTF-16, set into editor
; ---------------------------------------------------------------------------
SetNoteText PROC
    sub rsp, 72
    mov gNoteSrc, rcx         ; source utf8
    mov rcx, CP_UTF8
    xor edx, edx
    mov r8, gNoteSrc
    mov r9, -1
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    call MultiByteToWideChar
    test rax, rax
    jz snr_done
    mov gWsize, rax           ; chars incl null
    call GetProcessHeap
    mov gSnHeap, rax
    mov rcx, gSnHeap
    xor edx, edx
    mov rax, gWsize
    shl rax, 1
    mov r8, rax
    call HeapAlloc
    mov gWideBuf, rax
    mov rcx, CP_UTF8
    xor edx, edx
    mov r8, gNoteSrc
    mov r9, -1
    mov rax, gWideBuf
    mov [rsp+32], rax
    mov rax, gWsize
    mov [rsp+40], rax
    call MultiByteToWideChar
    mov rcx, hEditor
    mov rdx, gWideBuf
    mov gLoading, 1
    call SetWindowTextW
    mov gLoading, 0
    mov rcx, gSnHeap
    xor edx, edx
    mov r8, gWideBuf
    call HeapFree
    call ApplyMarkdown
    mov dirty, 0
snr_done:
    add rsp, 72
    ret
SetNoteText ENDP

; ---------------------------------------------------------------------------
; GwToCp(rcx = GetWindowTextW char index) -> rax = RichEdit CP index
; (RichEdit counts CRLF as ONE char; GetWindowTextW gives TWO, so CP = idx - #\n)
; ---------------------------------------------------------------------------
GwToCp PROC
    xor eax, eax          ; newline count
    xor edx, edx          ; loop idx
    mov r8, gMdText
gwc_loop:
    cmp edx, ecx
    jae gwc_done
    cmp WORD PTR [r8 + rdx*2], 0Ah
    jne gwc_next
    inc eax
gwc_next:
    inc edx
    jmp gwc_loop
gwc_done:
    mov edx, ecx
    sub edx, eax
    mov rax, rdx
    ret
GwToCp ENDP

; ---------------------------------------------------------------------------
; FmtSel(rcx = start, rdx = end) " apply gCf (pre-configured) to [start,end)
;   start/end are GetWindowTextW indices; converted to RichEdit CP internally.
; ---------------------------------------------------------------------------
FmtSel PROC
    sub rsp, 40
    mov gMdStart, rcx
    mov gMdEnd, rdx
    mov rcx, gMdStart
    call GwToCp
    mov gMdStart, rax
    mov rcx, gMdEnd
    call GwToCp
    mov gMdEnd, rax
    mov rcx, hEditor
    mov rdx, EM_SETSEL
    mov r8, gMdStart
    mov r9, gMdEnd
    call SendMessageA
    mov rcx, hEditor
    mov rdx, EM_SETCHARFORMAT
    mov r8, SCF_SELECTION
    lea r9, gCf
    call SendMessageA
    ; re-lock scroll to saved position (prevents visible scroll jump)
    mov rcx, hEditor
    mov rdx, EM_SETSCROLLPOS
    xor r8, r8
    lea r9, gScPt
    call SendMessageA
    add rsp, 40
    ret
FmtSel ENDP

; ---------------------------------------------------------------------------
; ApplyMarkdown " scan editor text, apply bold/italic/inline-code formatting
; (markers stay visible; source-mode style). Runs on EN_CHANGE, guarded.
; ---------------------------------------------------------------------------
ApplyMarkdown PROC
    push rbx
    push rsi
    push rdi
    push r12
    sub rsp, 72
    cmp gMdGuard, 1
    je am_done
    mov gMdGuard, 1
    ; suppress repaint during rescan
    mov rcx, hEditor
    mov rdx, WM_SETREDRAW
    xor r8, r8
    xor r9, r9
    call SendMessageA
    ; save caret selection
    mov rcx, hEditor
    mov rdx, EM_EXGETSEL
    xor r8, r8
    lea r9, gCr
    call SendMessageA
    ; save scroll position
    mov rcx, hEditor
    mov rdx, EM_GETSCROLLPOS
    xor r8, r8
    lea r9, gScPt
    call SendMessageA
    ; reset whole doc to base format (white, no bold/italic/underline) via SCF_ALL
    mov gCf.cbSize, 116
    mov gCf.dwMask, CFM_BOLD or CFM_ITALIC or CFM_UNDERLINE or CFM_COLOR
    mov gCf.dwEffects, 0
    mov gCf.crTextColor, 0E6E6E6h
    mov rcx, hEditor
    mov rdx, EM_SETCHARFORMAT
    mov r8, SCF_ALL
    lea r9, gCf
    call SendMessageA
    ; read editor text length
    mov rcx, hEditor
    call GetWindowTextLengthW
    mov gMdLen, rax
    test rax, rax
    jz am_notext
    ; alloc wide buffer
    call GetProcessHeap
    mov gMdHeap, rax
    mov rcx, gMdHeap
    xor edx, edx
    mov rax, gMdLen
    add rax, 1
    shl rax, 1
    mov r8, rax
    call HeapAlloc
    mov gMdText, rax
    mov rcx, hEditor
    mov rdx, gMdText
    mov rax, gMdLen
    add rax, 1
    mov r8, rax
    call GetWindowTextW
    ; scan: rbx = text ptr (callee-saved), esi = index i
    mov rbx, gMdText
    xor esi, esi
am_loop:
    movzx eax, WORD PTR [rbx + rsi*2]
    test ax, ax
    jz am_exit
    cmp ax, '#'
    je am_hash
    cmp ax, '*'
    je am_star
    cmp ax, '`'
    je am_tick
    inc esi
    jmp am_loop

; --- bold: ** ... ** ---
am_star:
    movzx eax, WORD PTR [rbx + rsi*2 + 2]
    cmp ax, '*'
    jne am_italic
    ; bold: format includes both ** markers
    mov edi, esi
    lea r12d, [edi + 2]
am_bold_find:
    movzx eax, WORD PTR [rbx + r12*2]
    test ax, ax
    jz am_exit
    cmp ax, '*'
    jne am_bold_next
    movzx eax, WORD PTR [rbx + r12*2 + 2]
    cmp ax, '*'
    je am_bold_apply
am_bold_next:
    inc r12d
    jmp am_bold_find
am_bold_apply:
    mov gCf.cbSize, 116
    mov gCf.dwMask, CFM_BOLD
    mov gCf.dwEffects, CFE_BOLD
    mov rcx, rdi
    lea rdx, [r12 + 2]
    call FmtSel
    lea esi, [r12d + 2]
    jmp am_loop

; --- italic: * ... * ---
am_italic:
    mov edi, esi
    mov r12d, edi
    inc r12d
am_ital_find:
    movzx eax, WORD PTR [rbx + r12*2]
    test ax, ax
    jz am_exit
    cmp ax, '*'
    je am_ital_apply
    inc r12d
    jmp am_ital_find
am_ital_apply:
    mov gCf.cbSize, 116
    mov gCf.dwMask, CFM_ITALIC
    mov gCf.dwEffects, CFE_ITALIC
    mov rcx, rdi
    lea rdx, [r12 + 1]
    call FmtSel
    lea esi, [r12d + 1]
    jmp am_loop

; --- inline code: ` ... ` ---
am_tick:
    mov edi, esi
    mov r12d, edi
    inc r12d
am_tick_find:
    movzx eax, WORD PTR [rbx + r12*2]
    test ax, ax
    jz am_exit
    cmp ax, '`'
    je am_tick_apply
    inc r12d
    jmp am_tick_find
am_tick_apply:
    mov gCf.cbSize, 116
    mov gCf.dwMask, CFM_COLOR
    mov gCf.dwEffects, 0
    mov gCf.crTextColor, 0E0A030h
    mov rcx, rdi
    lea rdx, [r12 + 1]
    call FmtSel
    lea esi, [r12d + 1]
    jmp am_loop

; --- header: # / ## / ### ... at line start ---
am_hash:
    test esi, esi
    jz am_h_start
    cmp WORD PTR [rbx + rsi*2 - 2], 0Ah   ; prev char == '\n'?
    jne am_h_notline
am_h_start:
    ; count consecutive '#' (1..6)
    xor r9d, r9d
am_h_count:
    cmp r9d, 6
    jae am_h_cnt_done
    mov eax, esi
    add eax, r9d
    cmp WORD PTR [rbx + rax*2], '#'
    jne am_h_cnt_done
    inc r9d
    jmp am_h_count
am_h_cnt_done:
    ; content = whole line (markers included), from i to end-of-line
    mov edi, esi
    mov r12d, esi
am_h_findend:
    movzx eax, WORD PTR [rbx + r12*2]
    test ax, ax
    jz am_h_found
    cmp ax, 0Dh          ; '\r'
    je am_h_found
    inc r12d
    jmp am_h_findend
am_h_found:
    ; clamp hash count to 1..6
    cmp r9d, 1
    jae am_h_ge1
    mov r9d, 1
am_h_ge1:
    cmp r9d, 6
    jbe am_h_le6
    mov r9d, 6
am_h_le6:
    ; yHeight (twips) = 480 - count*40  -> 1:440(pt22) ... 6:240(pt12)
    imul r9d, 40
    mov eax, 480
    sub eax, r9d
    mov gCf.yHeight, eax
    mov gCf.cbSize, 116
    mov gCf.dwMask, CFM_SIZE or CFM_BOLD
    mov gCf.dwEffects, CFE_BOLD
    mov rcx, rdi
    mov rdx, r12
    call FmtSel
    mov esi, r12d
    jmp am_loop
am_h_notline:
    inc esi
    jmp am_loop

am_exit:
    mov rcx, gMdHeap
    xor edx, edx
    mov r8, gMdText
    call HeapFree
am_notext:
    ; restore caret
    mov rcx, hEditor
    mov rdx, EM_EXSETSEL
    xor r8, r8
    lea r9, gCr
    call SendMessageA
    ; restore scroll position
    mov rcx, hEditor
    mov rdx, EM_SETSCROLLPOS
    xor r8, r8
    lea r9, gScPt
    call SendMessageA
    ; resume repaint + force full redraw
    mov rcx, hEditor
    mov rdx, WM_SETREDRAW
    mov r8, 1
    xor r9, r9
    call SendMessageA
    mov rcx, hEditor
    xor edx, edx
    mov r8, 1
    call InvalidateRect
    mov rcx, hEditor
    call UpdateWindow
    mov gMdGuard, 0
am_done:
    add rsp, 72
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
ApplyMarkdown ENDP

; ---------------------------------------------------------------------------
; StrContainsA(rcx = hay, rdx = needle) -> rax 1/0   (leaf, no calls)
; ---------------------------------------------------------------------------
StrContainsA PROC
    mov r10, rcx
    mov r11, rdx
    cmp BYTE PTR [r11], 0
    je sc_yes
sc_outer:
    cmp BYTE PTR [r10], 0
    je sc_no
    mov r8, r10
    mov r9, r11
sc_inner:
    movzx eax, BYTE PTR [r9]
    test al, al
    jz sc_yes
    movzx ecx, BYTE PTR [r8]
    test cl, cl
    jz sc_no
    cmp al, 'A'
    jb sc_c1
    cmp al, 'Z'
    ja sc_c1
    add al, 32
sc_c1:
    cmp cl, 'A'
    jb sc_c2
    cmp cl, 'Z'
    ja sc_c2
    add cl, 32
sc_c2:
    cmp al, cl
    jne sc_adv
    inc r8
    inc r9
    jmp sc_inner
sc_adv:
    inc r10
    jmp sc_outer
sc_yes:
    mov eax, 1
    ret
sc_no:
    xor eax, eax
    ret
StrContainsA ENDP

; ---------------------------------------------------------------------------
; BuildPath(rcx = dest, rdx = fn)  dest = vaultPath + "\" + fn
; ---------------------------------------------------------------------------
BuildPath PROC
    sub rsp, 40
    mov gDest, rcx
    mov gFn, rdx
    mov rcx, gDest
    lea rdx, vaultPath
    call lstrcpyA
    mov rcx, gDest
    lea rdx, szBackslash
    call lstrcatA
    mov rcx, gDest
    mov rdx, gFn
    call lstrcatA
    add rsp, 40
    ret
BuildPath ENDP

; ---------------------------------------------------------------------------
; FileContains(rcx = filename, rdx = search) -> rax 1/0 — case-insensitive
; full-content match (ASCII substring over file bytes).
; ---------------------------------------------------------------------------
FileContains PROC
    sub rsp, 56
    mov gFn, rcx
    mov gSearchPtr, rdx
    ; path = vault\filename
    lea rcx, pathBuf2
    mov rdx, gFn
    call BuildPath
    lea rcx, pathBuf2
    mov rdx, GENERIC_READ
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword ptr [rsp+32], OPEN_EXISTING
    mov qword ptr [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp+48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    je fc_nomatch
    mov gFileH, rax
    mov rcx, rax
    lea rdx, gSize
    call GetFileSizeEx
    call GetProcessHeap
    mov gHeap, rax
    mov rcx, gHeap
    xor edx, edx
    mov rax, gSize
    add rax, 1
    mov r8, rax
    call HeapAlloc
    mov gBuf, rax
    mov rcx, gFileH
    mov rdx, gBuf
    mov r8, gSize
    lea r9, gReadN
    mov qword ptr [rsp+32], 0
    call ReadFile
    mov rcx, gFileH
    call CloseHandle
    mov rdx, gBuf
    mov rax, gSize
    mov BYTE PTR [rdx + rax], 0
    mov rcx, gBuf
    mov rdx, gSearchPtr
    call StrContainsA
    mov gMatch, rax
    mov rcx, gHeap
    xor edx, edx
    mov r8, gBuf
    call HeapFree
    mov rax, gMatch
    add rsp, 56
    ret
fc_nomatch:
    xor eax, eax
    add rsp, 56
    ret
FileContains ENDP

; ---------------------------------------------------------------------------
; VaultInit  derive vaultPath from exe dir, create the folder
; ---------------------------------------------------------------------------
VaultInit PROC
    sub rsp, 40
    xor ecx, ecx
    lea rdx, vaultPath
    mov r8, 512
    call GetModuleFileNameA
    lea rcx, vaultPath
    call lstrlenA
    mov rcx, rax
    lea rdx, vaultPath
vi_loop:
    dec rcx
    js vi_done
    cmp BYTE PTR [rdx + rcx], '\'
    jne vi_loop
    mov BYTE PTR [rdx + rcx], 0
vi_done:
    lea rcx, vaultPath
    lea rdx, szVaultDirName
    call lstrcatA
    lea rcx, vaultPath
    xor edx, edx
    call CreateDirectoryA
    add rsp, 40
    ret
VaultInit ENDP

; ---------------------------------------------------------------------------
; SaveConfig — write window size/pos + last note to vault\rawNote.ini
; ---------------------------------------------------------------------------
SaveConfig PROC
    sub rsp, 72
    ; ini path = vault\rawNote.ini
    lea rcx, gIniPath
    lea rdx, szIniName
    call BuildPath
    ; window rect
    mov rcx, hMainWnd
    lea rdx, gRect
    call GetWindowRect
    ; w = right-left, h = bottom-top
    mov eax, gRect.right
    sub eax, gRect.left
    mov gCw, eax
    mov eax, gRect.bottom
    sub eax, gRect.top
    mov gChh, eax
    ; write x
    lea rcx, numBuf
    lea rdx, szFmtD
    mov r8d, gRect.left
    call wsprintfA
    lea rcx, szSecWindow
    lea rdx, szKeyX
    lea r8, numBuf
    lea r9, gIniPath
    call WritePrivateProfileStringA
    ; write y
    lea rcx, numBuf
    lea rdx, szFmtD
    mov r8d, gRect.top
    call wsprintfA
    lea rcx, szSecWindow
    lea rdx, szKeyY
    lea r8, numBuf
    lea r9, gIniPath
    call WritePrivateProfileStringA
    ; write w
    lea rcx, numBuf
    lea rdx, szFmtD
    mov r8d, gCw
    call wsprintfA
    lea rcx, szSecWindow
    lea rdx, szKeyW
    lea r8, numBuf
    lea r9, gIniPath
    call WritePrivateProfileStringA
    ; write h
    lea rcx, numBuf
    lea rdx, szFmtD
    mov r8d, gChh
    call wsprintfA
    lea rcx, szSecWindow
    lea rdx, szKeyH
    lea r8, numBuf
    lea r9, gIniPath
    call WritePrivateProfileStringA
    ; write last note
    lea rcx, szSecNote
    lea rdx, szKeyLast
    lea r8, currentFile
    lea r9, gIniPath
    call WritePrivateProfileStringA
    add rsp, 72
    ret
SaveConfig ENDP

; ---------------------------------------------------------------------------
; LoadConfig — restore window size/pos + last note from vault\rawNote.ini
; ---------------------------------------------------------------------------
LoadConfig PROC
    sub rsp, 72
    lea rcx, gIniPath
    lea rdx, szIniName
    call BuildPath
    ; read x,y,w,h with defaults
    lea rcx, szSecWindow
    lea rdx, szKeyX
    mov r8, CW_USEDEFAULT
    lea r9, gIniPath
    call GetPrivateProfileIntA
    mov gCw, eax
    lea rcx, szSecWindow
    lea rdx, szKeyY
    mov r8, CW_USEDEFAULT
    lea r9, gIniPath
    call GetPrivateProfileIntA
    mov gChh, eax
    lea rcx, szSecWindow
    lea rdx, szKeyW
    mov r8, 900
    lea r9, gIniPath
    call GetPrivateProfileIntA
    mov gLw, eax
    lea rcx, szSecWindow
    lea rdx, szKeyH
    mov r8, 600
    lea r9, gIniPath
    call GetPrivateProfileIntA
    mov gLh, eax
    ; position window (only if coords are sane)
    mov eax, gCw
    cmp eax, CW_USEDEFAULT
    je lc_skip
    mov rcx, hMainWnd
    mov edx, gCw
    mov r8d, gChh
    mov r9d, gLw
    mov eax, gLh
    mov [rsp+32], rax
    mov qword ptr [rsp+40], 1
    call MoveWindow
lc_skip:
    ; open last note if any
    lea rcx, szSecNote
    lea rdx, szKeyLast
    lea r8, szEmpty
    lea r9, currentFile
    mov qword ptr [rsp+32], 260
    lea rax, gIniPath
    mov [rsp+40], rax
    call GetPrivateProfileStringA
    lea rcx, currentFile
    call lstrlenA
    test rax, rax
    jz lc_done
    lea rcx, currentFile
    call LoadNote
lc_done:
    add rsp, 72
    ret
LoadConfig ENDP

; ---------------------------------------------------------------------------
; RefreshList  list *.md files in the vault, filtered by the search box
; ---------------------------------------------------------------------------
RefreshList PROC
    sub rsp, 40
    mov rcx, hSearch
    lea rdx, searchBuf
    mov r8, 260
    call GetWindowTextA
    lea rcx, pathBuf
    lea rdx, vaultPath
    call lstrcpyA
    lea rcx, pathBuf
    lea rdx, szMdWild
    call lstrcatA
    lea rcx, pathBuf
    lea rdx, wc_find
    call FindFirstFileA
    cmp rax, INVALID_HANDLE_VALUE
    je rl_done
    mov gFind, rax
    mov rcx, hList
    mov rdx, LB_RESETCONTENT
    xor r8, r8
    xor r9, r9
    call SendMessageA
rl_loop:
    mov eax, wc_find.dwFileAttributes
    test eax, FILE_ATTRIBUTE_DIRECTORY
    jnz rl_next
    lea rcx, searchBuf
    call lstrlenA
    test rax, rax
    jz rl_add
    lea rcx, wc_find.cFileName
    lea rdx, searchBuf
    call StrContainsA
    test rax, rax
    jnz rl_add
    ; filename didn't match -> try full-content search
    lea rcx, wc_find.cFileName
    lea rdx, searchBuf
    call FileContains
    test rax, rax
    jnz rl_add
    jmp rl_next
rl_add:
    mov rcx, hList
    mov rdx, LB_ADDSTRING
    xor r8, r8
    lea r9, wc_find.cFileName
    call SendMessageA
rl_next:
    mov rcx, gFind
    lea rdx, wc_find
    call FindNextFileA
    test rax, rax
    jnz rl_loop
    mov rcx, gFind
    call FindClose
rl_done:
    add rsp, 40
    ret
RefreshList ENDP

; ---------------------------------------------------------------------------
; LoadNote(rcx = fn)  read a note file into the editor
; ---------------------------------------------------------------------------
LoadNote PROC
    sub rsp, 56
    mov gFn, rcx
    lea rcx, pathBuf
    mov rdx, gFn
    call BuildPath
    lea rcx, pathBuf
    mov rdx, GENERIC_READ
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword ptr [rsp+32], OPEN_EXISTING
    mov qword ptr [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp+48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    je ln_fail
    mov gFileH, rax
    mov rcx, rax
    lea rdx, gSize
    call GetFileSizeEx
    call GetProcessHeap
    mov gHeap, rax
    mov rcx, gHeap
    xor edx, edx
    mov rax, gSize
    add rax, 1
    mov r8, rax
    call HeapAlloc
    mov gBuf, rax
    mov rcx, gFileH
    mov rdx, gBuf
    mov r8, gSize
    lea r9, gReadN
    mov qword ptr [rsp+32], 0
    call ReadFile
    mov rcx, gFileH
    call CloseHandle
    mov rdx, gBuf
    mov rax, gSize
    mov BYTE PTR [rdx + rax], 0
    ; skip UTF-8 BOM (EF BB BF) if present
    cmp BYTE PTR [rdx], 0EFh
    jne ln_no_bom
    cmp BYTE PTR [rdx + 1], 0BBh
    jne ln_no_bom
    cmp BYTE PTR [rdx + 2], 0BFh
    jne ln_no_bom
    add rdx, 3
ln_no_bom:
    mov rcx, rdx
    call SetNoteText
    mov rcx, gHeap
    xor edx, edx
    mov r8, gBuf
    call HeapFree
    lea rcx, currentFile
    mov rdx, gFn
    call lstrcpyA
    call UpdateStatus
    add rsp, 56
    ret
ln_fail:
    mov rcx, hMainWnd
    lea rdx, szLoadError
    lea r8, szAppName
    mov r9, MB_OK or MB_ICONERROR
    call MessageBoxA
    add rsp, 56
    ret
LoadNote ENDP

; ---------------------------------------------------------------------------
; HandleLinkClick(rcx = clicked CP) — if inside [[...]], open/create that note
; ---------------------------------------------------------------------------
HandleLinkClick PROC
    push rbx
    push rsi
    push rdi
    push r12
    push r13
    sub rsp, 72
    mov gLinkCp, rcx
    ; read full editor text (wide)
    mov rcx, hEditor
    call GetWindowTextLengthW
    mov gLinkLen, rax
    test rax, rax
    jz hcl_done
    call GetProcessHeap
    mov gLinkHeap, rax
    mov rcx, gLinkHeap
    xor edx, edx
    mov rax, gLinkLen
    add rax, 1
    shl rax, 1
    mov r8, rax
    call HeapAlloc
    mov gLinkBuf, rax
    mov rcx, hEditor
    mov rdx, gLinkBuf
    mov rax, gLinkLen
    add rax, 1
    mov r8, rax
    call GetWindowTextW
    ; scan: rbx = buf, esi = gw index, edi = cp. find [[...]] containing clicked cp
    mov rbx, gLinkBuf
    xor esi, esi
    xor edi, edi
hcl_scan:
    movzx eax, WORD PTR [rbx + rsi*2]
    test ax, ax
    jz hcl_notfound
    cmp ax, 0Ah       ; '\n' -> part of CRLF (cp already advanced at '\r')
    je hcl_nl
    cmp ax, '['
    je hcl_maybe
    ; normal char: gw+1, cp+1
    inc esi
    inc edi
    jmp hcl_scan
hcl_nl:
    inc esi           ; '\n' -> gw+1, cp+0
    jmp hcl_scan
hcl_maybe:
    ; is it '[['?
    movzx eax, WORD PTR [rbx + rsi*2 + 2]
    cmp ax, '['
    jne hcl_skip1
    ; link starts at cp = edi (the first '[')
    ; save link start cp
    mov r12d, edi      ; linkStartCp
    ; find ']]' starting after the two '['
    lea r13d, [esi + 2]  ; gw search index (r13)
    mov r8d, edi         ; cp at search (starts = linkStartCp + 2)
    add r8d, 2
hcl_findclose:
    movzx eax, WORD PTR [rbx + r13*2]
    test ax, ax
    jz hcl_notfound
    cmp ax, ']'
    jne hcl_fcnext
    movzx eax, WORD PTR [rbx + r13*2 + 2]
    cmp ax, ']'
    je hcl_foundclose
hcl_fcnext:
    ; advance search (handle CRLF for cp tracking)
    cmp WORD PTR [rbx + r13*2], 0Ah
    jne hcl_fc_incboth
    inc r13d
    jmp hcl_findclose
hcl_fc_incboth:
    inc r13d
    inc r8d
    jmp hcl_findclose
hcl_foundclose:
    ; link cp range = [r12d, r8d+1]  (r8d = cp of first ']')
    ; clicked cp is gLinkCp
    mov rax, gLinkCp
    cmp eax, r12d
    jb hcl_notmatch
    lea ecx, [r8d + 1]
    cmp eax, ecx
    ja hcl_notmatch
    ; inside the link -> extract inner text [esi+2 .. r13) in gw space
    ; copy wide inner to gLinkWide
    lea r9, [esi + 2]      ; source gw index (r9)
    lea r10, gLinkWide
    mov r11d, 0
hcl_copyw:
    cmp r9d, r13d
    jae hcl_copyw_done
    movzx eax, WORD PTR [rbx + r9*2]
    mov WORD PTR [r10 + r11*2], ax
    inc r9d
    inc r11d
    jmp hcl_copyw
hcl_copyw_done:
    mov WORD PTR [r10 + r11*2], 0   ; null terminate
    ; convert wide -> ANSI note name
    lea rcx, gLinkName
    ; WideCharToMultiByte(CP_ACP=0, 0, gLinkWide, -1, gLinkName, 260, 0, 0)
    mov rcx, 0
    xor edx, edx
    lea r8, gLinkWide
    mov r9, -1
    lea rax, gLinkName
    mov [rsp+32], rax
    mov qword ptr [rsp+40], 260
    mov qword ptr [rsp+48], 0
    mov qword ptr [rsp+56], 0
    call WideCharToMultiByte
    ; ensure .md extension
    lea rcx, gLinkName
    call lstrlenA
    mov r9, rax
    cmp r9, 3
    jb hcl_addmd
    lea rdx, gLinkName
    add rdx, r9
    sub rdx, 3
    cmp BYTE PTR [rdx], '.'
    jne hcl_addmd
    cmp BYTE PTR [rdx+1], 'm'
    jne hcl_addmd
    cmp BYTE PTR [rdx+2], 'd'
    jne hcl_addmd
    jmp hcl_open
hcl_addmd:
    lea rcx, gLinkName
    lea rdx, szDotMd
    call lstrcatA
hcl_open:
    lea rcx, gLinkName
    call lstrlenA
    test rax, rax
    jz hcl_notfound
    lea rcx, gLinkName
    call LoadNote
    jmp hcl_cleanup
hcl_notmatch:
    ; this link doesn't contain the click -> continue scanning from after it
    mov esi, r13d
    add esi, 2
    mov edi, r8d
    add edi, 2
    jmp hcl_scan
hcl_skip1:
    ; single '[' (not a link) -> advance one char
    inc esi
    inc edi
    jmp hcl_scan
hcl_notfound:
hcl_cleanup:
    mov rcx, gLinkHeap
    xor edx, edx
    mov r8, gLinkBuf
    call HeapFree
hcl_done:
    add rsp, 72
    pop r13
    pop r12
    pop rdi
    pop rsi
    pop rbx
    ret
HandleLinkClick ENDP

; ---------------------------------------------------------------------------
; GenNewName  set currentFile to a unique "Untitled N.md", create the file
; ---------------------------------------------------------------------------
GenNewName PROC
    sub rsp, 56
    mov gN, 0
gnn_try:
    lea rcx, currentFile
    lea rdx, szNewNoteFmt
    mov r8d, gN
    call wsprintfA
    lea rcx, pathBuf
    lea rdx, currentFile
    call BuildPath
    lea rcx, pathBuf
    mov rdx, GENERIC_WRITE
    xor r8, r8
    xor r9, r9
    mov qword ptr [rsp+32], CREATE_NEW
    mov qword ptr [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp+48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    je gnn_taken
    mov rcx, rax
    call CloseHandle
    add rsp, 56
    ret
gnn_taken:
    mov eax, gN
    inc eax
    mov gN, eax
    cmp gN, 1000
    jb gnn_try
    add rsp, 56
    ret
GenNewName ENDP

; ---------------------------------------------------------------------------
; SaveCurrentNote  write editor contents to currentFile
; ---------------------------------------------------------------------------
SaveCurrentNote PROC
    sub rsp, 72
    lea rcx, currentFile
    call lstrlenA
    test rax, rax
    jnz scn_have
    call GenNewName
scn_have:
    ; get wide text from rich edit
    mov rcx, hEditor
    call GetWindowTextLengthW
    mov gLen, rax
    call GetProcessHeap
    mov gHeap, rax
    mov rcx, gHeap
    xor edx, edx
    mov rax, gLen
    add rax, 1
    shl rax, 1
    mov r8, rax
    call HeapAlloc
    mov gWideBuf, rax
    mov rcx, hEditor
    mov rdx, gWideBuf
    mov rax, gLen
    add rax, 1
    mov r8, rax
    call GetWindowTextW
    ; convert UTF-16 -> UTF-8
    mov rcx, CP_UTF8
    xor edx, edx
    mov r8, gWideBuf
    mov r9, -1
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 0
    mov qword ptr [rsp+56], 0
    call WideCharToMultiByte
    mov gBytes, rax          ; required utf8 bytes (incl null)
    mov rcx, gHeap
    xor edx, edx
    mov r8, gBytes
    call HeapAlloc
    mov gBuf, rax
    mov rcx, CP_UTF8
    xor edx, edx
    mov r8, gWideBuf
    mov r9, -1
    mov rax, gBuf
    mov [rsp+32], rax
    mov rax, gBytes
    mov [rsp+40], rax
    mov qword ptr [rsp+48], 0
    mov qword ptr [rsp+56], 0
    call WideCharToMultiByte
    lea rcx, pathBuf
    lea rdx, currentFile
    call BuildPath
    lea rcx, pathBuf
    mov rdx, GENERIC_WRITE
    mov r8, FILE_SHARE_READ
    xor r9, r9
    mov qword ptr [rsp+32], CREATE_ALWAYS
    mov qword ptr [rsp+40], FILE_ATTRIBUTE_NORMAL
    mov qword ptr [rsp+48], 0
    call CreateFileA
    cmp rax, INVALID_HANDLE_VALUE
    je scn_fail
    mov gFileH, rax
    mov rax, gBytes
    sub rax, 1               ; don't write the trailing null
    mov gBytes, rax
    mov rcx, gFileH
    mov rdx, gBuf
    mov r8, gBytes
    lea r9, gWritten
    mov qword ptr [rsp+32], 0
    call WriteFile
    mov rcx, gFileH
    call CloseHandle
scn_fail:
    mov rcx, gHeap
    xor edx, edx
    mov r8, gWideBuf
    call HeapFree
    mov rcx, gHeap
    xor edx, edx
    mov r8, gBuf
    call HeapFree
    mov dirty, 0
    call RefreshList
    call UpdateStatus
    add rsp, 72
    ret
SaveCurrentNote ENDP

; ---------------------------------------------------------------------------
; NewNote  create a fresh note and open it
; ---------------------------------------------------------------------------
NewNote PROC
    sub rsp, 40
    call GenNewName
    mov rcx, hEditor
    xor edx, edx
    call SetWindowTextW
    mov dirty, 0
    call RefreshList
    mov rcx, hList
    mov rdx, LB_SELECTSTRING
    mov r8, -1
    lea r9, currentFile
    call SendMessageA
    call UpdateStatus
    add rsp, 40
    ret
NewNote ENDP

; ---------------------------------------------------------------------------
; DeleteCurrentNote  delete the open note after confirmation
; ---------------------------------------------------------------------------
DeleteCurrentNote PROC
    sub rsp, 40
    lea rcx, currentFile
    call lstrlenA
    test rax, rax
    jz dcn_done
    mov rcx, hMainWnd
    lea rdx, szDeletePrompt
    lea r8, szAppName
    mov r9, MB_YESNO or MB_ICONQUESTION
    call MessageBoxA
    cmp rax, IDYES
    jne dcn_done
    lea rcx, pathBuf
    lea rdx, currentFile
    call BuildPath
    lea rcx, pathBuf
    call DeleteFileA
    lea rcx, currentFile
    lea rdx, szEmpty
    call lstrcpyA
    mov rcx, hEditor
    xor edx, edx
    call SetWindowTextW
    call RefreshList
    call UpdateStatus
dcn_done:
    add rsp, 40
    ret
DeleteCurrentNote ENDP

; ---------------------------------------------------------------------------
; RenameCurrentNote  prompt for a new name, then move the file
; ---------------------------------------------------------------------------
RenameCurrentNote PROC
    sub rsp, 40
    lea rcx, currentFile
    call lstrlenA
    test rax, rax
    jz rcn_done
    lea rcx, renameBuf
    lea rdx, currentFile
    call lstrcpyA
    lea rcx, szRenameTitle
    lea rdx, renameBuf
    lea r8, renameBuf
    call PromptForText
    test rax, rax
    jz rcn_done
    lea rcx, pathBuf
    lea rdx, currentFile
    call BuildPath
    lea rcx, pathBuf2
    lea rdx, renameBuf
    call BuildPath
    lea rcx, pathBuf
    lea rdx, pathBuf2
    call MoveFileA
    lea rcx, currentFile
    lea rdx, renameBuf
    call lstrcpyA
    call RefreshList
    call UpdateStatus
rcn_done:
    add rsp, 40
    ret
RenameCurrentNote ENDP

; ---------------------------------------------------------------------------
; OpenSelected  open the note selected in the sidebar
; ---------------------------------------------------------------------------
OpenSelected PROC
    sub rsp, 40
    mov rcx, hList
    mov rdx, LB_GETCURSEL
    xor r8, r8
    xor r9, r9
    call SendMessageA
    cmp rax, -1
    je os_done
    mov gIdx, eax
    mov rcx, hList
    mov rdx, LB_GETTEXT
    mov r8d, gIdx
    lea r9, currentFile
    call SendMessageA
    lea rcx, currentFile
    call LoadNote
os_done:
    add rsp, 40
    ret
OpenSelected ENDP

; ---------------------------------------------------------------------------
; OpenVaultFolder  reveal the vault folder in Explorer
; ---------------------------------------------------------------------------
OpenVaultFolder PROC
    sub rsp, 56
    mov rcx, hMainWnd
    lea rdx, szOpen
    lea r8, vaultPath
    xor r9, r9
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], SW_SHOWNORMAL
    call ShellExecuteA
    add rsp, 56
    ret
OpenVaultFolder ENDP

; ---------------------------------------------------------------------------
; UpdateStatus  refresh status bar (char/word count + current file)
; ---------------------------------------------------------------------------
UpdateStatus PROC
    sub rsp, 40
    mov rcx, hEditor
    call GetWindowTextLengthW
    mov gChars, eax
    call GetProcessHeap
    mov gUsHeap, rax
    mov rcx, gUsHeap
    xor edx, edx
    mov eax, gChars
    add eax, 1
    shl rax, 1
    mov r8, rax
    call HeapAlloc
    mov gUsBuf, rax
    mov rcx, hEditor
    mov rdx, gUsBuf
    mov eax, gChars
    add eax, 1
    mov r8, rax
    call GetWindowTextW
    mov rcx, gUsBuf
    call CountWordsW
    mov gWords, eax
    mov rcx, gUsHeap
    xor edx, edx
    mov r8, gUsBuf
    call HeapFree
    lea rcx, currentFile
    call lstrlenA
    test rax, rax
    jz us_nonote
    lea rcx, statusBuf
    lea rdx, szStatusFmt
    mov r8d, gChars
    mov r9d, gWords
    lea rax, currentFile
    mov [rsp+32], rax
    call wsprintfA
    jmp us_set
us_nonote:
    lea rcx, statusBuf
    lea rdx, szStatusFmt
    mov r8d, gChars
    mov r9d, gWords
    lea rax, szNoNote
    mov [rsp+32], rax
    call wsprintfA
us_set:
    mov rcx, hStatus
    lea rdx, statusBuf
    call SetWindowTextA
    add rsp, 40
    ret
UpdateStatus ENDP

; ---------------------------------------------------------------------------
; PromptForText(rcx=title, rdx=default, r8=result) -> 1 on OK, 0 on cancel
; ---------------------------------------------------------------------------
PromptForText PROC
    sub rsp, 104
    mov gPromptRes, r8
    mov gPromptDef, rdx
    mov gPromptTitle, rcx
    mov ecx, WS_EX_TOPMOST
    lea rdx, szPromptClass
    mov r8, gPromptTitle
    mov r9, WS_CAPTION or WS_SYSMENU
    mov qword ptr [rsp+32], CW_USEDEFAULT
    mov qword ptr [rsp+40], CW_USEDEFAULT
    mov qword ptr [rsp+48], 380
    mov qword ptr [rsp+56], 120
    mov rax, hMainWnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], 0
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hPrompt, rax
    mov rcx, rax
    mov rdx, SW_SHOW
    call ShowWindow
    mov rcx, hPrompt
    call UpdateWindow
pft_pump:
    lea rcx, msg
    xor edx, edx
    xor r8, r8
    xor r9, r9
    call GetMessageA
    test rax, rax
    jle pft_exit
    lea rcx, msg
    call TranslateMessage
    lea rcx, msg
    call DispatchMessageA
    jmp pft_pump
pft_exit:
    mov rax, g_promptOk
    add rsp, 104
    ret
PromptForText ENDP

; ---------------------------------------------------------------------------
; promptproc  window proc for the rename/name prompt
; ---------------------------------------------------------------------------
promptproc PROC
    mov gHwnd, rcx
    mov gMsg, edx
    mov gWParam, r8
    mov gLParam, r9
    cmp gMsg, WM_CREATE
    je pp_create
    cmp gMsg, WM_COMMAND
    je pp_command
    cmp gMsg, WM_CLOSE
    je pp_close
    cmp gMsg, WM_DESTROY
    je pp_destroy
    cmp gMsg, WM_CTLCOLOREDIT
    je pp_ctlcolor
    cmp gMsg, WM_CTLCOLORBTN
    je pp_ctlcolor
    sub rsp, 40
    mov rcx, gHwnd
    mov edx, gMsg
    mov r8, gWParam
    mov r9, gLParam
    call DefWindowProcA
    add rsp, 40
    ret

pp_create:
    sub rsp, 104
    mov rcx, WS_EX_CLIENTEDGE
    lea rdx, szEditClass
    xor r8, r8
    mov r9, WS_CHILD or WS_VISIBLE or ES_AUTOHSCROLL
    mov qword ptr [rsp+32], 10
    mov qword ptr [rsp+40], 10
    mov qword ptr [rsp+48], 340
    mov qword ptr [rsp+56], 24
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_PROMPT_EDIT
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hPromptEdit, rax
    mov rcx, rax
    mov rdx, gPromptDef
    call SetWindowTextA
    mov rcx, hPromptEdit
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    xor ecx, ecx
    lea rdx, szButtonClass
    lea r8, szOK
    mov r9, WS_CHILD or WS_VISIBLE
    mov qword ptr [rsp+32], 190
    mov qword ptr [rsp+40], 50
    mov qword ptr [rsp+48], 80
    mov qword ptr [rsp+56], 26
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_PROMPT_OK
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    xor ecx, ecx
    lea rdx, szButtonClass
    lea r8, szCancel
    mov r9, WS_CHILD or WS_VISIBLE
    mov qword ptr [rsp+32], 280
    mov qword ptr [rsp+40], 50
    mov qword ptr [rsp+48], 80
    mov qword ptr [rsp+56], 26
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_PROMPT_CANCEL
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    add rsp, 104
    xor eax, eax
    ret

pp_ctlcolor:
    sub rsp, 40
    mov rcx, gWParam
    mov edx, 0E6E6E6h
    call SetTextColor
    mov rcx, gWParam
    mov edx, 1E1E1Eh
    call SetBkColor
    mov rax, gBrush
    add rsp, 40
    ret

pp_command:
    sub rsp, 40
    mov rax, gWParam
    movzx ecx, ax
    cmp ecx, IDC_PROMPT_OK
    je pp_ok
    cmp ecx, IDC_PROMPT_CANCEL
    je pp_cancel
    jmp pp_cmd_done
pp_ok:
    mov rcx, hPromptEdit
    mov rdx, gPromptRes
    mov r8, 260
    call GetWindowTextA
    mov g_promptOk, 1
    mov rcx, gHwnd
    call DestroyWindow
    jmp pp_cmd_done
pp_cancel:
    mov g_promptOk, 0
    mov rcx, gHwnd
    call DestroyWindow
pp_cmd_done:
    add rsp, 40
    xor eax, eax
    ret

pp_close:
    sub rsp, 40
    mov g_promptOk, 0
    mov rcx, gHwnd
    call DestroyWindow
    add rsp, 40
    xor eax, eax
    ret

pp_destroy:
    sub rsp, 40
    xor ecx, ecx
    call PostQuitMessage
    add rsp, 40
    xor eax, eax
    ret
promptproc ENDP

; ---------------------------------------------------------------------------
; listSubclassProc  deselect the note when clicking empty space in the list
; ---------------------------------------------------------------------------
listSubclassProc PROC
    push rbx
    push rsi
    push r12
    push r13
    mov rbx, rcx
    mov esi, edx
    mov r12, r8
    mov r13, r9
    cmp esi, WM_KEYDOWN
    je lsc_key
    cmp esi, WM_LBUTTONDOWN
    jne lsc_dispatch
    sub rsp, 40
    ; LB_ITEMFROMPOINT returns -1 for empty space below/above items
    mov rcx, rbx
    mov rdx, LB_ITEMFROMPOINT
    xor r8, r8
    mov r9, r13          ; packed client coords (already client-relative)
    call SendMessageA
    cmp eax, -1
    jne lsc_skip
    ; clicked empty space -> deselect
    mov rcx, rbx
    mov rdx, LB_SETCURSEL
    mov r8, -1
    xor r9, r9
    call SendMessageA
lsc_skip:
    add rsp, 40
lsc_dispatch:
    sub rsp, 40
    mov rcx, gOldListProc
    mov rdx, rbx
    mov r8d, esi
    mov r9, r12
    mov [rsp+32], r13
    call CallWindowProcA
    add rsp, 40
    pop r13
    pop r12
    pop rsi
    pop rbx
    ret
lsc_key:
    ; Enter -> open selected note
    cmp r12, VK_RETURN
    jne lsc_dispatch
    sub rsp, 40
    call OpenSelected
    add rsp, 40
    xor eax, eax
    pop r13
    pop r12
    pop rsi
    pop rbx
    ret
listSubclassProc ENDP

; ---------------------------------------------------------------------------
; editSubclassProc " make the scroll wheel scroll the (scrollbar-less) editor
; ---------------------------------------------------------------------------
editSubclassProc PROC
    push rbx
    push rsi
    push r12
    push r13
    mov rbx, rcx        ; hwnd
    mov esi, edx        ; msg
    mov r12, r8         ; wParam
    mov r13, r9         ; lParam
    cmp esi, WM_MOUSEWHEEL
    jne esc_dispatch
    ; delta = HIWORD(wParam), signed 16-bit; positive = wheel up
    mov rax, r12
    shr rax, 16
    movsx eax, ax
    test eax, eax
    jg esc_wheelup
    mov gWheelDir, SB_LINEDOWN
    jmp esc_wheelsend
esc_wheelup:
    mov gWheelDir, SB_LINEUP
esc_wheelsend:
    ; send WM_VSCROLL three times (3 lines per notch)
    sub rsp, 40
    mov rcx, rbx
    mov edx, WM_VSCROLL
    mov r8d, gWheelDir
    xor r9, r9
    call SendMessageA
    mov rcx, rbx
    mov edx, WM_VSCROLL
    mov r8d, gWheelDir
    xor r9, r9
    call SendMessageA
    mov rcx, rbx
    mov edx, WM_VSCROLL
    mov r8d, gWheelDir
    xor r9, r9
    call SendMessageA
    add rsp, 40
    xor eax, eax
    pop r13
    pop r12
    pop rsi
    pop rbx
    ret
esc_dispatch:
    sub rsp, 40
    mov rcx, gOldEditProc
    mov rdx, rbx
    mov r8d, esi
    mov r9, r12
    mov [rsp+32], r13
    call CallWindowProcA
    add rsp, 40
    pop r13
    pop r12
    pop rsi
    pop rbx
    ret
editSubclassProc ENDP

; ---------------------------------------------------------------------------
; wndproc  main window procedure
; ---------------------------------------------------------------------------
wndproc PROC
    mov gHwnd, rcx
    mov gMsg, edx
    mov gWParam, r8
    mov gLParam, r9
    cmp gMsg, WM_CREATE
    je wp_create
    cmp gMsg, WM_SIZE
    je wp_size
    cmp gMsg, WM_COMMAND
    je wp_command
    cmp gMsg, WM_CONTEXTMENU
    je wp_contextmenu
    cmp gMsg, WM_NCHITTEST
    je wp_nchittest
    cmp gMsg, WM_DRAWITEM
    je wp_drawitem
    cmp gMsg, WM_CTLCOLOREDIT
    je wp_ctlcolor
    cmp gMsg, WM_CTLCOLORLISTBOX
    je wp_ctlcolor
    cmp gMsg, WM_CTLCOLORSTATIC
    je wp_ctlstatic
    cmp gMsg, WM_CTLCOLORBTN
    je wp_ctlcolor
    cmp gMsg, WM_CLOSE
    je wp_close
    cmp gMsg, WM_DESTROY
    je wp_destroy
    sub rsp, 40
    mov rcx, gHwnd
    mov edx, gMsg
    mov r8, gWParam
    mov r9, gLParam
    call DefWindowProcA
    add rsp, 40
    ret

; --- WM_CREATE ---
wp_create:
    sub rsp, 104
    call CreateMenu
    mov g_hMenu, rax
    call CreatePopupMenu
    mov gSub, rax
    mov gFileMenu, rax
    mov rcx, g_hMenu
    mov edx, MF_POPUP
    mov r8, gSub
    lea r9, szMenuFile
    call AppendMenuA
    mov rcx, gSub
    xor edx, edx
    mov r8, IDM_NEW
    lea r9, szNew
    call AppendMenuA
    mov rcx, gSub
    xor edx, edx
    mov r8, IDM_SAVE
    lea r9, szSave
    call AppendMenuA
    mov rcx, gSub
    xor edx, edx
    mov r8, IDM_RENAME
    lea r9, szRename
    call AppendMenuA
    mov rcx, gSub
    xor edx, edx
    mov r8, IDM_DELETE
    lea r9, szDelete
    call AppendMenuA
    mov rcx, gSub
    xor edx, edx
    mov r8, IDM_OPENVAULT
    lea r9, szOpenVault
    call AppendMenuA
    mov rcx, gSub
    xor edx, edx
    mov r8, IDM_EXIT
    lea r9, szExit
    call AppendMenuA
    call CreatePopupMenu
    mov gSub, rax
    mov gNoteMenu, rax
    mov rcx, g_hMenu
    mov edx, MF_POPUP
    mov r8, gSub
    lea r9, szMenuNote
    call AppendMenuA
    mov rcx, gSub
    xor edx, edx
    mov r8, IDM_ABOUT
    lea r9, szAbout
    call AppendMenuA
    ; no SetMenu " frameless window with custom top bar
    ; context menu (right-click): New, Save, Rename, Delete
    call CreatePopupMenu
    mov gContextMenu, rax
    mov rcx, rax
    xor edx, edx
    mov r8, IDM_NEW
    lea r9, szNew
    call AppendMenuA
    mov rcx, gContextMenu
    xor edx, edx
    mov r8, IDM_SAVE
    lea r9, szSave
    call AppendMenuA
    mov rcx, gContextMenu
    xor edx, edx
    mov r8, IDM_RENAME
    lea r9, szRename
    call AppendMenuA
    mov rcx, gContextMenu
    xor edx, edx
    mov r8, IDM_DELETE
    lea r9, szDelete
    call AppendMenuA
    ; ---- custom title bar buttons ----
    ; File button (pops File menu)
    xor ecx, ecx
    lea rdx, szButtonClass
    lea r8, szBarFile
    mov r9, WS_CHILD or WS_VISIBLE or BS_OWNERDRAW
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 60
    mov qword ptr [rsp+56], 24
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_BTN_FILE
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hwnd_file, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    ; Note button (pops Note menu)
    xor ecx, ecx
    lea rdx, szButtonClass
    lea r8, szBarNote
    mov r9, WS_CHILD or WS_VISIBLE or BS_OWNERDRAW
    mov qword ptr [rsp+32], 60
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 60
    mov qword ptr [rsp+56], 24
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_BTN_NOTE
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hwnd_note, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    ; Close button (rightmost)
    xor ecx, ecx
    lea rdx, szButtonClass
    lea r8, szBarClose
    mov r9, WS_CHILD or WS_VISIBLE or BS_OWNERDRAW
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 34
    mov qword ptr [rsp+56], 24
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_BTN_CLOSE
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hwnd_close, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    ; Restore/max button
    xor ecx, ecx
    lea rdx, szButtonClass
    lea r8, szBarRestore
    mov r9, WS_CHILD or WS_VISIBLE or BS_OWNERDRAW
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 34
    mov qword ptr [rsp+56], 24
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_BTN_RESTORE
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hwnd_restore, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    ; Min button
    xor ecx, ecx
    lea rdx, szButtonClass
    lea r8, szBarMin
    mov r9, WS_CHILD or WS_VISIBLE or BS_OWNERDRAW
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 34
    mov qword ptr [rsp+56], 24
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_BTN_MIN
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hwnd_min, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    ; search box
    xor ecx, ecx
    lea rdx, szEditClass
    xor r8, r8
    mov r9, WS_CHILD or WS_VISIBLE or WS_BORDER or ES_AUTOHSCROLL
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 0
    mov qword ptr [rsp+56], 0
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_SEARCH
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hSearch, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    ; note list
    mov rcx, WS_EX_CLIENTEDGE
    lea rdx, szListClass
    xor r8, r8
    mov r9, WS_CHILD or WS_VISIBLE or WS_VSCROLL or LBS_NOTIFY or LBS_NOINTEGRALHEIGHT
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 0
    mov qword ptr [rsp+56], 0
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_LIST
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hList, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    ; subclass listbox: deselect when clicking empty space
    mov rcx, hList
    mov edx, GWLP_WNDPROC
    lea r8, listSubclassProc
    call SetWindowLongPtrA
    mov gOldListProc, rax
    ; editor (RichEdit control, no visible scrollbars; arrow-key scroll)
    mov rcx, WS_EX_CLIENTEDGE
    lea rdx, szRichEditClass
    xor r8, r8
    mov r9, WS_CHILD or WS_VISIBLE or ES_MULTILINE or ES_AUTOVSCROLL or ES_AUTOHSCROLL or ES_WANTRETURN
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 0
    mov qword ptr [rsp+56], 0
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_EDITOR
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hEditor, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    ; enable change notifications + lift text limit
    mov rcx, hEditor
    mov rdx, EM_SETEVENTMASK
    xor r8, r8
    mov r9, ENM_CHANGE
    call SendMessageA
    mov rcx, hEditor
    mov rdx, EM_EXLIMITTEXT
    xor r8, r8
    mov r9, 7FFFFFF0h
    call SendMessageA
    ; grey background for the rich edit
    mov rcx, hEditor
    mov rdx, EM_SETBKGNDCOLOR
    xor r8, r8
    mov r9, 1E1E1Eh
    call SendMessageA
    ; white text (default char format -> applies to loaded + new text)
    mov gCf.cbSize, 116
    mov gCf.dwMask, CFM_COLOR
    mov gCf.dwEffects, 0
    mov gCf.crTextColor, 0E6E6E6h
    mov rcx, hEditor
    mov rdx, EM_SETCHARFORMAT
    xor r8, r8                ; SCF_DEFAULT = 0 (control-wide default)
    lea r9, gCf
    call SendMessageA
    ; also recolor any text currently present
    mov rcx, hEditor
    mov rdx, EM_SETCHARFORMAT
    mov r8, SCF_ALL
    lea r9, gCf
    call SendMessageA
    ; subclass editor: scroll wheel support
    mov rcx, hEditor
    mov edx, GWLP_WNDPROC
    lea r8, editSubclassProc
    call SetWindowLongPtrA
    mov gOldEditProc, rax
    ; status bar (STATIC control -> WM_CTLCOLORSTATIC darkens it)
    xor ecx, ecx
    lea rdx, szStatusClass
    xor r8, r8
    mov r9, WS_CHILD or WS_VISIBLE or SS_CENTERIMAGE
    mov qword ptr [rsp+32], 0
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 0
    mov qword ptr [rsp+56], 0
    mov rax, gHwnd
    mov [rsp+64], rax
    mov qword ptr [rsp+72], IDC_STATUS
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hStatus, rax
    mov rcx, rax
    mov rdx, WM_SETFONT
    mov r8, gFont
    mov r9, 1
    call SendMessageA
    call VaultInit
    call RefreshList
    call UpdateStatus
    call LoadConfig
    add rsp, 104
    xor eax, eax
    ret

; --- WM_SIZE ---
wp_size:
    sub rsp, 56
    mov rax, gLParam
    movzx ecx, ax
    mov gCw, ecx
    mov edx, eax
    shr edx, 16
    mov gChh, edx
    mov eax, gCw
    imul eax, 2
    xor edx, edx
    mov ecx, 5
    div ecx
    mov gLw, eax
    mov eax, gCw
    sub eax, gLw
    mov gEw, eax
    mov eax, gChh
    sub eax, 52
    sub eax, 22
    mov gLh, eax
    mov eax, gChh
    sub eax, 22
    mov gSy, eax
    ; title bar buttons (right-aligned): close/restore/min
    mov rcx, hwnd_close
    mov edx, gCw
    sub edx, 34
    xor r8, r8
    mov r9d, 34
    mov qword ptr [rsp+32], 24
    mov qword ptr [rsp+40], 1
    call MoveWindow
    mov rcx, hwnd_restore
    mov edx, gCw
    sub edx, 68
    xor r8, r8
    mov r9d, 34
    mov qword ptr [rsp+32], 24
    mov qword ptr [rsp+40], 1
    call MoveWindow
    mov rcx, hwnd_min
    mov edx, gCw
    sub edx, 102
    xor r8, r8
    mov r9d, 34
    mov qword ptr [rsp+32], 24
    mov qword ptr [rsp+40], 1
    call MoveWindow
    ; search box
    mov rcx, hSearch
    xor edx, edx
    mov r8, 26
    mov r9d, gCw
    mov qword ptr [rsp+32], 26
    mov qword ptr [rsp+40], 1
    call MoveWindow
    mov rcx, hList
    xor edx, edx
    mov r8, 52
    mov r9d, gLw
    mov eax, gLh
    mov [rsp+32], rax
    mov qword ptr [rsp+40], 1
    call MoveWindow
    mov rcx, hEditor
    mov edx, gLw
    mov r8, 52
    mov r9d, gEw
    mov eax, gLh
    mov [rsp+32], rax
    mov qword ptr [rsp+40], 1
    call MoveWindow
    mov rcx, hStatus
    xor edx, edx
    mov r8d, gSy
    mov r9d, gCw
    mov qword ptr [rsp+32], 22
    mov qword ptr [rsp+40], 1
    call MoveWindow
    add rsp, 56
    xor eax, eax
    ret

; --- WM_COMMAND ---
wp_command:
    sub rsp, 72
    mov rax, gWParam
    movzx ecx, ax
    cmp ecx, IDC_BTN_FILE
    je wpc_btnfile
    cmp ecx, IDC_BTN_NOTE
    je wpc_btnnote
    cmp ecx, IDC_BTN_MIN
    je wpc_btnmin
    cmp ecx, IDC_BTN_RESTORE
    je wpc_btnrestore
    cmp ecx, IDC_BTN_CLOSE
    je wpc_btnclose
    cmp gLParam, 0
    jne wpc_ctrl
    cmp ecx, IDM_NEW
    je wpc_new
    cmp ecx, IDM_SAVE
    je wpc_save
    cmp ecx, IDM_RENAME
    je wpc_rename
    cmp ecx, IDM_DELETE
    je wpc_delete
    cmp ecx, IDM_OPENVAULT
    je wpc_openvault
    cmp ecx, IDM_ABOUT
    je wpc_about
    cmp ecx, IDM_EXIT
    je wpc_exit
    jmp wpc_done
wpc_new:
    call NewNote
    jmp wpc_done
wpc_save:
    call SaveCurrentNote
    jmp wpc_done
wpc_rename:
    call RenameCurrentNote
    jmp wpc_done
wpc_delete:
    call DeleteCurrentNote
    jmp wpc_done
wpc_openvault:
    call OpenVaultFolder
    jmp wpc_done
wpc_about:
    mov rcx, hMainWnd
    lea rdx, szAboutText
    lea r8, szAboutTitle
    mov r9, MB_OK or MB_ICONINFORMATION
    call MessageBoxA
    jmp wpc_done
wpc_exit:
    mov rcx, hMainWnd
    call DestroyWindow
    jmp wpc_done
wpc_btnfile:
    ; popup File menu anchored below the File button (screen coords)
    mov rcx, hwnd_file
    lea rdx, gRect
    call GetWindowRect
    mov rcx, gFileMenu
    mov edx, TPM_LEFTBUTTON or TPM_TOPALIGN or TPM_LEFTALIGN
    mov r8d, gRect.left
    mov r9d, gRect.bottom
    mov qword ptr [rsp+32], 0
    mov rax, hMainWnd
    mov [rsp+40], rax
    mov qword ptr [rsp+48], 0
    call TrackPopupMenu
    jmp wpc_done
wpc_btnnote:
    mov rcx, hwnd_note
    lea rdx, gRect
    call GetWindowRect
    mov rcx, gNoteMenu
    mov edx, TPM_LEFTBUTTON or TPM_TOPALIGN or TPM_LEFTALIGN
    mov r8d, gRect.left
    mov r9d, gRect.bottom
    mov qword ptr [rsp+32], 0
    mov rax, hMainWnd
    mov [rsp+40], rax
    mov qword ptr [rsp+48], 0
    call TrackPopupMenu
    jmp wpc_done
wpc_btnmin:
    mov rcx, hMainWnd
    mov edx, WM_SYSCOMMAND
    mov r8, SC_MINIMIZE
    xor r9, r9
    call SendMessageA
    jmp wpc_done
wpc_btnrestore:
    mov rcx, hMainWnd
    call IsZoomed
    test rax, rax
    jnz wpc_restore_now
    mov rcx, hMainWnd
    mov edx, WM_SYSCOMMAND
    mov r8, SC_MAXIMIZE
    xor r9, r9
    call SendMessageA
    jmp wpc_done
wpc_restore_now:
    mov rcx, hMainWnd
    mov edx, WM_SYSCOMMAND
    mov r8, SC_RESTORE
    xor r9, r9
    call SendMessageA
    jmp wpc_done
wpc_btnclose:
    mov rcx, hMainWnd
    mov edx, WM_SYSCOMMAND
    mov r8, SC_CLOSE
    xor r9, r9
    call SendMessageA
    jmp wpc_done
wpc_ctrl:
    mov rax, gWParam
    shr rax, 16
    movzx edx, ax
    cmp ecx, IDC_LIST
    jne wpc_c2
    cmp edx, LBN_SELCHANGE
    je wpc_open
    jmp wpc_done
wpc_c2:
    cmp ecx, IDC_SEARCH
    jne wpc_c3
    cmp edx, EN_CHANGE
    je wpc_refresh
    jmp wpc_done
wpc_c3:
    cmp ecx, IDC_EDITOR
    jne wpc_done
    cmp edx, EN_CHANGE
    jne wpc_done
    cmp gLoading, 1
    je wpc_done
    mov dirty, 1
    call ApplyMarkdown
    call UpdateStatus
    jmp wpc_done
wpc_open:
    call OpenSelected
    jmp wpc_done
wpc_refresh:
    call RefreshList
wpc_done:
    add rsp, 72
    xor eax, eax
    ret

; --- WM_CTLCOLOR* ---
wp_ctlcolor:
    sub rsp, 40
    mov rcx, gWParam
    mov edx, 0E6E6E6h
    call SetTextColor
    mov rax, gLParam
    cmp rax, hList
    je wpc_cl_list
    cmp rax, hSearch
    je wpc_cl_search
    jmp wpc_cl_default
wpc_cl_list:
    mov rcx, gWParam
    mov edx, 171717h
    call SetBkColor
    mov rax, gBrushList
    jmp wpc_cl_done
wpc_cl_search:
    mov rcx, gWParam
    mov edx, 111111h
    call SetBkColor
    mov rax, gBrushSearch
    jmp wpc_cl_done
wpc_cl_default:
    mov rcx, gWParam
    mov edx, 1E1E1Eh
    call SetBkColor
    mov rax, gBrush
wpc_cl_done:
    add rsp, 40
    ret

; --- WM_CTLCOLORSTATIC (status bar text) ---
wp_ctlstatic:
    sub rsp, 40
    mov rcx, gWParam
    mov edx, 0E6E6E6h
    call SetTextColor
    mov rcx, gWParam
    mov edx, 2A2A2Ah
    call SetBkColor
    mov rax, gBrushStatus
    add rsp, 40
    ret

; --- WM_DRAWITEM (owner-draw title-bar buttons) ---
wp_drawitem:
    sub rsp, 72
    mov rax, gLParam
    mov gDiPtr, rax         ; DRAWITEMSTRUCT*
    ; pick label + kind (0=ANSI text, 1=wide glyph) by CtlID
    mov rax, gDiPtr
    mov eax, [rax + 4]      ; CtlID
    cmp eax, IDC_BTN_CLOSE
    je wdi_close
    cmp eax, IDC_BTN_RESTORE
    je wdi_restore
    cmp eax, IDC_BTN_MIN
    je wdi_min
    cmp eax, IDC_BTN_FILE
    je wdi_file
    cmp eax, IDC_BTN_NOTE
    je wdi_note
    jmp wdi_done
wdi_close:
    lea rax, szGlyphClose
    mov gBtnLabel, rax
    mov gBtnGlyph, 1
    jmp wdi_pickdone
wdi_restore:
    lea rax, szGlyphRestore
    mov gBtnLabel, rax
    mov gBtnGlyph, 1
    jmp wdi_pickdone
wdi_min:
    lea rax, szGlyphMin
    mov gBtnLabel, rax
    mov gBtnGlyph, 1
    jmp wdi_pickdone
wdi_file:
    lea rax, szBarFile
    mov gBtnLabel, rax
    mov gBtnGlyph, 0
    jmp wdi_pickdone
wdi_note:
    lea rax, szBarNote
    mov gBtnLabel, rax
    mov gBtnGlyph, 0
wdi_pickdone:
    ; fill rounded grey rect
    mov rax, gDiPtr
    mov rcx, [rax + 32]     ; hdc
    mov rdx, gBrushBtn
    call SelectObject
    mov rax, gDiPtr
    mov rcx, [rax + 32]
    mov edx, [rax + 40]     ; left
    mov r8d, [rax + 44]     ; top
    mov r9d, [rax + 48]     ; right
    mov eax, [rax + 52]     ; bottom
    mov [rsp+32], rax
    mov qword ptr [rsp+40], 10
    mov qword ptr [rsp+48], 10
    call RoundRect
    ; white text, transparent bg, small font
    mov rax, gDiPtr
    mov rcx, [rax + 32]
    mov edx, 0E6E6E6h
    call SetTextColor
    mov rax, gDiPtr
    mov rcx, [rax + 32]
    mov edx, TRANSPARENT
    call SetBkMode
    mov rax, gDiPtr
    mov rcx, [rax + 32]
    mov rdx, gSmallFont
    call SelectObject
    ; draw the label
    mov rax, gDiPtr
    mov rcx, [rax + 32]     ; hdc
    mov rdx, gBtnLabel      ; text
    mov r8, -1
    lea r9, [rax + 40]      ; &rcItem
    mov rax, DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOCLIP
    mov [rsp+32], rax
    cmp gBtnGlyph, 1
    je wdi_draww
    call DrawTextA
    jmp wdi_done
wdi_draww:
    call DrawTextW
wdi_done:
    mov eax, 1
    add rsp, 72
    ret

; --- WM_NCHITTEST (drag the top bar) ---
wp_nchittest:
    sub rsp, 56
    ; lParam = screen coords -> convert to client
    mov rax, gLParam
    and eax, 0FFFFh
    mov gNcPt.x, eax
    mov rax, gLParam
    shr rax, 16
    and eax, 0FFFFh
    mov gNcPt.y, eax
    mov rcx, gHwnd
    lea rdx, gNcPt
    call ScreenToClient
    ; if 0 <= y < BARH -> draggable (HTCAPTION)
    mov eax, gNcPt.y
    cmp eax, 0
    jl wnc_default
    cmp eax, BARH
    jae wnc_default
    mov eax, HTCAPTION
    jmp wnc_done
wnc_default:
    mov rcx, gHwnd
    mov edx, gMsg
    mov r8, gWParam
    mov r9, gLParam
    call DefWindowProcA
wnc_done:
    add rsp, 56
    ret

; --- WM_CONTEXTMENU ---
wp_contextmenu:
    sub rsp, 56
    mov rax, gLParam
    movzx ecx, ax
    mov gCw, ecx
    mov edx, eax
    shr edx, 16
    mov gChh, edx
    mov rcx, gContextMenu
    mov edx, TPM_RIGHTBUTTON
    mov r8d, gCw
    mov r9d, gChh
    mov qword ptr [rsp+32], 0
    mov rax, gHwnd
    mov [rsp+40], rax
    mov qword ptr [rsp+48], 0
    call TrackPopupMenu
    add rsp, 56
    xor eax, eax
    ret

; --- WM_CLOSE ---
wp_close:
    sub rsp, 40
    cmp dirty, 1
    jne wp_close_now
    ; unsaved changes -> prompt Yes/No/Cancel
    mov rcx, gHwnd
    lea rdx, szSavePrompt
    lea r8, szAppName
    mov r9, MB_YESNOCANCEL or MB_ICONQUESTION
    call MessageBoxA
    cmp rax, IDYES
    je wp_close_save
    cmp rax, IDNO
    je wp_close_now
    ; IDCANCEL -> do nothing (keep window)
    jmp wp_close_ret
wp_close_save:
    call SaveCurrentNote
wp_close_now:
    mov rcx, gHwnd
    call DestroyWindow
wp_close_ret:
    add rsp, 40
    xor eax, eax
    ret

; --- WM_DESTROY ---
wp_destroy:
    sub rsp, 40
    call SaveConfig
    xor ecx, ecx
    call PostQuitMessage
    add rsp, 40
    xor eax, eax
    ret
wndproc ENDP

; ---------------------------------------------------------------------------
; entry point
; ---------------------------------------------------------------------------
PUBLIC start
start PROC
    sub rsp, 120
    xor ecx, ecx
    call GetModuleHandleA
    mov hInstance, rax
    mov iccx.dwSize, 8
    mov iccx.dwICC, ICC_STANDARD_CLASSES or ICC_BAR_CLASSES
    lea rcx, iccx
    call InitCommonControlsEx
    ; load rich edit library (RICHEDIT50W)
    lea rcx, szMsftedit
    call LoadLibraryA
    ; dark theme: grey brushes for each surface
    mov ecx, 1E1E1Eh
    call CreateSolidBrush
    mov gBrush, rax
    mov ecx, 171717h
    call CreateSolidBrush
    mov gBrushList, rax
    mov ecx, 111111h
    call CreateSolidBrush
    mov gBrushSearch, rax
    mov ecx, 2A2A2Ah
    call CreateSolidBrush
    mov gBrushStatus, rax
    mov ecx, 3A3A3Ah          ; button grey #3A3A3A
    call CreateSolidBrush
    mov gBrushBtn, rax
    ; small font for title-bar buttons
    mov rcx, DEFAULT_GUI_FONT
    call GetStockObject
    mov gSmallFont, rax
    ; font: Segoe UI, ~15pt
    mov ecx, -20
    xor edx, edx
    xor r8, r8
    xor r9, r9
    mov qword ptr [rsp+32], 400
    mov qword ptr [rsp+40], 0
    mov qword ptr [rsp+48], 0
    mov qword ptr [rsp+56], 0
    mov qword ptr [rsp+64], 1
    mov qword ptr [rsp+72], 0
    mov qword ptr [rsp+80], 0
    mov qword ptr [rsp+88], 5
    mov qword ptr [rsp+96], 0
    lea rax, szFontFace
    mov [rsp+104], rax
    call CreateFontA
    mov gFont, rax
    ; register main class
    mov wc.cbSize, 80
    mov wc.style, CS_HREDRAW or CS_VREDRAW
    lea rax, wndproc
    mov wc.lpfnWndProc, rax
    mov wc.cbClsExtra, 0
    mov wc.cbWndExtra, 0
    mov rax, hInstance
    mov wc.hInstance, rax
    mov rcx, hInstance
    mov edx, IDI_MAIN
    call LoadIconA
    mov wc.hIcon, rax
    xor ecx, ecx
    mov edx, IDC_ARROW
    call LoadCursorA
    mov wc.hCursor, rax
    mov rax, gBrush
    mov wc.hbrBackground, rax
    mov wc.lpszMenuName, 0
    lea rax, szMainClass
    mov wc.lpszClassName, rax
    mov rcx, hInstance
    mov edx, IDI_MAIN
    call LoadIconA
    mov wc.hIconSm, rax
    lea rcx, wc
    call RegisterClassExA
    ; register prompt class
    mov wc.cbSize, 80
    mov wc.style, 0
    lea rax, promptproc
    mov wc.lpfnWndProc, rax
    mov rax, gBrush
    mov wc.hbrBackground, rax
    lea rax, szPromptClass
    mov wc.lpszClassName, rax
    lea rcx, wc
    call RegisterClassExA
    ; create main window
    xor ecx, ecx
    lea rdx, szMainClass
    lea r8, szAppName
    mov r9, WS_POPUP or WS_MINIMIZEBOX or WS_MAXIMIZEBOX or WS_SYSMENU
    mov qword ptr [rsp+32], CW_USEDEFAULT
    mov qword ptr [rsp+40], CW_USEDEFAULT
    mov qword ptr [rsp+48], 900
    mov qword ptr [rsp+56], 600
    mov qword ptr [rsp+64], 0
    mov qword ptr [rsp+72], 0
    mov rax, hInstance
    mov [rsp+80], rax
    mov qword ptr [rsp+88], 0
    call CreateWindowExA
    mov hMainWnd, rax
    mov rcx, rax
    mov rdx, SW_SHOW
    call ShowWindow
    mov rcx, hMainWnd
    call UpdateWindow
st_loop:
    lea rcx, msg
    xor edx, edx
    xor r8, r8
    xor r9, r9
    call GetMessageA
    test rax, rax
    jle st_exit
    cmp msg.message, WM_KEYDOWN
    jne st_dispatch
    mov rax, msg.wParam
    cmp rax, 'N'
    je st_keyN
    cmp rax, 'S'
    je st_keyS
    jmp st_dispatch
st_keyN:
    mov ecx, VK_CONTROL
    call GetAsyncKeyState
    test ax, 8000h
    jz st_dispatch
    call NewNote
    jmp st_loop
st_keyS:
    mov ecx, VK_CONTROL
    call GetAsyncKeyState
    test ax, 8000h
    jz st_dispatch
    call SaveCurrentNote
    jmp st_loop
st_dispatch:
    lea rcx, msg
    call TranslateMessage
    lea rcx, msg
    call DispatchMessageA
    jmp st_loop
st_exit:
    xor ecx, ecx
    call ExitProcess
start ENDP

END
