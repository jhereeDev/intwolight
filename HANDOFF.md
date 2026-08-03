# TWO SUNS — Handoff

**Written 2026-08-03, end of the first working session, on the `Jhere` PC.**
Read this before touching anything. It is the fastest way back into context.

---

## 🔴 Do this first, next session

**1. App Store Connect → Agreements, Tax, and Banking → is *Paid Applications* ACTIVE?**
(15 min. Unstarted all day.)

Shipaton requires the RevenueCat SDK to power **at least one real in-app purchase**.
RevenueCat Ads does not satisfy it — it is public beta, is a revenue-*tracking* layer
rather than a purchase mechanism, and has no documented Flutter support.

**No agreement → no IAP → no valid entry, for any app.** Every hour spent on levels,
lighting or polish is conditional on this answer. One hour to find out the plan is dead
beats forty.

**2. Play generated levels 1, 6 and 12 and say whether difficulty actually rises.** (10 min.)
There is **no validated difficulty metric** — two were tried and both failed (see below).
You are the only ground truth available, and this decides whether the curve needs work.

---

## What this is

A wordless spatial-deduction puzzle. An abstract sculpture of hinged low-poly arms hangs in
the corner where two perpendicular walls meet, lit by two sources. A level is solved when
**both** cast shadows match their target silhouettes at once — adjusting the form to fix one
shadow breaks the other, and that tension is the puzzle.

**Shipaton 2026 entry.** Target: **Best Game Award** (primary) and **Design Award**
(secondary) — the only two traction-free cash categories on the board. Submissions close
**2026-09-30**.

Full reasoning, including the six candidates that were killed to get here, is in the AIOS at
`jhere-dev/decisions/log.md` (2026-08-03) and `jhere-dev/projects/two-suns/`.

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
| **RevenueCat** | ❌ **not integrated** — M3, and blocked on the agreement above |
| **CI** | ❌ **none.** See "known debt" |
| Design pass | ❌ M0 UI is deliberately ugly — three flat panels and two numbers |
| Progression / stars / map | ❌ not started |

---

## Setting up on another machine

```bash
git clone git@github.com-personal:jhereeDev/2sun.git two-suns
cd two-suns
```

### ⚠️ The trap: Flutter's location is machine-specific and it is NOT on PATH

**Find it, do not assume it.**

| Machine | Path |
|---|---|
| `Jhere` PC | `C:/flutter` |
| Laptop (per `flame-minis/CLAUDE.md`) | `D:\flutter` — **verify, that note may be stale** |

```bash
# Git Bash
export PATH="/c/flutter/bin:$PATH"
# PowerShell
$env:PATH = "C:\flutter\bin;$env:PATH"
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

```bash
flutter devices
flutter emulators                              # a Pixel_10_Pro AVD exists on the PC
flutter emulators --launch Pixel_10_Pro        # laptop may need one created
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
