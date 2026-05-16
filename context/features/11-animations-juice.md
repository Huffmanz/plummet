# Feature 11 — Animations + Juice
*Plummet · Game Jam Build*

## Purpose

Juice is everything that makes the game feel good without changing the rules. This feature covers clear animations, cascade timing, score popups, screen shake, and sound cues. For a jam entry, feel is often what separates a good game from a great one.

---

## Scope

- Piece drop animation
- Clear animation
- Cascade timing and pacing
- Gravity settle animation
- Score popups
- Screen shake
- Sound cues
- Combo announcement text

Not in scope: UI transitions between screens (shop, run summary) — those are handled as part of the relevant features.

---

## Design Principles

- Every player action should produce immediate visual feedback.
- Cascades should feel like a chain reaction — each level slightly faster than the last, building excitement.
- Score popups should reinforce what just happened — the player should be able to read the board and understand their score without looking at the scoreboard.
- Juice should never obscure gameplay — animations must complete or be interruptible before the next turn begins.

---

## Piece Drop Animation

When a piece is dropped:

1. The piece appears at the top of the selected column.
2. It animates downward at a consistent speed to its landing row.
3. On landing, a brief squash-and-stretch: the piece compresses vertically then rebounds to full size over approximately 3 frames.
4. Landing produces a short impact sound (see Sound Cues).

Drop speed should feel snappy — fast enough to not feel sluggish, slow enough that the player can track where it lands.

---

## Clear Animation

When a clear is detected:

1. The matching cells flash once (bright fill, approximately 2 frames).
2. The cells then contract to a point and disappear over approximately 6 frames.
3. A clear sound plays at the moment of disappearance.

If multiple clears happen simultaneously (same cascade depth), all matching cells animate together.

---

## Cascade Timing

The cascade loop should be paced visually — do not resolve instantly.

- After each clear animation completes, pause briefly (approximately 8 frames) before running gravity.
- Gravity settle animates: pieces fall at a consistent speed to their new positions.
- After gravity settles, pause briefly (approximately 4 frames) before checking for the next clear.

As cascade depth increases, shorten the pause between steps by approximately 10% per level. A deep cascade (depth 4+) should feel rapid and exciting, not methodical.

---

## Score Popups

When a clear occurs, display a floating score popup above the cleared cells:

- Show the points awarded for that specific clear.
- If a cascade multiplier applies, show the multiplier alongside the base value (e.g. "100 ×2").
- If the cross-color bonus applies, show a separate "+150 CHAIN" popup.
- Popups float upward and fade out over approximately 30 frames.
- Multiple simultaneous popups should stack vertically to avoid overlap.

---

## Screen Shake

Screen shake is used sparingly for high-impact moments only:

| Event | Shake intensity |
|---|---|
| Cascade depth 2 | Light shake (2px, 4 frames) |
| Cascade depth 3+ | Medium shake (4px, 6 frames) |
| Volatile explosion | Medium shake (4px, 6 frames) |
| Board flip (The Inverter) | Heavy shake (8px, 12 frames) |
| Match win | Light shake (2px, 4 frames) |

Shake should never trigger on routine drops or first-level clears — it must remain meaningful.

---

## Combo Announcement Text

When a cascade reaches depth 2 or higher, display a brief combo announcement in the center of the board:

| Depth | Text |
|---|---|
| 2 | "COMBO" |
| 3 | "CHAIN" |
| 4+ | "CASCADE" |

Text appears large, fades in quickly (4 frames), holds briefly (12 frames), then fades out (8 frames). Does not block gameplay — purely cosmetic overlay.

---

## Sound Cues

All sounds should be short and non-intrusive. A minimal set for the jam:

| Event | Sound |
|---|---|
| Piece lands | Short low thud |
| 4-in-a-row clear | Bright chime |
| 5+ clear | Brighter, longer chime |
| Cascade (each level) | Ascending tone per level |
| Cross-color chain bonus | Distinct two-tone flourish |
| Volatile explosion | Short burst |
| Match win | Short fanfare |
| Match loss | Short descending tone |
| Shop open | Soft click |
| Modifier attached | Positive chime |
| Enemy gimmick trigger | Distinct per-enemy cue (lower, slightly ominous) |

Sound can be implemented with a minimal audio library or browser audio APIs. All sounds should be optional — include a mute toggle.

---

## Accessibility Considerations

- All juice effects are cosmetic — the game must be fully playable with all animations disabled.
- Consider a reduced motion option that skips animations and shows final states immediately.
- Screen shake should be disableable independently — it can cause discomfort for some players.
- Score information must be readable from the scoreboard alone, not just the popups.

---

## Implementation Priority

For the jam, implement in this order — stop when time runs out:

1. Clear animation (highest impact, most immediately satisfying)
2. Score popups (makes scoring legible without the scoreboard)
3. Piece drop animation (polish on every action)
4. Cascade timing and pacing (makes combo chains exciting)
5. Sound cues (transforms the feel of every interaction)
6. Screen shake (high drama for big moments)
7. Combo announcement text (nice to have)

---

## Acceptance Criteria

- Pieces animate downward to their landing position visibly.
- Cleared cells animate out before gravity runs.
- Score popups appear above cleared cells with correct values.
- Cascade multipliers appear in the popup correctly.
- Cross-color chain bonus displays as a distinct popup.
- Screen shake triggers on cascade depth 2+ and Volatile explosions.
- Combo text appears on cascade depth 2+.
- Sound plays on clear, land, and cascade.
- All animations complete before the next turn input is accepted.
- A mute option disables all sounds.

---

## Dependencies

- Feature 01 — Board engine (board rendering to layer animations over)
- Feature 02 — Cascade loop (cascade depth for timing and shake)
- Feature 03 — Scoring system (score delta for popups)

## Required by

- Nothing (this is a polish layer over all other features)
