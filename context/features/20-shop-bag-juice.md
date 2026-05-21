# Feature 20 — Shop Bag Row Juice
*Plummet · Shop juice · Plummet*

## Purpose

The bag row is where the player’s build lives. Pieces should feel alive between drags, and successful attachments should **pop** on the piece — not only update data.

---

## Scope

- Subtle **idle breathe** on bag piece previews
- **Modifier badge pop** when modifier attached (after drop snap)
- **Piece type morph** juice when type changes from offer or upgrade popover
- **× remove button** hover/click juice (align with `JuicySfxButton` feel)
- Drop ring tuning optional (brightness already in feature 17)

## Not in scope

- Bag layout / piece slot count (7 slots, feature 07)
- Upgrade popover layout (only juice when type applied)
- Relic row (separate slots)

---

## Dependencies

- Feature 07 — `ShopPieceSlot`, `ShopPiecePreview`, modifier remove
- Feature 17 — Drop snap timing (badge pop starts after snap)
- Feature 18 — `modifier_attach`, `piece_type_apply`, `modifier_remove`
- `ModifierIconBadge`, `shop_drop_ring_overlay.gd`

---

## Idle breathe (bag pieces)

Each `ShopPiecePreview` (or parent slot) while shop visible and not dragging:

| Parameter | Value |
|-----------|-------|
| Scale | `1.0` ↔ `1.006` loop |
| Period | `2.5–3.5s` per cycle (desync per slot by random phase offset) |
| Ease | sine in/out |
| Pivot | Center of piece circle |

### Rules

- Pause breathe on slot while `drop_highlight` active
- Pause all bag breathe while any offer is dragging (optional performance)
- **Reduced motion:** scale fixed at 1.0

### Implementation

- Small script on `ShopPiecePreview` or tween in `ShopPieceSlot.setup`
- Do not breathe the modifier badge separately (only the piece circle / preview root)

---

## Modifier badge pop

When `ShopPieceSlot` receives new modifier after purchase (or `_update_modifier_icon` with non-empty id post-attach):

| Step | Value |
|------|-------|
| 1 | Badge starts `scale = Vector2.ZERO` or `0.3` |
| 2 | Tween to `1.15` over `0.1s` `TRANS_BACK` |
| 3 | Settle to `1.0` over `0.08s` |
| 4 | Play `modifier_attach` SFX (feature 18) |

If badge already existed (refresh only): skip pop.

---

## Piece type morph

When `piece.type` changes on slot (`setup` after piece_type offer or popover upgrade):

| Step | Value |
|------|-------|
| 1 | `ShopPiecePreview` squash `scale.y = 0.85`, `scale.x = 1.1` over `0.06s` |
| 2 | Swap shader style / type in middle frame |
| 3 | Restore `scale = 1` over `0.12s` `TRANS_BACK` |
| 4 | Brief shader `modulate` flash `Color(1.4,1.4,1.4,1)` → white |
| 5 | Play `piece_type_apply` SFX |

Track previous type on slot to only run when type actually changed.

---

## Remove modifier (× button)

| Event | Juice |
|-------|-------|
| Hover | Scale `1.1`, same duration as `JuicySfxButton` hover `0.14s` |
| Press | Quick squash `0.9` → `1.0` |
| Success | Badge shrink `1 → 0` + fade `0.12s`, then clear modifier |
| SFX | `modifier_remove` |

Consider replacing raw `Button` with `JuicySfxButton` instance (small, danger styled) if layout allows.

---

## Drop ring (optional tuning)

Existing `ShopDropRingOverlay` rotation — optional:

- Increase `ROT_SPEED` slightly when highlight on (feature 17)
- One-shot ring brighten on highlight start

Not required if feature 17 covers hover feedback.

---

## Upgrade popover (piece click)

When player picks type from popover (`_apply_upgrade`):

- Use same **piece type morph** as drag apply
- Popover closes with quick fade `0.1s` (optional)
- Chip juice (feature 16) runs in parallel

---

## Reduced motion

- No breathe, no badge pop, no morph — instant `setup` state
- Remove modifier: instant badge hide

---

## Implementation notes

### Files to touch

- `scripts/visual/shop_piece_slot.gd`
- `scripts/visual/shop_piece_preview.gd`
- `scripts/visual/shop_screen.gd` — call `slot.play_attach_juice(kind)` after purchase
- `scenes/game/shop_piece_slot.tscn` — optional JuicySfxButton for remove

---

## Acceptance criteria

- [ ] Bag pieces have a subtle idle scale pulse while shop is open
- [ ] Attaching a modifier pops the badge in after drop completes
- [ ] Changing piece type squashes/morphs the preview visibly
- [ ] Removing a modifier animates the badge out and plays remove SFX
- [ ] Idle and attach animations pause under reduced motion

---

## Related features

- 16 — Chip spend floater on purchases
- 17 — Drop snap timing
- 18 — Bag SFX cues
