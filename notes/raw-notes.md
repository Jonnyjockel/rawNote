# rawNote — step log

## 2026-08-22 — feature run + wiki-link attempt
- SHIPPED: dirty-flag/save-on-close (Yes/No/Cancel), Enter-to-open, window
  size/pos + last-note persistence (vault\rawNote.ini), Unicode/BOM interop
  (skip UTF-8 BOM on load), full-content search (FileContains fallback).
- WIKI-LINKS (`[[...]]`) ATTEMPTED but caused a crash on every keystroke; full
  revert. SHELVED. Suspected cause: stack misalignment in HandleLinkClick
  (5 pushes = odd, breaks 16-byte alignment before calls) + scan interaction.
- Fixed along the way: TrackPopupMenu stack overflow (sub rsp 40->72) + screen-
  coords anchor; EM_CHARFROMPOS was wrong value (0x4D7 vs 0x427); scroll-wheel
  direction held in volatile r11.
- LESSONS: verify RichEdit message values against the SDK headers, not memory;
  keep callee-saved regs or use globals for state that crosses calls; NEVER
  line-range-delete source via exec (use edit tool).

## 2026-08-20 — course correction (Jonny)
- Jonny clarified: rawNote was meant to be a **note-taking app** written **fully in assembly**, NOT an assembly-learning scratchpad. My earlier
  interpretation was wrong; corrected.
- Rebuilt rawNote as a real Win32 GUI app in 100% x86-64 assembly (ML64).
- Scope decision (told Jonny): a full-featured product = multi-month; shipped a
  real v1 with note CRUD + search + word/char count, structured to grow.

### v1 structure
- `src/rawNote.asm` — entire app (entry point + all logic), single file.
- `src/rawNote.inc` — constants, Win32 types, imports.
- `build.ps1` — assemble + link -> `build\rawNote.exe`.
- `docs/architecture.md`, `docs/build.md`, `docs/roadmap.md`.
- Removed the old learning docs + example .asm files (inside rawNote only).

### v1 features
- GUI: sidebar note list + editor + search + status bar + File/Note menus.
- Notes as plain `.md` in a `vault\` folder next to the exe (auto-created).
- Create / open / save / rename / delete; live filename search; word+char count;
  open-vault-folder; Ctrl+N / Ctrl+S.

### ML64 constraints discovered (important, for all future asm work)
- ML64 (x64 MASM) does NOT support: `INVOKE`, `ADDR`, `.IF/.ELSE/.ENDIF`,
  `WORD "string"`/`DW "string"` string initializers, `WSTR`, or `END <entry>`.
- Workarounds: manual `call` + register args + shadow space; `lea` for addrs;
  `cmp`/`jcc` for branching; `DB "..."` (ANSI) strings; bare `END` + `PUBLIC
  start` + `/entry:start` on the linker.

### v1 DONE — builds clean
- `build\rawNote.exe` = 10240 bytes, valid PE (MZ/PE), imports kernel32/user32/
  gdi32/shell32/comctl32. `ml64` + `link` both exit 0.
- v1 is ANSI (narrow) API. Unicode = v2 (needs a wide-string macro or -W API
  with explicit char lists).

### NEXT UP:
- (Jonny to try it) Run `build\rawNote.exe` — verify the GUI opens, vault is
  created next to the exe, notes list/save/rename/delete work.
- Then v2: dirty-flag + save-on-close; Unicode (wide-string macro).

## 2026-08-20 — v1.1 bug hunt (Jonny's report)
Jonny tested: app opens + typing works, but (1) File/Note menu buttons not
clickable, (2) Ctrl+N/S don't work, (3) can't create/save. Two root causes:

1. **Menu**: top-level "File"/"Note" were appended with flags=0 (MF_STRING)
   instead of MF_POPUP, so they were leaf items, not popups. Fixed: added
   `MF_POPUP EQU 10h` and `mov edx, MF_POPUP` on the two top-level appends.
2. **Accelerators**: `SIZEOF ACCEL` = 5 in ML64 (it packs struct members tight,
   no auto-alignment) but Windows' ACCEL is 6 bytes (1-byte pad after fVirt).
   Fixed: added `pad_ BYTE ?` between fVirt and key. Verified SIZEOF ACCEL = 6.

Both fixed, rebuilt clean. v1.1. (Lesson: ML64 structs are PACKED, not aligned
— always verify SIZEOF against the Win32 header, esp. BYTE+WORD mixes.)

## 2026-08-20 — v1.1 continued (Ctrl+N/S STILL broken)
- After struct+initializer fixes, the accelerator table still didn't fire
  (TranslateAcceleratorA path, unobservable from here).
- **Decision: removed the accelerator-table path entirely.** Now Ctrl+N / Ctrl+S
  are handled DIRECTLY in the message loop: check `msg.message == WM_KEYDOWN` +
  `msg.wParam == 'N'`/`'S'` + `GetAsyncKeyState(VK_CONTROL)` high bit, then
  `call NewNote`/`call SaveCurrentNote` and skip dispatch. Deterministic, no
  dependence on CreateAcceleratorTable/TranslateAccelerator.
- Added: `WM_KEYDOWN`, `VK_CONTROL`, `EXTERN GetAsyncKeyState`.
- Rebuilt clean.

## 2026-08-20 — END OF SESSION wrap-up

### Working (verified by Jonny)
- Menu File/Note dropdowns, Ctrl+N/S, right-click context menu (New/Save/Rename/Delete),
  single-click open, rename prompt (topmost; no minimize/close).
- Context menu trimmed to New/Save/Rename/Delete only (separate gContextMenu popup).

### BUG (UNRESOLVED): deselect on empty-list-area click
Jonny: clicking the white space BELOW the note list should clear the selection.
NOT working. Implemented in `listSubclassProc` (listbox subclassed via
SetWindowLongPtrA(GWLP_WNDPROC)). On WM_LBUTTONDOWN: y=HIWORD(lParam),
totalH = LB_GETCOUNT * LB_GETITEMHEIGHT(0); if y >= totalH -> LB_SETCURSEL(-1),
then CallWindowProcA to old proc.

Attempts so far:
1. LB_ITEMFROMPOINT == -1  -> failed (returns NEAREST item, not -1).
2. y >= count*itemHeight    -> STILL not working.

Hypotheses to test tomorrow (in order):
- (a) Subclass not actually called. Verify: temp status-bar text / MessageBox inside
    listSubclassProc on WM_LBUTTONDOWN; check SetWindowLongPtrA return is non-zero.
- (b) Deselect undone by original proc after CallWindowProcA. Try forwarding the
    click FIRST then deselect AFTER; or swallow (don't forward) the empty click.
- (c) Re-entrancy: LB_SETCURSEL(-1) fires LBN_SELCHANGE -> OpenSelected (handles -1).
- (d) Scroll: if list scrolled, Y math is wrong (need LB_GETTOPINDEX).

## 2026-08-21 — RichEdit + markdown groundwork
- Swapped the editor from plain EDIT to RichEdit (RICHEDIT50W via Msftedit.dll)
  with UTF-8 <-> UTF-16 conversion for load/save.
- **CRASH root-caused:** re-entrant UpdateStatus (fired by EN_CHANGE during
  SetWindowTextW) clobbered shared gHeap/gBuf globals. Fixed by giving
  SetNoteText/UpdateStatus dedicated heap/buffer globals (gSnHeap/gUsHeap/gUsBuf).
- **WHITE TEXT root-caused:** RichEdit 4.1 rejects CHARFORMATW (90B) for
  EM_SETCHARFORMAT; it needs CHARFORMAT2W (116B). Added correct struct incl.
  alignment padding; cbSize=116. Text is now soft-white (#E6E6E6) on dark grey
  (#1E1E1E, via EM_SETBKGNDCOLOR).
- LESSON: ML64 structs are PACKED (no auto-alignment) — always verify SIZEOF
  against the Win32 header and insert manual pad bytes.

### NEXT UP:
- Markdown syntax scanner (bold/italic/headers/code/lists) -> apply
  EM_SETCHARFORMAT/EM_SETPARAFORMAT region by region.

## 2026-08-21 (late) — big feature run + wrap-up
- Added: scroll wheel (editor subclass -> WM_VSCROLL), headers (#..###### via
  CFM_SIZE), frameless window (WS_POPUP, no WS_THICKFRAME/WS_CAPTION), custom
  top bar (File/Note + min/restore/close owner-draw rounded grey buttons,
  DrawTextW glyphs), drag via WM_NCHITTEST->HTCAPTION.
- Backups taken before the frameless/button work: Stuffs\backups\rawNote_*.
- RESIZE REMOVED (WS_THICKFRAME dropped): Jonny OK'd it (fullscreen enough).
- KNOWN BUGS (deferred, in TODO):
  1. File-menu crash after clicking away (TrackPopupMenu teardown).
  2. File/Note dropdown anchored top-right instead of under the button
     (hardcoded TrackPopupMenu coords in wpc_btnfile/wpc_btnnote).
- BUILD: clean. EXE ~21.5KB. Defenders may false-positive on the unsigned ASM.

## 2026-08-21 — dark theme + scrollbars + INCIDENT
- Added dark theme (grey shades per surface), bigger Segoe UI font, STATIC status
  bar, grey scrollbars (multiple attempts), then removed scrollbars entirely at
  Jonny's request (arrow-key/caret auto-scroll via ES_AUTOVSCROLL/ES_AUTOHSCROLL).
- **INCIDENT (self-inflicted):** while removing the editor scrollbar subclass, a
  bad line-range PowerShell deletion corrupted rawNote.asm (ate top ~2/3).
  .inc was intact. Reconstructed the full .asm from scratch and rebuilt clean.
- LESSON: never do line-range array slicing ([0..s-1]+[e..]) on source files via
  exec; use the edit tool's exact-text replacement instead. Text > shell for edits.
