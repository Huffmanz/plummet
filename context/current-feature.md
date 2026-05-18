# Current Feature — Feature 13: Additional Juice

## Status
In Progress

## Goals

- Gravity animation: pieces slide down visually after clears instead of snapping
- Landing impact burst: 4–6 dots fly outward and fade on piece landing
- AI drop preview: faint column highlight 300ms before AI drops
- Column hover highlight: subtle vertical strip behind hovered column (~10% alpha)
- Score counter tween: score label ticks up over ~20 frames instead of snapping
- Piece trail while falling: 2–3 ghost copies behind falling piece at decreasing alpha
- Column fill warning: column turns red/pulses when 1–2 cells from full
- Piece lock flash: brief white flash on column when it becomes undroppable (full/frozen)
- Clear line sweep: thin line traces matched cells just before they flash
- Board idle breathe: very subtle scale pulse (0.999→1.001) when board is idle
- Your turn indicator pop: "YOUR TURN" text bounces/scales in on player turn start
- AI thinking dots: animated "..." in turn indicator during AI turn
- Column rejection shake: frozen/full column shakes horizontally on failed click
- Queue slide: next piece slides down into position when current piece is consumed
- Incoming piece drop preview: queued piece subtly bounces to draw attention
- Modifier badge pulse: modifier badges on queued pieces pulse gently
- Multiplier escalation color: score popups shift yellow→orange→red with cascade depth
- Match-end score comparison: scores count up dramatically side by side before winner reveal
- Chip earn flash: "+1 chip" micro-popup near score on clear

## Notes

Priority order (biggest feel win for least code):
1. Gravity animation — cascades feel incomplete without it; snapshot positions before/after `apply_gravity()`, animate in AnimLayer
2. Landing impact burst — fires on every player action; ~20 lines with `draw_circle` per dot
3. Column rejection shake — no-feedback clicks feel broken
4. AI drop preview — makes AI feel intentional
5. Column hover highlight — pairs with existing ghost piece

All additions extend existing `AnimLayer`, `BoardCanvas`, `GhostCanvas`, `QueueCanvas` — no new scene nodes required unless needed for score counter or queue slide.

Not in scope: core animations already in Feature 11, sound, shop UI, run summary screen.

## History

### Feature 01 — Board Engine
Implemented the core grid engine: 7×12 configurable board, drop logic, gravity settle, 4-directional clear detection (including runs of 5+), clear removal with deduplication, and 7 public interface methods. Added `Piece`, `MatchedRun` data classes and a test script covering all acceptance criteria. Signals wired for renderer integration.

### Feature 02 — Cascade Loop
Implemented the repeating detect→remove→gravity cycle with cascade depth tracking, cross-color chain detection (player→AI→player), and modifier hooks at three points (on_land, on_clear, on_gravity). Added `TaggedClear`, `CascadeResult` data classes and a test script covering all acceptance criteria. Added `set_cell` to `BoardEngine` for test setup and future enemy gimmick use.

### Feature 03 — Scoring System
Implemented `ScoreCalculator` (base values, cascade depth multiplier ×2^depth, simultaneous ×1.5 bonus, cross-color +150, modifier trigger +25), `ScoreTracker` (running totals, per-turn delta, match-end comparison with tie detection), `TurnScore` and `MatchResult` data classes, and a test script covering all acceptance criteria. Round breakdown stored in `MatchResult` for the run summary screen.

### Feature 12 — Visual Layer
Implemented the full rendering pipeline: `RenderState` data snapshot (84 `CellState` cells, 2-entry player queue, scores, turn state, frozen columns, landing rows), `RenderStateBuilder` bridging game logic to visuals, `ThemeBase`/`ThemeJam` with swappable draw methods (purple/teal circles, 4 piece-type border styles, 6 modifier badge types, AI center-dot accessibility marker), `LayoutManager` computing DESKTOP/MOBILE/TOO_SMALL modes with dynamic cell sizing (32–48 px), `BoardRenderer` with frozen-column rejection and ghost-piece placement, and `BoardCanvas`/`GhostCanvas`/`QueueCanvas` thin draw wrappers. `GameBoard` scene wires the full player-vs-AI loop (drop → cascade → score → AI response). 27 acceptance tests pass covering data correctness, theme contracts, renderer validity checks, and builder mappings.

### Feature 11 — Animations + Juice
Implemented `AnimLayer` (Node2D overlay) with five animation systems: piece drop (1400 px/s fall with 3-phase squash→stretch→restore on landing), clear animation (2-frame white flash + 6-frame contract-to-point), score popups (yellow text floating upward over 30 frames with cascade multiplier label e.g. "100 ×2"), screen shake (light 2px/4f at cascade depth 2, medium 4px/6f at depth 3+, light on match win), and combo announcement text (COMBO/CHAIN/CASCADE fading in/holding/out centered on board). Cascade loop converted to async coroutine with paced timing (~8-frame pause post-clear, ~4-frame post-gravity, each shrinking 10% per depth). `BoardCanvas` and `GhostCanvas` gain `shake_offset` for synchronized shake. Cross-color chain popup "+150 CHAIN" spawns on detection. Accessibility: R key toggles reduced motion (skips all animation), M key toggles mute (wired for future audio). All animations complete before next turn input is accepted via `_animating` flag.

### Feature 04 — AI Opponent
Implemented `AIOpponent` with a one-ply column-scoring heuristic (AI clear +1000/+1500, extend AI line +100/piece, block player clear +800/+1200, give player a clear −500, column height penalty −10/row above halfway), random tie-breaking, and a `noise` parameter for difficulty tuning. Implemented `TurnManager` with strict player→AI alternation, 40 turns each, and match-end signals for turn exhaustion or board fill. Added six gimmick hook slots (`on_turn_start`, `on_column_selected`, `on_piece_landed`, `on_cascade_complete`, `on_player_turn_start`, `on_player_piece_landed`) for future enemy scripts. AI tracks a hidden current/next piece queue. Added `get_landing_row()` to `BoardEngine`. 27 acceptance tests pass.
