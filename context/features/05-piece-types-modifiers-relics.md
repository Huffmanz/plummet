# Feature 05 — Piece Types, Modifiers & Relics
*Plummet · Game Jam Build — replaces previous Feature 05 and Feature 06*

## Overview

Three distinct progression layers, each with a clear job:

| Layer | Job | Found |
|---|---|---|
| **Piece types** | Passive identity — what this piece *is* | Shop upgrades |
| **Modifiers** | Active effects on land or clear | Shop offerings |
| **Relics** | Run-wide passive benefits | Shop + boss drops |

One modifier per piece maximum. Piece type and modifier are independent — any type can hold any modifier.

---

## Piece Types

Piece types define the passive scoring identity of a piece. They do not change drop or gravity behavior — all pieces fall and stack identically. Types affect what happens when the piece is involved in a clear or scores points.

### Normal
**Passive:** None. Baseline piece.
**Shader:** Solid flat fill, no effects.
**Notes:** All pieces in the starting bag are Normal. The reference point everything else is balanced against.

---

### Prism
**Passive:** When this piece is part of a clear, double the base point value of that clear (before multipliers).
**Shader:** Rainbow light dispersion — white core with spectral color bands refracting outward. Rotates slowly.
**Notes:** Stacks with cascade multipliers (double base, then apply multiplier).

---

### Coin
**Passive:** When this piece is part of a clear, earn +3 chips in addition to normal chip earnings.
**Shader:** Metallic gold with a spinning coin shimmer. Specular highlight sweeps across on clear.
**Notes:** Chip bonus applies regardless of clear size. Multiple Coins in the same clear each trigger independently — 2 Coins in one clear = +6 chips.

---

### Ember
**Passive:** When this piece is part of a clear, add +1 to the current cascade depth multiplier for all subsequent clears in this chain.
**Shader:** Smoldering orange-red with a heat shimmer distortion effect around the edges. Glows brighter as cascade depth increases.
**Notes:** Each Ember adds +1 to the clear multiplier (linear: 1 Ember → ×2, 4 Embers → ×4). Ember carry from earlier clears in the chain also adds +1 each to later clears. Cascade combo depth still uses the normal ×2/×4/×8 exponential ladder separately.

---

### Shard
**Passive:** When this piece is part of a clear, it shatters — removing itself and the two pieces directly above it from the board (regardless of owner). The removed pieces do not score and do not trigger clears.
**Shader:** Fractured crystal with internal cracks visible. On clear, shatters into fragments with a burst particle effect.
**Notes:** Shard's removal can expose pieces beneath them, potentially setting up cascades. The two pieces removed above do not count as cleared — they dissolve away visually. If fewer than two pieces exist above, only those present are removed.

---

## Modifiers

Modifiers attach to individual pieces (one per piece). They trigger on a specific event — landing or clearing — and produce a scoring or board effect. Modifiers are visually represented as a single colored badge on the piece.

### Landing modifiers

These trigger the moment the piece contacts its resting position, before the cascade loop runs.

---

#### Magnet
**Trigger:** On landing
**Effect:** The nearest piece of your color in the same row (left or right) slides one cell toward this piece. If it lands adjacent, a clear check is triggered immediately.
**Badge:** Blue horseshoe icon
**Notes:** Only moves one piece. If two pieces are equidistant, move the leftmost. The slid piece obeys gravity after moving — if its column now has a gap below it (from a previous clear), it falls.

---

#### Deposit
**Trigger:** On landing
**Effect:** Earn +5 chips immediately on landing, regardless of whether this piece clears.
**Badge:** Gold coin stack icon
**Synergy:** Pairs well with Coin piece type — Deposit earns chips on land, Coin earns chips on clear.
**Notes:** Chips are deposited even if the piece never clears during the match.

---

#### Ripple
**Trigger:** On landing
**Effect:** Each piece orthogonally adjacent to the landing cell is pushed one cell farther away from the landing position (left, right, up, or down) if that destination is empty. Gravity runs afterward.
**Badge:** Teal wave icon
**Notes:** Blocked if the push destination is occupied or off the board. The pushed pieces retain their type and modifier.

---

### Clear modifiers

These trigger when the piece is part of a clear, after the clear is detected but before pieces are removed.

---

#### Echo
**Trigger:** On clear
**Effect:** A copy of this piece (same type, no modifier) is dropped into the column with the fewest total pieces at the time of the clear.
**Badge:** Purple double-ring icon
**Synergy:** Echo + Prism type = the copy also doubles clear values when it eventually clears.
**Notes:** The copy drops after the current clear resolves, before the next cascade round. If multiple columns tie for fewest pieces, choose the leftmost.

---

#### Detonate
**Trigger:** On clear
**Effect:** Removes all pieces in the same row as this piece (both colors). Removed pieces do not score. Triggers gravity and a cascade check after removal.
**Badge:** Orange explosion burst icon
**Notes:** Detonate clears an entire row — powerful for disruption but removes your own pieces too. Best used in rows where the opponent has more pieces than you. Non-matched pieces in the row dissolve away visually; matched cells still use the normal clear animation.

---

#### Bounty
**Trigger:** On clear
**Effect:** For each opponent piece in the same row as this piece at the moment of clear, earn +10 points.
**Badge:** Green target reticle icon
**Synergy:** Strong with Detonate on an adjacent piece — Bounty scores for opponent pieces, then Detonate removes them.
**Notes:** Bounty counts opponent pieces in the full row, not just the cleared line. Rewards dropping into contested rows.

---

#### Ignite
**Trigger:** On clear
**Effect:** When this piece is part of a clear, each cell in that line beyond the first four (5th, 6th, etc.) earns a flat +100 bonus on top of normal scoring.
**Badge:** Red flame icon
**Notes:** A 5-in-a-row with Ignite earns +100 extra; a 6-in-a-row earns +200. The first four cells score normally (including length-based base value for 5+ lines).

---

#### Surge
**Trigger:** On clear
**Effect:** Earn chips equal to the length of the cleared line (4-in-a-row = +4 chips, 5-in-a-row = +5 chips, etc.) when this piece is part of that clear.
**Badge:** Yellow lightning bolt icon
**Notes:** Chips are awarded on top of normal clear scoring. Multiple Surge pieces in the same line still pay out once per clear.

---

## Relics

Relics are run-wide passive items that persist for the entire run once acquired. They reduce difficulty or improve run navigation — they do not directly improve scoring the way piece types and modifiers do. A player can hold up to 4 relics simultaneously.

Relics are found two ways:
- **Boss drops:** one relic offered as a free reward after each boss fight (choose 1 of 2)
- **Shop:** one relic available for purchase each shop visit (25 chips)

### Relic list

---

#### Compass
**Effect:** At the start of each match, reveal the enemy's gimmick and their first 3 planned moves (columns they will play).
**Rarity:** Common
**Source:** Shop
**Notes:** Removes the information asymmetry of the early turns. Lets the player set up a counter-strategy before the AI has established a pattern.

---

#### Cushion
**Effect:** Once per run, a match loss is ignored — the run continues as if you won (you skip the shop for that match).
**Rarity:** Uncommon
**Source:** Boss drop
**Notes:** Safety net for a single mistake. Does not award chips or open the shop. Consumed on use — cannot be stacked.

---

#### Almanac
**Effect:** The shop always shows 4 modifier offers instead of 3.
**Rarity:** Common
**Source:** Shop
**Notes:** Improves the odds of seeing the modifier you want each visit. Simple, reliable, always useful.

---

#### Forge
**Effect:** Once per shop visit, you may upgrade one piece type for free (the chip cost is waived).
**Rarity:** Uncommon
**Source:** Shop
**Notes:** Accelerates bag development. Pairs especially well with early runs where chips are scarce.

---

#### Lens
**Effect:** Before each match, see the board layout after the first 4 AI drops (a preview of their opening).
**Rarity:** Common
**Source:** Shop
**Notes:** Tactical advantage in the opening turns. Lets you anticipate column threats before they develop.

---

#### Stockpile
**Effect:** Chip earnings from clears are doubled (1 chip per clear becomes 2).
**Rarity:** Common
**Source:** Shop
**Notes:** Compounds over a run — more chips means more shop actions, means a stronger bag. Best acquired early.

---

#### Patron
**Effect:** The shop's relic slot is free once per run (the 25 chip cost is waived for one relic purchase).
**Rarity:** Uncommon
**Source:** Boss drop
**Notes:** Effectively a free relic. Most useful for acquiring an expensive relic you could not otherwise afford mid-run.

---

#### Echo Chamber
**Effect:** Any piece with the Echo modifier drops 2 copies instead of 1.
**Rarity:** Rare
**Source:** Boss drop
**Notes:** Only useful if you have at least one Echo-modified piece. Transforms Echo from a chip-in to a board-flooding engine.

---

#### Momentum
**Effect:** Each consecutive match win increases your starting score for the next match by 50 points.
**Rarity:** Uncommon
**Source:** Shop
**Notes:** Rewards win streaks. A 3-match streak enters the 4th match already up 150 points. Resets to 0 on any loss.

---

#### Cartographer
**Effect:** After each act, choose which enemy you face first in the next act (instead of the fixed order).
**Rarity:** Rare
**Source:** Boss drop
**Notes:** Run navigation relic. Lets you avoid a bad matchup for your current build, or seek out a favorable one. Does not change which enemies appear — only the order.

---

## Balancing Notes

**Piece type interaction priority:** Prism doubles base value before cascade multipliers apply. Ember adds to the cascade depth counter. Coin and Deposit are purely additive chip generators. Shard is the only type with a board-altering effect.

**Modifier interaction priority:** Landing modifiers (Magnet, Deposit, Ripple) resolve before the cascade loop starts. Clear modifiers (Echo, Detonate, Bounty, Ignite, Surge) resolve after clear detection, before removal.

**Relic acquisition rate:** A full run (3 acts, 3 boss fights) yields 3 free boss-drop relics. Shop relics are available every won match — roughly 6–8 shop visits per full run at 25 chips each. Expect a well-played run to end with 3–5 relics total.

**Chip economy with new types:** Coin and Deposit generate chips from gameplay rather than just match wins. Adjust base chip earnings if playtesting shows the shop becoming trivially affordable — consider reducing win-bonus chips from 15 to 10 to compensate.

---

## Acceptance Criteria

**Piece types**
- Normal piece scores base value with no modification.
- Prism doubles base clear value; multiple Prisms in one clear do not stack.
- Coin awards +3 chips per clear; multiple Coins in one clear each award independently.
- Ember adds +1 to cascade depth for subsequent clears; multiple Embers stack.
- Shard removes itself and the two pieces above on clear; missing pieces above are handled gracefully.

**Modifiers**
- Ignite awards +100 per cell cleared beyond four in the same line.
- Magnet slides the nearest same-color row piece toward itself and triggers a clear check.
- Deposit awards +5 chips on landing every time.
- Ripple pushes orthogonal neighbors one cell away on landing when the destination is empty.
- Echo drops a copy into the column with fewest pieces on clear.
- Detonate removes the entire row on clear.
- Bounty scores +10 per opponent piece in the row on clear.
- Surge awards chips equal to the cleared line length when the Surge piece is in that clear.

**Relics**
- Cushion correctly absorbs one loss and is consumed.
- Almanac consistently shows 4 offers in the shop.
- Stockpile doubles per-clear chip earnings throughout the run.
- Echo Chamber correctly causes Echo to drop 2 copies instead of 1.
- Momentum correctly tracks win streak and applies starting score bonus.
- Cartographer correctly allows enemy order selection at act transitions.

---

## Dependencies

- Feature 01 — Board engine
- Feature 02 — Cascade loop (modifier resolution hooks)
- Feature 03 — Scoring system (piece type value modifications)
- Feature 07 — Shop (acquisition of types, modifiers, relics)
- Feature 09 — Run loop (relic persistence, boss drop trigger)

## Required by

- Feature 07 — Shop
- Feature 08 — Enemy gimmicks (some gimmicks interact with piece types)
- Feature 11 — Animations + juice (shader identities per type)
- Feature 12 — Visual layer (badge rendering, shader definitions)
