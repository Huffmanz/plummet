# Current Feature

## Status
Not Started

## Goals
- <!-- Add goals for the active feature -->

## Notes
- <!-- Add implementation notes and constraints -->

## History

### Feature 01 — Board Engine
Implemented the core grid engine: 7×12 configurable board, drop logic, gravity settle, 4-directional clear detection (including runs of 5+), clear removal with deduplication, and 7 public interface methods. Added `Piece`, `MatchedRun` data classes and a test script covering all acceptance criteria. Signals wired for renderer integration.

### Feature 02 — Cascade Loop
Implemented the repeating detect→remove→gravity cycle with cascade depth tracking, cross-color chain detection (player→AI→player), and modifier hooks at three points (on_land, on_clear, on_gravity). Added `TaggedClear`, `CascadeResult` data classes and a test script covering all acceptance criteria. Added `set_cell` to `BoardEngine` for test setup and future enemy gimmick use.
