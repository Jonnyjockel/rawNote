# rawNote — build

## Requirements
- Windows with Visual Studio 2022, MSVC x64 tools (`ml64.exe`, `link.exe`),
  Windows SDK, and the x64 Win32 import libraries.

## Build
```
cd rawNote
.\build.ps1            # assemble + link -> build\rawNote.exe
.\build.ps1 -Clean     # remove build output
```

The script locates Visual Studio via `vswhere`, loads `vcvars64.bat` into the
session, then:
```
ml64  /c /nologo /Fo"build\rawNote.obj" "src\rawNote.asm"
link  /nologo /subsystem:windows /entry:start build\rawNote.obj \
      kernel32.lib user32.lib gdi32.lib shell32.lib comctl32.lib \
      /out:build\rawNote.exe
```

## Notes
- `/entry:start` — no CRT startup; `start` is our entry point.
- `/subsystem:windows` — GUI app, no console.
- The exe depends only on system DLLs; it's a single portable binary.
- Run it from anywhere; the vault is created as `vault\` next to the exe.
