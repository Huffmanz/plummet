# Current Feature — Feature 07: Shop

## Status
In Progress

## Goals

- Shop opens after a won match only; skipped after a loss
- Chip count correctly totals win bonus (15), per-clear bonus (1 each), and win streak bonus (+5 per consecutive win beyond the first)
- Modifier attach: costs 10 chips, places selected modifier on any chosen piece with < 3 modifiers
- Modifier remove: costs 5 chips, strips a modifier from any piece
- Piece type upgrade: costs 20 chips, converts a Normal piece to Weighted or Ghost (preserves modifiers)
- Reroll: costs 5 chips, replaces all 3 offers; only usable once per visit
- Unspent chips carry over to next shop visit
- All actions disabled (not hidden) when player cannot afford them

## Notes

### When Shop Appears
- After a **won** match only; lost match skips shop entirely

### Chip Economy
- Win a match: +15
- Each player clear during match: +1 (already tracked via `_chip_count` in `GameBoard`)
- Win streak 2nd win: +5 extra; 3rd+ win: +5 additional per win
- Unspent chips carry over (persistent across shop visits)

### Modifier Offers
- 3 random modifiers drawn from pool each visit
- Pool for jam build: Echo, Magnet, Heavy, Anchor, Catalyst, Volatile (all 6 base modifiers)
- Player selects an offer then selects which piece to attach it to
- Piece must have < 3 modifiers to be eligible
- Reroll (5 chips, once per visit) replaces all 3 offers

### Actions
- **Attach modifier** (10 chips): offer → piece selection → confirm
- **Remove modifier** (5 chips): piece selection → modifier selection → confirm
- **Upgrade type** (20 chips): Normal-only piece → Weighted or Ghost
- **Reroll** (5 chips): available once per visit

### Volatile Pieces
- Volatile type cannot be created via upgrade; added as a new bag piece (bag temporarily 8; drops oldest Normal piece at start of next match if bag > 7)
- Not in scope for jam build core — stub allowed

### Out of Scope
- Meta-progression unlock checks (feature 10) — treat all modifiers/types as available
- Tier II modifiers
- Ghost unlock gate (treat as always available for jam)

### UI Structure
- Shop is a new scene (`ShopScreen`) shown between matches
- Displays: chip count, 3 modifier offers, full bag with type + modifiers per piece, costs, reroll status
- "Done" button proceeds to next match

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

### Feature 15 — Pixel Art Sprites
Replaced all programmatic `draw_circle`/`draw_rect` piece and cell rendering in `ThemeJam` with a 256×256 grayscale spritesheet (`assets/assets.png`). Grid tile (sprite 0) always renders on top of pieces via a split `render_board_under`/`render_board_tiles` pass in `BoardRenderer`; piece sprite (sprite 1) tinted per player/AI color with type overlays (arcs, spikes) drawn on top. Falling and gravity pieces draw into `BoardCanvas` behind the grid overlay via `AnimLayer.draw_pieces_to()`. `CELL_GAP` set to 0 for seamless tiling. `TEXTURE_FILTER_NEAREST` applied to all canvas nodes and `AnimLayer`. New palette applied to background, pieces, particles, and popups. AI center dot removed.

### Feature 14 — Moar Juice
Extended `AnimLayer`, `BoardRenderer`, `GameBoard`, `ThemeJam`, and added `EnemyPortrait` with 11 polish effects: board edge glow pulses player/AI color on active turn, cascade heat shifts board background warmer as chain depth increases, frozen column frost overlay draws blue hatching over locked columns, drop shadow ellipse shrinks toward landing cell as piece falls, piece blooms to 120% saturation on landing then settles, modifier trigger flash pulses accent color on activation, score milestone pop fires large centered text at 500/1000/2000+, cascade counter badge shows ×N depth in corner during chains and fades after, turn counter pulses red in last 10 turns, EnemyPortrait (shape-based face) reacts neutral/smug/startled based on game events, and BLOCKED! popup fires when a placement cuts across 3+ consecutive opponent pieces.

### Feature 05 — Piece Bag + Modifiers
Implemented `PieceBag` (7-slot cycling array with `current()`/`peek(offset)`/`advance()`), `ModifierResolver` (stateful hook handler for all 6 modifiers), and added an `on_pre_gravity` hook to `CascadeLoop` (fires between `remove_clears` and `apply_gravity` for Anchor). Heavy pushes the piece below down one row on landing. Magnet scans left/right for the closest same-color piece and slides it one step toward the magnet. Catalyst sets a flag so the next piece's landing modifiers fire twice. Echo queues a copy of the player's piece to drop into the column with the most AI pieces, fired in `on_gravity`. Volatile removes 4 orthogonal neighbors in `on_clear`. Anchor saves its board position before gravity and restores it after, keeping it immune to compaction. `GameBoard` draws the current piece from the bag (advancing after each drop), fires modifier hooks at the correct points in `_on_column_selected` and `_run_cascade_animated`, and passes the next 2 upcoming pieces to `_build_state()` for queue display.

### Feature 06 — Piece Types
Expanded `Piece.Type` enum to `NORMAL`, `WEIGHTED`, `GHOST`, `VOLATILE`. Weighted: on landing pushes the piece directly below down one row then settles into the vacated slot; `_try_push_down` is recursive so stacked Weighted pieces chain their push, and Anchor-modified pieces resist displacement. Ghost: `BoardEngine.get_ghost_landing_row()` finds the first empty slot below the topmost occupied cell (returns -1 for packed stacks or a piece at row 0); `drop_ghost_piece()` places the piece there and emits `piece_placed`; `GameBoard` uses this path when the current piece is Ghost and shows a column-reject shake for invalid drops. Volatile type: `ModifierResolver.on_clear` fires `_apply_volatile_type` which removes all 8 Moore-neighborhood cells; when the piece also carries the Volatile modifier, 4 orthogonal cells at distance 2 are additionally removed (combined 3×3 + cross effect); the modifier's own 4-orthogonal path is skipped to avoid double-removal. `RenderStateBuilder._map_piece_type` now maps all four types to `CellState.PieceType`. 18 acceptance tests in `piece_type_test.gd` cover all spec criteria.
