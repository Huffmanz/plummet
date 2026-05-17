# Current Feature — 02: Cascade Loop

## Status
In Progress

## Goals
- Repeating clear → gravity → detect cycle after every piece drop
- Loop exits when no clears are found (board stable)
- Cascade depth tracked: starts at 0, increments each round
- Clear attribution: all clears in a chain owned by the player who triggered the first clear
- Cross-color chain detection: player → AI → player sequence sets a flag
- Modifier hooks at three points: after landing, after clear detection, after gravity
- Returns structured result: list of clears (with owner + depth), attribution, cross-color flag

## Notes
- Both owners' clears are detected each round; attribution (for scoring) goes to the initiating player
- AI clears within a player cascade are still recorded (needed for cross-color bonus)
- Cross-color flag only qualifies for player → AI → player sequence; AI → player → AI does not count
- Simultaneous clears for both owners in the same round are recorded at the same depth
- Deduplication of shared cells must occur before removal (already handled by BoardEngine.remove_clears)
- Modifier hooks must be registerable without modifying the core loop logic
- No scoring logic here — pass depth and cross-color flag to feature 03

## History

### Feature 01 — Board Engine
Implemented the core grid engine: 7×12 configurable board, drop logic, gravity settle, 4-directional clear detection (including runs of 5+), clear removal with deduplication, and 7 public interface methods. Added `Piece`, `MatchedRun` data classes and a test script covering all acceptance criteria. Signals wired for renderer integration.
