# Current Feature

## Status
Not Started

## Goals

## Notes

## History

### Feature 01 — Board Engine
Implemented the core grid engine: 7×12 configurable board, drop logic, gravity settle, 4-directional clear detection (including runs of 5+), clear removal with deduplication, and 7 public interface methods. Added `Piece`, `MatchedRun` data classes and a test script covering all acceptance criteria. Signals wired for renderer integration.

### Feature 02 — Cascade Loop
Implemented the repeating detect→remove→gravity cycle with cascade depth tracking, cross-color chain detection (player→AI→player), and modifier hooks at three points (on_land, on_clear, on_gravity). Added `TaggedClear`, `CascadeResult` data classes and a test script covering all acceptance criteria. Added `set_cell` to `BoardEngine` for test setup and future enemy gimmick use.

### Feature 03 — Scoring System
Implemented `ScoreCalculator` (base values, cascade depth multiplier ×2^depth, simultaneous ×1.5 bonus, cross-color +150, modifier trigger +25), `ScoreTracker` (running totals, per-turn delta, match-end comparison with tie detection), `TurnScore` and `MatchResult` data classes, and a test script covering all acceptance criteria. Round breakdown stored in `MatchResult` for the run summary screen.

### Feature 04 — AI Opponent
Implemented `AIOpponent` with a one-ply column-scoring heuristic (AI clear +1000/+1500, extend AI line +100/piece, block player clear +800/+1200, give player a clear −500, column height penalty −10/row above halfway), random tie-breaking, and a `noise` parameter for difficulty tuning. Implemented `TurnManager` with strict player→AI alternation, 40 turns each, and match-end signals for turn exhaustion or board fill. Added six gimmick hook slots (`on_turn_start`, `on_column_selected`, `on_piece_landed`, `on_cascade_complete`, `on_player_turn_start`, `on_player_piece_landed`) for future enemy scripts. AI tracks a hidden current/next piece queue. Added `get_landing_row()` to `BoardEngine`. 27 acceptance tests pass.
