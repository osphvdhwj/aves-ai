# Aves ↔ AVESPlusTools — companion contract

Single source of truth for the wire between the Aves gallery and the
AI companion. Update whenever either side changes.

---

## Repos

| Repo | Language | Package | Role |
|---|---|---|---|
| **Aves** | Flutter + Kotlin | `deckers.thibault.aves` | Gallery; consumes AI |
| **AVESPlusTools** | Kotlin | `com.avesplus.tools` | AI companion; provides capabilities |
| **aves-ai-core** (legacy) | Kotlin | `io.github.osphvdhwj.aves.ai` | Earlier AIDL companion; kept as fallback, do not extend |

---

## Transport

```
Flutter (Aves)      →   Kotlin (Aves)   →   AIDL   →   Kotlin (Tools)
MethodChannel           AiHandler                bind   AiCompanionService
'deckers.thibault/aves/ai'                            (com.avesplus.tools)
```

Aves never talks to the Tools app directly. Everything goes through
`deckers.thibault/aves/ai` and Aves' `AiHandler.kt`, which binds to
the companion over AIDL.

`AiHandler.COMPANION_PACKAGES` is an ordered list; the first installed
wins:

1. `com.avesplus.tools`
2. `io.github.osphvdhwj.aves.ai.debug`
3. `io.github.osphvdhwj.aves.ai`

The service component is always
`<package>.io.github.osphvdhwj.aves.ai.AiCompanionService`.

---

## Flutter method surface

| Method | Args | Reply |
|---|---|---|
| `health` | – | see below |
| `chat` | `{ text, entryIds, entries }` | `{ text, entryIds, errorMessage, errorCode }` |
| `gphotosBackupStatus` | `{ mediaStoreIds: [int] }` | `{ statuses: { "<id>": "uploaded"\|"not_uploaded" }, error? }` |

### `health` reply keys Dart reads

```
installed        Bool
connected        Bool
apiVersion       Int?
capabilities     List<String>
error            String?
companionPackage String?     // which APK answered
```

### Capability strings and what they gate

| Capability | Enables |
|---|---|
| `ocr` | Extract-text dialog, long-press text-select page |
| `nsfw` | Auto-tag's NSFW classifier branch |
| `person`, `faces` | People row in header, People page |
| `objects` | Objects page |
| `gphotos_backup` | Backup row in Details (root only) |

Any capability the companion does not advertise → Aves hides or
disables the matching UI. No error surfaces.

---

## `chat` request — the `entries` payload

Every media-touching command needs a real path. `entryIds` are
Aves-internal DB row ids and are useless to the companion.

Each element of `entries`:

```
id         Int      Aves internal id (echo only; do not open media with it)
contentId  Int?     MediaStore _id (64-bit) — safe to query
uri        String   content:// URI
path       String?  filesystem path; may be null under scoped storage
mimeType   String
```

Use `path` first; fall back to `uri`. If both are null, reply
`onError(id, 2, "no media path")`.

---

## AIDL `submit` Bundle — keys Aves sends

```
capability     String   "chat" for most requests,
                        "gphotos_backup" for the backup query
requestId      Long
text           String   only for chat
entryIds       Int[]    only for chat
entries        Bundle[] only for chat, one Bundle per entry
mediaStoreIds  Long[]   only for gphotos_backup (64-bit MediaStore _id)
```

---

## AIDL `onResult` Bundle — keys Aves reads

### `capability = "chat"`
```
text      String?   reply text; per-command shape below
entryIds  Int[]?    ids to display as results
```

### `capability = "gphotos_backup"`
```
statuses  Bundle    String id -> String state
                    state is "uploaded" or "not_uploaded"
```

---

## AIDL `onError`

```
code     Int
message  String
```

Frozen error codes:

| Code | Name | Aves behaviour |
|---|---|---|
| 0 | OK | unused (success goes through onResult) |
| 1 | UNSUPPORTED | "Update AVES+ Tools" |
| 2 | MODEL_MISSING | "Companion needs a model it does not have" |
| 3 | OOM | raw message |
| 4 | PERMISSION | raw message |
| 5 | INTERNAL | raw message |
| 6 | CANCELLED | silent |

Do not renumber. Aves' Dart side maps 1 and 2 to strings.

---

## Command tokens (`chat` `text` prefix)

| Token | Meaning | Reply |
|---|---|---|
| `/find <query>` | semantic search | `entryIds` ranked |
| `/dup` | duplicate groups | `entryIds` grouped |
| `/blur` | blurry detection | `entryIds` |
| `/receipt` | receipt / document finder | `entryIds` |
| `/clean` | large / old / junk | `entryIds` |
| `/objects <query>` | object-category search | `entryIds` |
| `/faces` | face clusters | `entryIds` |
| `/translate <text>` | translate text | `text` |
| `@ocr` | OCR on `entries[0]` | `text` = recognised |
| `@ocr.structured` | OCR with positions | `text` = rows `L,T,W,H<TAB>text` |
| `@nsfw` | NSFW score for `entries[0]` | `text` = `nsfw:0.87` or `nsfw:0.87:label1,label2` |

### `@ocr.structured` row format

One row per detected text block. Four floats separated by commas, a
tab, then the text. Coordinates normalized to `[0, 1]`:

```
0.10,0.20,0.30,0.05<TAB>Hello world
0.10,0.30,0.40,0.06<TAB>Second line
```

Parsed by `lib/widgets/viewer/info/translation_overlay.dart ::
parseOcrBlocks`. Malformed rows are skipped.

### `@nsfw` score format

Either `nsfw:<score>` or `nsfw:<score>:<labels>` with labels comma
separated. Score in `[0, 1]`. Aves clamps and applies a 0.75
threshold before suggesting a tag. Empty reply = unknown.

---

## File map (Aves side)

| Concern | File |
|---|---|
| Flutter channel to Kotlin | `lib/services/ai_service.dart` |
| Kotlin bridge to AIDL | `android/.../channel/calls/AiHandler.kt` |
| GPhotos backup caller | `lib/services/gphotos_backup_service.dart` |
| OCR dialog | `lib/widgets/viewer/info/extract_text_dialog.dart` |
| OCR select-mode page | `lib/widgets/viewer/info/text_select_page.dart` |
| In-place translation | `lib/widgets/viewer/info/translation_overlay.dart` |
| Auto-tag engine (local rules) | `lib/model/auto_tagger.dart` |
| Auto-tag review page | `lib/widgets/viewer/info/auto_tag_page.dart` |
| NSFW classifier wrapper | `lib/services/nsfw_service.dart` |
| AI tools hub | `lib/widgets/viewer/info/ai_tools_page.dart` |
| NSFW vocabulary asset | `assets/nsfw_tags.txt` |

---

## Rules (frozen)

1. Do not change the AIDL interfaces.
2. Do not renumber error codes.
3. Do not change the `capability` or `requestId` Bundle keys.
4. Never throw out of `submit()`. All errors go through `onError`.
5. Media is passed as a path. Never bytes over AIDL.
6. Any new capability must be added to this file and to Aves in the
   same change cycle.

---

## Adding a capability — checklist

1. Add its string to the companion's `getCapabilities()`.
2. Add its command token to the token table above.
3. Add its request and reply shape under the AIDL section.
4. On Aves:
   - extend `AiCommands.all` in `lib/model/ai/ai_command.dart` so
     the palette and quick actions pick it up automatically;
   - if the capability gates UI, extend the `AiHealth.has()` checks
     in `header_section.dart`, `ai_tools_page.dart`,
     `auto_tag_page.dart`.
5. Add a row to the File map if a new file appears.