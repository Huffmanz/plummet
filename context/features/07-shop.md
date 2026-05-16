# Feature 07 — Shop
*Plummet · Game Jam Build*

## Purpose

The shop is the primary expression point between matches. The player spends Chips earned during the match to attach modifiers, upgrade piece types, or remove unwanted modifiers from their bag. It appears after every won match.

---

## Scope

- Chip economy (earning and spending)
- Modifier offers (3 per visit, rerollable once)
- Attach modifier action
- Remove modifier action
- Upgrade piece type action
- Win-only gating

Not in scope: meta-progression unlocks (feature 10), which affect the modifier and piece type pool available in the shop.

---

## When the Shop Appears

The shop opens after a won match only. A lost match skips the shop entirely — the player proceeds directly to the next match (or the run ends if it was the final match).

---

## Chip Economy

### Earning chips

| Event | Chips |
|---|---|
| Win a match | 15 |
| Each clear during the match | 1 |
| Win streak bonus (2nd consecutive win) | +5 |
| Win streak bonus (3rd+ consecutive win) | +5 additional per win |

Chips accumulate across the run. Unspent chips carry over to the next shop visit.

### Spending chips

| Action | Cost |
|---|---|
| Attach a modifier to a piece | 10 chips |
| Remove a modifier from a piece | 5 chips |
| Upgrade a piece type (Normal → Weighted or Ghost) | 20 chips |
| Reroll modifier offers | 5 chips (once per shop visit) |

---

## Modifier Offers

The shop presents 3 modifiers for the player to choose from. The player may attach one of them to any piece in their bag that has fewer than 3 modifiers.

### Offer generation

Draw 3 modifiers at random from the available pool. The pool is determined by:

- Which modifiers have been unlocked in meta-progression (feature 10)
- Which act the player is on (some modifiers only appear from act 2 onward)

Higher-tier modifiers (Tier II, unlocked via meta-progression) have a lower appearance weight than base modifiers.

### Reroll

The player may reroll the 3 offers once per shop visit for 5 chips. Rerolling replaces all 3 offers with 3 new draws from the pool. Offers already dismissed cannot be recovered.

### Attaching a modifier

After selecting a modifier offer, the player selects which piece in their bag to attach it to. A piece that already holds 3 modifiers cannot be selected. The chip cost is deducted on confirmation.

---

## Remove Modifier Action

The player may remove any modifier from any piece in their bag for 5 chips. This is useful for clearing a piece slot to make room for a better modifier, or for removing a modifier that has become a liability.

Removed modifiers are discarded — they do not return to the pool or go to the player's inventory.

---

## Upgrade Piece Type Action

The player may upgrade any Normal piece in their bag to Weighted or Ghost (if Ghost is unlocked) for 20 chips.

- Only Normal pieces can be upgraded.
- The piece retains all its existing modifiers after upgrading.
- Volatile pieces cannot be created via upgrade — they appear as separate shop offers (a new piece is added to the bag, making the bag temporarily 8 pieces, then normalizing at the start of the next match by removing the oldest Normal piece if the bag exceeds 7).

---

## Shop State

The shop must display:

- The player's current chip count
- The 3 modifier offers
- The player's full piece bag with current types and modifiers on each piece
- Which pieces are eligible for modifier attachment (fewer than 3 modifiers)
- Which pieces are eligible for type upgrade (Normal type only)
- The cost of each available action
- Whether the reroll has been used this visit

---

## Leaving the Shop

The player confirms they are done with the shop to proceed to the next match. There is no time limit. Unspent chips carry over.

---

## Edge Cases

- If the player has 0 chips, all paid actions are disabled. The shop still opens — the player can view their bag even if they cannot afford anything.
- If all pieces in the bag already have 3 modifiers, the modifier attach action is unavailable even if the player selects an offer.
- If no Normal pieces remain in the bag, the upgrade action is unavailable.
- Ghost upgrade must check that Ghost is unlocked in meta-progression before appearing as an option.
- If the modifier pool has fewer than 3 available modifiers (very early runs, few unlocks), show as many as available without padding.

---

## Acceptance Criteria

- The shop does not appear after a lost match.
- Chips earned during a match are correctly totalled and available at the shop.
- A win streak of 3 adds 25 chips total (15 + 5 + 5).
- Attaching a modifier costs 10 chips and correctly places it on the chosen piece.
- A piece with 3 modifiers cannot receive a 4th.
- Removing a modifier costs 5 chips and removes it from the piece.
- Upgrading a piece type costs 20 chips and correctly changes the type while preserving modifiers.
- Rerolling costs 5 chips and replaces all 3 offers. Reroll is unavailable after being used once.
- Unspent chips carry over to the next shop.

---

## Dependencies

- Feature 05 — Piece bag + modifiers
- Feature 06 — Piece types

## Required by

- Feature 09 — Run loop
- Feature 10 — Meta-progression (affects available pool)
