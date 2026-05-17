# Current Feature — 03: Scoring System

## Status
In Progress

## Goals
- Base clear values: 4-in-a-row = 100, 5-in-a-row = 250, 6+ = 500
- Cascade depth multiplier: depth 0 = ×1, depth 1 = ×2, depth 2 = ×4, doubling each level
- Simultaneous clear bonus: ×1.5 applied to a player's total when they clear 2+ lines at the same depth
- Cross-color chain bonus: +150 flat to the initiating player when the flag is set
- Modifier trigger bonus: +25 per trigger
- Live score tracking for both players (accumulates per turn, exposes delta for UI)
- Match-end comparison with sudden death on tie

## Notes
- Receives CascadeResult from the loop: clears list (owner, cell count, depth), attribution, cross_color flag, modifier trigger count
- Processing order: base value → depth multiplier → simultaneous bonus → sum per owner → cross-color bonus → modifier triggers → add to running totals
- A 6-cell run = 500 flat (not 100+250 stacked)
- Simultaneous bonus only applies within the same depth round — different depths do not combine
- Modifier trigger bonuses count even if the modifier didn't contribute to a clear
- Sudden death: alternate extra turns until a clear occurs; may require multiple rounds
- Score delta from last turn needed for feature 11 (score popups)
- No chip earning here — that's feature 07

## History

### Feature 01 — Board Engine
Implemented the core grid engine: 7×12 configurable board, drop logic, gravity settle, 4-directional clear detection (including runs of 5+), clear removal with deduplication, and 7 public interface methods. Added `Piece`, `MatchedRun` data classes and a test script covering all acceptance criteria. Signals wired for renderer integration.

### Feature 02 — Cascade Loop
Implemented the repeating detect→remove→gravity cycle with cascade depth tracking, cross-color chain detection (player→AI→player), and modifier hooks at three points (on_land, on_clear, on_gravity). Added `TaggedClear`, `CascadeResult` data classes and a test script covering all acceptance criteria. Added `set_cell` to `BoardEngine` for test setup and future enemy gimmick use.
