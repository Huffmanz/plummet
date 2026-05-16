# Feature 01 — Board Engine
*Plummet · Game Jam Build*

## Purpose

The board engine is the foundation of the entire game. Every other feature hooks into it. This feature covers the grid state, dropping pieces, gravity, and detecting clears. No scoring, no AI, no modifiers — just the raw board mechanics.

---

## Scope

- 7×12 grid state
- Piece ownership (player or AI)
- Column drop logic
- Gravity settle
- 4-in-a-row clear detection (horizontal, vertical, diagonal)
- Clear removal

Not in scope: cascade loop (feature 02), scoring (feature 03), modifiers (feature 05).

---

## Data Model

### The grid

The board is a 7-column × 12-row grid. Row 0 is the bottom. Row 11 is the top. Pieces fall downward and stack from row 0 up.

Each cell holds one of three values:

- Empty
- Player piece
- AI piece

### Piece

A piece has:

- Owner (player or AI)
- Type (Normal by default; extended in feature 06)
- Modifier slots (empty by default; extended in feature 05)

---

## Behaviors

### Drop

When a piece is dropped into a column:

1. Find the lowest empty row in that column.
2. If the column is full, the drop is invalid — reject it.
3. Place the piece at that row.
4. Return the landing position.

### Gravity

After any pieces are removed from the board, gravity runs on every column independently:

1. Collect all pieces in the column from bottom to top, ignoring empty cells.
2. Rewrite the column so pieces are packed from row 0 upward, with empty cells above.

Gravity applies to all pieces regardless of owner.

### Clear detection

Scan the board for any run of 4 or more pieces of the same owner in a line. Lines to check:

- Horizontal — across each row
- Vertical — up each column
- Diagonal ascending — bottom-left to top-right
- Diagonal descending — top-left to bottom-right

A clear is a set of cells that form a qualifying run. Return all clears found across both owners.

Rules:
- Only same-owner pieces count toward a clear.
- A cell can be part of multiple clears simultaneously (e.g. a piece at the intersection of a horizontal and vertical run).
- Runs of 5 or 6 are valid — return the full run, not just the first 4.

### Clear removal

Given a set of cleared cells, remove all of them from the board (set to empty). Do not apply gravity here — that is handled by the cascade loop (feature 02).

---

## Interfaces

The board engine should expose the following operations to other systems:

| Operation | Input | Output |
|---|---|---|
| Drop piece | Column index, piece | Success or invalid |
| Apply gravity | — | Updated board state |
| Detect clears | — | List of clear sets (cells + owner) |
| Remove clears | List of clear sets | Updated board state |
| Get cell | Column, row | Cell value |
| Is column full | Column index | Boolean |
| Is board full | — | Boolean |

---

## Edge Cases

- A drop into a full column must be rejected cleanly — this is a valid game state when the board fills late in a match.
- A run of 5 or 6 must return the full matched set, not split into multiple 4s.
- Diagonal detection must not run off the edges of the grid — clamp checks to valid coordinates.
- Gravity must handle columns that are already fully packed (no-op) and fully empty (no-op).
- A cell shared between two clears (e.g. corner of a cross) is removed once, not twice.

---

## Acceptance Criteria

- A piece dropped into column 3 lands at the correct row given existing pieces below it.
- Dropping into a full column returns an invalid result and does not modify the board.
- After pieces are removed, gravity packs all remaining pieces to the bottom of their columns.
- A horizontal run of 4 same-owner pieces is detected correctly.
- A vertical run of 4 same-owner pieces is detected correctly.
- A diagonal run of 4 same-owner pieces (both directions) is detected correctly.
- A run of 5 returns all 5 cells, not just 4.
- A cell at the intersection of two runs appears in both clear sets but is only removed once.
- Mixed-owner pieces in the same line do not trigger a clear.
- An empty board reports no clears.

---

## Dependencies

None. This is the foundation layer.

## Required by

- Feature 02 — Cascade loop
- Feature 03 — Scoring system
- Feature 04 — AI opponent
- Feature 05 — Piece bag + modifiers
- Feature 06 — Piece types
