# Plummet — Game Design Document
*Version 1.0 · Game Jam Build*

---

## Overview

Plummet is a competitive roguelike puzzle game for one player versus AI. Both players drop colored pieces onto a shared 7×12 board. When four or more of your pieces align in a row, column, or diagonal, they clear — triggering gravity, cascades, and potentially chain reactions across both colors. Matches are score races: most points when the turn limit runs out wins. Between matches, players collect piece modifiers that stack into increasingly broken combos. Runs escalate through three acts of stranger enemies and weirder boards.

**Genre:** Roguelike / competitive puzzle
**Platform:** Web (game jam); desktop (post-jam)
**Target session length:** 25–40 minutes per run

---

## Core Loop

Each turn, a player drops a piece onto the board. If it completes a line of four or more, those pieces clear, gravity settles, and the board is checked again for new clears — for both colors. This cascade loop repeats until the board is stable. When the match ends, the shop opens. After the shop, the next match begins against an escalating enemy. Three acts, each ending in a boss fight, complete a full run.

Losing a run banks **Fragments** proportional to progress. Fragments unlock new modifiers, piece types, and starting bags in future runs. Progression expands options, never starting power.

---

## Board & Match Rules

| Parameter | Value |
|---|---|
| Board size | 7 columns × 12 rows |
| Players | 1 (player) vs 1 (AI), shared board |
| Piece colors | 2 — one per player, always visible |
| Clear condition | 4+ of your color aligned (horizontal, vertical, diagonal) |
| Post-clear gravity | All pieces fall. Both colors checked for new clears. |
| Turn structure | Alternating. Player drops one piece per turn. |
| Turn limit | 40 turns each (80 total drops) |
| Match end | Turn limit reached, or all columns fill |
| Piece queue | Your next 2 pieces shown. Opponent queue hidden. |

### The cascade loop

Every clear triggers the same sequence:

1. Remove matched pieces
2. Apply gravity to all remaining pieces (both colors)
3. Check both colors for new clears
4. If any found, return to step 1
5. Attribution: the player who triggered the original clear owns all cascades from it

This is the most technically critical piece of the engine. Every modifier and enemy gimmick hooks into this loop.

---

## Scoring

Points are scored only by the player whose piece completes the clear. All cascades triggered from your clear are yours — regardless of which color's pieces fall and clear in between.

| Event | Points |
|---|---|
| 4-in-a-row clear | 100 |
| 5-in-a-row clear | 250 |
| 6+ in a row | 500 |
| Cascade clear (each additional level) | ×2 multiplier |
| Cross-color cascade bonus | +150 |
| Simultaneous clears (two of your lines at once) | ×1.5 |
| Piece modifier trigger | +25 per trigger |

### Cross-color cascade bonus

Awarded when: your clear causes opponent pieces to fall and clear, which then causes more of your pieces to fall and clear again. Both players score their respective clears. The original dropper earns the +150 bonus for engineering the chain.

**Example:** You drop a piece completing a 4-in-a-row (+100). The opponent's pieces above fall and complete their own line (they score). Your remaining pieces then fall and complete a second line (+200, cascade ×2). The cross-color chain is detected, awarding an additional +150. Turn total: 450 points.

---

## Piece System

Each player has a **piece bag** of 7 pieces that cycles throughout the match. Pieces have a type and up to 3 attached modifiers. The combo-building happens in the shop between matches — the payoff happens on the board.

### Piece types

| Type | Behavior |
|---|---|
| Normal | Standard piece. Baseline for modifiers. |
| Weighted | Pushes the piece directly below it down one extra row on landing. |
| Volatile | On clearing, removes the 4 orthogonal neighbors regardless of color. |
| Ghost | Passes through one piece on the way down, landing beneath it. |

*Ghost unlocked via meta-progression. Volatile available from act 2.*

### Piece modifiers

Modifiers attach to individual pieces in the bag. Each has both an offensive use (help your clears) and a defensive use (disrupt their board state).

| Modifier | Effect | Key synergy |
|---|---|---|
| **Echo** | On clear, drops a copy into the column with the most opponent pieces | Echo + Catalyst = 2 copies |
| **Magnet** | On landing, slides one adjacent piece of your color one cell toward this piece | Magnet + Weighted = forced alignment |
| **Heavy** | Pushes the piece below it down one extra row | Heavy + Heavy = chain push |
| **Anchor** | Immune to cascade gravity — holds position when pieces below clear | Anchor + diagonal setup = survives multiple cascades |
| **Catalyst** | The next piece played has all its modifiers triggered twice | Catalyst + Volatile = double explosion |
| **Double Drop** | After landing, drops again from row 1 in the same column | Double Drop + Echo = 4 pieces from one turn |

*Modifiers stack up to 3 per piece. Order of modifier resolution: landing effects first, then clear effects.*

---

## Shop

Appears after every match win. Costs paid in **Chips** earned during the match.

### Shop actions (pick one)

- **Add modifier** — choose 1 of 3 offered modifiers, attach to any piece in your bag (10 chips)
- **Upgrade piece type** — Normal → Weighted or Normal → Ghost (20 chips)
- **Remove modifier** — strip a modifier from any piece (5 chips)
- **Reroll** — swap the 3 offered modifiers for 3 new ones (5 chips, once per shop)

### Chip earning

| Event | Chips |
|---|---|
| Win a match | 15 |
| Each clear during the match | 1 |
| Win streak bonus (2+ wins) | +5 per win |
| Losing a match | 0 (skip shop) |

---

## Run Structure

Three acts, each with 3–4 matches plus a boss. Enemy difficulty and board gimmicks escalate each act.

Each act contains 3 regular matches and a boss fight, with a shop available after each won match. Acts escalate in enemy strangeness — act 1 introduces the basic gimmick system, act 2 adds board-altering enemies, act 3 introduces structural chaos before the final boss.

### Enemy roster

Each enemy modifies one rule about the shared board. The escalation is mechanical strangeness, not just harder AI.

| Enemy | Act | Gimmick |
|---|---|---|
| The Stoic | 1 | No gimmick. Standard heuristic AI. Teaches board geometry. |
| The Blocker | 1 | Every 5 turns, freezes the column you last played for 2 turns. |
| The Gravedigger | 2 | Cleared pieces sink to the bottom row as grey immovable cells. |
| The Architect | 2 | Only scores clears of 5+. Plays slowly. Devastating if ignored. |
| The Mirror | Boss 1 | Copies the modifier on your last-played piece onto their next piece. |
| The Painter | 3 | Every 6 turns, recolors a 2×2 area to whichever color they need most. |
| The Shifter | 3 | After every 8 drops, slides all board contents one column left or right. |
| The Inverter | Boss 2 | Once per match, flips the board upside down. Gravity reverses for 3 turns. |
| The Hoarder | Boss 3 (final) | Earns double points but only from clears where all pieces are their own color. Force-pollute their lines. |

---

## Meta-Progression

Losing a run banks Fragments proportional to acts completed. Fragments unlock:

| Unlock | Cost |
|---|---|
| Ghost piece type | 30 fragments |
| Tier II modifiers (stronger versions) | 20 fragments each |
| Alternate starting bag (pre-attach 1 modifier) | 25 fragments |
| New enemy encounters | 15 fragments each |
| Board variant: 8-wide | 40 fragments |
| Board variant: gravity flip mode | 60 fragments |

**Design principle:** meta-progression expands the option pool, never starting power. No modifier is pre-loaded into the bag — you always find it in-run.

---

## 10-Day Build Plan

| Days | Milestone | Cut if needed |
|---|---|---|
| 1–2 | Board engine: drop, gravity, clear detection, cascade loop | — |
| 3 | Basic AI, alternating turns, win/loss state | — |
| 4 | Scoring system: base points, cascade multiplier, cross-color bonus | Cross-color bonus |
| 5–6 | Piece modifier system: bag, modifier resolution, Echo + Heavy + Volatile + Magnet | Catalyst, Double Drop |
| 7 | Run loop: 3-act structure, shop UI, chip economy | Reroll option |
| 8 | Enemy variety: The Blocker + The Gravedigger + The Mirror boss | The Architect, The Painter |
| 9–10 | Juice: clear animations, cascade feel, score popups, sound, run summary screen | Sound |

**Minimum shippable core:** board engine + 3 modifiers + The Blocker + scoring. Everything else is depth.

---

## Open Questions

- **Ownership visibility** — subtle inner ring on your pieces, or full color contrast only?
- **Tie-break** — if scores are equal at turn limit, play sudden-death turns until next clear?
- **Modifier cap** — 3 modifiers per piece feels right; consider a 2-cap for the jam to reduce edge cases
- **AI queue visibility** — keep opponent queue hidden for jam; reveal as an unlock in meta-progression?

---

*Plummet · Game Design Document · v1.0*