# Aves + — Master Plan

Consolidated record of every decision. Single source of truth.

---

## 1. Project structure

| Repo | Role | Branch | Status |
|---|---|---|---|
| `osphvdhwj/aves-ai` | Fork of deckerst/aves, becomes "Aves +" | develop | active |
| `osphvdhwj/aves-ai-core` | AI companion backend, AIDL service | main | active |
| `deckerst/aves` | upstream, read-only | develop | tracked |

Companion runs inference. Aves runs UI. Connected via AIDL bound service.
No cloud. No PRs upstream. BSD-3 retained.

---

## 2. Design language — M3E, no Aves identity

**Decision:** full Material 3 Expressive. Break from Aves's chip-heavy visual identity.

**Reality check:** Flutter has no official M3E. Community packages fill the gap.

**Package stack (mixed):**
- `m3e_design` — M3E tokens (color, type, shape, spacing, motion) as ThemeExtension
- `expressive_m3` — spring physics, expressive shapes, wavy progress, PressableScale
- `material_3_expressive` — cherry-picked widgets where the others fall short
- `m3e_buttons`, `m3e_expandable` — component-level additions as needed

**Constraint:** some Compose-only M3E APIs cannot be replicated (MaterialExpressiveTheme,
MotionScheme internals, MaterialShapes). We get as close as Flutter allows.

**Goal:** look and feel like PixelPlayer / ReFra. Not possible pixel-for-pixel.
Achievable: spring motion, squish-on-press, shape morph, morphing loaders,
emphasized typography, expressive nav, wavy indicators.

**Rules going forward:**
- every new UI component is M3E by default
- every existing component is replaced during Phase migration
- no legacy Aves chip / color / typography survives untouched

---

## 3. M3E migration phases

### Phase 1 — Foundation (no visible change)
- [ ] add packages to pubspec
- [ ] wire M3ETheme as ThemeExtension into existing ThemeData
- [ ] map Aves ColorScheme through M3E tokens
- [ ] verify no visual regression

### Phase 2 — Motion
- [ ] PressableScale on all tap targets (chips, tiles, buttons, FAB)
- [ ] ExpressiveSpringScheme for existing animations
- [ ] replace CircularProgressIndicator with ExpressiveLoadingIndicator
- [ ] page transitions — shared-axis X, spring-settled paging

### Phase 3 — Core components
- [ ] NavigationBar → expressive variant with liquid indicator
- [ ] NavigationRail → expressive
- [ ] TabBar → M3E tabs
- [ ] EmphasizedTextTheme for headers
- [ ] expressive progress bars where progress exists

### Phase 4 — New surfaces
- [ ] ButtonGroup / SplitButton where multi-action buttons exist
- [ ] FABMenu where FAB currently opens sheet
- [ ] floating / docked Toolbar
- [ ] evaluate every screen individually — no mass replacement

Phase 1 is one commit. Phases 2–4 are one commit per screen or component family.

---

## 4. App rename & rebranding

- [ ] applicationId → `com.harry.avesplus`
- [ ] app label → "Aves +"
- [ ] new launcher icon (adaptive + legacy PNGs) — source TBD
- [ ] remove terms & conditions flow
- [ ] remove all data collection, analytics, crashlytics
- [ ] remove `aves_report_crashlytics` module reference
- [ ] remove `isErrorReportingAllowed` setting + UI
- [ ] About page: strip deckerst links, GitHub, funding, Play Store, changelog
- [ ] About shows only: Aves + name, version, BSD-3 license, nothing external
- [ ] audit `deckers.thibault.aves` string references in Dart

### Package strategy (pending final answer)
Recommended: applicationId + label change only. Keep Kotlin package
`deckers.thibault.aves` internally. Zero build risk.
Alternative: full source tree move to `com.harry.avesplus`. ~120 Kotlin files.
Touching package declarations and imports. Either works completely or fails completely.

---

## 5. AI companion architecture

**Transport:** bound Android Service via AIDL.
- action: `io.github.osphvdhwj.aves.ai.BIND`
- permission: `io.github.osphvdhwj.aves.ai.permission.BIND_AI_COMPANION`
- debug uses `normal`, release upgrades to `signature`

**Interface version 1** — frozen long-term. Capabilities added via new strings, not v2.

**Capabilities today:** `echo`, `chat`
**Planned:** `find`, `face_detect`, `face_embed`, `object_detect`, `clip`, `ocr`, `translate`

**Hard rules:**
- Aves never runs inference, never ships models, never downloads models
- Companion never reads user media; Aves grants temporary URI access per job
- Companion is optional; feature hides itself when absent
- No cloud ever

**Model unload:** after 60s idle, companion drops all loaded models.

---

## 6. AI search UX

**Surface:** replaces search page body when `aiSearchEnabled` setting is on.
Old search delegate preserved in repo but inactive.

**Toggle:** Debug settings → `aiSearchEnabled` (default off)

**Layout:**
- top: face circles row (placeholder — Icons.person until real clustering exists)
- below: "Try asking" prompt cards
- bottom: input row `[@] [field] [/] [+] [send]`
- typing `/` or `@` opens a scrollable picker above the input row

**Commands (`/`)**
- `/find` — semantic search
- `/dup` — duplicate finder
- `/blur` — blurry photos
- `/receipt` — receipts

**Modes (`@`)**
- `@deep` — force deep rerank
- `@fast` — CLIP only, no rerank
- `@ocr` — search text only
- `@person` — filter by face cluster
- `@like` — similar to current photo

**Prompt sources:**
- "My best pictures" — special card, uses "me" face
- 120 static prompts in `prompt_library.dart`, 6 randomized per open
- dynamic prompts from library data — top albums, top tags, recent dates, favourites

**"Me" onboarding:** inline card with 3-4 top faces + more button. No detour to a
separate People page.

**History:** all AI queries (commands + free text), tap to rerun, cap 50, separate
from Aves's existing search history.

**Result rendering:** inline thumbnail grid inside AI surface. Tapping opens viewer.
Does not touch Aves's normal filter state.

---

## 7. Face pipeline (planned)

- detect: ML Kit or YuNet 100KB
- embed: ArcFace MobileFaceNet 131MB
- cluster: DBSCAN cosine in companion
- People grid in Aves — grid of face circles
- Person → Files view
- swipe for more faces (no Google Photos limit)
- `@person` and `/find` integration

Blocker: models and runtime must exist in companion first.

---

## 8. Other AI features (planned)

- duplicate finder — dHash, hamming ≤ 6
- cleaner — blurry, screenshots, tiny files, huge videos (confirm-only)
- OCR — ML Kit Text Recognition v2, bounding-box overlay, long-press 3s
- metadata strip on share — drop GPS + camera/device serials
- translator — ML Kit Translate per language
- auto-tag — write XMP-dc:Subject only, flat strings, no hierarchy
- object detect — YOLOv8n, object grid UI
- segmentation — MobileSAM, hold 3s to extract crop
- Google Photos Picker API — read-only, opt-in, deferred

---

## 9. Info page redesign

- [x] thumbnail strip at bottom (reuses ViewerThumbnailPreview)
- [x] setting: `showInfoThumbnail`, gated behind `showOverlayThumbnailPreview`
- [ ] Google Photos-style restructure:
  - [ ] date as large header
  - [ ] editable caption field
  - [ ] People section (placeholder until faces exist)
  - [ ] Albums section (which albums contain this entry)
  - [ ] Details section — filename, resolution, size, backup status
  - [ ] Location section with "Add a location"
  - [ ] keep Exif / color sections below, collapsed
- [ ] edit metadata for all media types + all extensions

---

## 10. Album page refinement

- [ ] layout matching Google Photos Collections tab
- [ ] 2-column section grid (People, Wardrobe, Documents, Moments style)
- [ ] bottom nav: Photos / Collections / Create
- [ ] maintain M3E visual language, not literal copy

---

## 11. Back navigation

**Fixed:** push instead of pushAndRemoveUntil in drawer, search, snackbar actions,
viewer-to-collection, filter grid-to-collection, map-to-collection, stats-to-collection.

**Kept** (intentional resets): force TV layout toggle, app startup redirect,
TV back-to-home, TV rail, slideshow "show in collection".

**Flagged:** slideshow_page.dart:145 — user decision pending.

**Behavior now:** back returns to previous page in the stack. App exits only when the
stack is truly empty.

---

## 12. Repo state

### aves-ai — local commits ahead of origin/develop
- feat(ai): ai search shell behind aiSearchEnabled toggle
- feat(ai): prompt library + empty state cards
- feat(ai): dynamic prompts from library data
- feat(ai): bottom input row + / and @ command palettes
- chore(ai): use Icons.add, drop unused AIcons import
- fix(nav): push instead of replace, back returns to previous page
- fix(nav+info): correct push replacement, fix settings tile title types
- feat(info): thumbnail preview at top + setting toggle (reverted in next)
- Revert "fix(nav): stop wiping stack on snackbar/viewer/grid navigation"
- feat(ai): faces placeholder row in search empty state
- feat(info): thumbnail preview at top + setting toggle
- docs: info page redesign + M3 direction in backlog
- fix(info): bottom thumbnail strip, gate on overlay thumbnails setting
- chore(info): dedupe thumbnail_preview import
- feat(ui): migrate bottom nav to Material 3 NavigationBar

### aves-ai-core — local commits ahead of origin/main
- feat(core): chat capability with rule-based replies

Nothing pushed. Nothing tested on device since the last green CI.

---

## 13. What's committed, what's pending

### Done
- fork + CI for both repos
- AIDL pipe, health check, chat capability
- chat playground in companion
- AI search shell with toggle
- prompt library (120 static) + dynamic prompt generation
- bottom input row + / @ palettes with filter-as-you-type
- faces placeholder row
- info page bottom thumbnail strip
- back-navigation fix across 11 sites
- M3 bottom nav migration

### Pending (in rough order)
1. push current stack, test on device, fix what breaks
2. Phase 1 M3E foundation (tokens + ThemeExtension)
3. app rename + rebranding
4. Info page Google Photos-style restructure
5. real CLIP in companion (`find` capability)
6. inline result grid in AI search
7. AI history
8. "me" face onboarding
9. face pipeline in companion
10. People grid in Aves
11. album page refinement
12. metadata editing coverage
13. OCR, dup, cleaner, metadata strip, translator
14. Google Photos Picker (deferred)

---

## 14. Open decisions

1. Push current stack now, or continue local? (recommend: push)
2. Slideshow `pushAndRemoveUntil` — keep or fix?
3. Launcher icon — user-supplied or generated placeholder?
4. Rename Kotlin package — applicationId only, or full source tree move?
5. About page — keep page with only Aves + info, or remove entirely?
