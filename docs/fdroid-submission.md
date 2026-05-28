# F-Droid submission package (draft)

This document is the **submission package** for proposing Linthra to F-Droid: a
ready-to-adapt merge-request description for
[fdroiddata](https://gitlab.com/fdroid/fdroiddata), the build-recipe and
version decisions, the verification status, the remaining blockers, and the
exact next steps. It is a planning/preparation aid.

> **Linthra is NOT on F-Droid and NO submission/merge request has been made.**
> Nothing here publishes, signs, or submits anything. This is the material to
> review before a human opens a merge request to fdroiddata. Do not present
> Linthra as accepted on, or available from, F-Droid.

See also: [fdroid-readiness.md](./fdroid-readiness.md) (overall checklist),
[fdroid-build-recipe.md](./fdroid-build-recipe.md) (recipe/reproducibility),
[dependency-license-audit.md](./dependency-license-audit.md) (licensing),
[listing-assets.md](./listing-assets.md) (icon/graphic/screenshots),
[release-process.md](./release-process.md) (versioning & tagging), and the draft
recipe at [`metadata/io.github.thezupzup.linthra.yml`](../metadata/io.github.thezupzup.linthra.yml).

## 1. App identity

| Field   | Value                         |
| ------- | ----------------------------- |
| Name    | Linthra                       |
| App ID  | `io.github.thezupzup.linthra` |
| License | `MPL-2.0` (SPDX)              |
| Source  | https://github.com/thezupzup/linthra |
| Issues  | https://github.com/thezupzup/linthra/issues |
| Category| Multimedia                    |

## 2. Target version — the latest WORKING alpha

F-Droid builds from a git tag, and Linthra now has tagged releases
(`v0.1.0-alpha.1` … `v0.1.0-alpha.25`), each built by the Android Release Build
workflow. The submission targets the **latest working** alpha:

| Item            | Value                                   |
| --------------- | --------------------------------------- |
| **Target tag**  | `v0.1.0-alpha.25` (commit `c9c1fb3`)     |
| versionName     | `0.1.0-alpha.25`                        |
| versionCode     | `100025`                                |
| Changelog file  | `fastlane/metadata/android/en-US/changelogs/100025.txt` |

> **Do NOT target `v0.1.0-alpha.24`.** Its GitHub Release is explicitly marked
> **"Broken release — do not install … startup regression."** `v0.1.0-alpha.25`
> is the hotfix that reverts that regression; it is the correct, launchable
> target. The metadata `commit:` and `CurrentVersion`/`CurrentVersionCode` point
> at alpha.25, never alpha.24.

### Why versionCode `100025` (and not `15`)

`pubspec.yaml` carries a **static** dev version, `0.1.0-alpha.15+15`, that is the
same at every tagged commit (it does not track tags — the release workflow
overrides it). Consequences:

- A plain `flutter build apk` at *any* tag produces versionName `0.1.0-alpha.15`
  / versionCode **15**. F-Droid could not tell releases apart (every build would
  be versionCode 15) — this is a hard blocker, not a cosmetic one.
- The upstream **GitHub release** build derives the version from the tag via
  `tool/version_from_tag.dart` (the single source of truth), giving
  `v0.1.0-alpha.25` → `0.1.0-alpha.25` / **100025**.

**Decision:** the F-Droid recipe derives the version from the checked-out tag the
same way (passing `--build-name`/`--build-number`), so the produced APK reports
`0.1.0-alpha.25` / `100025` — matching the metadata and the GitHub channel. This:

- gives each tag a distinct, strictly-monotonic versionCode (F-Droid can order
  releases and offer updates);
- keeps the F-Droid and GitHub versionCodes **identical** for the same tag (no
  cross-channel inversion); and
- stays correct under `AutoUpdateMode` for future tags (the build derives, rather
  than hard-codes, the version).

The changelog file is therefore named by the **derived** code (`100025.txt`),
consistent with [release-process.md §1](./release-process.md#1-versioning-model)
(the historical `1.txt`/`9.txt`/`15.txt` stay as-is).

> **Alternative considered:** bump `pubspec.yaml`'s `version:` to the tag value
> at each tagged commit, so a plain `flutter build` yields the right code and the
> recipe needs no flags. That is cleaner long-term but changes the release
> process (out of scope here), so the recipe-derives-from-tag approach is used
> for the first submission.

## 3. Build recipe status

The draft recipe is in
[`metadata/io.github.thezupzup.linthra.yml`](../metadata/io.github.thezupzup.linthra.yml).
Key properties (mapped to F-Droid's expectations):

- **Builds from source**, no signing keys required — F-Droid signs its own
  builds; Linthra's release signing is optional and injected only on the GitHub
  channel (see [release-signing.md](./release-signing.md)). No keystore/secret is
  committed.
- **Pinned toolchain:** Flutter `3.27.4` (stable), Dart `3.6.x`, JDK 17,
  Gradle 8.3 — identical to `.flutter-version` and all CI workflows.
- **No codegen prebuild:** the Drift output
  `lib/data/database/linthra_database.g.dart` is committed, so no `build_runner`
  step is needed.
- **One native component:** SQLite via `sqlite3_flutter_libs`, compiled from
  source (public domain). No prebuilt closed blobs; no Google Play Services /
  Firebase anywhere in the resolved tree (152 packages audited).
- **No GitHub Actions secrets / Play signing** are involved in the from-source
  build.

**To validate at submission time (draft caveats):**

1. **Flutter provisioning mechanism.** The draft provisions Flutter 3.27.4 via a
   `sudo:` git-clone of `flutter/flutter` at the `3.27.4` tag. fdroiddata may
   prefer its `flutter` **srclib** (`srclibs: [flutter@3.27.4]`, referenced as
   `$$flutter$$`). Match whichever convention current fdroiddata Flutter recipes
   use. Flutter's pinned engine artifacts are fetched at the pinned version —
   standard for Flutter-on-F-Droid, and pinned/reproducible (not an uncontrolled
   blob download).
2. **`git describe` at the tag.** The build derives the version with
   `git describe --tags --exact-match HEAD`; confirm F-Droid's checkout of
   `commit: v0.1.0-alpha.25` leaves the tag resolvable (it should — F-Droid
   checks out the tag ref).
3. **Output path / ABI splitting.** `build/app/outputs/flutter-apk/app-release.apk`
   is the single-APK output; if per-ABI splitting is preferred, adjust `output:`
   accordingly.
4. **`pubspec.lock` policy.** Still git-ignored; decide whether to commit it at
   the tagged commit for a fully pinned dependency set
   ([fdroid-build-recipe.md §4](./fdroid-build-recipe.md#4-reproducibility-notes)).
5. **Gradle wrapper jar** is not committed; F-Droid restores it, but confirm the
   recipe handles it (a `flutter build` provisions the wrapper).

## 4. Anti-feature assessment

Full reasoning in [fdroid-readiness.md §5](./fdroid-readiness.md#5-anti-features-review)
and [dependency-license-audit.md §6](./dependency-license-audit.md#6-anti-features--non-free-check).
Conclusion: **no anti-features to declare.**

| Anti-feature  | Apply? | One-line reason |
| ------------- | ------ | --------------- |
| Ads           | No  | No ad libraries/code anywhere. |
| Tracking      | No  | No telemetry/analytics/crash SDK; on-device signals only; nothing auto-sent. |
| NonFreeAdd    | No  | Promotes/installs no non-free add-ons. |
| NonFreeDep    | No  | All 152 resolved packages permissive; playback is AndroidX Media3 (Apache-2.0); Cast is pure-Dart (no GMS Cast SDK). |
| NonFreeNet    | No  | Local-first core needs no network; Jellyfin/Navidrome/Subsonic are optional, user-supplied, free-software servers — none bundled/promoted/required. |
| UpstreamNonFree | No | Repo is entirely MPL-2.0; icons generated from a committed SVG. |
| KnownVuln     | No  | No known-vulnerable version in the resolved tree at audit time; F-Droid's scanner re-checks. |
| NoSourceSince | No  | Source fully published; builds from source. |

> **Re-review trigger:** any *future* online provider that defaults to or
> promotes a non-free hosted service would need a fresh `NonFreeNet` assessment.

## 5. Permissions summary

Six permissions are declared explicitly in `AndroidManifest.xml`;
`ACCESS_NETWORK_STATE` is merged in from the AndroidX Media3 AAR. The set is
deliberately minimal — **no storage, location, contacts, camera, microphone, or
phone permission, and no `MANAGE_EXTERNAL_STORAGE`** (folder access uses the
Storage Access Framework). Each is justified in
[fdroid-readiness.md §5 (Android permissions)](./fdroid-readiness.md#android-permissions):
`INTERNET`, `ACCESS_NETWORK_STATE`, `FOREGROUND_SERVICE`,
`FOREGROUND_SERVICE_MEDIA_PLAYBACK`, `POST_NOTIFICATIONS`, `WAKE_LOCK`,
`CHANGE_WIFI_MULTICAST_STATE` (mDNS for Cast discovery; AOSP `NsdManager`, not
GMS). The exact merged set should be re-confirmed against a release build's
merged manifest at submission time.

## 6. Listing assets status

Tracked in [listing-assets.md](./listing-assets.md). The real app **icon**
(512×512) and **feature graphic** (1024×500) are committed (generated from
`tool/branding/linthra_icon.svg`). **Screenshots are the only missing listing
asset** — they must be captured from a real build, never mocked. Collection is
already tracked by **issue #77** ("Add real app screenshots to the README and
store metadata"), which lists the target screens (Now Playing, Library,
Settings → Jellyfin, Downloads, Cast, Android Auto) and the no-private-data rule.
Screenshots are **not** strictly required for an fdroiddata MR, but are strongly
recommended for the listing; capture before/soon after submitting.

## 7. Verification status

Run in this preparation pass (this environment has **no Flutter/Dart/Android SDK
and no fdroidserver**, so app/build/lint checks could not run here):

| Check | Status |
| ----- | ------ |
| Metadata YAML parses (PyYAML) | ✅ parses; fields/types as expected (Summary 57 chars ≤ 80; versionCode integer 100025). A plain YAML parse is **not** a full F-Droid schema check (see below). |
| `flutter pub get` | ⏳ not run here (no toolchain). Run locally / in CI. |
| `dart format --set-exit-if-changed .` | ⏳ not run here. CI (`ci.yml`) runs it on every PR. |
| `flutter analyze` | ⏳ not run here. CI runs it on every PR. |
| `flutter test` | ⏳ not run here. CI runs it on every PR. |
| `flutter build apk --debug` | ⏳ not run here (no Android SDK). CI (`android-debug-apk.yml`) builds the debug APK on every PR. |
| `flutter build apk --release` | ⏳ not run here. The tag build (`android-release-build.yml`) produced the alpha.25 release APK; re-confirm a clean from-source release build on an SDK-equipped machine. |
| `fdroid lint` / `fdroid build -l io.github.thezupzup.linthra` | ⏳ not run here (no fdroidserver). Run inside an fdroiddata checkout (see §8). |

> **Do not treat the YAML parse as F-Droid validation.** It only confirms the
> file is syntactically valid YAML with the expected fields. Real validation is
> `fdroid lint` + an actual `fdroid build` in an fdroiddata checkout.

**Exact commands to run locally / in an fdroiddata checkout:**

```sh
# In the Linthra repo (pinned Flutter 3.27.4 — see scripts/setup_flutter.sh):
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release \
  --build-name=0.1.0-alpha.25 --build-number=100025   # what the recipe derives

# In an fdroiddata checkout, after copying metadata/io.github.thezupzup.linthra.yml in:
fdroid readmeta
fdroid lint io.github.thezupzup.linthra
fdroid build -v -l io.github.thezupzup.linthra        # full from-source build test
```

## 8. Next steps to submit to fdroiddata

1. **Capture & commit screenshots** (issue #77) — recommended before submitting.
2. **Re-confirm a clean `flutter build apk --release`** from source on an
   SDK-equipped machine (and the merged-manifest permission set).
3. **Fork** https://gitlab.com/fdroid/fdroiddata and create a branch.
4. **Copy** `metadata/io.github.thezupzup.linthra.yml` into fdroiddata's
   `metadata/` directory. In the real entry, drop the inline `Summary`/
   `Description` (F-Droid pulls them from the Fastlane files) unless you
   deliberately want to override them.
5. **Finalize the Builds toolchain** to fdroiddata's current Flutter convention
   (srclib vs. sudo-clone — §3) and run `fdroid lint` + `fdroid build -l` until
   green (§7).
6. **Open the merge request** using the description in §9. Mark it clearly as an
   **early-alpha, pre-release** submission and confirm with reviewers whether
   F-Droid will track an `-alpha` tag or wants to wait for a stable tag.
7. **Do not** state Linthra is on F-Droid until the MR is merged and the build
   publishes.

## 9. Merge-request description (ready to adapt)

> Paste into the fdroiddata MR. Honest, not overhyped.

---

**New app: Linthra — `io.github.thezupzup.linthra`**

**Summary:** Local-first music player for your own self-hosted library.

**What it is.** Linthra is an open-source, local-first Android music player for
people who own their music: play a local folder, or stream from your own
self-hosted Jellyfin or Navidrome / Subsonic server. It is an **unofficial
community project**, not affiliated with or endorsed by Jellyfin, Navidrome, or
the Subsonic project.

**Why it fits F-Droid.**
- **License:** MPL-2.0 (FSF/OSI-approved), declared in `LICENSE`.
- **Builds from source**, no signing keys needed (F-Droid signs its own builds).
- **No proprietary dependencies.** A full transitive audit (152 packages) found
  only permissive licenses (BSD/MIT/Apache-2.0/MPL-2.0) and **no Google Play
  Services / Firebase / analytics / ads / crash-reporting** package. The only
  native component is SQLite (public domain, built from source); playback is
  AndroidX Media3 (Apache-2.0); Cast is a **pure-Dart** implementation (no GMS
  Cast SDK).
- **No anti-features.** No ads, no tracking/telemetry, nothing phones home. The
  optional self-hosted sources are user-supplied free-software servers (none
  bundled/promoted/required), so `NonFreeNet` does not apply.
- **Minimal permissions.** No storage/location/contacts/camera/mic/phone
  permission and no `MANAGE_EXTERNAL_STORAGE`; folder access uses the Storage
  Access Framework.

**Source / tracker.** https://github.com/thezupzup/linthra (issues at `/issues`).

**Build target.** Tag `v0.1.0-alpha.25`, versionName `0.1.0-alpha.25`,
versionCode `100025`. The build derives the version from the tag (the upstream
single-source-of-truth `tool/version_from_tag.dart`), so the versionCode is
distinct/monotonic per release and matches the upstream GitHub-release APK.
(Note: `v0.1.0-alpha.24` was a withdrawn broken release; alpha.25 is the hotfix.)

**Status — honest scope.** This is **early-alpha, pre-release** software: usable
for testing on a real device, not production-stable, with documented rough edges.
It is currently distributed only via GitHub Releases (sideloaded APK). I'd
welcome guidance on whether F-Droid prefers to track this `-alpha` tag now or
wait for a first stable (`vX.Y.Z`) tag.

**Build verification.** `flutter analyze` / `flutter test` / formatting run green
in CI on every PR, and CI builds a debug APK per PR; the tagged release APK
builds via the release workflow. I will additionally run `fdroid lint` +
`fdroid build -l` and confirm a clean from-source `flutter build apk --release`.

**Known limitations.** Early alpha; local files show file names until tag parsing
lands; single Jellyfin server; some Subsonic features (favourites/lyrics/cover
art) are follow-ups; screenshots are being captured from real builds.

---

## 10. GitHub issue draft — "Submit Linthra to F-Droid"

> Body for a tracking issue in this repo. **Provided as a draft — not created
> automatically.** A separate readiness issue (#87) and the screenshots issue
> (#77) already exist; this one tracks the actual submission. Suggested labels:
> `documentation`, `f-droid`.

**Title:** Submit Linthra to F-Droid

**Body:**

### Overview

Track the actual submission of Linthra to
[fdroiddata](https://gitlab.com/fdroid/fdroiddata). This is **not** a claim that
Linthra is on F-Droid — it is the submission work itself. Readiness groundwork is
done (#87); this issue covers cutting the MR.

The target is the latest **working** alpha, **`v0.1.0-alpha.25`** (versionCode
`100025`) — the hotfix that supersedes the withdrawn, broken `v0.1.0-alpha.24`.

### Checklist

- [ ] Capture & commit real screenshots (#77) — recommended before submitting.
- [ ] Re-confirm a clean from-source `flutter build apk --release` on an
      SDK-equipped machine; re-check the merged-manifest permission set.
- [ ] Decide `pubspec.lock` policy for the tagged commit.
- [ ] Fork fdroiddata; copy in `metadata/io.github.thezupzup.linthra.yml`.
- [ ] Finalize the Builds toolchain to fdroiddata's Flutter convention
      (srclib vs. sudo-clone).
- [ ] `fdroid readmeta` + `fdroid lint` + `fdroid build -l` all green.
- [ ] Open the MR (description in `docs/fdroid-submission.md` §9); flag the
      early-alpha / pre-release status and ask about `-alpha` tag tracking.

### Blockers / open questions

- F-Droid's stance on tracking a **pre-release `-alpha`** CurrentVersion (vs.
  waiting for a stable tag) — judgement call to confirm with reviewers.
- Final Flutter-on-F-Droid build incantation must be validated in an fdroiddata
  checkout.

### Links

- Metadata draft: `metadata/io.github.thezupzup.linthra.yml`
- Submission package: `docs/fdroid-submission.md`
- Readiness checklist: `docs/fdroid-readiness.md`
- Build recipe notes: `docs/fdroid-build-recipe.md`
- Dependency/license audit: `docs/dependency-license-audit.md`
- Listing assets: `docs/listing-assets.md`

### Current status

Metadata, audit, permissions, anti-feature review, build recipe, and submission
text are prepared and target `v0.1.0-alpha.25`. Remaining before the MR:
screenshots, an SDK-machine release-build re-confirmation, and `fdroid lint` /
`fdroid build` validation in an fdroiddata checkout.
