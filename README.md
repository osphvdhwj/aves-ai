<div align="center">

<img src="https://raw.githubusercontent.com/osphvdhwj/aves-ai/develop/aves_logo.svg" alt="Aves + logo" width="200" />

## Aves +

![Version badge][Version badge]
![Build badge][Build badge]

Aves + is a gallery and metadata explorer app. It is built for Android, with Flutter. It is a fork of [Aves](https://github.com/deckerst/aves) with a Material 3 Expressive redesign of the info page and an on-device AI companion integration.

[<img src="https://raw.githubusercontent.com/deckerst/common/main/assets/get-it-on-github.png"
      alt='Get it on GitHub'
      height="80">](https://github.com/osphvdhwj/aves-ai/releases/latest)

<div align="left">

## Features

Aves + can handle all sorts of images and videos, including your typical JPEGs and MP4s, but also more exotic things like **multi-page TIFFs, SVGs, old AVIs and more**!

It scans your media collection to identify **motion photos**, **panoramas** (aka photo spheres), **360° videos**, as well as **GeoTIFF** files.

**Navigation and search** is an important part of Aves +. The goal is for users to easily flow from albums to photos to tags to maps, etc.

Aves + integrates with Android (including Android TV) with features such as **widgets**, **app shortcuts**, **screen saver** and **global search** handling. It also works as a **media viewer and picker**.

## New in Aves +

### Material 3 Expressive info page
- Google Photos-inspired layout: two-line date header, caption, People, Albums, Details, chip clusters (Media / When / Where / Why), grouped Exif tiles, color palette with tap-to-copy hex
- Spring physics throughout; critically-damped by default so it settles quickly without overshoot
- Section entrance animation uses M3E `SpringAnimatedValue`
- All icons use `material_symbols_icons`

### AI companion integration
Aves + talks to a separate on-device companion app, [AVESPlusTools](https://github.com/osphvdhwj/aves-ai), over an AIDL bridge. When installed, the following become available:

- **Extract text** — OCR on any image, with a long-press select-text page
- **Find similar** — visual similarity to the current photo
- **NSFW tag picker** — bundled vocabulary
- **Auto-tag review** — metadata + companion-proposed tags, with collection mode
- **Cleaner** — large files, screenshots, blurry (Laplacian variance), dark (mean luma), duplicates (FNV-1a + keep-best), old
- **Memories** — auto-curated local collections
- **Query composer** — chip-based filter builder

When the companion is not installed, everything above degrades gracefully: tiles are dimmed, status banners explain the dependency, and the rest of the app works unchanged.

## Permissions

Aves + requests the standard media and permission set used by Aves. The AI companion, when installed, may additionally request root access to read Google Photos' local database (for the backup-status row in the info page). That path is opt-in.

## Contributing

### Issues

Please report bugs and feature requests at [github.com/osphvdhwj/aves-ai/issues](https://github.com/osphvdhwj/aves-ai/issues).

### Code

The repository is at [github.com/osphvdhwj/aves-ai](https://github.com/osphvdhwj/aves-ai). Fork, branch, and open a pull request.

## Certificate Fingerprint

Aves + is signed with a fork-local debug key during development. Release builds use a separately managed release key; do not assume the upstream Aves certificate applies.

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## Credits

Aves + is a fork of [deckerst/aves](https://github.com/deckerst/aves) by Thibault Deckers, used under the MIT license. All original design, code, and metadata extraction work belongs to the upstream project. This fork adds the Material 3 Expressive redesign and the AI companion bridge described above.

[Version badge]: https://img.shields.io/github/v/release/osphvdhwj/aves-ai?include_prereleases&sort=semver
[Build badge]: https://img.shields.io/github/actions/workflow/status/osphvdhwj/aves-ai/build.yml?branch=develop
