# Feature 03 — Scoring System
*Plummet · Game Jam Build*

## Purpose

The scoring system translates cascade loop output into points for each player. It applies base values, cascade multipliers, and bonus conditions. It also maintains live score state for both players throughout the match.

---

## Scope

- Base clear point values
- Cascade depth multiplier
- Simultaneous clear bonus
- Cross-color chain bonus
- Modifier trigger bonus
- Live score tracking for both players
- Match-end score comparison

Not in scope: chip earning for the shop (feature 07), Fragment earning for meta-progression (feature 10).

---

## Point Values

| Event | Points |
|---|---|
| 4-in-a-row clear | 100 |
| 5-in-a-row clear | 250 |
| 6+ in a row | 500 |
| Each additional cascade level | ×2 multiplier on that clear |
| Two of your lines clearing simultaneously | ×1.5 on total for that round |
| Cross-color chain bonus | +150 flat |
| Piece modifier trigger | +25 per trigger |

### Cascade multiplier

The multiplier applies per clear based on its cascade depth:

- Depth 0 (first clear): no multiplier — base value only
- Depth 1: ×2
- Depth 2: ×4
- Depth 3: ×8
- And so on, doubling each level

### Simultaneous clear bonus

If the same player clears two or more lines in the same cascade round (same depth level), the combined point value for that round is multiplied by ×1.5.

### Cross-color chain bonus

A flat +150 awarded to the player who initiated the cascade when the cross-color chain flag is confirmed by the cascade loop. Applied once per cascade chain, not per clear.

---

## Scoring Flow

For each cascade loop completion, the scoring system receives:

- The list of clears (owner, cell count, cascade depth)
- The attribution (which player initiated the cascade)
- The cross-color chain flag
- The count of modifier triggers that occurred

Processing order:

1. For each clear, calculate base value from cell count.
2. Apply cascade depth multiplier.
3. Group clears by owner and depth level. If any owner has 2+ clears at the same depth, apply the simultaneous bonus to their total for that depth.
4. Sum all points per owner.
5. If the cross-color flag is set, add +150 to the initiating player's total.
6. Add +25 per modifier trigger to the appropriate player.
7. Add totals to each player's running score.

---

## Score State

Maintain a score value for each player that persists for the duration of the match. It starts at 0 and accumulates each turn.

Expose:
- Current score for each player
- Score delta from the last turn (useful for displaying popups in feature 11)

---

## Match End

When the match ends (turn limit or board full), compare both players' scores:

- Higher score wins.
- If scores are equal, resolve by sudden death: each player takes one additional turn until a clear occurs, and the player who scores that clear wins.

Return:
- Winner (player or AI)
- Final scores for both players
- Score breakdown by round (for the run summary screen in feature 09)

---

## Edge Cases

- A turn with no clears scores 0 points — valid and common.
- A 6-cell run scores 500, not 100 + 250 — it is a single clear event at the highest bracket.
- The simultaneous bonus applies only if the same player clears two lines in the same depth round. Two lines at different cascade depths do not combine.
- Modifier trigger bonuses apply even if the modifier did not contribute to a clear — any trigger counts.
- Sudden death may require multiple rounds if neither player clears on their extra turn.

---

## Acceptance Criteria

- A single 4-in-a-row at depth 0 scores exactly 100 points.
- A single 4-in-a-row at depth 1 scores exactly 200 points.
- A 5-in-a-row at depth 0 scores exactly 250 points.
- Two simultaneous 4-in-a-row clears at depth 0 score 150 points (100 + 100, then ×1.5).
- A cross-color chain awards exactly +150 to the initiating player.
- Scores accumulate correctly across multiple turns.
- Equal scores at match end trigger sudden death correctly.
- A turn with no clears adds 0 to both scores.

---

## Dependencies

- Feature 01 — Board engine
- Feature 02 — Cascade loop

## Required by

- Feature 04 — AI opponent
- Feature 07 — Shop (chip earning uses match performance)
- Feature 09 — Run loop (run summary screen)
