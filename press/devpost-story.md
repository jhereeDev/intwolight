## Inspiration

I wanted to know whether you could make a puzzle out of *disagreement*.

Shadow puzzles usually ask one question: turn the object until its outline matches the picture. One shadow, one answer, and the main skill is patience. Shadowmatic has done that beautifully for ten years.

So I added a second light — and with it a second shadow, which has to be true at the same time. Now the object can't just be turned until something looks right. Every rotation that fixes the left wall breaks the back wall. You have to reason your way to a pose that satisfies both, then go there.

That tension is the whole game, and the entire build was a bet on one question: is it actually interesting, or just annoying?

## What it does

An abstract sculpture of hinged low-poly arms hangs in the corner where two perpendicular walls meet, lit from two directions. Each wall shows a target silhouette. You drag to rotate the form and bend it at its joints. The level is solved when **both** cast shadows match their targets at once.

No words. No timer. No hints. 36 levels across three chapters, sorted by how many joints the form has.

## How I built it

Flutter 3.44.8 / Dart 3.12.2, no game engine. The geometry is all hand-rolled:

- **Projection** — each box's corners are rotated into world space and projected onto two perpendicular planes.
- **Silhouettes** — a convex hull per box per wall, then every hull is drawn into a single 64×64 occupancy mask, so unions come for free.
- **Scoring** — intersection-over-union between that mask and the target's, thresholded at 0.92.
- **Levels** — a generator samples candidate sculptures, rejection-samples the bad ones, and writes out `levels.g.dart`.

The decision that made everything else cheap: **levels are authored as a solved pose, and the target silhouettes are derived from it.** Every level is therefore solvable by construction. Generating a new one is nearly free, and two tests assert that all 36 score 1.0 at their solution and that none open pre-solved.

## Challenges I ran into

**I built two difficulty metrics and both of them were wrong.**

I'd convinced myself one of my hand-authored levels was under-constrained — that its two shadows agreed across too many poses, so the second light was doing no work. I had inferred that from screenshots, not from playing it.

So I built metrics to catch it: constraint correlation, and a hill-climb findability probe.

| Metric | The level I called bad | The level I knew was good |
|---|---|---|
| Constraint correlation | 0.40 | **0.67** |
| Hill-climb findability | 40% | 35% |

Both ranked it backwards. The correlation metric would have thrown out the single best level in the game.

So I shipped **no difficulty filter at all**. The code is still there, deliberately unused, with a comment explaining why. An unvalidated metric that discards your best work is worse than no metric, and I'd rather carry a known gap than a confident wrong number.

I also dropped a dependency I'd designed around. The original plan used polygon boolean operations for shadow unions. Rasterising to a grid instead removed the dependency entirely, made unions free, and quantises scores at about ±0.01 — far inside the solve threshold.

## Accomplishments that I'm proud of

I wrote a **kill gate** before I wrote the game: three questions, a date, and a rule that "maybe" counts as no.

1. Does fixing one shadow actually break the other?
2. Is solving it deduction, or fiddling?
3. Can you read the targets well enough to plan a move?

I passed it seven days early, on the hinge level. The answer to the second question was "deduction — I reasoned about it," which is the answer that justified continuing. *"I wiggled it until it went amber"* would have ended the project there.

## What I learned

That a negative result is worth shipping. Two failed metrics told me more about my own game than a working one would have — mainly that I don't yet know what makes one of these levels hard, and that no amount of arithmetic substitutes for handing it to a person.

## What's next for In Two Lights

- **Real corner geometry and lighting** — shadow falloff, a spotlight cone, dust in the beam. Right now it's a puzzle; it isn't yet a place.
- **Progression** — a level map, chapters, and stars awarded on precision rather than speed.
- **A one-time chapter unlock through RevenueCat**, designed as an in-world transition rather than a modal.
