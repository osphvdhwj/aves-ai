# Aves AI — Feature Backlog

Status legend: [ ] todo · [~] in progress · [x] done · [!] blocked

## AI search (in progress)
- [x] aiSearchEnabled toggle (off by default)
- [x] Prompt library (120 static entries)
- [x] Dynamic prompts from library (albums, tags, dates, favourites)
- [x] Bottom input row (@ text / + send)
- [x] / and @ command palettes with filter-as-you-type
- [ ] History (all AI queries, tap-to-rerun)
- [ ] "Me" face onboarding card with 3-4 top faces + more button
- [ ] Inline result grid (thumbnails inside AI surface)
- [ ] Real CLIP scoring in companion
- [ ] Learning: AI adapts behaviour over time from user picks

## Back navigation
- [x] push instead of pushAndRemoveUntil in drawer + search + snackbars + viewer
- [~] slideshow_page.dart:145 — undecided (Show in collection)
- [ ] Audit remaining flows after device testing

## Info page
- [x] Show thumbnail preview at top
- [x] Setting toggle for thumbnail on/off
- [ ] Google Photos-style redesign:
  - [ ] Date as large header
  - [ ] Editable caption field
  - [ ] People section (placeholder until faces exist)
  - [ ] Albums section (which albums contain this entry)
  - [ ] Details section (filename, resolution, size, backup status)
  - [ ] Location section ("Add a location")
  - [ ] Keep Exif / color sections below, collapsed
- [ ] Edit metadata for all media types + all extensions

## Design language
- Confirm: Material 3 + Material Symbols (Pixel icon set) everywhere
- Any new UI must match existing chips, tiles, spacing, typography

## Album page refinement
- [ ] Layout matching Google Photos Collections tab
- [ ] Section grid (People, Wardrobe, Documents, Moments style)
- [ ] Bottom nav: Photos / Collections / Create

## Faces
- [ ] Face detect (ML Kit or YuNet) in companion
- [ ] Face embed (ArcFace) in companion
- [ ] Cluster (DBSCAN cosine) in companion
- [ ] Aves: People grid
- [ ] Swipe for more faces (no G Photos limit)
- [ ] Person → Files view

## Google Photos
- [ ] OAuth flow (Google Photos Picker API, read-only)
- [ ] Pick media from Google Photos
- [ ] Download / cache picked media
- [ ] Sync toggle in settings
- [ ] Never auto-upload

## Cleaner / utilities
- [ ] Duplicate finder (dHash)
- [ ] Blurry detector
- [ ] Screenshots finder
- [ ] Tiny files / huge videos
- [ ] Strip metadata on share

## OCR / Text
- [ ] ML Kit Text Recognition v2
- [ ] Extract text with bounding-box overlay
- [ ] Long-press 3s → select mode
- [ ] @ocr query

## Translation
- [ ] ML Kit Translate (per-language download)

## Companion core
- [x] AIDL service + client
- [x] health check + capabilities
- [x] echo + chat capabilities
- [ ] ONNX Runtime integration
- [ ] Model download / sha256 / management
- [ ] Model unload after 60s idle
- [ ] WorkManager background jobs
- [ ] Settings: model manager UI

## Out of scope / deferred
- User-authored scripts
- Objects grid (after People)
- Real conversational LLM (after CLIP)
- Multi-device sync
