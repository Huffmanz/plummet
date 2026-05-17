# Feature 05 — Piece Bag + Modifiers
*Plummet · Game Jam Build*

## Purpose

The piece bag and modifier system is the core roguelike mechanic. The player builds a bag of 7 (make configurable) pieces between matches, attaching modifiers that stack and interact. This is where combos are designed. The payoff happens on the board.

---

## Scope

- Piece bag of 7 (configurable), cycling through the match
- Modifier attachment (up to 3 per piece)
- All 6 modifiers and their resolution logic
- Modifier resolution order
- Piece queue display (next 2 pieces visible)

Not in scope: piece types (feature 06), shop UI for attaching modifiers (feature 07).

---

## The Piece Bag

Each player has a bag of 7 pieces. The bag cycles in order — when the last piece is played, the bag resets to the first. The bag persists across the match; it does not reshuffle each cycle.

The player's next 2 pieces are always visible. The AI's queue is hidden.

At the start of a run, the player's bag contains 7 Normal pieces with no modifiers attached.

---

## Modifiers

Modifiers attach to individual pieces. Each piece can hold up to 3 modifiers. Modifiers are acquired in the shop (feature 07) and persist in the bag between matches within a run.

### Resolution order

When a piece is dropped, modifiers resolve in this order:

1. **Landing effects** — trigger immediately when the piece contacts its landing position (before the cascade loop runs).
2. **Clear effects** — trigger when this piece is part of a clear (during the cascade loop, after clear detection but before removal).

If a piece has multiple modifiers of the same type, they each resolve individually in the order they were attached.

---

## Modifier Definitions

### Heavy
**Type:** Landing effect

On landing, the piece directly below the dropped piece is pushed down one additional row. If that piece cannot move down (it is at row 0, or the row below is occupied by a piece that cannot move), the effect does nothing.

Synergy: Two Heavy pieces in sequence can chain — the second Heavy pushes the piece the first Heavy already displaced.

---

### Magnet
**Type:** Landing effect

On landing, the player may select one adjacent piece of their own color (orthogonally adjacent) and slide it one cell horizontally toward this piece. If no eligible adjacent piece exists, the effect does nothing.

The slid piece obeys gravity after moving — if its new position has empty space below it, it falls.

---

### Anchor
**Type:** Passive (gravity exception)

This piece is immune to cascade gravity. When pieces below it are cleared and gravity runs, Anchor pieces stay in their current position. Empty cells below them remain empty until filled by subsequent drops.

Anchor does not prevent the piece itself from being cleared if it forms part of a 4-in-a-row.

---

### Echo
**Type:** Clear effect

When this piece is part of a clear, a copy of this piece (same type, no modifiers) is dropped into the column containing the most opponent pieces at the time of the clear. If multiple columns tie for most opponent pieces, pick the leftmost.

The Echo copy drops after the current clear resolves but before the next cascade round begins.

---

### Volatile
**Type:** Clear effect

When this piece is part of a clear, the 4 orthogonally adjacent cells (up, down, left, right) are also removed from the board, regardless of their owner or content. Locked cells (from The Gravedigger enemy) are not removed by Volatile.

Volatile removal triggers gravity but does not count as a clear for scoring purposes — no points are awarded for the bonus cells removed.

---

### Catalyst
**Type:** Landing effect

The next piece the player drops after this one has all of its own modifiers triggered twice. Each modifier on the next piece fires once normally, then fires again immediately.

Catalyst does not affect the Catalyst piece itself. If the next piece has no modifiers, Catalyst has no effect.

---

## Modifier Interaction Notes

- Echo + Catalyst: the Echo copy drops twice (once per Catalyst trigger), placing two copies.
- Volatile + Catalyst: the explosion radius fires twice — removes orthogonal neighbors, then removes orthogonal neighbors of the original position again (same cells, effectively a no-op unless board state changed between the two triggers).
- Anchor + Heavy: if a Heavy piece lands on top of an Anchor piece, the Heavy's push effect targets the Anchor. The Anchor does not move (it is already placed), so Heavy does nothing.
- Double Drop (feature 06 piece type) + Echo: the second drop also carries the Echo modifier, potentially placing two Echo copies per turn.

---

## Edge Cases

- A piece with 3 modifiers cannot receive a 4th — the shop must not offer attachment to full pieces.
- If Magnet has no adjacent same-color pieces on landing, it silently does nothing.
- If Heavy targets row 0, the push does nothing — the piece is already at the bottom.
- Echo fires even if the clear it belongs to is part of an AI-attributed cascade — the copy is still the player's piece.
- Catalyst only affects the immediately next piece — if the player is interrupted (e.g. by a gimmick), it still applies to the next piece they personally drop.

---

## Acceptance Criteria

- The bag cycles correctly through all 7 pieces and resets after the 7th.
- The next 2 pieces in the queue are correctly displayed.
- A piece with Heavy pushes the piece below it down one row on landing.
- A piece with Magnet slides an adjacent same-color piece toward it on landing.
- An Anchor piece does not move when gravity runs after a clear below it.
- An Echo piece drops a copy into the correct column on clear.
- A Volatile piece removes its 4 orthogonal neighbors on clear.
- Catalyst causes the next piece's modifiers to fire twice.
- No piece can hold more than 3 modifiers.

---

## Dependencies

- Feature 01 — Board engine
- Feature 02 — Cascade loop (modifier hooks)

## Required by

- Feature 06 — Piece types
- Feature 07 — Shop
