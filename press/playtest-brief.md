# Playtest brief — In Two Lights

**Why this exists.** There is no validated difficulty metric. Two were built and
both ranked backwards against the only human data point; level ordering uses an
`approach` number that has never been checked against a person. The plan for
months was "Jhere plays levels 6, 12 and 13". That is not enough, and the reason
is not effort:

> **You know the generator, the solution families and the transformations. Your
> solve time measures your familiarity, not the level's difficulty.** n=1, and
> that 1 is the author.

Five naive players for twenty minutes each is the cheapest thing that produces a
trustworthy signal. It is also achievable this week: **TestFlight internal
testers need no beta review** — add up to 100 people under Users and Access and
they can install immediately.

---

## Who

Five to eight people who have **never seen the game**. They do not need to be
gamers. They must not be told how it works.

## Setup

1. App Store Connect → Users and Access → add each tester by Apple ID.
2. TestFlight → Internal Testing → add them to the group.
3. Ask them to **screen record** (iOS: Control Centre → Record) and send the file.

## What to say — read this verbatim, then stop talking

> "This is a puzzle game. I'm not going to explain it. Play for about twenty
> minutes and think out loud — say what you're trying and what you expect to
> happen. If you get stuck, stay stuck; that's the useful part. I won't answer
> questions until the end."

**Do not help.** The urge to explain is the single biggest way a playtest is
wasted. Every question they ask that you do not answer is a finding.

## What they play

The opening arc, in order — **1 Tee, 2 Step, 3 Cat, 4 Hinge** — then jump them
to **6, 12 and 13**, which have never been played by anyone.

Counterbalance: half the group plays 6 → 12 → 13, the other half 13 → 12 → 6.
Otherwise learning makes the later ones look easier and you will "discover" a
difficulty curve you actually manufactured.

## What to write down, per level

| Measure | Why |
|---|---|
| Time until **either** wall first crosses 0.92 | how long to get any traction |
| Time until **both** walls first look close | when they found the real constraint |
| Total time to solve, or **gave up** | the headline number |
| Times one wall locked while the other got worse | whether the two-wall tension is landing |
| Resets used | thrashing |
| Did they touch the hinge slider unprompted | whether the joint teaches itself |

## The two questions at the end — these matter more than the timings

1. **"Explain how the puzzle works, as if to a friend."**
   If they describe *rotating until it clicks*, the deduction is not landing and
   the game is a fiddling game. If they describe *fixing one shadow breaking the
   other*, it is working. This single answer separates "slow because thinking"
   from "slow because fighting the controls" — which no metric in the codebase
   can currently tell apart.

2. **"How hard was that, 1–5?"** — asked per level, immediately after it.

## What the results decide

- **Ordering.** Compare their per-level times and 1–5 ratings against the
  `approach` metric recorded in `levels.g.dart`. If the correlation is absent or
  inverted, the campaign order is decoration and should be re-sorted by hand.
- **Whether endless mode ships.** Endless generates from the same accept/reject
  bands. If naive players find generated rooms arbitrary rather than fair, a
  polished doorway into infinite arbitrary rooms is worse than no doorway.
- **Whether the first four minutes work at all** — see below.

## The four-minute test

A competition judge will play for roughly four minutes. Watch the recording and
mark the timestamp where the player first says something like *"oh — fixing that
one breaks the other."*

**If that moment is later than ~90 seconds, the opening is wrong**, and no
amount of content further in will compensate. That number is the single most
important output of this whole exercise.
