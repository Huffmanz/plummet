# Feature 06 — Piece Types
*Plummet · Game Jam Build*

## Purpose

Piece types give individual pieces distinct physical behaviors beyond the standard drop-and-stack. They are the second axis of piece customization alongside modifiers, and are upgraded through the shop.

---

## Scope

- Normal piece (baseline)
- Weighted piece
- Ghost piece
- Volatile piece type (distinct from the Volatile modifier)

Not in scope: modifier attachment (feature 05), shop upgrade UI (feature 07).

---

## Piece Type Definitions

### Normal
The default piece type. Drops straight down, lands on the first occupied cell or the board floor, and obeys standard gravity. No special behavior.

All pieces in the starting bag are Normal.

---

### Weighted
**When available:** Act 1 shop

On landing, the Weighted piece pushes the piece directly below it down one additional row before settling.

Resolution:
1. The Weighted piece falls to its normal landing position.
2. The piece directly below it (if one exists) is displaced downward by one row.
3. If the row below that piece is occupied or is the board floor, the displaced piece cannot move and the effect does nothing.
4. After displacement, the Weighted piece settles into the position vacated by the displaced piece.

Chaining: if a Weighted piece is displaced by another Weighted piece landing on top of it, the chain continues — each Weighted piece pushes the next one down.

---

### Ghost
**When available:** Unlocked via meta-progression (30 fragments); available in shop from act 2 onward

On drop, the Ghost piece passes through one piece it encounters on the way down, landing beneath it.

Resolution:
1. The Ghost piece begins falling from the top of the column.
2. When it reaches a piece, it passes through it and continues falling.
3. It passes through exactly one piece, then behaves normally — landing on the next occupied cell or board floor below.
4. The piece it passed through remains in its original position.

If the first cell below the top is empty all the way to the floor, the Ghost piece behaves identically to Normal.

Ghost pieces obey standard gravity after landing.

---

### Volatile (piece type)
**When available:** Act 2 shop

When a Volatile piece is part of a clear, it explodes — removing the 8 surrounding cells (the full Moore neighborhood: orthogonal and diagonal neighbors) regardless of owner or content.

This is a larger explosion than the Volatile modifier (which only removes 4 orthogonal neighbors). The piece type and modifier stack: a Volatile piece type with a Volatile modifier removes all 8 neighbors plus the 4 orthogonal neighbors of the original position (effectively a 3×3 area plus a cross).

Locked cells (from The Gravedigger enemy) are not removed by explosions.

Explosion removal triggers gravity but does not award points for the bonus cells removed.

---

## Piece Type + Modifier Interactions

| Piece type | Modifier | Interaction |
|---|---|---|
| Weighted | Heavy | Both push effects apply. The Weighted type pushes during the drop; Heavy pushes on landing. Net effect: two separate push events. |
| Weighted | Anchor | The Weighted piece can be pushed by another Weighted piece landing on it, unless it has Anchor — in which case it resists displacement. |
| Ghost | Magnet | Magnet fires on landing (after Ghost has settled). Eligible adjacent pieces are checked from the Ghost's final position, not its pass-through position. |
| Ghost | Echo | Echo fires normally when the Ghost piece clears — the copy is a Normal piece, not a Ghost. |
| Volatile (type) | Volatile (modifier) | The explosion extends to a 3×3 area plus orthogonal cross. See definition above. |

---

## Upgrade Path

In the shop (feature 07), the player can upgrade piece types:

- Normal → Weighted (20 chips)
- Normal → Ghost (20 chips, requires Ghost to be unlocked in meta-progression)

Piece types cannot be downgraded. A Weighted or Ghost piece cannot be converted to the other type — it would need to be replaced entirely (not supported in the jam build).

Volatile pieces are found as shop offerings, not upgrades — the player receives them as a new piece added to the bag, not a conversion of an existing one.

---

## Edge Cases

- Weighted push into a full column base (row 0 occupied, no room to push): the push does nothing, and the Weighted piece still lands normally.
- Ghost passing through the topmost piece in a column that is at row 11 (the board ceiling): the Ghost cannot land — the column is full from the Ghost's perspective. This drop is invalid and must be prevented.
- Volatile explosion at the board edge: neighbors that would fall outside the grid are simply ignored.
- A Ghost piece that passes through an Anchor-modified piece: the Anchor's gravity immunity is not relevant during the pass-through — Anchor only affects gravity, not piece-type interactions during the drop.

---

## Acceptance Criteria

- A Weighted piece displaces the piece below it by one row on landing.
- Two stacked Weighted pieces chain their push effect correctly.
- A Ghost piece lands one row below the first piece it encounters in a column.
- A Ghost piece in an empty column behaves identically to Normal.
- A Volatile piece type removes all 8 surrounding cells on clear, not just the 4 orthogonal ones.
- A Volatile piece type + Volatile modifier removes the combined area correctly.
- A Ghost drop into a column where the topmost occupied cell is row 11 is rejected as invalid.

---

## Dependencies

- Feature 01 — Board engine
- Feature 02 — Cascade loop
- Feature 05 — Piece bag + modifiers

## Required by

- Feature 07 — Shop
