## Inspiration

I wanted to know whether you could make a puzzle out of *disagreement*.

Shadow puzzles usually ask one question: turn the object until its outline matches the picture. One shadow, one answer, and the main skill is patience. Shadowmatic has done that beautifully for ten years.

So I added a second light — and with it a second shadow, which has to be true at the same time. Now the object can't just be turned until something looks right. Every rotation that fixes the left wall breaks the back wall. You have to reason your way to a pose that satisfies both, then go there.

That tension is the whole game, and the entire build was a bet on one question: is it actually interesting, or just annoying?

## What it does

A sculpture of hinged low-poly arms hangs in the corner where two perpendicular walls meet, lit from two directions. Each wall shows a target silhouette. You drag to rotate the form and bend it at its joints. The room is solved when **both** cast shadows match their targets at once.

No words. No timer. No hints for the first minute.

- **47 rooms across five chapters** — Rotation, The Joint, Two Joints, Forms, Silhouettes. The opening four are hand-authored so a new player's first minutes are designed rather than sampled.
- **Endless mode** — rooms generated on the device, numbered from 1, running as deep as you want to go. Room 340 is the same room for everyone, so a depth is a claim you can check.
- **A daily room** — one puzzle a day, the same one for every player.
- **Stars on precision, not speed.** A timer would turn a contemplative puzzle into a twitch one.

## How I built it

Flutter 3.44.8 / Dart 3.12.2, no game engine. The geometry is hand-rolled:

- **Meshes** — every piece is a triangle mesh. Lathed forms, extruded prisms and unions, built by ear clipping. (This replaced an earlier convex-hull approach, which could not represent anything concave — no ducks, no moths.)
- **Projection** — vertices rotate into world space and project onto two perpendicular planes. Two axis-aligned lights make wall A's shadow `(z,y)` and wall B's `(x,y)`, which is what keeps the two constraints genuinely independent.
- **Scoring** — intersection-over-union against the target on a 64×64 occupancy raster, thresholded at 0.92.
- **Latching** — a solve is *entered* at 0.92 but only *given up* below 0.89. Without that gap a finger resting on the glass wanders across the threshold, the chord re-fires and the glow reverses, and the player stops trusting the silhouette they just reasoned out and starts stabilising a number.
- **Determinism** — endless uses a hand-written splitmix64 PRNG, not `dart:math`. `Random`'s algorithm is not contractual, and rooms are generated at runtime on the player's device; an SDK upgrade could otherwise silently change everyone's room 340.
- **Generation off the UI thread** — a hinged room costs about a second to generate on a desktop and several times that on a phone, so endless generates in an isolate and prefetches room N+1 while you play room N.

The decision that made everything else cheap: **rooms are authored as a solved pose, and the target silhouettes are derived from it.** Every room is therefore solvable by construction. 94 tests, including ones that assert every sampled endless room scores 1.0 at its solution and none opens pre-solved.

RevenueCat gates a one-time unlock past the free first chapter. The entitlement check **fails open** — if the store can't be reached, the player keeps what they paid for. An outage should never paywall someone who already bought it.

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

That gap got more expensive when I shipped endless mode, which generates from the same unvalidated bands. It is now the thing a real playtest has to settle, and I can't settle it myself: I know the generator, the solution families and the transformations, so my own solve time measures my familiarity rather than the room's difficulty.

## Accomplishments that I'm proud of

I wrote a **kill gate** before I wrote the game: three questions, a date, and a rule that "maybe" counts as no.

1. Does fixing one shadow actually break the other?
2. Is solving it deduction, or fiddling?
3. Can you read the targets well enough to plan a move?

I passed it seven days early, on the hinge level. The answer to the second question was "deduction — I reasoned about it," which is the answer that justified continuing. *"I wiggled it until it went amber"* would have ended the project there.

## What I learned

That a negative result is worth shipping. Two failed metrics told me more about my own game than a working one would have — mainly that I don't yet know what makes one of these rooms hard, and that no amount of arithmetic substitutes for handing it to a person.

I also learned to distrust a correction that comes from reasoning when the original reading came from evidence. I talked myself out of a build failure's actual cause once, and the next build proved the evidence right.

## What's next for In Two Lights

- **Five naive playtesters**, screen-recorded, with the timestamp marked where they first say *"oh — fixing that one breaks the other."* If that moment lands later than ninety seconds, the opening is wrong and no amount of content further in compensates.
- **Difficulty ordering rebuilt from what they do**, not from an unvalidated number.
- **App Store release.** It's on TestFlight now.
