# Current Feature: Visual Layer

## Status
In Progress

## Goals

- Render all 84 board cells correctly (all empty at match start)
- Player and AI pieces render in distinct colors and are distinguishable without color
- All 4 piece types are visually distinguishable from each other
- All 6 modifier badges render correctly on pieces in the queue and on the board
- Frozen columns display a visible overlay and reject hover/ghost piece rendering
- Locked cells display as distinct from empty cells and normal pieces
- Column hover state shows a ghost piece at the correct landing row
- Layout adapts correctly between desktop and mobile viewport sizes
- Full visual layer can be replaced by swapping the theme object with no changes to game logic files
- All visual states are driven solely by the render state — no visual code reads game state directly

## Notes

- Decoupled from game logic: game produces a read-only render state; visual layer only reads it
- Render state includes: board cells (occupant, type, modifiers, locked/frozen), piece queue (next 2), scores, turn state, active effects, match state, chip count
- Jam theme (default): purple circles (player), teal circles (AI), dark grey background, modifier badges as colored pills with letter abbreviations
- Piece types distinguished by border style: Normal (none), Weighted (thick), Ghost (dashed), Volatile (jagged)
- AI pieces get a small square center dot for non-color distinguishability (accessibility)
- Board: 7×12, 48×48 px cells, 4 px gaps; UI panels flank left (player) and right (AI/chips/enemy)
- Desktop: left panel | board | right panel; Mobile: board centered, UI above/below
- Minimum cell size 32×32 px before "rotate device" prompt
- Theme system: swap one theme object to change all visuals; interface must not assume specific output
- Modifier badge layout: up to 3 per piece, bottom-left/center/right; 2-char abbreviation + distinct color per type
- Ghost piece preview in frozen columns must not appear (show invalid state instead)
- Gravity-flip mode (The Inverter): board renders upside down, row 11 at bottom

## History

### Feature 01 — Board Engine
Implemented the core grid engine: 7×12 configurable board, drop logic, gravity settle, 4-directional clear detection (including runs of 5+), clear removal with deduplication, and 7 public interface methods. Added `Piece`, `MatchedRun` data classes and a test script covering all acceptance criteria. Signals wired for renderer integration.

### Feature 02 — Cascade Loop
Implemented the repeating detect→remove→gravity cycle with cascade depth tracking, cross-color chain detection (player→AI→player), and modifier hooks at three points (on_land, on_clear, on_gravity). Added `TaggedClear`, `CascadeResult` data classes and a test script covering all acceptance criteria. Added `set_cell` to `BoardEngine` for test setup and future enemy gimmick use.

### Feature 03 — Scoring System
Implemented `ScoreCalculator` (base values, cascade depth multiplier ×2^depth, simultaneous ×1.5 bonus, cross-color +150, modifier trigger +25), `ScoreTracker` (running totals, per-turn delta, match-end comparison with tie detection), `TurnScore` and `MatchResult` data classes, and a test script covering all acceptance criteria. Round breakdown stored in `MatchResult` for the run summary screen.

### Feature 04 — AI Opponent
Implemented `AIOpponent` with a one-ply column-scoring heuristic (AI clear +1000/+1500, extend AI line +100/piece, block player clear +800/+1200, give player a clear −500, column height penalty −10/row above halfway), random tie-breaking, and a `noise` parameter for difficulty tuning. Implemented `TurnManager` with strict player→AI alternation, 40 turns each, and match-end signals for turn exhaustion or board fill. Added six gimmick hook slots (`on_turn_start`, `on_column_selected`, `on_piece_landed`, `on_cascade_complete`, `on_player_turn_start`, `on_player_piece_landed`) for future enemy scripts. AI tracks a hidden current/next piece queue. Added `get_landing_row()` to `BoardEngine`. 27 acceptance tests pass.
