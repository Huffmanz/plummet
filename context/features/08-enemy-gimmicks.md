# Feature 08 — Enemy Gimmicks
*Plummet · Game Jam Build*

## Purpose

Each enemy modifies one rule about the shared board. Gimmicks are layered on top of the base AI (feature 04) using the hook interface defined there. The escalation across acts is mechanical strangeness, not harder AI.

---

## Scope

All 9 enemies and their gimmick definitions. Each gimmick is described as a set of hooks that register into the AI turn sequence.

---

## Gimmick Design Principles

- Each gimmick modifies exactly one rule or board behavior.
- Gimmicks must be readable — the player should be able to understand what just happened.
- Gimmicks should interact interestingly with piece modifiers without requiring knowledge of them to function.
- Bosses may have gimmicks with broader scope than regular enemies.

---

## Act 1 Enemies

### The Stoic
**Type:** Regular

No gimmick. Standard base AI with medium noise (10–15%). Acts as the tutorial opponent — the player learns the board geometry before things get strange.

Hook registrations: none.

---

### The Blocker
**Type:** Regular

Every 5 turns (counting total drops by both players), The Blocker freezes the column the player last dropped into for 2 turns. A frozen column cannot receive any drops from either player. The freeze counter is per-column and does not stack — freezing an already-frozen column resets its timer to 2 turns.

Hook registrations:
- On player piece landed: record the column. If 5 turns have elapsed since last freeze, freeze that column for 2 turns.
- On turn start (both players): decrement freeze counters. Unfreeze columns that reach 0.

UI requirement: frozen columns must be visually marked so the player can see which columns are unavailable.

---

## Act 2 Enemies

### The Gravedigger
**Type:** Regular

Cleared pieces do not vanish — they sink to the bottom row of their column as grey locked cells. Locked cells cannot be cleared, cannot be moved by gravity or modifiers (except Volatile explosions do not remove them), and count as occupied for the purpose of drops and gravity.

Hook registrations:
- On cascade complete: for every cleared cell, place a locked cell at row 0 of that cell's column (pushing existing pieces upward if needed — if the column is full, the locked cell cannot be placed and is discarded).

Note: locked cells accumulate over the match. Late-game boards become increasingly constrained. This is intentional.

---

### The Architect
**Type:** Regular

The Architect only scores clears of 5 or more pieces. It ignores any 4-in-a-row opportunities, playing instead for longer lines. It scores double points for any clear it makes (to compensate for the constraint).

Hook registrations:
- On column selected: override the heuristic's column scoring to weight 5+ line setups at ×3 and ignore 4-in-a-row completions entirely.

Design note: The Architect plays slowly and is not threatening early in the match. If ignored, it builds devastating chains. The player must decide whether to disrupt it or out-score it.

---

## Act 1 Boss

### The Mirror
**Type:** Boss

The Mirror copies the modifier on the player's last-played piece onto its own next piece. If the player's last piece had no modifiers, The Mirror plays normally. If the player's piece had multiple modifiers, The Mirror copies the first one only.

Hook registrations:
- On player piece landed: record the first modifier on the piece that just landed (if any).
- On turn start (AI): attach the recorded modifier to the AI's next piece before it plays.

Design note: The Mirror punishes highly-specialized single-modifier builds. A player running heavy Volatile combos will find The Mirror using Volatile against them. Forces the player to vary their bag.

---

## Act 3 Enemies

### The Painter
**Type:** Regular

Every 6 turns, The Painter recolors a 2×2 area of the board to whichever color it needs most for its next clear. Recoloring changes the owner of those cells. The Painter selects the 2×2 area that maximizes its own line-completion potential.

Hook registrations:
- On turn start (AI): if 6 turns have elapsed since last paint, select the optimal 2×2 area, recolor those cells to AI ownership, and reset the counter.

UI requirement: recolored cells should flash briefly to indicate the change.

---

### The Shifter
**Type:** Regular

After every 8 total drops, The Shifter slides all board contents one column in a direction it chooses (left or right). Pieces that would slide off the edge of the board are discarded. Empty columns created on the opposite side remain empty.

Hook registrations:
- On cascade complete: if 8 drops have elapsed, choose slide direction (prefer the direction that disrupts the player's longest line), apply the slide, reset the counter.

---

## Act 2 Boss

### The Inverter
**Type:** Boss

Once per match, The Inverter flips the entire board upside down. Gravity reverses for 3 turns — all pieces fall upward and stack against the ceiling. After 3 turns, gravity returns to normal and all pieces fall back down, triggering a cascade check.

Hook registrations:
- On turn start (AI): if the Inverter has not yet used its flip and the AI's score is trailing by more than 200 points, trigger the flip. Apply reversed gravity for the next 3 turns. After 3 turns, restore normal gravity and run the cascade loop on the resulting board state.

Design note: The Inverter is a comeback mechanic for the AI. The player should learn to recognize the conditions that trigger it and try to avoid falling behind by 200+ points.

---

## Act 3 Boss (Final)

### The Hoarder
**Type:** Boss

The Hoarder earns double points but only from clears where every piece in the cleared line is its own color. Any clear that includes a player piece in the line scores nothing. This incentivizes The Hoarder to keep its lines pure — and incentivizes the player to pollute them.

Hook registrations:
- On cascade complete: before scoring, check each AI clear. If any cell in the cleared set is player-owned, that clear scores 0. If the clear is purely AI-owned, award double points.

Design note: The Hoarder is the final test of the shared board concept. The player must actively disrupt the AI's lines rather than focusing purely on their own combos. It rewards the player who has mastered reading both sides of the board.

---

## Enemy Roster Summary

| Enemy | Act | Gimmick summary |
|---|---|---|
| The Stoic | 1 | No gimmick. Medium noise AI. |
| The Blocker | 1 | Freezes the player's last column every 5 turns for 2 turns. |
| The Gravedigger | 2 | Cleared pieces become locked cells at the column bottom. |
| The Architect | 2 | Only scores 5+ clears. Double points for those clears. |
| The Mirror | Boss 1 | Copies the player's last modifier onto its next piece. |
| The Painter | 3 | Recolors a 2×2 area to its color every 6 turns. |
| The Shifter | 3 | Slides the entire board left or right every 8 drops. |
| The Inverter | Boss 2 | Flips gravity once per match when trailing by 200+ points. |
| The Hoarder | Boss 3 | Double points only for pure-color clears. |

---

## Edge Cases

- The Blocker freezing a column that the player needs: the player may not drop there even if it would complete a clear. Plan around it.
- The Gravedigger filling the bottom row completely: subsequent locked cells from that column are discarded. The board becomes increasingly hostile.
- The Painter recoloring a cell that the player needed for a clear: the clear no longer qualifies. No compensation.
- The Shifter discarding pieces off the edge: these pieces are simply gone — no scoring, no cascade from them.
- The Inverter triggering during the player's turn: the flip happens on the AI's turn start, so the player always completes their turn before the board flips.
- The Hoarder mixed-cell clear scoring 0: this applies even if the AI had 6 of its own pieces and 1 player piece in a 7-cell run. Purity is all-or-nothing.

---

## Acceptance Criteria

- The Stoic plays without any board modifications.
- The Blocker correctly freezes and unfreezes columns on the right turns.
- The Gravedigger places a locked cell at the bottom of every cleared column.
- The Architect never completes a 4-in-a-row — it only clears on 5+.
- The Mirror correctly attaches the player's last modifier to its next piece.
- The Painter recolors a 2×2 area every 6 turns.
- The Shifter slides the board every 8 drops.
- The Inverter triggers only once per match and only when trailing by 200+.
- The Hoarder scores 0 for any mixed-color clear and double for pure clears.

---

## Dependencies

- Feature 04 — AI opponent (gimmick hook interface)

## Required by

- Feature 09 — Run loop (enemy selection per act)
