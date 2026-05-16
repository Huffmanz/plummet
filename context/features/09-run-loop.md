# Feature 09 — Run Loop
*Plummet · Game Jam Build*

## Purpose

The run loop sequences the full roguelike experience — acts, matches, shops, bosses, win/loss routing, and the run summary screen. It is the top-level game state machine.

---

## Scope

- 3-act structure
- Match sequencing within each act
- Enemy selection per act
- Shop gating (win-only)
- Boss fight routing
- Win/loss state and run end conditions
- Run summary screen
- Fragment earning

Not in scope: meta-progression unlocks (feature 10), individual enemy gimmicks (feature 08).

---

## Run Structure

A full run consists of 3 acts. Each act contains 3 regular matches and 1 boss fight. The shop is available after each won regular match (not after boss fights).

```
Act 1:  Match → Match → Match → Boss
Act 2:  Match → Match → Match → Boss
Act 3:  Match → Match → Match → Final Boss
```

The player's piece bag carries over between all matches within a run. Chips carry over between shops. The board resets to empty at the start of every match.

---

## Match Sequencing

Within each act:

1. Select the enemy for this match (see Enemy Selection below).
2. Reset the board to empty.
3. Run the match (features 01–05, 08).
4. Determine the match result (win or loss).
5. If win: open the shop (unless this was a boss fight), then proceed to the next match.
6. If loss: end the run immediately. Proceed to the run summary screen.

### Boss fights

Boss fights use the same match structure as regular matches, with the boss enemy's gimmick active. There is no shop after a boss fight — win or lose, the player proceeds immediately (to the next act, or to the run summary).

A boss loss ends the run. A boss win advances to the next act.

---

## Enemy Selection

### Act 1
- Match 1: The Stoic (always — tutorial opponent)
- Match 2: The Blocker
- Match 3: The Stoic or The Blocker (random)
- Boss: The Mirror

### Act 2
- Match 1: The Gravedigger
- Match 2: The Architect
- Match 3: The Gravedigger or The Architect (random)
- Boss: The Inverter

### Act 3
- Match 1: The Painter
- Match 2: The Shifter
- Match 3: The Painter or The Shifter (random)
- Boss: The Hoarder (final boss)

Enemies unlocked via meta-progression (feature 10) may be added to the random pool for act 3 match 3.

---

## Win / Loss Conditions

### Match win
The player's score is higher than the AI's score when the turn limit is reached, or when the board fills completely.

### Match loss
The AI's score is higher than the player's score at match end. Or: the board fills and the AI is leading.

### Tie
Resolved by sudden death (feature 03 — scoring system).

### Run win
The player defeats the final boss (The Hoarder in act 3).

### Run loss
The player loses any match — regular or boss — at any point in the run.

---

## Run Summary Screen

Displayed after any run end (win or loss). Shows:

- Run result (victory or defeat)
- Act and match reached
- Final score for the match that ended the run
- Total score across all matches in the run
- Fragments earned (see below)
- Highest cascade chain achieved during the run
- Number of cross-color bonuses earned
- The player's bag at the time the run ended (piece types + modifiers)
- A prompt to start a new run or return to the main menu

---

## Fragment Earning

Fragments are the meta-progression currency (feature 10). They are earned at run end based on progress:

| Milestone | Fragments |
|---|---|
| Complete act 1 (defeat The Mirror) | 10 |
| Complete act 2 (defeat The Inverter) | 20 |
| Complete act 3 / win the run | 40 |
| Each regular match won | 3 |
| Each boss defeated | 5 |
| Run total score above 2000 | +5 bonus |
| Run total score above 5000 | +10 bonus |

Fragments from a lost run are still awarded for progress made before the loss.

---

## State to Persist Within a Run

The run loop must track and maintain across matches:

- Player's piece bag (types + modifiers)
- Player's chip count
- Win streak counter (for shop chip bonuses)
- Acts completed
- Matches won and lost this run
- Total score across all matches
- Fragments earned so far this run

---

## Edge Cases

- If the player wins all 3 acts, the run ends in victory — there is no 4th act.
- A loss on match 1 of act 1 ends the run immediately with minimal fragments.
- The shop must not appear after a boss fight even if the boss fight is won.
- The win streak counter resets to 0 on any loss (even if the run continues — which it doesn't, but the counter logic should be clean).
- If meta-progression is not yet implemented (feature 10), the Fragment display on the run summary screen can show earned totals without applying them.

---

## Acceptance Criteria

- A full run sequences through exactly 12 matches (9 regular + 3 bosses) if the player wins all of them.
- The shop opens after every won regular match and is skipped after boss fights.
- A loss at any point ends the run and routes to the run summary screen.
- The run summary screen displays correct scores, fragments, and bag state.
- Fragments are awarded correctly for each milestone, including partial runs.
- The board resets to empty at the start of every match.
- The player's bag and chips carry over correctly between matches.

---

## Dependencies

- Feature 03 — Scoring system
- Feature 04 — AI opponent
- Feature 07 — Shop
- Feature 08 — Enemy gimmicks

## Required by

- Feature 10 — Meta-progression
