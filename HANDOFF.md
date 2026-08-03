# IN TWO LIGHTS — Handoff

**Written 2026-08-03, end of the first working session, on the LAPTOP (`LAPTOP-CHI3Q4MR`).**
Read this before touching anything. It is the fastest way back into context.

> **Corrected 2026-08-03 on the `Jhere` PC.** This file originally claimed it was written on
> the PC and had the two machines' Flutter paths swapped — the exact trap the section below
> exists to prevent, stated backwards. Everything M0 (the gate play-through, the Pixel 10 Pro
> release run) happened **on the laptop**. Machine facts below are now verified per-machine.

---

## 🔴 Do this first, next session

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

**2. Decide: Android-first, or also Apple?** Android-first drops the Paid Applications item
entirely and reuses `flame-minis`' working Codemagic config. Apple can be added later.

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

| Area | State |
|---|---|
| **M0 kill gate** | ✅ **PASSED 2026-08-03**, seven days early. Jhere solved the hinge level and reported *deduction*, not fiddling |
| Projection + scoring | ✅ dual-wall shadows, convex hull, raster IoU |
| Level generator | ✅ `tool/gen_levels.dart`, deterministic, rejection-sampled |
| Levels | ✅ **36**, three chapters by hinge count (0 / 1 / 2), curated easiest-first |
| Tests | ✅ **10 passing**, incl. all 36 verified solvable and none pre-solved |
| `flutter analyze` | ✅ clean |
| Verified running | ✅ Pixel 10 Pro emulator, release build |
| **RevenueCat** | ❌ **not integrated** — M3. *Not* blocked: purchase **or** RevenueCat Ads both qualify, and Google Play alone is a valid store |
| **CI** | ❌ **none.** See "known debt" |
| Design pass | ❌ M0 UI is deliberately ugly — three flat panels and two numbers |
| Progression / stars / map | ❌ not started |

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
flutter test        # expect: All tests passed! (10 tests)
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

**1. No CI.** `flame-minis` has a working `codemagic.yaml` shipping both stores; this repo has
nothing. That is the price of the separate-repo decision, and it lands in M4.
**If neither machine is a Mac, Codemagic is the only route to an iOS build** — port that config
before M4, not during it.

**2. Never run on real hardware.** Emulator only, so far. `kalyedex` was built, tested, tagged
and store-ready without ever running on a device; do not repeat that.

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
lib/geom.dart        V3/V2, rotation, wall projection, convex hull, raster mask, IoU
lib/level.dart       Box/Pose/Level, world transform, shadows, LevelRuntime, tutorial trio
lib/generator.dart   candidate sculptures, sampled metrics, rejection sampling
lib/levels.g.dart    GENERATED — 36 curated levels
lib/main.dart        the ugly M0 UI: drag-rotate, two wall panels, hinge slider
tool/gen_levels.dart run by hand to regenerate levels.g.dart
tool/probe.dart      scratch experiment: hill-climb difficulty. Negative result, kept
test/geom_test.dart  10 tests
```

**Design rule worth not re-deriving:** levels are authored as a **solved pose**, and the target
silhouettes are derived from it. Every level is therefore solvable by construction, generation is
nearly free, and two tests assert exactly that.

---

## What comes next, in order

| # | Work | Hours |
|---|---|---|
| 1 | **Corner + lighting** — real perpendicular walls, soft shadow falloff, spotlight cone, dust motes. The Shadowmatic atmosphere, procedurally. Biggest payoff per hour | ~8 |
| 2 | **Level map + stars + next button** — chapters, three stars on *precision* not speed, progression persistence | ~6 |
| 3 | **RevenueCat** — one-time chapter unlock, designed as an in-world transition rather than a modal | ~5 |
| 4 | **Ship** — icon, in-app screenshots (Guideline 2.3.3, literal captures only), privacy policy, submission | ~5 |
| 5 | **Submission craft** — demo video + per-category write-ups | ~6 |

> Shipaton's judging page: *"Categories must be explicitly addressed in both video and written
> submission to be judged."* The write-ups are build work, not paperwork.

**The scope rule that protects the deadline:** ship a small, complete, beautiful thing. A finished
gallery can place; a clever engine full of placeholder puzzles cannot.
