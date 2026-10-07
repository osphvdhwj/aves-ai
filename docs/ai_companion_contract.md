# AI Companion Contract

Aves delegates every ML/AI task to a separate companion app. The
companion is shared with the author's other apps, so the contract below
is deliberately generic and versioned.

## Channel

- Method channel: `deckers.thibault/aves/ai`
- All requests and responses are `Map<String, dynamic>`.

## Methods

### health

Returned once per app start (and on demand). Used to gate UI.

- `installed`: bool
- `connected`: bool
- `apiVersion`: int
- `capabilities`: [ "ocr", "nsfw", "person", "objects", "translate", ... ]
- `error`: String? (present when installed/connected is false)

### chat

Free-form request. The `text` field starts with a command token; the
companion dispatches on that token. `entryIds` carries the caller's
current selection so the companion can scope the request.

- request:  { text: "/find dogs", entryIds: [1, 2, 3] }
- response: { text: "...", entryIds: [4, 5], errorMessage: String? }

## Command tokens

| Token        | Meaning                         | Reply shape |
|--------------|---------------------------------|-------------|
| /find        | Semantic search                 | entryIds[] |
| /dup         | Duplicate groups                | entryIds[] (grouped) |
| /blur        | Blurry photos                   | entryIds[] |
| /receipt     | Receipts / documents            | entryIds[] |
| /clean       | Large / old / junk candidates   | entryIds[] |
| /translate   | Translate text in photos        | text |
| /objects     | Object-category search          | entryIds[] |
| /faces       | Face-cluster browse             | entryIds[] |
| @deep        | Force deep rerank               | modifier |
| @fast        | Skip rerank                     | modifier |
| @ocr         | Text-only search / OCR result   | text (extracted text) |
| @nsfw        | NSFW score for a single entry   | text, see below |
| @person      | Filter by a face cluster        | entryIds[] |
| @like        | Similar to current photo        | entryIds[] |

## @nsfw reply format

The reply text must be one of:

- `nsfw:<score>`                     e.g. nsfw:0.87
- `nsfw:<score>:<label>,<label>`     e.g. nsfw:0.87:nudity,suggestive
- plain number                       e.g. 0.87

`score` is a float in [0, 1]. Aves clamps to [0, 1] and applies its own
threshold (default 0.75) before proposing an NSFW tag. When the score
cannot be produced, return an empty reply; Aves treats it as unknown.

Capability gating: Aves checks health.capabilities contains "nsfw"
before calling @nsfw. Do not advertise "nsfw" unless scoring will
succeed.

## @ocr reply format

Plain text of recognised characters, one line per detected block. Text
is displayed in a selectable pane and can be searched with /find.

TODO for the companion: per-block bounding boxes (normalized rect in
[0, 1] x [0, 1]) so Aves can render translated text in place over the
source, per the TranslationOverlayDialog layout.

## Notes for other consumers

- The channel name is Aves-specific, but the request/response shapes are
  generic. Other apps can talk to the companion by matching the same
  shape on their own channel name; the companion decides which callers
  it answers.
- apiVersion is bumped on breaking changes. Callers must tolerate
  unknown fields and unknown capability strings.
- entryIds are Aves-internal content ids. If the companion caches per
  entry results, key by contentId from entry.toPlatformEntryMap() rather
  than by id, which is stable only within an install.
