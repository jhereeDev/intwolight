# IN TWO LIGHTS — Handoff

# ▶ RESUME HERE — rewritten 2026-08-06 on the `Jhere` PC

> **This section previously said the iOS signing key was the one blocker and asked the laptop to
> go hunting for it. That was discharged on 2026-08-04 and the text sat here stale for two days.**
> The signing story is kept below, compressed, because it cost a day. It is history, not a task.

**The build is done and on TestFlight. Nothing in the code blocks the release.**
**What blocks it is paperwork only Jhere can enter.**

## Where things actually stand

Verified on the `Jhere` PC, 2026-08-06 — every number below was measured, not copied forward:

| | |
|---|---|
| Repo | `25d76c7` on `main`. PC and laptop both in sync with `origin`, nothing uncommitted |
| Toolchain | Flutter **3.44.8** · Dart **3.12.2** · stable |
| `flutter analyze` | ✅ **No issues found** |
| `flutter test` | ✅ **107 passing** |
| Campaign | **247 levels across 13 chapters** (`chapterStarts` in `progress.dart`), plus a daily room and endless mode |
| Free / paid split | CHAPTER I = **15 levels free**, chapters II–XIII (**232 levels**) behind the one-time RevenueCat unlock |
| iOS | ✅ **Signing solved 2026-08-04.** **15 builds uploaded**, the newest two on Aug 5. All read *Ready to Submit*; the version currently has **#13** attached |
| Privacy policy | ✅ **live** — `https://jhereedev.github.io/intwolight/privacy.html` returns **200** (re-checked 2026-08-06) |

## ✅ The Apple paperwork is DONE. Read this before believing any older note.

**Checked in the account itself on 2026-08-06, not inferred from a status file:**

| Business → Agreements | |
|---|---|
| **Paid Apps Agreement** | ✅ **Active**, Jul 23 2026 – May 17 2027 |
| Free Apps Agreement | ✅ Active, same dates |
| Bank account | ✅ **Active** — Philippines, PHP, royalties in USD |
| **U.S. Form W-8BEN** | ✅ **Active**, submitted **Aug 4 2026** |
| **U.S. Certificate of Foreign Status** | ✅ **Active**, submitted **Aug 4 2026** |
| Digital Services Act (account level) | ✅ Active, 27 countries |

> **This section said the opposite for two days**, and an earlier rewrite of this very file
> repeated it — because both were built from `status.md` and the repo, and neither opened the
> account. **The forms were filed on Aug 4 and everything went Active.** The AIOS rule that a
> `status.md` is a claim rather than a fact exists for precisely this; so does the Article 8 tax
> research, which is now spent and lives in the git history if it is ever needed again.

**The in-app purchase exists and is configured:** `In Two Lights Pro`,
product ID **`com.jhere.intwolights.pro`**, non-consumable, priced, available in 175 countries,
display name "All Chapters", description *"Chapters II–V: 32 more rooms, one payment."*
Status **Prepare for Submission**. The entitlement string matches `Store.entitlement`
in `lib/store.dart`.

## 🔴 What actually blocks submission

1. **The IAP has no review screenshot.** `Review Information → Screenshot` is empty and it is
   required. Apple also states *"your first non-consumable in-app purchase must be submitted with
   a new app version"* — so this one empty field gates the entire 1.0 submission.
   **The file is ready at `press/unlock-screen.png`**, captured through `Shot('07-unlock')`;
   it only needs uploading. Never re-shoot it by hand.

   > 🔴 **Two pieces of store copy went stale when the campaign grew to 247.** The paywall
   > derives its own headline (`allLevels.length - chapterEnd(0)`) and now reads **"232 more
   > rooms"**, but App Store Connect still says:
   > * **IAP description** — *"Chapters II–V: 32 more rooms, one payment."* → it is chapters
   >   **II–XIII** and **232** rooms.
   > * **App Store description** — says **47 rooms** → 247.
   >
   > Understating what is sold is not a rejection risk, but the chapter range is now simply
   > wrong. Both are Jhere's to edit.
2. **App Privacy is filled in but NOT published.** Every declaration is entered — Purchase History
   and User ID, both *used for app functionality*, neither linked to identity — and the page still
   shows a live **Publish** button. Nothing has been submitted to Apple.
3. **App Review contact information is empty.** Personal data; Jhere enters this.
4. **DSA trader status is "non-trader" at the app level.** App Information reads *"This developer
   has identified itself as a non-trader for this app."* The **account-level** DSA registration is
   Active, but these are different things, and the app is set to sell an IAP into 175 countries
   including the EU. **Resolve what this means for EU availability before release** — the flow
   (`/business?collectContactInfo=true`) collects contact details that are then shown publicly, so
   it is a decision, not a click.
5. **The version has build 13 attached, but builds 14 and 15 exist** (both uploaded Aug 5 2026,
   after the last commit). Decide which one ships.

## Then, in order

1. **Submit 1.0 for App Review.** Review time is the schedule risk and the first public release
   must land inside **2026-07-31 → 09-30**. Ship early, update after.
2. **Submit for external TestFlight beta review** (~1–2 days) so strangers can be recruited.
   Internal testers are instant but must be added as App Store Connect *users* — not something
   to hand a stranger.
3. **Run the five-tester playtest** — `press/playtest-brief.md`. Longest lead time of anything
   left, because it depends on other people's evenings. Still the only thing that can validate the
   difficulty ordering, and **the three knobs below are all guesses until it runs**.
4. **Demo video, under 2 min** + the store URL — both still open on Devpost entry
   `1123433-in-two-lights`.

### Knobs that need a real player, not a terminal
`_settleDelay` 900ms · `_hintDelay` 60s · the drone's floor/duck/curve in `tool/gen_audio.py`.

## The App Store listing — what is already done

**Verified in App Store Connect 2026-08-06. Several items this file previously called outstanding
are finished; do not redo them.**

| | |
|---|---|
| Age rating | ✅ **4+**, 172 countries. Brazil ALL, Korea override, Vietnam 00+ |
| Content rights | ✅ "does not contain, show, or access third-party content" |
| Pricing and availability | ✅ base **United States (USD)**, price set, **175 countries**, tax category *App Store software* |
| Screenshots | ✅ 6 of 10, 6.5" display |
| Description / promo text / keywords | ✅ in, and reading 47 rooms |
| Privacy policy URL | ✅ live, 200 |
| `Sign-in required` | ✅ correctly **unchecked** — the game has no accounts |
| Export compliance | ✅ **not an issue** — all eight builds read *Ready to Submit*, none says "Missing Compliance" |

Everything still outstanding is in the numbered list above.

> ⚠️ **Release option currently reads "Manually release this version"** — set by a misdirected
> click, not a decision. Defensible (it puts go-live under Jhere's control against a 09-30 window)
> but it was not intentional. Confirm before submitting.

## Regenerating the IAP review screenshot

```bash
export PATH="/d/flutter/bin:$PATH"                      # Jhere PC
flutter emulators --launch Medium_Phone_API_36.0
flutter run -d emulator-5554 --release --dart-define=SHOT=true
# tap through to shot 07-unlock, then:
adb exec-out screencap -p > press/unlock-screen.png
```

`Shot('07-unlock')` renders the real `UnlockScreen` against `_ShotStore`, a two-getter subclass
that lives in `lib/shots.dart`. **It exists because a keyless build has nothing to sell**, so the
genuine screen renders its button as "STORE UNAVAILABLE" — the one thing an IAP review screenshot
must not show. It grants nothing: `unlocked` is `entitled || !canBuy`, so forcing `canBuy` true
makes the app *more* locked, and `computeUnlocked` in `store.dart` is untouched. **The money path
was not modified for a screenshot, and should not be.** Override the price with
`--dart-define=SHOT_PRICE='$4.99'` when the real tier is decided.

## Open questions and warnings

- ⚠️ **Codemagic triggering is unresolved. Do not rely on it under deadline pressure.**
  `codemagic.yaml` declares `triggering: events: [tag]` — `ios-v*` for the iOS workflow,
  `android-v*` for `android-release`. **Config says tags only**, yet builds have been observed
  attributed to `main`, and pushing tag `ios-v0.2` did not fire promptly either; #12 was started
  manually, cancelled by neither Jhere nor Claude, and #13 appeared for the same commit. The
  likeliest reading is a late webhook plus auto-cancel of the duplicate. **When a build must
  happen, start it from the dashboard and watch it.**
- Queued ~10 min before getting a machine is **normal** — free-plan priority on the shared M2 pool,
  not quota (**~48 / 500** macOS minutes used). **Do not cancel and retry a queued build**; it only
  sends you to the back of the line.
- ⚠️ **`ios-v0.1` is a stale tag** and `triggering: events: [tag]` makes it look deliberate.
  Delete it or re-point it.
- ⚠️ **`UIRequiresFullScreen` is deprecated** — slated to stop exempting apps on iPadOS 26+. Fine
  for 1.0; after Shipaton it is real iPad landscape or `TARGETED_DEVICE_FAMILY = 1`.
- ⚠️ **Build warning `90068: MinimumOSVersion too low`** — the app declares **13.0** and Apple
  requires **15.0 or later from Spring 2027** to upload or submit. A warning, not an error: builds
  14 and 15 carry it and were still accepted. Not a 1.0 problem; it becomes one next year.
- ⚠️ **The ASC issuer ID is recorded nowhere.** Capture it next time you are in Codemagic.
- ⚠️ **App Store Connect maintenance 2026-08-08, 6am PDT, up to two hours.** Do not plan a
  submission around that morning.
- ⚠️ On Devpost, *"Are you an employee of RevenueCat or a Shipaton Sponsor?"* is **checked**.
  Nobody changed it because it is a factual claim about Jhere. That question normally decides
  prize eligibility — **ask him**.

## How the signing blocker was solved — history, not a task

`sarimanok-cert-key` on the laptop (`C:\Users\FF MIRAVITE\sarimanok-cert-key`) was the right key.
**The certificate cap was never the wall and nothing was revoked** — the `HANDOFF.md` fallback of
revoking kalyedex's certificate was never needed. The file has no extension, which is why this
document's own suggested search (`-Include *.pem,*.key`) could not have found it.
`kalyedex_cert_key2.pem`, also on the laptop, remains the untried backup if a fresh certificate is
ever required. Full inventory: AIOS `connections.md` §Signing key material.

Three failures, none of them the obvious reading of its own error message:

| Build | Error | Actual cause |
|---|---|---|
| #3 | `Cannot save Signing Certificates without certificate private key` | Built from tag `ios-v0.1`, where `codemagic.yaml` has the env group **commented out**. *An old tag pins an old pipeline, not just old source.* |
| #4 | altool `90474` — iPad multitasking orientations | `UIRequiresFullScreen` missing. `sarimanok` carries it and warns about this in its own plist comment; the port dropped exactly that key. |
| #4 again | identical `90474` | The fix was committed and **never pushed**, so CI rebuilt the same bundle. The push had failed: plain `git@github.com` **reads** on the laptop and cannot **write**. See AIOS `connections.md`. |

## Everything already wired (do not redo)

| | |
|---|---|
| Apple Team | `A23ZGW4Y37` |
| App ID | `com.jhere.intwolights` (`HKF44N9DFA`) — registered |
| App Store Connect | **In Two Lights**, Apple ID `6797556691`, SKU `intwolights-ios-001` |
| Agreements | Free Apps **Active**. Paid Apps **Pending User Info** — see the blocker above. **Not needed for TestFlight** |
| Codemagic | app `intwolight`, on `codemagic.yaml`, integration `asc-key` (`FGDYK5MTLK`) |
| Devpost | entry `1123433-in-two-lights` — story, pitch, thumbnail, six captioned screenshots, tags, repo link all saved. Needs demo video + store URL |
| Privacy policy | ✅ live at `https://jhereedev.github.io/intwolight/privacy.html` (Pages is enabled) |
| Store assets | regenerate with `--dart-define=SHOT=true` (`lib/shots.dart`) — **never re-shoot by hand**, they went stale twice in one day. `press/raw` is replaced in place, never joined by a `raw2/` |
| Android keystore | `C:\Users\jhere\Documents\reset-signing-backup.zip` (PC only) — for `android-release` later |
| iOS signing key | `C:\Users\jhere\Documents\intwolights-CERTIFICATE_PRIVATE_KEY.pem` — **PC only, and the only readable copy**; Codemagic never reveals a secret back |

## How to read the rest of this file

Everything below was **reconciled against the working tree on 2026-08-06** — the sections that had
gone stale (State of play, the code map, Known debt, "What comes next", the test counts) now carry
measured numbers, and the historical corrections are marked as history rather than as tasks.

Two rules for keeping it that way:

1. **This section is the only place a next action belongs.** Everything below is context, decisions
   and machine setup. When a task moves, it moves here.
2. **Numbers in this file are claims with a date on them.** They went stale twice — "25 tests" when
   there were 94, "no CI" after 13 builds. If a number matters, measure it (`flutter test`,
   `git log`) rather than quoting the file. **Trust order: this section → the git log → the AIOS
   `projects/in-two-lights/status.md` → everything else.**

---

**Written 2026-08-03, end of the first working session, on the LAPTOP (`LAPTOP-CHI3Q4MR`).**
Read this before touching anything. It is the fastest way back into context.

> **Corrected 2026-08-03 on the `Jhere` PC.** This file originally claimed it was written on
> the PC and had the two machines' Flutter paths swapped — the exact trap the section below
> exists to prevent, stated backwards. Everything M0 (the gate play-through, the Pixel 10 Pro
> release run) happened **on the laptop**. Machine facts below are now verified per-machine.

---

## Decisions from 2026-08-03 — kept because they still bind, not because they are pending

> **This section used to be titled "🔴 Do this first, next session".** It is not the next session's
> list any more — see `▶ RESUME HERE` at the top for that. What survives here is the *reasoning*,
> which is still load-bearing, and one open human question.

> ### ⚠️ The old #1 here was wrong. Corrected 2026-08-03 against the official rules.
>
> This file previously said: *"Shipaton requires the RevenueCat SDK to power at least one real
> in-app purchase. RevenueCat Ads does not satisfy it… no documented Flutter support. No agreement
> → no IAP → no valid entry, for any app."* **Three errors.**
>
> 1. The rules say the app *"uses the RevenueCat SDK to power at least one in-app or web purchase,
>    **or that serves ads through RevenueCat Ads**."* The ads path is named explicitly.
> 2. RevenueCat's docs list **Flutter as supported** for ad monetization (`purchases_flutter`
>    10.2.0+). It *is* beta — a real risk — but "no Flutter support" was false.
> 3. The store requirement is *"Apple's App Store, **the Google Play Store**, or the Samsung Galaxy
>    Store."* **Google Play alone is a valid entry. Apple is optional.**
>
> Net: the Apple Paid Applications agreement is **not** a blocker on entry validity. It only
> gates App Store revenue. Source: <https://revenuecat-shipaton-2026.devpost.com/rules>

**1. Play generated levels 1, 6 and 12 and say whether difficulty actually rises.** (10 min.)
There is **no validated difficulty metric** — two were tried and both failed (see below).
You are the only ground truth available, and this decides whether the curve needs work.
Level 1 was played and solved on the PC 2026-08-03; 6 and 12 are still open.

**2. ✅ DECIDED 2026-08-03 — APPLE FIRST.** Three consequences, all now live:

- 🔴 **Paid Applications — checked in the account 2026-08-03, and it is NOT "unstarted".**
  Free Apps Agreement is **Active** (Jul 23 2026 → May 17 2027). Paid Apps Agreement is
  **"Pending User Info"** — already accepted, waiting on two things that were never supplied:
  **no bank account** and the **U.S. Tax Questionnaire shows "Missing Tax Info"**.
  So this is not a 15-minute click; it needs PH bank details and a tax form (W-8BEN territory),
  and only Jhere can enter them.
  **Crucially: TestFlight does not need any of it.** Free Apps Active is sufficient to upload and
  test. Only real IAP revenue is blocked.
- **iOS cannot be built on either machine.** Xcode is macOS-only and neither the PC nor the laptop
  is a Mac, so `codemagic.yaml` (ported from sarimanok, at the repo root) is not a convenience —
  it is the only route to the App Store.
- **App Review is the schedule risk.** The first public release must land inside
  2026-07-31 → 09-30, and a rejection costs days. Ship 1.0 early and update, per RevenueCat's own
  advice. `android-release` is kept in the CI config as the escape hatch: Google Play alone is a
  valid Shipaton entry if Review turns hostile near the deadline.

**3. Post build-in-public.** The #BuildInPublic award pays **$30k / $20k / $10k** — double Best
Game — and its engagement window (**2026-07-31 → 09-30**) is already running. Tag `#Shipaton`
and `#BuildInPublic`. Judged on *"sharing story creatively, engagement/feedback incorporation,
lessons learned"* — so incorporating a reply beats broadcasting.

---

## What this is

A wordless spatial-deduction puzzle. An abstract sculpture of hinged low-poly arms hangs in
the corner where two perpendicular walls meet, lit by two sources. A level is solved when
**both** cast shadows match their target silhouettes at once — adjusting the form to fix one
shadow breaks the other, and that tension is the puzzle.

**Shipaton 2026 entry**, registered on Devpost as **In Two Lights** (renamed from "Two Suns"
2026-08-03 — the old name read as sci-fi and misdescribed the game).

Targets, corrected 2026-08-03 against the published prize table:

| Category | 1st / 2nd / 3rd | Judged on |
|---|---|---|
| **#BuildInPublic** | **$30k / $20k / $10k** | story, feedback incorporation, lessons |
| **Best Game** (primary build target) | $15k / $10k / $5k | gameplay engagement, unique experience/**progression**, monetization fit |
| **Design** (secondary) | $15k / $10k / $5k | innovation, aesthetics/delight, **standout animations** |

Submission window **2026-07-31 → 2026-09-30, 11:45 PM PDT**. Judging Oct 1–13; winners Oct 21.
The first public release must fall inside that window.

**Required at submission** (not just paperwork — these are build constraints):
demo video **under 2 min** on YouTube/Vimeo · 1024×1024 icon · screenshot **1179×2556, no device
frames** · public store URL · **a free trial or promo codes so judges can unlock paid content.**
Non-US winners file a **W-8BEN**; the sponsor reserves the right to withhold — do not quote a net
prize figure.

Full reasoning, including the six candidates that were killed to get here, is in the AIOS at
`jhere-dev/decisions/log.md` (2026-08-03) and `jhere-dev/projects/in-two-lights/`.

---

## State of play

**Verified on the `Jhere` PC 2026-08-06 — this table was two builds out of date and is now measured.**

| Area | State |
|---|---|
| **M0 kill gate** | ✅ **PASSED 2026-08-03**, seven days early. Jhere solved the hinge level and reported *deduction*, not fiddling |
| Projection + scoring | ✅ dual-wall shadows, **arbitrary triangle meshes**, raster IoU |
| Level generator | ✅ `tool/gen_levels.dart` (boxes) and `tool/gen_levels_ext.dart` (mixed shapes), both deterministic and rejection-sampled |
| Shape vocabulary | ✅ box · rod · bulb · wedge · hex · **ell, tee, chevron (concave)**. A box's shadow *is* its convex hull, so the concave three are the only pieces doing something a box cannot — `shapes_test.dart` proves it by rasterising each shadow against its own hull |
| Campaign | ✅ **247 levels across 13 chapters**. I–V as below (47); **VI–XIII are 8 × 25 mixed-shape rooms** — THE ROD, THE WEDGE, THE BULB, THE ANGLE, THE ARROW, ASSEMBLY, TANGLE, THE WORKS — joints running 0 → 1 → 2 again over the new vocabulary |
| Chapters I–V | ROTATION 15, THE JOINT 16, TWO JOINTS 9, FORMS 3, SILHOUETTES 4 |
| Daily room | ✅ **180 baked rooms**, TODAY chip on the map, free and outside the chapter gate. Baked, not generated at runtime — "same room for everyone" only holds if the level is bit-identical, and `dart:math` Random makes no cross-platform promise. Date maths in **UTC** |
| Endless mode | ✅ `lib/endless_screen.dart`, generated **on device** via `compute()`. The isolate is not optional — a hinged room costs ~1s on desktop and several times that on a phone. Room N+1 prefetches while N is played |
| Tests | ✅ **107 passing** |
| `flutter analyze` | ✅ **No issues found** |
| Verified running | ✅ `Medium_Phone_API_36.0` (PC) and `Pixel_10_Pro` (laptop), release builds. ⚠️ **Real hardware still unconfirmed** — see Known debt |
| Design pass | ✅ the corner is a real room: two walls, floor, two light pools, shadows dark on lit walls, dust, eased solve glow + haptics |
| Audio | ✅ proximity drone whose gain tracks the **weaker** wall, plus a 620ms solve chord matched to the glow. Synthesised by `tool/gen_audio.py` — **the numbers in that file are the sound design** |
| Onboarding | ✅ wordless — a drifting ghost touch point, gone on first drag. No modal, no Skip |
| Progression / stars / map | ✅ level map of miniature rooms, chapters, stars on **precision** (0.92 / 0.955 / 0.985), `shared_preferences`. **Three separate ledgers** — campaign (`best_v2`), daily, endless (`endless_v1`, keyed by depth so a campaign reorder never invalidates it) |
| Hints | ✅ fade in after 60s stuck, withdraw on solve, no button to ask |
| Extras | ✅ Menagerie (`lib/menagerie.dart`), Workshop (`lib/workshop_screen.dart`), challenge-a-friend (`lib/challenge.dart`), share that captures **the scene only**, undo, streak counting from *yesterday* |
| **CI** | ✅ `codemagic.yaml` at the root. **13 builds run; #13 succeeded and uploaded to App Store Connect.** See the triggering warning at the top |
| **RevenueCat** | ✅ **integrated** — `lib/store.dart`, `lib/unlock_screen.dart`, `Progress.chapterLocked()`. One non-consumable, entitlement `In Two Lights Pro`. **Cannot take money until Paid Applications goes Active** |
| Store assets | ✅ icon, six screenshots at 1242×2688, privacy policy live. ❌ demo video still outstanding |

---

## Setting up on another machine

```bash
# The SSH host alias differs per machine — plain git@github.com works on both.
git clone git@github.com:jhereeDev/intwolight.git in-two-lights
cd in-two-lights
```

### Names and identifiers — renamed 2026-08-03

The project was **"Two Suns" until 2026-08-03**. Nothing has shipped under the old name, so the
rename is complete and free. Current identifiers:

| Thing | Value |
|---|---|
| Display name | **In Two Lights** |
| Dart package (`pubspec.yaml`) | `in_two_lights` |
| Bundle / application ID, **both platforms** | `com.jhere.intwolights` |
| Devpost entry | In Two Lights |
| Apple Team ID | `A23ZGW4Y37` |
| App Store Connect Apple ID | `6797556691` |
| ASC SKU | `intwolights-ios-001` |
| Privacy policy URL | `https://jhereedev.github.io/intwolight/privacy.html` — ✅ live, returns 200 |

**Registered 2026-08-03 in the real Apple account:** the App ID
`com.jhere.intwolights` exists in Certificates/Identifiers, and the App Store Connect record
exists with the name **In Two Lights** — which also settles name availability, since App Store
Connect rejects a name already taken.

⚠️ **The bundle ID was inconsistent before the rename** — Android used `com.jhere.two_suns`,
iOS used `com.jhere.twoSuns`. They are now unified. Keep them identical: RevenueCat keys
products per app per store, and a mismatch surfaces as missing entitlements at M3.

**GitHub repo renamed** `2sun` → **`intwolight`** 2026-08-03; the `origin` remote on the PC was
repointed the same day and verified reachable. GitHub redirects the old URL, so a stale clone
still fetches — but repoint it anyway so the two machines agree.

⚠️ **Note the spelling.** The repo is `intwolight` (**singular**), the bundle ID is
`com.jhere.intwolights` (**plural**), and the display name is "In Two **Lights**". Harmless, but
do not assume one from the other — copy the exact string from this table.

⚠️ **Still carrying the old name:** both local directories are `two-suns`
(`D:\Claude\two-suns`, `C:\coding_projects\personal\two-suns`). Purely cosmetic — but rename
them on both machines together if at all, so the two don't diverge.

**A bundle ID cannot be changed after a store release.** It is correct now; do not touch it again.

### Where the clone lives, per machine

| Machine | Repo path |
|---|---|
| `Jhere` PC (the D: rig) | **`D:\Claude\two-suns`** — cloned 2026-08-03 |
| Laptop (`LAPTOP-CHI3Q4MR`) | `C:\coding_projects\personal\two-suns` |

### ⚠️ The trap: Flutter's location is machine-specific and it is NOT on PATH

**Find it, do not assume it.** Both entries below are verified, not inferred:

| Machine | Path |
|---|---|
| `Jhere` PC | **`D:/flutter`** — `C:/flutter` does not exist on this rig |
| Laptop (`LAPTOP-CHI3Q4MR`) | `C:\flutter` — laptop has **only a C: drive** |

```bash
# Git Bash — on the Jhere PC
export PATH="/d/flutter/bin:$PATH"
# PowerShell — on the Jhere PC
$env:PATH = "D:\flutter\bin;$env:PATH"
```

Required toolchain: **Flutter 3.44.8 · Dart 3.12.2 · stable.** Check with `flutter --version`
before anything else — a different minor version is the most likely cause of a mystery build
failure.

### Verify the clone is healthy

```bash
flutter pub get
flutter analyze     # expect: No issues found!
flutter test        # expect: All tests passed! (94 tests, ~8s)
```

If those three pass, the checkout is good.

### Running it

**AVDs are per-machine too — there is no shared emulator name.** Verified 2026-08-03:

| Machine | AVDs | Use |
|---|---|---|
| `Jhere` PC | `Medium_Phone_API_36.0` (Android 16, API 36), `Pixel_4a` | **`Medium_Phone_API_36.0`** — the adopted default on this rig |
| Laptop | `Pixel_10_Pro` | what M0 was gate-tested on |

```bash
flutter devices
flutter emulators
flutter emulators --launch Medium_Phone_API_36.0   # on the Jhere PC
flutter run -d emulator-5554 --release
```

`adb` lives at `~/AppData/Local/Android/Sdk/platform-tools/adb.exe` and is also not on PATH.
Useful for screenshots: `adb exec-out screencap -p > shot.png`.

### Regenerating levels

```bash
dart run tool/gen_levels.dart     # ~30s, rewrites lib/levels.g.dart
```

Deterministic in the chapter seeds, so the same run gives the same 36 levels. This is **not**
build_runner and there is no watch mode — run it by hand, commit the output.

---

## Known debt, carried deliberately

**1. ✅ RESOLVED — CI exists.** This entry used to read "No CI". `codemagic.yaml` was ported from
sarimanok and has run 13 builds; #13 succeeded and uploaded to App Store Connect. **Neither machine
is a Mac, so Codemagic remains the only route to an iOS build.** What is *not* resolved is
**when it fires** — see the triggering warning in `▶ RESUME HERE`.

**2. ✅ MOSTLY RESOLVED — it has run on real hardware.** This entry said "never run on real
hardware", which the TestFlight numbers disprove: builds 6–15 carry **installs and sessions**
(build 13 alone: 4 installs, 13 sessions). `kalyedex` was built, tested, tagged and store-ready
without ever running on a device — that trap was avoided here. What is still missing is a **written
account of what those sessions found**; installs are not a playtest, and the five-tester run in
`press/playtest-brief.md` is still the thing that closes it.

**3. No validated difficulty metric — and the failure is instructive.**
A claim was made that hand-authored level 1 (Tee) was *under-constrained*. It was inferred from
screenshots, not from play. Two metrics were then built to catch it, and **both ranked backwards**:

| Metric | Tee (claimed bad) | Hinge (known good) |
|---|---|---|
| Constraint correlation | 0.40 | **0.67** — would have rejected the good level |
| Hill-climb findability | 40% | 35% — no separation |

So **no difficulty filter ships.** `kMaxCorrelation` in `lib/generator.dart` is defined and
deliberately unused; `tool/probe.dart` holds the hill-climb experiment. Both are kept so the dead
end is not re-derived. Ordering uses an `approach` metric, which produces a ~21× spread but has
never been checked against a human.

**4. Two simplifications with stated ceilings**, both commented in `lib/geom.dart`:
- **Raster IoU on a 64×64 grid** instead of polygon booleans. Unions come free; `clipper2` was
  dropped entirely. Scores quantise at about ±0.01, far inside the 0.92 solve threshold.
- **Euler yaw/pitch, not a quaternion arcball.** Gimbal lock needs pitch ±90°, which the UI
  clamps away from.

---

## Map of the code

```
lib/geom.dart          V3/V2, rotation, wall projection, convex hull, raster mask, IoU
lib/mesh.dart          arbitrary triangle meshes — replaced the box-only model
lib/level.dart         Box/Pose/Level, world transform, shadows, LevelRuntime, tutorial trio
lib/forms.dart         allLevels — THE campaign order. Organic forms + designed silhouettes
lib/levels.g.dart      GENERATED — 36 procedural box levels, consumed by forms.dart
lib/levels_ext.g.dart  GENERATED — 200 mixed-shape levels, chapters VI–XIII.
                       Pieces are emitted as `piece(Shape.rod, …)` RECIPES, not
                       baked vertices: one lathe is ~90 points, so baking would
                       make this a megabyte nobody can read or diff.
lib/generator.dart     candidate sculptures, sampled metrics, rejection sampling
lib/progress.dart      chapterStarts/chapterNames, stars, locking, the three ledgers
lib/main.dart          app entry and the play screen
lib/scene.dart         the corner rendered as one room: walls, floor, seam, light pools, dust
lib/map_screen.dart    level map — each node a miniature of its own room
lib/store.dart         RevenueCat wrapper + computeUnlocked (the money path, pure & testable)
lib/unlock_screen.dart the paywall
lib/daily.dart         + dailies.g.dart — 180 baked rooms, UTC date maths
lib/endless.dart       + endless_screen.dart — on-device generation via compute(), prefetched
lib/menagerie.dart     shelf of the figures you have found
lib/workshop*.dart     the game read backwards
lib/challenge.dart     challenge a friend without handing them the answer
lib/audio.dart         proximity drone + solve chord
lib/shots.dart         --dart-define=SHOT=true capture harness for the press kit
tool/gen_levels.dart   run by hand to regenerate levels.g.dart
tool/gen_levels_ext.dart  the mixed-shape chapters (~5 min). Prints the
                       chapterStarts/chapterNames lines to paste into
                       progress.dart, so the table is never hand-counted.
tool/gen_audio.py      synthesises the audio — the numbers in it ARE the sound design
tool/silcheck.dart     verifies a silhouette reads on wall B and is not pre-solved
tool/probe.dart        scratch experiment: hill-climb difficulty. Negative result, kept
test/                  17 files, 107 tests
```

### Two invariants that adding levels must not break

**1. `allLevels` order IS the save format — append, never insert.** `Progress` keys
stars by index, so splicing a chapter into the middle moves every star after it onto a
different puzzle. Chapters VI–XIII went on the end, every index ≤ 46 is untouched, and
`campaignKey` therefore stays `best_v4` and nobody loses progress. If a level ever *has*
to be inserted, bump the key and accept that everyone's campaign resets.

**2. `generator.dart` is shared with endless, which generates on the device.** Its ledger
is keyed by **depth**, on the promise that room 340 is the same puzzle forever. So mixed
generation is opt-in — `generateChapter(mixed: false)` by default, and `_mixedCandidate`
is a separate function rather than a flag inside `_candidate`, because the two draw
different numbers of values from the RNG and a changed draw order would silently renumber
every endless room. `shapes_test.dart` pins the default to box-only. **Endless must never
pass `mixed: true`.**

**The money path is a pure function on purpose.** `Store.computeUnlocked` is
`forceLock ? false : (entitled || !canBuy)`. It was `entitled || !configured`, which failed open
when the SDK was *unconfigured* and **not** in the state this app is actually in — keys valid, SDK
configured, offering empty because Paid Applications is Pending User Info. In that state 32 of 47
levels sat behind a button reading "STORE UNAVAILABLE" that did nothing: a broken game and a
guaranteed **Guideline 3.1.1** rejection. An offering you cannot buy from is a store you cannot
reach. **Do not re-derive this as `configured`.**

**Design rule worth not re-deriving:** levels are authored as a **solved pose**, and the target
silhouettes are derived from it. Every level is therefore solvable by construction, generation is
nearly free, and two tests assert exactly that.

---

## What comes next, in order

**Rows 1–3 and most of 4 are shipped.** Kept as a record of the estimate against the outcome:

| # | Work | Est. | State |
|---|---|---|---|
| 1 | **Corner + lighting** — real perpendicular walls, soft shadow falloff, spotlight cone, dust motes | ~8h | ✅ done 2026-08-03 |
| 2 | **Level map + stars** — chapters, three stars on *precision* not speed, progression persistence | ~6h | ✅ done 2026-08-03 |
| 3 | **RevenueCat** — one-time chapter unlock | ~5h | ✅ done 2026-08-04 (`lib/store.dart`) |
| 4 | **Ship** — icon, in-app screenshots (Guideline 2.3.3, literal captures only), privacy policy, submission | ~5h | 🟡 assets done, **submission blocked on Paid Applications** |
| 5 | **Submission craft** — demo video + per-category write-ups | ~6h | ⬜ **the only build work left.** Devpost story is written; the video is not |

Everything genuinely outstanding now lives in `▶ RESUME HERE` at the top of this file. Nothing in
this table is a next action.

> Shipaton's judging page: *"Categories must be explicitly addressed in both video and written
> submission to be judged."* The write-ups are build work, not paperwork.

**The scope rule that protects the deadline:** ship a small, complete, beautiful thing. A finished
gallery can place; a clever engine full of placeholder puzzles cannot.
