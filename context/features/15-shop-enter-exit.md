# Feature 15 — Shop Enter / Exit Transition
*Plummet · Shop juice · Plummet*

## Purpose

The shop should feel like a dedicated screen in the run, not an instant UI swap over the board. Reuse the project’s existing full-screen transition pipeline so opening and closing the shop matches the main menu and run flow.

---

## Scope

- Animated transition when the shop **opens** (after a won match, before interaction)
- Animated transition when the player presses **Continue →** (shop closes, next match or run flow resumes)
- Block shop input until the enter animation completes
- Optional: block match start until exit animation completes

## Not in scope

- Animations inside the shop (offers, bag, purchases) — see features 16–21
- Boss relic pick screen transitions
- Meta-progression shop unlock effects

---

## Dependencies

- Feature 07 — Shop (layout and `ShopScreen.open` / `shop_closed`)
- `TransitionManager` autoload (`scenes/autoload/transition_manager.tscn`)
- `TransitionManager.transition_screen(callback)` pattern (used by main menu)
- Feature 18 — Shop audio (`shop_open`, `shop_close` cues)

---

## When transitions run

| Event | Trigger location | Transition style |
|-------|------------------|------------------|
| Shop open | `GameBoard` after match win overlay dismisses, before `ShopScreen.open()` | Cover board → reveal shop (default: diagonal wipe, same as run) |
| Shop close | `ShopScreen` Continue pressed, before `shop_closed` emit / next match | Cover shop → reveal board or run controller |

Use `UITheme.CANVAS` (or existing `default_fade_color`) for wipe color so it matches cozy UI.

---

## Enter sequence (open)

1. Match end overlay hides (existing).
2. `await TransitionManager.transition_screen(func(): _open_shop_content())`
3. Inside callback:
   - `ShopScreen.open(bag, chips, relic_mgr)` — shop is hidden or at 0 opacity until callback runs at midpoint/reveal per transition design
   - Prefer: shop `visible = true` at reveal phase so player never sees half-built layout
4. After transition finishes:
   - Enable shop input (drag, buttons, piece click)
   - Play offer deal-in (feature 19) and any enter SFX (feature 18)

### Timing

| Parameter | Suggested value | Notes |
|-----------|-----------------|-------|
| Total duration | `0.4s` (match `TransitionManager.default_duration`) | Export on shop juice config if tunable |
| Input lock | Until `transition_finished` + deal-in complete | Avoid drag during wipe |

### Visual

- **Style:** `TransitionManager.Style.DIAGONAL_WIPE` (project default)
- Shop root starts at `modulate.a = 0` optional; transition reveal handles exposure
- Do not scale the whole shop on enter unless combined with offer stagger (feature 19 handles cards separately)

---

## Exit sequence (close)

1. Player presses Continue (already uses `JuicySfxButton` click SFX).
2. Disable shop input immediately (no new drags).
3. `await TransitionManager.transition_screen(func(): _finish_shop_close())`
4. Inside callback at appropriate midpoint:
   - `ShopScreen.hide()` or `visible = false`
   - `shop_closed.emit(chips_remaining)` — keep chip persistence logic unchanged
5. `GameBoard` / `RunController` resumes next match after transition completes.

### Timing

| Parameter | Suggested value |
|-----------|-----------------|
| Total duration | `0.4s` |
| Hide shop | At wipe midpoint (fully covered) |

---

## Implementation notes

### Files to touch

- `scripts/visual/game_board.gd` — wrap `_shop_screen.open(...)` in `transition_screen`
- `scripts/visual/shop_screen.gd` — wrap `_on_continue` exit; expose `open_immediate` vs `open_animated` if preview scene needs instant open
- `scripts/visual/shop_screen.gd` preview guard (`get_parent() == root`) — **skip transition** in editor preview so F6 test stays fast

### API sketch

```gdscript
# game_board.gd — after win
await TransitionManager.transition_screen(func():
    _shop_screen.open(_player_bag, _chip_count, _relic_manager)
)

# shop_screen.gd — continue
func _on_continue() -> void:
    _set_input_enabled(false)
    await TransitionManager.transition_screen(func():
        hide()
        shop_closed.emit(_chips)
    )
```

### Input gating

Add `_input_enabled: bool` on `ShopScreen`:

- `false` during transition and deal-in
- `false` during exit transition
- Offer cards check before drag; buttons `disabled` when false

### Reduced motion

If board `AnimLayer.reduced_motion` is true (or future global setting):

- Use `TransitionManager.Style.FADE` with shorter duration (`0.15s`), or skip transition and call open/close immediately
- Still play shop open/close SFX at low volume optional

---

## Acceptance criteria

- [ ] After a won match, the shop does not pop in instantly; a full-screen transition plays first
- [ ] Continue → plays a closing transition before the next match starts
- [ ] Player cannot drag offers or spend chips while the enter/exit wipe is in progress
- [ ] Standalone shop preview (`ShopScreen` as main scene) still opens without requiring `TransitionManager`
- [ ] Transition style matches main menu / run (`DIAGONAL_WIPE` by default)
- [ ] Shop open/close sounds (feature 18) fire at reveal/hide if audio is implemented

---

## Related features

- 16 — Shop chip juice (chip label updates after enter)
- 18 — Shop audio (`shop_open`, `shop_close`)
- 19 — Shop offer cards juice (deal-in after enter completes)
