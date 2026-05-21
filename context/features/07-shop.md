# Feature 07 — Shop
*Plummet · Game Jam Build*

## Purpose

The shop is the primary expression point between matches. The player spends Chips to attach modifiers, upgrade piece types, and acquire relics. It is a full-screen takeover with a drag-to-attach interaction model — no confirmation dialogs, no multi-step menus. Every action is a single gesture.

---

## Scope

- Full-screen layout (four sections: topbar, offers, bag, relics)
- Chip economy (earning and spending)
- Offers row (modifiers and relics, 3 cards per visit, rerollable once)
- Drag-to-attach interaction for modifiers and relics
- Remove modifier action (via × button on piece)
- Piece type upgrade (via click on piece)
- Win-only gating

Not in scope: meta-progression unlocks (feature 10), which affect the offer pool. Board cascade animations and sound (feature 11).

### Shop juice (companion specs)

| Feature | Topic |
|---------|--------|
| [15-shop-enter-exit](15-shop-enter-exit.md) | Full-screen enter/exit via `TransitionManager` |
| [16-shop-chip-juice](16-shop-chip-juice.md) | Chip count tween, spend flash, `−N` floaters |
| [17-shop-drag-juice](17-shop-drag-juice.md) | Drag lift, valid/invalid hover, drop snap |
| [18-shop-audio](18-shop-audio.md) | All shop SFX via `RandomAudioPlayer` (sound list + filenames TBD) |
| [19-shop-offer-cards-juice](19-shop-offer-cards-juice.md) | Deal-in, hover, relic shimmer, consumed exit |
| [20-shop-bag-juice](20-shop-bag-juice.md) | Piece breathe, badge pop, type morph, remove juice |
| [21-shop-reroll-juice](21-shop-reroll-juice.md) | Reroll exit shuffle + re-deal |

---

## When the Shop Appears

The shop opens after a won match only. A lost match skips the shop — the player proceeds directly to the next match or the run ends. The shop does not appear after boss fights.

---

## Layout

The shop is a full-screen takeover. The board is not visible while the shop is open. Four sections read top to bottom:

### 1. Topbar
- Left: "Shop" title + chip count (always visible, updates immediately on any purchase)
- Right: "Continue →" button (always reachable, no scroll required)

### 2. Offers row
Three offer cards displayed side by side. Each card shows:
- Icon (color-coded by category)
- Name
- Type label (modifier + trigger type, or "relic · run-wide")
- One-sentence description
- Cost in chips
- Drag instruction ("drag onto any piece" or "drag to relic row")

Effect summary is shown on the card body (no hover tooltip).

Modifier cards and relic cards are visually distinguished — relics have a teal border accent.

A reroll button sits in the top-right of the offers section. It shows the chip cost and is greyed out after use.

### 3. Bag
All 7 pieces displayed in a horizontal row. Each piece slot shows:
- Piece circle (color and shape reflect piece type)
- Piece type label
- Modifier badge (shows modifier name, or "no modifier" as a dashed outline badge if empty)

Hovering a piece slot reveals a small × button in the top-right corner to remove its modifier.

When a modifier card is being dragged, eligible piece slots (those without a modifier) highlight as drop targets. Ineligible slots (already have a modifier) do not highlight.

### 4. Relics row
Four relic slots displayed horizontally below the bag. Each slot shows:
- Occupied: relic icon + name + one-line summary
- Empty: dashed outline with "empty slot" label

When a relic card is being dragged, empty relic slots highlight as drop targets.

---

## Interaction Model

### Attaching a modifier
1. Player drags a modifier offer card.
2. Eligible piece slots in the bag highlight.
3. Player drops the card onto a piece slot.
4. The modifier badge on that piece updates immediately.
5. Chips are deducted immediately. No confirmation dialog.

### Acquiring a relic
1. Player drags a relic offer card.
2. Empty relic slots highlight.
3. Player drops the card onto an empty relic slot.
4. The relic slot updates to show the relic name and summary.
5. Chips are deducted immediately. No confirmation dialog.

### Removing a modifier
1. Player hovers a piece slot — the × button appears.
2. Player clicks ×.
3. The modifier badge resets to "no modifier."
4. Chips are deducted immediately. No confirmation dialog.
5. The removed modifier is discarded — it does not return to the offer pool.

### Upgrading a piece type
1. Player clicks a piece slot (not dragging — a click opens an upgrade popover).
2. A small popover appears above the piece showing available upgrades for that type and their chip costs.
3. Player clicks an upgrade option.
4. The piece circle and type label update immediately.
5. Chips are deducted. Popover closes.

Only Normal pieces show upgrade options. Non-Normal pieces show an info popover describing the piece type instead.

---

## Chip Economy

### Earning chips

| Event | Chips |
|---|---|
| Win a match | 15 |
| Each clear during the match | 1 |
| Coin piece type clear bonus | +3 per Coin piece in the clear |
| Deposit modifier land bonus | +5 per Deposit piece on landing |
| Win streak (2nd consecutive win) | +5 |
| Win streak (3rd+ consecutive win) | +5 additional per win |

Chips accumulate across the run. Unspent chips carry over.

### Spending chips

| Action | Cost |
|---|---|
| Attach a modifier | 10 chips |
| Remove a modifier | 5 chips |
| Upgrade piece type (Normal → any) | 20 chips |
| Acquire a relic | 25 chips |
| Reroll offers | 5 chips (once per visit) |

---

## Offer Generation

Draw 3 items at random from the available pool. The pool contains modifiers and relics weighted as follows:

- Base modifiers: high weight (appear most often)
- Tier II modifiers (meta-progression unlocks): low weight (roughly ⅓ as likely as base)
- Common relics: medium weight
- Uncommon relics: low weight
- Rare relics: very low weight (roughly ½ as likely as uncommon)

The 3 offers may be any mix of modifiers and relics — the pool is not partitioned. A visit showing 3 relics is unlikely but valid.

Rerolling replaces all 3 offers with 3 new draws. The reroll button is unavailable after use and after the player has 0 chips (unless the reroll is the only action they can afford).

---

## Offer Availability Rules

- A modifier offer is unavailable to attach if all 7 pieces already have a modifier. The card is still shown but all piece slots are ineligible drop targets — the player must remove a modifier first.
- A relic offer is unavailable if all 4 relic slots are occupied. The card is still shown but relic slots do not highlight as drop targets.
- A piece type upgrade is unavailable if the piece is not Normal type, or if the target upgrade type is not yet unlocked in meta-progression.
- If the player cannot afford an action, the offer card and relevant interactive elements are visually dimmed. Drag is disabled. The chip cost is shown in a muted color.

---

## Leaving the Shop

The "Continue →" button is always visible in the topbar. Clicking it closes the shop and begins the next match. There is no time limit. Unspent chips carry over.

---

## Edge Cases

- If the player has 0 chips and cannot afford any action, the shop still opens. Offer cards are dimmed. The bag and relics are visible for review. The player can continue immediately.
- If all 7 pieces already have a modifier and no relic slots are open, all offer cards are effectively inert — the player can only reroll (if affordable) or continue.
- If the modifier pool has fewer than 3 available items (very early runs), show as many as available. Do not pad with duplicates.
- Dragging a relic card onto a piece slot (wrong target) should have no effect — the slot does not highlight and the drop is ignored.
- Dragging a modifier card onto a relic slot (wrong target) has no effect.
- If the player upgrades a piece type that already has a modifier, the modifier is preserved on the upgraded piece.
- Reroll after a partial purchase (e.g. one offer already purchased): the remaining 2 offers are replaced along with the purchased slot — the player gets 3 fresh offers.

---

## Acceptance Criteria

- The shop does not appear after a lost match or after a boss fight.
- Chip count in the topbar updates immediately after every purchase.
- Dragging a modifier card onto an eligible piece slot attaches the modifier and deducts 10 chips.
- Dragging a modifier card onto a piece that already has a modifier has no effect.
- Dragging a relic card onto an empty relic slot acquires the relic and deducts 25 chips.
- Clicking × on a piece removes its modifier and deducts 5 chips.
- Clicking a Normal piece opens an upgrade popover with available upgrades.
- Upgrading a piece type preserves its existing modifier.
- Rerolling costs 5 chips, replaces all 3 offers, and disables the reroll button for the rest of the visit.
- Offer cards are visually dimmed and non-interactive when the player cannot afford them.
- Unspent chips carry over to the next shop visit.
- The "Continue →" button is always visible and functional regardless of shop state.

---

## Dependencies

- Feature 05 — Piece types, modifiers, and relics (definitions and bag structure)
- Feature 03 — Scoring system (chip earning from clears)

## Required by

- Feature 09 — Run loop (shop gating, boss drop relic flow)
- Feature 10 — Meta-progression (affects available offer pool)
- Feature 12 — Visual layer (shop screen layout and drag interaction rendering)
