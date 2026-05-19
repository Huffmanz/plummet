# Current Feature

## Feature 15 — Pixel Art Sprites

## Status
In Progress

## Goals
- Replace programmatic `draw_circle`/`draw_rect` calls in `ThemeJam` with a spritesheet
- Grid cell tile drawn from sprite 0 (0,0 region), tinted per state (empty, locked, frozen)
- Game piece drawn from sprite 1 (16,0 region), tinted per player color; type overlays (arcs, spikes) remain on top
- Canvas nodes set to `TEXTURE_FILTER_NEAREST` for crisp pixel art at all cell sizes

## Notes
- Spritesheet: `res://assets/assets.png` — 256×256, 16×16 sprites, grayscale for tinting
- Sprite 0: tileable grid cell
- Sprite 1: game piece
- Cell size is dynamic (16–32px); `draw_texture_rect_region` scales sprite to fit

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

### Feature 13 — Additional Juice
Extended `AnimLayer`, `BoardCanvas`, `GhostCanvas`, `QueueCanvas`, and `GameBoard` with 19 polish effects: gravity animation (pieces slide to new rows after clears), landing impact burst (4–6 dots fly outward on piece landing), AI drop preview (faint column highlight 300ms before AI drops), column hover highlight (subtle vertical strip ~10% alpha), score counter tween (score ticks up over ~20 frames), piece trail while falling (2–3 ghost copies at decreasing alpha), column fill warning (column pulses red when 1–2 cells from full), piece lock flash (white flash on undroppable column), clear line sweep (thin line traces matched cells before flash), board idle breathe (0.999→1.001 scale pulse), your-turn indicator pop (bounces/scales in on player turn), AI thinking dots (animated "..." during AI turn), column rejection shake (horizontal shake on failed click), queue slide (next piece slides down into position), incoming piece drop preview (queued piece bounces), modifier badge pulse (badges pulse gently), multiplier escalation color (score popups shift yellow→orange→red with cascade depth), match-end score comparison (dramatic count-up side by side before winner reveal), and chip earn flash ("+1 chip" micro-popup near score). Added `MatchEndOverlay` scene and `JuiceTest` scene for isolated testing.

### Feature 14 — Moar Juice
Extended `AnimLayer`, `BoardRenderer`, `GameBoard`, `ThemeJam`, and added `EnemyPortrait` with 11 polish effects: board edge glow pulses player/AI color on active turn, cascade heat shifts board background warmer as chain depth increases, frozen column frost overlay draws blue hatching over locked columns, drop shadow ellipse shrinks toward landing cell as piece falls, piece blooms to 120% saturation on landing then settles, modifier trigger flash pulses accent color on activation, score milestone pop fires large centered text at 500/1000/2000+, cascade counter badge shows ×N depth in corner during chains and fades after, turn counter pulses red in last 10 turns, EnemyPortrait (shape-based face) reacts neutral/smug/startled based on game events, and BLOCKED! popup fires when a placement cuts across 3+ consecutive opponent pieces.
