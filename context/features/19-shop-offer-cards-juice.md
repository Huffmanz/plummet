# Feature 19 — Shop Offer Cards Juice
*Plummet · Shop juice · Plummet*

## Purpose

Offer cards are the shop’s menu. They should **deal in** on open, respond to hover, and communicate affordable vs unaffordable vs relic-tier without tooltips.

---

## Scope

- Staggered **deal-in** when shop opens (after feature 15 enter completes)
- **Hover** feedback on offer cards (scale / border brighten)
- **Unaffordable** state: slow pulse or muted pulse (not only flat 42% dim)
- **Relic** cards: subtle teal border shimmer / pulse
- **Consumed** offers: exit animation before invisible spacer (scale down + fade)
- Optional: `FREE` pop on footer when Patron cost is 0

## Not in scope

- Card layout / copy (feature 07 — on-card description done)
- Drag lift / row dim (feature 17)
- Reroll shuffle animation (feature 21 — may call same deal-in)

---

## Dependencies

- Feature 07 — `ShopOfferCard`, `_offer_cards`, `set_affordable`, `set_consumed`
- Feature 15 — Enter transition (deal-in starts after)
- Feature 18 — `play_random_overlapping` for deal-in slide SFX (reuse `drag_pickup` or dedicated slide stream)

---

## Deal-in (shop open)

After enter transition and `ShopScreen` input enabled:

### Targets

- All **visible** offer cards for this visit (`0 .. _offer_count-1`, not hidden Offer3 unless Almanac)

### Motion

| Parameter | Value |
|-----------|-------|
| Pattern | Stagger left → right (index 0 first) |
| Per card delay | `0.05–0.07s` |
| Start offset | `+32px` Y or `+24px` X slide up (choose one; Y feels like “dealing”) |
| Start modulate | `a = 0` |
| Duration | `0.22–0.28s` per card |
| Ease | `EASE_OUT`, `TRANS_BACK` (slight overshoot `1.03` scale optional) |
| End | `position` rest, `modulate = WHITE` or affordable dim |

### Reference implementation

Consider reusing `StaggerFlyInContainer` pattern (`scripts/ui/stagger_fly_in_container.gd`) or a dedicated `ShopOfferDealIn` helper that tweens each `ShopOfferCard`.

### Audio

- One `play_random_overlapping` per card at stagger time (slide stream), OR
- Single shuffle sound at start — prefer per-card quiet slide with pitch vary

---

## Hover (not dragging)

When mouse over affordabled, non-consumed `ShopOfferCard` and **not** dragging:

| Effect | Value |
|--------|-------|
| Scale | `1.0` → `1.03` over `0.12s` |
| Border | Brighten `StyleBoxFlat.border_color` toward `UITheme.SURFACE_BORDER` full opacity |
| Cursor | `GameCursor.apply_open()` (existing) |

On exit: restore scale `1.0` over `0.1s`.

**While dragging:** suppress card hover (feature 17 controls row).

### Implementation

- Wrap card content in `VisualPivot` `Control` (like `JuicySfxButton`) so scale doesn’t fight `PanelContainer` layout, OR tween `scale` on card with `pivot_offset = size * 0.5`

---

## Unaffordable state

When `set_affordable(false)` and not consumed:

| Effect | Value |
|--------|-------|
| Base modulate | `Color(1,1,1,0.42)` (keep) |
| Pulse | Loop `modulate.a` 0.35 ↔ 0.48 over `1.2s` sine (subtle) |
| Footer color | `TEXT_MUTED_ON_SURFACE` (keep) |
| Drag | Disabled (keep) |

When affordable again: stop pulse tween.

---

## Relic card accent

When `is_relic == true` in `setup`:

| Effect | Value |
|--------|-------|
| Border | Teal `RELIC_BORDER`, 3px (existing) |
| Shimmer | Loop border `modulate` or `border_color` lerp toward lighter teal over `1.5s` |
| Optional | Very slow scale breathe `1.0` ↔ `1.008` |

Do not apply shimmer to modifier/piece_type cards.

---

## Consumed offer exit

When `set_consumed(true)` **before** invisible spacer state:

| Step | Value |
|------|-------|
| 1 | Tween scale `1 → 0.85`, modulate `a → 0` over `0.18s` |
| 2 | Then `_apply_consumed_appearance()` (invisible spacer, no panel) |

Prevents layout “pop” when siblings resize.

On reroll (feature 21): all visible cards exit, then new deal-in.

---

## Patron free footer

When `offer_cost == 0` for relic:

- Footer text: `"Free · drag to relic row"` (existing)
- Optional one-shot: footer label scale pop `1 → 1.15 → 1` on card deal-in

---

## Reduced motion

- Instant show all cards at full opacity
- No hover scale, no pulse, no shimmer
- Consumed: skip exit tween

---

## Implementation notes

### Files to touch

- `scripts/visual/shop_offer_card.gd` — hover, pulse, consumed exit, relic shimmer
- `scripts/visual/shop_screen.gd` — trigger deal-in after open
- Optional: `scripts/visual/shop_offer_deal_in.gd`

### Do not

- Re-enable tooltips (copy is on-card)

---

## Acceptance criteria

- [ ] Visible offer cards animate in staggered on each shop visit open
- [ ] Hovering an affordable offer slightly scales/highlights the card
- [ ] Unaffordable offers have a visible pulse, not only static dim
- [ ] Relic offers have a subtle ongoing teal accent animation
- [ ] Purchasing an offer shrinks/fades the card before it becomes a layout spacer
- [ ] Deal-in and hover respect reduced motion

---

## Related features

- 15 — Enter transition timing
- 17 — Drag (suppress hover during drag)
- 18 — Deal-in slide SFX
- 21 — Reroll (exit + re-deal)
