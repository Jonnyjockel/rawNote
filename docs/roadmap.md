# rawNote - roadmap

## v1 (shipped)
- [x] Native GUI: sidebar + editor + search + status bar + menu
- [x] Create / open / save / rename / delete notes (`.md` in vault folder)
- [x] Live filename search filter
- [x] Word + character count
- [x] Open vault folder, Ctrl+N / Ctrl+S accelerators

## v2 - polish & robustness
- [ ] Dirty indicator (asterisk) + save prompt on close with unsaved changes
- [ ] UTF-8 with BOM handling (interop with other editors)
- [ ] Empty-state hint text in the search box
- [ ] Remember last-opened note + window size/position (INI file)
- [ ] Open note on Enter (single click + keyboard), not just double-click

## v3 - Richer markdown features (the interesting work)
- [ ] RichEdit-based editor with **live markdown preview** (bold/italic/headers/code)
- [ ] `[[wiki-link]]` parsing + click-to-open (backlinks-lite)
- [ ] Full-content search (not just filename)
- [ ] Tags (#tag) extraction + sidebar grouping
- [ ] Note list sorted by modified time / title

## Long-term (hard, optional)
- [ ] Backlink graph view (canvas rendering)
- [ ] Multiple vaults / folder picker
- [ ] Plugin-ish script hooks
- [ ] Themes

## Non-goals / boundaries
- No cloud sync, no networking, no telemetry.
- Everything stays local to the vault folder.
