# IN TWO LIGHTS

A wordless spatial-deduction puzzle game for iOS. An abstract sculpture of hinged low-poly boxes
hangs in the corner where two perpendicular walls meet, lit by two sources. A level is solved when
**both** cast shadows simultaneously match their target silhouettes — adjusting the form to fix one
shadow breaks the other, and that tension is the puzzle.

Built by Jhere as a **RevenueCat Shipaton 2026** entry. Orchestrated from the AIOS at
`jhere-dev/projects/in-two-lights/` — read `status.md` there before starting a session.

## ⚠️ Read before running anything

📄 **New machine, or coming back after a gap? Read [`HANDOFF.md`](HANDOFF.md) first.** It carries
setup, the open blockers, and the dead ends worth not re-deriving.

**Flutter is NOT on PATH, and its location differs per machine — find it, don't assume it.**
`C:/flutter` on the `Jhere` PC; `flame-minis/CLAUDE.md` claims `D:\flutter` on the laptop, which
may be stale. **Never hardcode either one.**

```bash
export PATH="/c/flutter/bin:$PATH"       # Git Bash — adjust the drive
$env:PATH = "C:\flutter\bin;$env:PATH"    # PowerShell
```

Required: **Flutter 3.44.8 · Dart 3.12.2 · stable.** Check `flutter --version` before debugging
anything — a version mismatch is the likeliest cause of a mystery build failure.

## Stack

**Plain Flutter + `CustomPainter`. No Flame, no physics engine** — this is turn-based, with no
sprites, no simulation and no game loop. Standard widgets give menus, level select and the paywall
for free.

| Package | Purpose |
|---|---|
| `vector_math` | Matrix4 / Vector3 / Quaternion (ships with Flutter) |
| `clipper2` | Polygon union, intersection, area. **Verify its API in hour 1 of M0.** |
| `purchases_flutter` | RevenueCat — mandatory for Shipaton eligibility |
| `shared_preferences` | Level progress only |

```bash
flutter pub get
flutter run          # attach a REAL device — the simulator lies about feel
flutter analyze
flutter test
flutter build ios --release
```

## The maths

**Shadow of a convex solid = convex hull of its projected vertices.** No occlusion, no face union,
no z-buffer. This is what makes cuboids tractable.

1. Compose hinge rotations + global arcball rotation → 8 world vertices per box.
2. Project along light `L` onto the wall plane: `v + L*t` where `t = (d - n·v)/(n·L)`; convert to
   the wall's 2D basis.
3. Andrew monotone chain over the 8 points → per-box shadow polygon.
4. `clipper2` union of all box hulls → the wall's total shadow.
5. `IoU = area(∩)/area(∪)` against the target. **Solved when both walls ≥ ~0.92** (tune in M0).

The fiddly part is **rendering the solid**, not the shadows: project faces, back-face cull by
`normal·view`, depth-sort by centroid (painter's algorithm), flat-shade by `normal·light`. Correct
at 3–6 boxes; do not generalise beyond that.

## v1 scope

**Core:** rotate + fold a hinged solid until both shadows resolve.
**Done =** six authored levels, RevenueCat one-time unlock, live on the App Store before
**2026-09-30**.

**Out of scope:** Android (Play account is post-2023-11-13 → 12 testers × 14 days), accounts,
backend, PII, ads, subscriptions, hint packs, currency, level editor, non-convex shapes, more than
~6 boxes, sound-driven mechanics, narrative.

## 🔴 The kill gate

**M0, first ~8 hours, decided by 2026-08-10:** build the projection system and **three real
puzzles**. Then answer in writing:

- Does fixing one shadow *actually* break the other, or do most configurations satisfy both?
- Is puzzle 3 genuinely more interesting than puzzle 1, or just fiddlier?
- Can you read the solid on a real phone well enough to plan a move?

> **If the third puzzle is not genuinely interesting: abandon and write down why.**

The gate is discharged by a written continue/kill either way — not by winning.

## The scope rule that protects the deadline

**Ship six excellent levels as a complete product before authoring a seventh.** The mechanic is
~30% of a puzzle game; sequencing, tutorialisation, difficulty curve and removing accidental
solutions are the other 70%. A small finished gallery can place; a clever engine full of
placeholder puzzles cannot.

## Conventions

- No codegen. No `freezed`, no `json_serializable`, no `build_runner` — nothing to break on a
  weekend. (Same rule as `flame-minis` and `kalyedex`.)
- Levels are **authored data**, not procedural. Keep them in one readable list.
- Geometry code stays pure and testable — no widget imports under `lib/geom/`.
- Animate with easing curves, never linear tweens. Haptics on every hinge snap and near-match.
- Store screenshots are **literal in-app captures** (Apple Guideline 2.3.3). Never mockups.
- Commit in small, working increments.

## Testing

`flutter analyze` clean and `flutter test` green before any commit. One unit test on the IoU
scorer with known polygons — a solved state and a near-miss. **Verify M0 by playing on real
hardware**; `kalyedex` was emulator-only and never run on a device, and that is the mistake this
line exists to prevent.
