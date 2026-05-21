# Feature 21 — Shop Reroll Juice
*Plummet · Shop juice · Plummet*

## Purpose

Reroll should feel like a **machine**: pay chips, old offers tumble away, new ones deal in. Not a silent data refresh.

---

## Scope

- Reroll button press feedback (uses `JuicySfxButton` + extra shake optional)
- Chip spend juice on reroll (feature 16 `−5` floater)
- **Exit** animation for current visible offer cards
- **Deal-in** animation for new offers (reuse feature 19)
- Disable input during reroll sequence (~0.4–0.6s total)
- `reroll` SFX once per press (feature 18)

## Not in scope

- Changing reroll cost or once-per-visit rule (feature 07)
- Rolling new offer weights / pool logic

---

## Dependencies

- Feature 07 — `_on_reroll`, `_roll_offers`, `_rerolled` flag
- Feature 16 — Chip tween `−5`
- Feature 19 — Offer deal-in / consumed exit tweens
- Feature 18 — `reroll` sound
- `JuicySfxButton` on `%RerollBtn`

---

## Sequence (single reroll press)

| Step | Time | Action |
|------|------|--------|
| 0 | 0 | Disable shop input; validate chips ≥ 5 and not `_rerolled` |
| 1 | 0 | Button click juice (JuicySfxButton) + `reroll` SFX |
| 2 | 0 | Chip spend: `_chips -= 5`, chip tween + `−5` floater (feature 16) |
| 3 | 0–0.18 | **Exit** all visible offer cards (consumed spacers included if visible): scale down, fade out |
| 4 | 0.18 | `_offers = _roll_offers()`, reset `_offer_used`, `_rerolled = true` |
| 5 | 0.18 | `_refresh_offers()` data; cards visible but start offset/transparent for deal-in |
| 6 | 0.18–0.45 | **Deal-in** new cards (stagger 0.05–0.07s each, feature 19) |
| 7 | end | Enable input; reroll button shows “Rerolled” disabled (existing) |

Total target: **≤ 0.6s** before player can drag again.

---

## Exit animation (old offers)

Same as feature 19 consumed exit, applied to **all** offer card nodes with `visible == true`:

| Parameter | Value |
|-----------|-------|
| Parallel | Yes — all cards exit together |
| Scale | `1 → 0.8` |
| Modulate | `a → 0` |
| Duration | `0.16–0.2s` |
| Ease | `EASE_IN` |

Do not leave invisible consumed spacers mid-animation — reset card visibility for reroll (`set_consumed(false)` on refresh).

---

## Deal-in (new offers)

Call shared `ShopScreen._play_offer_deal_in()` used on shop open (feature 19).

Stagger only `mini(_offer_count, _offers.size())` cards.

---

## Reroll button extra juice

`%RerollBtn` is already `JuicySfxButton`. Optional add:

| Effect | Value |
|--------|-------|
| Press | Brief `rotation_deg` wiggle `±4°` over `0.1s` |
| Disabled state | After sequence, label “Rerolled” — no pulse |

---

## Partial purchase before reroll

Per feature 07: reroll replaces **all** slots including already-purchased offers. Exit animation runs on empty spacers too — they become visible briefly for exit or skip if `modulate.a == 0`:

- Force `set_consumed(false)` and `visible = true` with `modulate.a = 0` before exit, OR
- Only animate cards that had content this visit

**Recommended:** animate only cards that were showing offers (`i < _offers.size()` before reroll), not consumed spacers.

---

## Audio

| Cue | When |
|-----|------|
| `reroll` | Step 1, once |
| `chip_spend` | Step 2 (or rely on chip juice only) |
| Deal-in slides | Optional per-card during step 6 |

---

## Reduced motion

- Instant `_roll_offers` + `_refresh`
- No exit/deal-in tweens
- Keep SFX optional / quiet

---

## Implementation notes

### Files to touch

- `scripts/visual/shop_screen.gd` — async `_on_reroll`, extract `_play_offer_exit()`, `_play_offer_deal_in()`
- `scripts/visual/shop_offer_card.gd` — `play_exit()` / `prepare_deal_in()`

### API sketch

```gdscript
func _on_reroll() -> void:
    if _rerolled or _chips < COST_REROLL:
        return
    _set_input_enabled(false)
    _audio.play_reroll()
    _spend_chips(COST_REROLL)
    await _play_offer_exit()
    _offers = _roll_offers()
    _offer_used.fill(false)
    _rerolled = true
    _refresh_offers()
    await _play_offer_deal_in()
    _set_input_enabled(true)
    _refresh()  # reroll btn disabled state
```

---

## Acceptance criteria

- [ ] Pressing Reroll plays shuffle SFX and chip spend feedback
- [ ] Old offers visibly leave before new offers appear
- [ ] New offers deal in with stagger (same as shop open)
- [ ] Player cannot drag or buy during the reroll sequence
- [ ] Reroll button ends disabled with “Rerolled” text
- [ ] Reduced motion performs instant swap without blocking input long

---

## Related features

- 16 — Chip floater `−5`
- 18 — `reroll` + `chip_spend` audio
- 19 — Deal-in / exit card animations
