# rawNote

A minimal, Obsidian-style note-taking app written **100% in x86-64 assembly**
(MASM / ML64), using the Win32 API directly. No C runtime, no resource files,
no framework — a single native `.exe`.

## Why?
Because it's possible. Every line of the source is hand-written assembly, and
the whole thing builds to a ~24 KB portable binary that does what most note
apps ship 100 MB of Electron to do.

## Features
- **Dark grey theme** with white text / bigger font
- **Markdown** (source-mode, markers stay visible): `**bold**`, `*italic*`,
  `` `code` ``, `#`–`######` headers
- **Notes** as plain `.md` files in a `vault\` folder next to the exe
- Create / open / save / rename / delete notes
- **Search**: live filename **and** full-content matching (case-insensitive)
- Scroll wheel + arrow-key scrolling (no visible scrollbars)
- Word + character count in the status bar
- **Frameless window** with custom rounded title-bar buttons (min / restore / close)
- Right-click context menu (New / Save / Rename / Delete)
- **Dirty-flag**: prompts "unsaved changes?" on close
- Window size/position + last-opened-note persistence (`vault\rawNote.ini`)
- UTF-8 notes (BOM-aware on load)
- Custom icon
- Shortcuts: `Ctrl+N` new note, `Ctrl+S` save

## Run it
Download `build/rawNote.exe` and run it. The `vault\` folder (where notes
live) is created next to the exe on first launch. No installation.

## Build from source
Requires Visual Studio 2022 (MSVC x64 tools: `ml64.exe` + `link.exe`) and the
Windows SDK's `rc.exe` (for the icon resource).

```
.\build.ps1          # assemble + link -> build\rawNote.exe
.\build.ps1 -Clean   # remove build output
```

## Layout
```
rawNote/
├── src/rawNote.asm     the entire app (entry point + all logic)
├── src/rawNote.inc     constants, Win32 types, imports
├── src/rawNote.rc      icon resource
├── src/favicon.ico     the app icon
├── build.ps1
├── docs/               architecture, build, roadmap
├── notes/              developer step-log
└── build/              compiled output (rawNote.exe)
```

## License
MIT — see [LICENSE](LICENSE).
