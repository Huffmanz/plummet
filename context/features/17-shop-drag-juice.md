# Feature 17 — Shop Drag Pipeline Juice
*Plummet · Shop juice · Plummet*

## Purpose

Drag-and-drop is the shop’s core interaction. Juice should make valid targets obvious, invalid targets silent, and a successful drop feel like the offer **snapped into** the bag or relic row.

---

## Scope

- Offer card **lift** when drag starts (scale, shadow, row dim)
- **Valid / invalid** hover feedback (cursor already custom; extend slot/card feedback)
- **Drop snap** — drag icon flies to target and dissolves; then purchase logic runs
- Rest of offer row dims while dragging
- Works for all offer kinds: `modifier`, `piece_type`, `relic`

## Not in scope

- Changing drag-and-drop rules (feature 07)
- Rotating dashed ring on piece slots (already implemented — tune only)
- Offer card layout / tooltip (removed)

---

## Dependencies

- Feature 07 — Shop drag payloads (`kind`, `index`, `id`, `cost`)
- `ShopOfferCard`, `ShopOfferDragIcon`, `ShopPieceSlot`, `ShopRelicSlot`
- `GameCursor` autoload (open / closed during drag)
- Feature 18 — Shop audio (`drag_pickup`, `drop_valid`, `drop_invalid`, attach-specific cues)

---

## Drag start (offer card)

When `ShopOfferCard._start_drag()` runs:

### Card being dragged

| Effect | Value |
|--------|-------|
| Hidden | Card stays `modulate.a = 0` (current) — keep |
| Cursor icon | Existing `ShopOfferDragIcon` at cursor |

### Rest of offer row

| Effect | Value |
|--------|-------|
| Other visible offer cards | `modulate = Color(1,1,1,0.45)` |
| Consumed / invisible spacers | Unchanged |

### Dragging card’s row slot

The consumed card’s spacer: no change (already invisible).

### Audio

Play `drag_pickup` (feature 18) once on drag start.

---

## Valid hover feedback

### Modifier → empty piece

- `ShopPieceSlot.set_drop_highlight(true)` — rotating dashed ring (existing)
- Ring: optional brighten `modulate` to `Color(1.2, 1.2, 1.2, 1)` while highlighted
- Ring rotation speed: optional `ROT_SPEED * 1.4` while hover active

### Piece type → any piece

- All pieces highlight (existing logic)
- Same ring tuning

### Relic → empty relic slot

- `ShopRelicSlot` highlight (existing accent fill border)
- Optional: pulse border `modulate` 1.0 ↔ 1.15 over `0.5s` loop while highlighted

### Invalid hover

- Modifier on occupied piece: **no** ring
- Relic on piece slot: no highlight
- Modifier/piece type on relic slot: no highlight
- Optional: play `drop_invalid` once per hover enter (throttle 200ms) — quiet, not spammy

`GameCursor` stays **closed** during drag (existing).

---

## Drop snap (before purchase resolves)

On successful `_drop_data` (piece or relic slot):

1. **Do not** apply purchase instantly on drop frame 0
2. Tween drag icon from cursor position to target center:

| Parameter | Value |
|-----------|-------|
| Duration | `0.14–0.18s` |
| Ease | `EASE_OUT`, `TRANS_BACK` (slight overshoot optional) |
| End scale | `0.4` or fade `modulate.a` → 0 |
| End | `queue_free()` icon, then call existing purchase handler |

3. Play kind-specific SFX at snap land (feature 18):
   - `modifier_attach` / `piece_type_apply` / `relic_acquire`

4. Run `_apply_*_offer` / `_on_relic_dropped` after snap completes (~0.15s total delay acceptable)

### Target center

- Piece slot: center of `ShopPiecePreview` circle (slot `size * 0.5`)
- Relic slot: center of empty slot panel

### Failed drop (drag end without valid target)

- `NOTIFICATION_DRAG_END` on card: restore row modulate, clear highlights
- No snap animation
- Optional quiet `drop_invalid` if drag had movement

---

## Drag end cleanup

On `drag_ended` / `NOTIFICATION_DRAG_END`:

| Item | Action |
|------|--------|
| Offer row modulate | Reset all cards to affordable dim or `WHITE` |
| Piece/relic highlights | `set_drop_highlight(false)` (existing) |
| Cursor | `GameCursor` refresh via shop (existing) |

---

## Implementation notes

### Files to touch

- `scripts/visual/shop_offer_card.gd` — row dim on drag; defer purchase to snap
- `scripts/visual/shop_offer_drag_icon.gd` — `snap_to(global_pos, callback)`
- `scripts/visual/shop_screen.gd` — orchestrate snap then `_apply_*`; dim offer cards array
- `scripts/visual/shop_drop_ring_overlay.gd` — optional faster spin when active
- `scripts/visual/shop_relic_slot.gd` — optional border pulse while highlighted

### Order of operations (successful drop)

```
drop_data emitted
  → shop_screen intercepts OR slot calls screen with snap first
  → tween icon to target
  → on complete: apply purchase, _refresh(), chip juice, bag/offer juice
```

Prefer single orchestrator in `shop_screen.gd` to avoid duplicate purchases.

### Reduced motion

- Skip snap tween; apply purchase immediately
- Keep highlight on/off instantly

---

## Acceptance criteria

- [ ] Starting a drag dims other offer cards in the row
- [ ] Valid piece/relic slots are clearly highlighted during drag
- [ ] Invalid slots never highlight
- [ ] Successful drop: icon moves to target and fades/shrinks before bag/relic UI updates
- [ ] Failed drop: no purchase, cards un-dim, highlights clear
- [ ] Modifier, piece type, and relic drags all use the same pipeline
- [ ] Total snap delay ≤ `0.2s` — shop still feels snappy

---

## Related features

- 18 — Shop audio
- 19 — Offer cards (card hover separate from drag)
- 20 — Bag juice (badge pop after snap completes)
