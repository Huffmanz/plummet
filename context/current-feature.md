# Current Feature: Feature 11 — Animations + Juice

## Status
In Progress

## Goals

- Pieces animate downward to their landing position visibly
- Cleared cells animate out before gravity runs
- Score popups appear above cleared cells with correct values
- Cascade multipliers appear in the popup correctly (e.g. "100 ×2")
- Cross-color chain bonus displays as a distinct "+150 CHAIN" popup
- Screen shake triggers on cascade depth 2+ and Volatile explosions
- Combo announcement text appears on cascade depth 2+ ("COMBO" / "CHAIN" / "CASCADE")
- Sound plays on clear, land, and cascade
- All animations complete before the next turn input is accepted
- A mute option disables all sounds

## Notes

**Implementation priority (stop when time runs out):**
1. Clear animation — highest impact
2. Score popups — makes scoring legible without the scoreboard
3. Piece drop animation — polish on every action
4. Cascade timing and pacing — makes combo chains exciting
5. Sound cues — transforms the feel of every interaction
6. Screen shake — high drama for big moments
7. Combo announcement text — nice to have

**Key design rules:**
- All juice effects are cosmetic — game must be fully playable with all animations disabled
- Cascades should pace visually: ~8-frame pause after clear, gravity animates, ~4-frame pause before next clear check; shorten pauses ~10% per cascade depth level
- Screen shake table: depth 2 = light (2px/4f), depth 3+ = medium (4px/6f), Volatile = medium (4px/6f), board flip = heavy (8px/12f), match win = light (2px/4f)
- Popups float upward and fade over ~30 frames; stack vertically to avoid overlap
- Reduced motion option should skip to final states immediately
- Screen shake must be independently disableable

## History

### Feature 01 — Board Engine
Implemented the core grid engine: 7×12 configurable board, drop logic, gravity settle, 4-directional clear detection (including runs of 5+), clear removal with deduplication, and 7 public interface methods. Added `Piece`, `MatchedRun` data classes and a test script covering all acceptance criteria. Signals wired for renderer integration.

### Feature 02 — Cascade Loop
Implemented the repeating detect→remove→gravity cycle with cascade depth tracking, cross-color chain detection (player→AI→player), and modifier hooks at three points (on_land, on_clear, on_gravity). Added `TaggedClear`, `CascadeResult` data classes and a test script covering all acceptance criteria. Added `set_cell` to `BoardEngine` for test setup and future enemy gimmick use.

### Feature 03 — Scoring System
Implemented `ScoreCalculator` (base values, cascade depth multiplier ×2^depth, simultaneous ×1.5 bonus, cross-color +150, modifier trigger +25), `ScoreTracker` (running totals, per-turn delta, match-end comparison with tie detection), `TurnScore` and `MatchResult` data classes, and a test script covering all acceptance criteria. Round breakdown stored in `MatchResult` for the run summary screen.

### Feature 12 — Visual Layer
Implemented the full rendering pipeline: `RenderState` data snapshot (84 `CellState` cells, 2-entry player queue, scores, turn state, frozen columns, landing rows), `RenderStateBuilder` bridging game logic to visuals, `ThemeBase`/`ThemeJam` with swappable draw methods (purple/teal circles, 4 piece-type border styles, 6 modifier badge types, AI center-dot accessibility marker), `LayoutManager` computing DESKTOP/MOBILE/TOO_SMALL modes with dynamic cell sizing (32–48 px), `BoardRenderer` with frozen-column rejection and ghost-piece placement, and `BoardCanvas`/`GhostCanvas`/`QueueCanvas` thin draw wrappers. `GameBoard` scene wires the full player-vs-AI loop (drop → cascade → score → AI response). 27 acceptance tests pass covering data correctness, theme contracts, renderer validity checks, and builder mappings.

### Feature 04 — AI Opponent
Implemented `AIOpponent` with a one-ply column-scoring heuristic (AI clear +1000/+1500, extend AI line +100/piece, block player clear +800/+1200, give player a clear −500, column height penalty −10/row above halfway), random tie-breaking, and a `noise` parameter for difficulty tuning. Implemented `TurnManager` with strict player→AI alternation, 40 turns each, and match-end signals for turn exhaustion or board fill. Added six gimmick hook slots (`on_turn_start`, `on_column_selected`, `on_piece_landed`, `on_cascade_complete`, `on_player_turn_start`, `on_player_piece_landed`) for future enemy scripts. AI tracks a hidden current/next piece queue. Added `get_landing_row()` to `BoardEngine`. 27 acceptance tests pass.
