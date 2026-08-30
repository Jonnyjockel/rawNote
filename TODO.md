# rawNote — TODO

The app itself is the project now. Track remaining work here.

## KNOWN BUGS (fixed 2026-08-22)
- [x] **File menu crashes after clicking elsewhere** → stack overflow: TrackPopupMenu
      takes 7 args (writes [rsp+48]) but wp_command only reserved 40 bytes.
      Bumped to sub rsp,72.
- [x] **File dropdown position wrong** → TrackPopupMenu needs SCREEN coords; was
      passing hardcoded client coords. Now GetWindowRect(button) + TPM_LEFTBUTTON
      anchored below the button.

## Session 2026-08-20/21 — everything done today (v1.1.x)
- [x] **Menu not clickable** → missing `MF_POPUP` on File/Note top-level appends.
- [x] **Ctrl+N / Ctrl+S dead** → ACCEL struct was 5 bytes (ML64 packs tight);
      added pad byte. Still didn't fire via TranslateAcceleratorA, so **removed
      the accelerator table entirely** — Ctrl+N/S now handled directly in the
      message loop (WM_KEYDOWN + wParam + GetAsyncKeyState(VK_CONTROL)).
- [x] **Rename prompt minimized/closed the main window** → caused by the
      EnableWindow(disable/re-enable) dance triggering the owner-window
      activate/minimize behavior. **Removed all enable/disable**; prompt is now
      a topmost owned window; only the prompt is destroyed (OK saves, Cancel
      discards, X closes).
- [x] **Single-click opens a note** (was double-click) → switched `LBN_DBLCLK`
      to `LBN_SELCHANGE`.
- [x] **Right-click context menu** → `WM_CONTEXTMENU` + `TrackPopupMenu`, shows
      the file actions at the cursor.
- [x] **Context menu trimmed** to New / Save / Rename / Delete only (separate
      `gContextMenu` popup; menu-bar File menu unchanged).

## Bugs (in progress)
- [x] **Deselect note on empty-list click** → ABANDONED (2026-08-22). Tried
      LB_ITEMFROMPOINT, manual count*height, and LB_SETCURSEL(-1); none cleared
      the selection reliably. Low value; dropping it. (Subclass fires — Enter-to-
      open in the same proc works.)

## v1 (done)
- [x] Full Win32 GUI in assembly: sidebar + editor + search + status bar + menu
- [x] Note CRUD (create/open/save/rename/delete) as `.md` files in a vault folder
- [x] Live filename search filter
- [x] Word/char count, open-vault-folder, Ctrl+N/Ctrl+S

## v2
- [x] Dirty flag + confirm-on-close when unsaved (Yes/No/Cancel)
- [x] Enter-to-open in the list (VK_RETURN in list subclass)
- [x] Persist window size/position + last-opened note (vault\rawNote.ini)
- [ ] Unicode support (currently ANSI): wide-string macro or -W API layer
- [ ] UTF-8/BOM interop with other editors

## v3
- [x] Full-content search (not just filename) — falls back to FileContains for
      non-filename matches
- [ ] `[[wiki-link]]` click-to-open — SHELVED (not completable now). Attempted
      2026-08-22, caused a keystroke crash; reverted. Park for a future session
      with a fresh root-cause pass (suspect stack alignment in the click helper
      + scan interaction).
- [ ] RichEdit + live markdown preview
- [ ] Tag extraction + grouping
- [ ] Backlink graph view
