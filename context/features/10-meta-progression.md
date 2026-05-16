# Feature 10 — Meta-Progression
*Plummet · Game Jam Build*

## Purpose

Meta-progression gives players a reason to run again after losing. Fragments earned across runs are spent on permanent unlocks that expand the option pool — new modifiers, piece types, starting bags, enemies, and board variants. Progress expands what you can find in a run, never your starting power.

---

## Scope

- Fragment persistence across runs
- Unlock table and unlock conditions
- Starting bag variants
- Board variants
- Effect on shop pool and enemy roster

Not in scope: Fragment earning (feature 09 — run loop).

---

## Design Principle

Meta-progression expands options, never starting power. No unlock makes the player stronger before the run starts. Every unlock adds something new to find or choose from — a new modifier that can appear in the shop, a new enemy encounter, a new board configuration to play on. The first run and the tenth run start from the same baseline bag of 7 Normal pieces.

---

## Fragment Persistence

Fragments are earned at the end of each run (feature 09) and stored persistently between sessions. They accumulate indefinitely. Spending Fragments on an unlock deducts them from the total.

Display the player's current Fragment total on the main menu and on the unlock screen.

---

## Unlock Table

### Piece types

| Unlock | Cost | Effect |
|---|---|---|
| Ghost piece type | 30 fragments | Ghost becomes available as a shop upgrade from act 2 onward |

### Modifier tiers

Each base modifier has a Tier II version that is a stronger variant. Unlocking a Tier II modifier adds it to the shop pool at a lower appearance weight than base modifiers.

| Unlock | Cost | Tier II effect |
|---|---|---|
| Echo II | 20 fragments | Echo drops 2 copies instead of 1 |
| Magnet II | 20 fragments | Magnet slides up to 2 adjacent same-color pieces (player chooses) |
| Heavy II | 20 fragments | Heavy pushes the piece below down 2 rows instead of 1 |
| Anchor II | 20 fragments | Anchor also prevents the piece from being targeted by Volatile explosions |
| Catalyst II | 20 fragments | Catalyst affects the next 2 pieces instead of just the next 1 |
| Double Drop II | 20 fragments | Double Drop drops a third time after the second (3 total landings per turn) |

### Starting bags

Starting bags are pre-configurations the player can choose at the start of a run. They replace the default 7 Normal pieces with a bag that has 1 modifier pre-attached to one piece. This is the only form of starting advantage — it skips one shop purchase, not more.

| Unlock | Cost | Starting bag |
|---|---|---|
| The Echo Start | 25 fragments | 1 Normal piece has Echo pre-attached |
| The Heavy Start | 25 fragments | 1 Weighted piece in the bag (no modifier) |
| The Ghost Start | 25 fragments | 1 Ghost piece in the bag (requires Ghost unlock) |

### Enemy encounters

Unlocking an enemy adds it to the random match pool for its act.

| Unlock | Cost | Enemy | Act pool |
|---|---|---|---|
| Unlock The Trickster | 15 fragments | Swaps the player's next piece with their 3rd next piece every 4 turns | Act 2 |
| Unlock The Compressor | 15 fragments | Reduces the board height by 1 row every 10 turns (pieces above the new ceiling are removed) | Act 3 |

### Board variants

Board variants change the physical dimensions or gravity of the board. Selected at the start of a run, before the first match. Only one variant can be active per run.

| Unlock | Cost | Effect |
|---|---|---|
| Wide board | 40 fragments | Board is 9 columns × 12 rows instead of 7 × 12 |
| Tall board | 40 fragments | Board is 7 columns × 15 rows instead of 7 × 12 |
| Gravity flip mode | 60 fragments | Every 10 total drops, gravity direction alternates (pieces fall up, then down, alternating) |

---

## Unlock Screen

Accessible from the main menu. Displays:

- Player's current Fragment total
- All unlocks, grouped by category
- Lock/unlock state of each item
- Fragment cost
- A brief description of the effect
- A purchase button for unafforded items (greyed out if insufficient fragments)

Purchases are confirmed immediately — no undo.

---

## Effect on Shop Pool

When a Tier II modifier is unlocked, it is added to the shop's modifier pool with a weight of 0.3× compared to base modifiers. This means base modifiers appear roughly 3× more often than their Tier II equivalents.

Ghost as a shop upgrade option only appears if the Ghost piece type is unlocked in meta-progression.

---

## Effect on Enemy Roster

Unlocked enemy encounters are added to the random selection pool for their designated act. The base roster always appears (The Stoic, Blocker, etc.) — unlocked enemies expand the pool rather than replacing anything.

---

## Edge Cases

- A player who has unlocked Ghost but not the Ghost Starting Bag can still find Ghost as a shop upgrade in a run — the unlock enables it in-run, the starting bag just pre-loads it.
- Board variants are selected at run start and apply to all 12 matches in that run.
- If the player has 0 fragments, the unlock screen is still accessible — they can browse upcoming unlocks.
- Tier II modifiers should never appear in the shop if their base version has not been encountered at least once — gate their appearance weight until the player has seen the base version at least once per run.

---

## Acceptance Criteria

- Fragments accumulate correctly across multiple runs.
- Spending fragments on an unlock deducts the correct amount.
- An unlocked modifier appears in the shop pool (at reduced weight) from the next run onward.
- Ghost becomes available as a shop upgrade after unlocking.
- Starting bags correctly pre-configure the player's bag at run start.
- Board variants correctly change board dimensions or gravity for the full run.
- Unlocked enemies appear in the correct act's random pool.
- The unlock screen correctly shows locked/unlocked state and current fragment total.

---

## Dependencies

- Feature 09 — Run loop (Fragment earning)

## Required by

- Nothing (this is the final feature layer)
