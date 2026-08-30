# rawNote — architecture

## One binary, no CRT
The entry point is `start` (linked with `/entry:start /subsystem:windows`), not
the CRT `WinMain`. `hInstance` comes from `GetModuleHandleW(NULL)`.

## Structure of `src/rawNote.asm`
```
start            entry: init common controls, register classes, main window,
                 accelerator table, message loop, ExitProcess
wndproc          main window procedure:
                   WM_CREATE   build menu, create controls, VaultInit, list
                   WM_SIZE     manual layout (search / list / editor / status)
                   WM_COMMAND  menu commands + control notifications
                   WM_CLOSE    DestroyWindow
                   WM_DESTROY  PostQuitMessage
promptproc       modal rename/name prompt window procedure
PromptForText    modal loop around the prompt window
```

## Data layer (filesystem helpers)
```
VaultInit         derive vault path from exe dir, create folder
RefreshList       FindFirst/NextFileW over vault\*.md, filter by search text
LoadNote          ReadFile into heap buffer -> SetWindowTextW(editor)
SaveCurrentNote   GetWindowTextW(editor) -> WriteFile (CREATE_ALWAYS)
GenNewName        allocate a unique "Untitled N.md"
DeleteCurrentNote DeleteFileW after confirmation
RenameCurrentNote MoveFileW after prompt
```

## Key decisions
- **ANSI (narrow) strings + `-A` API.** ML64 has no `WORD "string"` string
  initializer (and no `WSTR`), so wide strings would need a macro or explicit
  char lists. ANSI keeps v1 simple and buildable; a Unicode layer is a v2 item.
- **Manual calling convention.** ML64 does not support `INVOKE`/`ADDR`/`.IF`,
  so every call is explicit: args in RCX/RDX/R8/R9, 32-byte shadow space,
  `call` + `ret`, and `cmp`/`jcc` for branching.
- **EDIT + LISTBOX**, not RichEdit/ListView. Fewer moving parts, no RICHED20.dll
  loading, trivially correct. RichEdit (for markdown rendering) is a roadmap item.
- **Manual layout** on WM_SIZE (fixed pixel math) instead of child-window
  auto-resize. Deterministic and easy to reason about in assembly.
- **Single source file.** Avoids cross-file EXTERN/PUBLIC symbol-type headaches.
