# Current Feature — 01: Board Engine

## Status
In Progress

## Goals
- 7×12 (configurable) grid state with cell values: Empty, Player piece, AI piece 
- Drop piece into column (finds lowest empty row, rejects full column)
- Gravity settle after removals (pack pieces to bottom of each column)
- Clear detection: horizontal, vertical, diagonal ascending and descending (4+ same-owner pieces)
- Runs of 5 or 6 return the full run, not just 4
- A cell at the intersection of two clears appears in both sets but is removed once
- Clear removal (sets cells to empty; gravity handled separately by feature 02)

## Notes
- Row 0 is bottom, Row 11 is top — pieces stack from row 0 upward
- Only same-owner pieces count toward a clear
- Diagonal detection must clamp to valid grid coordinates (no out-of-bounds)
- Gravity: no-op on fully packed or fully empty columns
- This is the foundation layer — no scoring, no AI, no cascade loop, no modifiers
- Expose as interface: Drop, Apply Gravity, Detect Clears, Remove Clears, Get Cell, Is Column Full, Is Board Full

## History
