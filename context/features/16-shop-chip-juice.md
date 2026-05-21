# Feature 16 — Shop Chip Counter Juice
*Plummet · Shop juice · Plummet*

## Purpose

Chips are the shop’s only currency. The topbar count should feel as important as the match score: immediate feedback on every spend, readable at a glance, and satisfying without slowing purchases.

---

## Scope

- Animated chip count in topbar (`%ChipLabel`) when value changes
- Brief color flash on **spend** (and optional subtle pulse on display refresh)
- Floating `−N` text near chip label on spend (optional but recommended)
- Sync displayed value with actual `_chips` after animation completes (no desync)

## Not in scope

- Chip **earning** animation on match win (happens before shop opens; can be separate polish)
- Patron “FREE” relic pricing UI (see offer cards / purchase feedback)
- Changing chip costs or economy rules (feature 07)

---

## Dependencies

- Feature 07 — Shop (`_chips`, `_refresh`, purchase handlers)
- Feature 18 — Shop audio (`chip_spend` cue, optional)
- Feature 15 — Enter transition (chip label can animate from pre-shop total after enter)

---

## UI target

- Node: `ShopScreen` → `%ChipLabel` (topbar)
- Theme: keep `UITheme.ACCENT` override on chip label; flash uses `UITheme.ACCENT_POP` or brief `Color(2,2,2,1)` modulate spike

---

## Count-up / count-down tween

When `_chips` changes from purchase, remove, reroll, or upgrade popover:

| Parameter | Value |
|-----------|-------|
| Method | `create_tween().tween_method()` on displayed integer |
| Duration | `0.28s` |
| Ease | `Tween.EASE_OUT`, `Tween.TRANS_QUAD` |
| Chain | New spend cancels in-flight tween and starts from **current displayed** value, not stale target |

### Implementation pattern

```gdscript
var _displayed_chips: int = 0
var _chip_tween: Tween

func _animate_chips_to(target: int, spent_delta: int = 0) -> void:
    if _chip_tween != null and _chip_tween.is_valid():
        _chip_tween.kill()
    _chip_tween = create_tween()
    _chip_tween.tween_method(
        func(v): _set_chip_display(int(v)),
        float(_displayed_chips),
        float(target),
        0.28
    ).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
    _displayed_chips = target
    if spent_delta > 0:
        _flash_chip_spend()
        _spawn_chip_floater(-spent_delta)
```

`_set_chip_display(v)` sets `"%d chips" % v`.

Call from `_refresh()` only when chips changed, or directly from each purchase handler before `_refresh()` to avoid double animation.

---

## Spend flash

On any **deduction** (`spent_delta > 0`):

1. Tween `ChipLabel` modulate to `Color(2.0, 1.2, 0.5, 1.0)` (warm gold spike) over `0.06s`
2. Return to `Color.WHITE` over `0.12s`
3. Do not block input

| Parameter | Value |
|-----------|-------|
| Total flash time | ~`0.18s` |
| Stacks with count tween | Yes |

---

## Floating spend text (`−N`)

Spawn a small `Label` child on topbar (or dedicated `ChipFxLayer` `Control`):

| Parameter | Value |
|-----------|-------|
| Text | `"−%d" % amount` |
| Font size | `10–11` |
| Color | `UITheme.ACCENT_POP` |
| Start position | Offset right of chip label (`+8px x`, `-4px y`) |
| Motion | Drift up `12px` over `0.35s` |
| Fade | `modulate.a` 1 → 0 over same duration |
| Cleanup | `queue_free()` after tween |

Only on spends, not on reroll if you want reroll-specific FX (feature 21 may use its own floater).

### Spend amounts to show

| Action | Delta shown |
|--------|-------------|
| Attach modifier | `−10` |
| Remove modifier | `−5` |
| Piece type offer / upgrade popover | `−20` |
| Relic | `−25` (or `−0` / hide floater if Patron free) |
| Reroll | `−5` (or handled by feature 21) |

---

## Free purchases (Patron)

When `_relic_purchase_cost() == 0`:

- Do **not** show `−0` floater
- Optional: brief `FREE` pop in gold (feature 19/21 overlap) — not required here

---

## Reduced motion

If reduced motion enabled:

- Snap label to final value instantly
- Skip floater and flash

---

## Implementation notes

### Files to touch

- `scripts/visual/shop_screen.gd` — centralize chip display updates
- Optional: `scripts/visual/shop_chip_fx.gd` + child node on topbar

### Avoid

- Animating chips in `_process` every frame
- Running chip tween on every `_refresh()` when value unchanged

---

## Acceptance criteria

- [ ] Buying anything updates the chip label with a visible count tween, not an instant snap
- [ ] Rapid purchases chain tweens from the current on-screen number
- [ ] Spends produce a brief gold/white flash on the chip label
- [ ] A `−N` floater appears on paid actions (except 0-cost Patron relic)
- [ ] Chip text still reads `"N chips"` format
- [ ] Reduced motion skips animation but keeps correct final value

---

## Related features

- 18 — Shop audio (`chip_spend`)
- 21 — Shop reroll juice (may share floater helper)
