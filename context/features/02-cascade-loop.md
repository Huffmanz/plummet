# Feature 02 — Cascade Loop
*Plummet · Game Jam Build*

## Purpose

The cascade loop is the repeating cycle that runs after every piece drop. It chains clears together, applies gravity between each clear, and detects new clears until the board is stable. This is the mechanic that makes combos possible. Every modifier and enemy gimmick hooks into this loop.

---

## Scope

- The repeating clear → gravity → detect cycle
- Cascade depth tracking
- Clear attribution (who triggered the original clear owns the chain)
- Cross-color chain detection (player clear → AI clear → player clear)

Not in scope: scoring (feature 03), modifier resolution (feature 05).

---

## How It Works

After a piece lands, the cascade loop runs as follows:

1. Detect all clears on the board (both owners).
2. If no clears exist, stop — the board is stable.
3. Record which clears belong to which owner.
4. Remove all cleared cells.
5. Apply gravity to all columns.
6. Increment cascade depth.
7. Return to step 1.

The loop runs until step 2 exits it.

---

## Attribution

Attribution determines who scores each clear. The rule is:

**The player whose piece completes a clear owns that clear — and all clears that cascade from it.**

Attribution is tracked per cascade chain, not per clear. Once a chain starts, every subsequent clear in that chain is attributed to the player who triggered the first clear — regardless of which color's pieces fall and clear in between.

### Attribution tracking

At the start of each cascade loop run:
- Record the owner of every clear detected in step 1.
- Mark the cascade chain as owned by the player who dropped the piece that initiated this loop run.
- All subsequent clears within this loop run inherit that attribution.

The AI's clears within a player-initiated cascade are still recorded (for the cross-color bonus), but scoring credit goes to the player.

---

## Cross-Color Chain Detection

A cross-color chain occurs when:

1. A player clear causes AI pieces to fall.
2. Those AI pieces form a clear.
3. That AI clear causes player pieces to fall.
4. Those player pieces form another player clear.

The full sequence must pass through at least one AI clear between two player clears to qualify.

Track a flag during the cascade loop:
- Set it when an AI clear is detected during a player-attributed cascade.
- If a further player clear then occurs in the same cascade, the cross-color chain flag is confirmed.

Pass this flag to the scoring system (feature 03) when the loop completes.

---

## Cascade Depth

Cascade depth starts at 0 for the first clear in a chain. Each subsequent round of clears in the same loop run increments depth by 1.

Pass the depth value to the scoring system so it can apply the cascade multiplier.

---

## Loop Completion Data

When the cascade loop finishes, it should return:

| Data | Description |
|---|---|
| List of clears | Each clear set, tagged with owner and cascade depth |
| Attribution | Which player initiated the cascade |
| Cross-color flag | Whether a cross-color chain occurred |
| Final board state | The stable board after all clears and gravity |

---

## Modifier Hooks

Feature 05 will inject modifier behavior into the cascade loop at specific points. The loop should support hooks at:

- After a piece lands (before the first clear check) — for landing-effect modifiers (Heavy, Magnet, Double Drop)
- After each clear is detected but before removal — for clear-effect modifiers (Volatile, Echo)
- After gravity settles each round — for post-gravity modifiers (Anchor)

Design the loop so these hooks can be registered and called at the appropriate points without modifying the core loop logic.

---

## Edge Cases

- If the first drop causes no clears, the loop exits immediately at depth 0 with no clears to report.
- If both owners clear simultaneously in the same loop round, both are recorded at the same depth level.
- A cell shared by two clears is removed once — deduplication must occur before removal.
- Gravity after removal may cause no further clears — the loop must handle a zero-clear round cleanly.
- The cross-color flag should only confirm if the sequence is player → AI → player. AI → player → AI does not qualify (AI does not receive the bonus).

---

## Acceptance Criteria

- A piece drop that creates no clears exits the loop immediately.
- A piece drop that creates a clear, which after gravity creates another clear, runs the loop twice and reports depth 1 on the second clear.
- All clears in a player-initiated cascade are attributed to the player, even if AI clears occur in the middle.
- A player → AI → player cascade sequence sets the cross-color flag.
- A player → AI cascade with no further player clear does not set the cross-color flag.
- Simultaneous clears for both owners in the same round are both recorded at the same cascade depth.
- The loop terminates on every possible board state — no infinite loops.

---

## Dependencies

- Feature 01 — Board engine (clear detection, removal, gravity)

## Required by

- Feature 03 — Scoring system
- Feature 04 — AI opponent
- Feature 05 — Piece bag + modifiers
