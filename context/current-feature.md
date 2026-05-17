# Current Feature — 04: AI Opponent

## Status
Complete

## Goals
- Column-scoring heuristic: evaluate every valid column and pick the highest score
- Heuristic factors: AI clear (+1000/+1500), extend AI line (+100/piece), block player clear (+800/+1200), give player a clear (−500), column height penalty (−10/row above halfway)
- Ties broken randomly among tied columns
- Noise parameter: replace top-scored column with random valid column at given probability
- Alternating turn management: player → AI → player, 40 turns each
- Match end: both players reach 40 turns, or board fills completely
- Gimmick hook interface: 6 named hooks that fire at specific points in the turn sequence
- AI piece queue: tracks current and next pieces

## Notes
- Heuristic is one-ply only — no lookahead beyond immediate drop result
- Difficulty expressed via noise, not heuristic weights: low (0–5%), medium (10–15%), high (20%+)
- Noise samples only from VALID columns (never full ones)
- If all columns are full on AI's turn: skip turn and trigger match end
- Gimmick hooks: on_turn_start, on_column_selected, on_piece_landed, on_cascade_complete, on_player_turn_start, on_player_piece_landed
- Hooks receive board state and may modify it, modify selected column, or inject pieces
- Heuristic simulates a drop without actually placing the piece
- Individual enemy gimmicks are feature 08 — only the hook interface lives here
- AI queue is hidden from player

## History

### Feature 01 — Board Engine
Implemented the core grid engine: 7×12 configurable board, drop logic, gravity settle, 4-directional clear detection (including runs of 5+), clear removal with deduplication, and 7 public interface methods. Added `Piece`, `MatchedRun` data classes and a test script covering all acceptance criteria. Signals wired for renderer integration.

### Feature 02 — Cascade Loop
Implemented the repeating detect→remove→gravity cycle with cascade depth tracking, cross-color chain detection (player→AI→player), and modifier hooks at three points (on_land, on_clear, on_gravity). Added `TaggedClear`, `CascadeResult` data classes and a test script covering all acceptance criteria. Added `set_cell` to `BoardEngine` for test setup and future enemy gimmick use.

### Feature 03 — Scoring System
Implemented `ScoreCalculator` (base values, cascade depth multiplier ×2^depth, simultaneous ×1.5 bonus, cross-color +150, modifier trigger +25), `ScoreTracker` (running totals, per-turn delta, match-end comparison with tie detection), `TurnScore` and `MatchResult` data classes, and a test script covering all acceptance criteria. Round breakdown stored in `MatchResult` for the run summary screen.
