# Current Feature

## Status

Not Started

## Goals

<!-- Bullet points of what success looks like for the active feature -->

## Notes

<!-- Spec path, constraints, dependencies -->

## History

### Shop Enter / Exit Transition

Wrapped shop open/close in `TransitionManager.transition_screen()` so a diagonal wipe plays before the shop appears (in `game_board.gd` after match win overlay dismisses) and again on Continue before the next match starts (in `shop_screen.gd` `_on_continue`). Added `_input_enabled: bool` to `ShopScreen` with `_set_input_enabled()` helper — disables Continue/Reroll buttons and gates `_on_offer_drag_started` while false. `open()` calls `_set_input_enabled(true)` on each visit. Standalone shop preview (`ShopScreen` as main scene, `get_parent() == root`) skips the transition and closes immediately so F6 test stays fast.

### Shop

Rebuilt the shop as a scene-based full-screen takeover (`shop_screen.tscn`) with drag-and-drop: modifier and piece-type offers onto any bag piece (shader piece previews, rotating dashed drop ring), relic offers onto empty relic slots, and remove/upgrade via × and popover. Weighted offer pool mixes modifiers, piece types (Prism/Coin/Ember/Shard), and shop relics; consumed offers stay as invisible layout spacers. Added `ShopOfferCard` (on-card descriptions, no tooltips), `GameTooltip`/`GameCursor` autoloads, `JuicySfxButton` on Continue/Reroll, and companion juice specs 15–21 (enter transition, chip tween, drag snap, audio list, offer/bag/reroll animation — not yet implemented).

### Headless Run Simulation Test

Added `run_simulation_test.gd` and `scenes/tests/run_simulation_test.tscn` — a headless, seed-deterministic test suite (`seed(12345)`) that instantiates game logic directly with no rendering. Covers all 8 modifiers (unit tests per hook), piece types and scoring rules, 10 relic passives, bag mutations, chip economy, and a full simulated run (3 acts × 4 matches) with guaranteed player wins, shop visits cycling modifiers/relics, and pass/fail reporting. Fixed magnet test to assert slide after gravity compaction and bag init to assign seven modifiers without overwriting Ignite.

### Scoring Popup Accumulator

Added `ScoreAccumulatorOverlay` (`scenes/ui/score_accumulator_overlay.tscn`, `scripts/ui/score_accumulator_overlay.gd`) — an editor-built `Control` scene centered on the board via `CenterContainer`. During cascade resolution it shows a `PanelContainer` with a player row (top) and AI row (bottom), each displaying a rapidly counting-up base score and a snapping multiplier label (×1, ×2, ×4…). The overlay appears on the first clear of a cascade, updates incrementally per-run as each clear animation plays (not all at once), and flashes white then fades out after the cascade ends. Both rows are hidden until their owner scores; the divider only shows when both are active. Prism type doubling is reflected in the accumulator by re-scanning run cells for `Piece.Type.PRISM` in the animation loop. Count-up uses `tween_method` (0.28s quad-ease-out) so rapid successive clears chain from the current displayed value. Also fixed Echo + Echo Chamber: `on_gravity` was replaced with `pop_echo_pieces()` + `find_echo_target(board)` so column selection re-evaluates after each drop rather than targeting the same column for all copies; pieces are placed and animated one at a time so each drop is visible before the next begins.

### Feature 05 — Piece Types, Modifiers & Relics

Implemented 5 piece types (Normal, Prism, Coin, Ember, Shard), 8 modifiers (Ignite, Magnet, Deposit, Ripple, Echo, Detonate, Bounty, Surge), and 10 relics (Compass, Cushion, Almanac, Forge, Lens, Stockpile, Patron, Echo Chamber, Momentum, Cartographer) as resource-driven `.tres` data files. `DataRegistry` autoload scans and indexes all three resource directories globally. `ModifierResolver` handles all landing and clear hooks; `RelicManager` tracks run-wide passives and passes them through `RunController` across matches. Piece type effects hook into `ScoreCalculator` (Prism ×2 base, Ember +1 cascade depth, Coin +1 chip) and `CascadeLoop` (Shard removes piece above on clear). Modifier initials render centered on pieces in `ThemeCozy`/`ThemeJam` (expandable to icons via resource `icon_path`). Echo fixed to animate drops before updating board canvas; Ripple corrected to push pieces below landing row. Sandbox test scene (`modifier_relic_test.tscn`) provides isolated playtesting of all combinations with tooltips from resource descriptions.

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

### Feature 07 — Shop (initial)

Implemented `ShopScreen` (full-screen Control overlay, all UI built programmatically) shown after a won match only. Four-phase state machine (IDLE → ATTACH_PICK_PIECE / REMOVE_PICK_MOD / UPGRADE_PICK_TYPE) drives contextual buttons on each bag row. Modifier attach costs 10 chips (offer → piece with < 3 modifiers); remove costs 5 (piece → select which modifier); upgrade costs 20 (Normal-only → Weighted or Ghost); reroll costs 5 (once per visit, replaces all 3 offers). Each visit draws 3 random modifiers from the 6-item pool. All actions disabled when unaffordable. `GameBoard` now tracks `_win_streak` and adds the win bonus (+15) and streak bonus (+5 × (streak−1) for streak ≥ 2) before opening the shop; `PieceBag` and `_chip_count` persist across matches so upgrades and unspent chips carry over. Standalone preview mode populates a sample bag for isolated testing.

### Feature 09 — Run Loop

Implemented `RunController` as the top-level game state machine with `RunState` tracking act/match progress, bag, chips, win streak, scores, cascade stats, and fragments. 3-act × 4-match structure (3 regular + boss per act) with per-act enemy schedule and random opponent on act match 3. `GameBoard` gains `setup_match()` and `match_complete` signal — shop opens after regular wins only in run mode; boss wins skip shop and advance directly. `RunSummaryScreen` shows victory/defeat, progress reached, final/total scores, fragments earned, highest cascade, cross-color count, and end-of-run bag. Fragment milestones awarded per match (3 regular, 5 boss, act completion 10/20/40) plus stacking score thresholds (+5 at 2000, +10 at 5000). Main scene set to `run_controller.tscn` with `MainMenu` entry point.

### Feature 16 — Light Cozy UI

Replaced pixel-art board rendering with `ThemeCozy` vector drawing (outlined circles, square cells, type overlays). Added `UITheme` design tokens and `StyleBoxFlat` helpers for a cream canvas, navy surfaces, and sage accents across main menu, shop, run summary, match HUD, and match-end overlay. `CozyScreenBackground` draws a subtle star pattern. Fixed board z-order so pieces render above empty cells and animating drops draw last. `LayoutManager` simplified to desktop-only side panels with frame padding and tweakable `BOARD_OFFSET`; mobile layout removed. Coaster font added as project default.

### Juicy SFX Button

Added `JuicySfxButton` (`scenes/ui/juicy_sfx_button.tscn`, `scripts/ui/juicy_sfx_button.gd`) — editor-built flat `Button` with `VisualPivot` panel/label and `AudioStreamPlayer`. Plays a random hover SFX from an exported list via null-safe `_play_random_from()`. Hover and keyboard focus tween scale, bg/label colors, and a high-contrast border rim independent of fill color; rotation wiggle on enter. Preview scene `juicy_sfx_button_preview.tscn` for isolated testing. Menu/shop wiring left as follow-up.

### Juicy Main Menu

Rebuilt `main_menu.tscn` as an editor-visible layout with `CozyStripeBackground`, seven `TitleLetterBall` instances (staggered PLUMMET drop from top with bounce), and `JuicySfxButton` Start Run / Quit controls. `RunController` starts runs via `TransitionManager.transition_screen()` with a diagonal wipe (`transition_overlay.tscn` + `diagonal_wipe_transition.gdshader`, progress 0→1 cover at midpoint then 1→0 reveal). Added reusable `cozy_stripe_background.tscn` for shop/summary/preview. Fixed `queue_free` teardown when advancing matches after shop.
