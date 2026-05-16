# Feature 04 — AI Opponent
*Plummet · Game Jam Build*

## Purpose

The AI opponent drives the enemy side of every match. It consists of a base heuristic that all enemies share, plus a gimmick layer that each individual enemy adds on top. This feature covers the base AI and the turn management system. Individual gimmicks are defined in feature 08.

---

## Scope

- Column-scoring heuristic
- Alternating turn management
- Turn limit tracking and match-end trigger
- Gimmick hook interface (to be implemented in feature 08)
- Piece queue management for the AI

Not in scope: individual enemy gimmicks (feature 08), scoring (feature 03).

---

## Turn Structure

Turns alternate: player, then AI, then player, and so on. Each player has a turn limit of 40 turns (80 total drops). The match ends when both players exhaust their turns, or when the board fills completely.

### Turn sequence (per AI turn)

1. Apply any pre-turn gimmick effects (feature 08 hook).
2. Run the column-scoring heuristic to select a column.
3. Drop the AI's current piece into the selected column.
4. Run the cascade loop.
5. Apply any post-turn gimmick effects (feature 08 hook).
6. Advance the AI's piece queue.
7. Hand control back to the player.

---

## Base Heuristic

The AI scores every valid column and picks the highest. A column is invalid if it is full.

### Column score calculation

For each valid column, simulate dropping the AI's current piece there and evaluate:

| Factor | Score contribution |
|---|---|
| Completes an AI clear of 4 | +1000 |
| Completes an AI clear of 5+ | +1500 |
| Extends an AI line by 1 (toward a future clear) | +100 per piece in that line |
| Blocks a player clear of 4 | +800 |
| Blocks a player clear of 5+ | +1200 |
| Would give the player a clear on their next turn | −500 |
| Column height (prefer lower columns for flexibility) | −10 per row above halfway |

The AI picks the column with the highest total score. On ties, pick randomly among tied columns.

### Look-ahead

The base heuristic is one-ply — it evaluates only the immediate result of each drop, not future turns. This is intentional for the jam build. It produces a competent opponent without expensive computation.

---

## Piece Queue

The AI maintains a queue of upcoming pieces, identical in structure to the player's queue (feature 05). The AI's queue is hidden from the player.

The AI always knows its next 2 pieces and may factor them into column selection. For the base heuristic, only the current piece needs to be considered.

---

## Difficulty Scaling

The base heuristic is consistent across all enemies. Difficulty is expressed through gimmicks (feature 08), not through changes to the heuristic weights.

However, the heuristic can have a noise parameter applied per enemy to simulate varying skill levels:

- Low noise (0–5%): near-optimal play, used for act 3 enemies and bosses.
- Medium noise (10–15%): occasionally suboptimal, used for act 1–2 enemies.
- High noise (20%+): visibly imperfect, used only for The Stoic in act 1 to ease players in.

Noise is implemented by occasionally replacing the top-scored column with a random valid column at the specified probability.

---

## Gimmick Hook Interface

Each enemy in feature 08 registers behavior at one or more of the following hooks:

| Hook | When it fires |
|---|---|
| On turn start | Before the AI selects a column |
| On column selected | After heuristic picks a column, before the drop |
| On piece landed | After the AI piece lands, before the cascade loop |
| On cascade complete | After the cascade loop finishes |
| On player turn start | At the start of the player's turn |
| On player piece landed | After the player drops, before the cascade loop |

Hooks receive the current board state and may modify it, modify the selected column, inject additional pieces, or apply board transformations.

---

## Match End

Track turns taken by each player. When both reach 40 turns, trigger match end and pass control to the scoring system for final comparison. If the board fills before the turn limit, also trigger match end immediately.

---

## Edge Cases

- If all columns are full on the AI's turn, the AI skips its turn and match end is triggered.
- The AI must never drop into an invalid column — validate before every drop.
- Noise should not cause the AI to drop into a full column — only sample from valid columns.
- If the heuristic produces equal scores for all columns, the AI picks randomly.

---

## Acceptance Criteria

- The AI takes turns correctly after the player in strict alternation.
- The AI always completes an immediate 4-in-a-row if one is available.
- The AI always blocks an immediate player 4-in-a-row if completing its own is not possible.
- With high noise applied, the AI occasionally makes visibly suboptimal choices.
- The match ends exactly when both players reach 40 turns.
- The match ends early if the board fills completely.
- The gimmick hooks fire at the correct points in the turn sequence.

---

## Dependencies

- Feature 01 — Board engine
- Feature 02 — Cascade loop
- Feature 03 — Scoring system

## Required by

- Feature 08 — Enemy gimmicks
- Feature 09 — Run loop
