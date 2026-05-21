# Feature 18 — Shop Audio
*Plummet · Shop juice · Plummet*

## Purpose

Wire short, cozy SFX to every shop gesture so drag, purchase, reroll, and navigation match the board and menu feel. All shop sounds go through **`RandomAudioPlayer`** so a single imported file still gets pitch variation.

---

## Scope

- `RandomAudioPlayer` nodes on `ShopScreen` (or child `ShopAudio` node)
- One-shot cues for open, close, drag, purchase, reroll, deny
- Respect global **mute** (same as board: `AnimLayer.muted` or shared run setting)
- Pitch randomization on **every** play, even when only one stream is assigned

## Not in scope

- Music / ambient shop loop
- Voice acting
- Board cascade sounds (feature 11 / `AnimLayer`)

---

## Dependencies

- Feature 07 — Shop interactions (when to trigger each cue)
- Features 15–17, 19–21 — animation timing (sync SFX to snap, deal-in, reroll)
- `scripts/audio/random_audio_player.gd`
- Scene: `scenes/audio/random_audio_player.tscn` (instanced per cue group)

---

## Critical implementation rule: always use `RandomAudioPlayer`

**Do not** use raw `AudioStreamPlayer` for shop cues.

For each logical sound:

1. Add a child node instanced from `scenes/audio/random_audio_player.tscn`
2. Set `streams` to an `Array[AudioStream]` — may contain **one or many** files
3. Enable `randomize_pitch = true` (default)
4. Recommended pitch ranges:

| Cue type | `min_pitch` | `max_pitch` |
|----------|-------------|-------------|
| UI click / hover tick | `0.92` | `1.08` |
| Soft whoosh / slide | `0.88` | `1.12` |
| Positive attach / chime | `0.94` | `1.06` |
| Error / deny | `0.85` | `1.0` |

5. Call `play_random()` or `play_random_overlapping(parent)` for rapid repeats

**Why:** With only one WAV in the array, `pick_random_stream()` still returns it, and `_apply_pitch()` varies `pitch_scale` each play so repeats do not sound robotic.

Reference: `JuicySfxButton`, `StaggerFlyInContainer`, `AnimLayer` land/clear SFX.

### Overlapping plays

| Cue | Method |
|-----|--------|
| Hover tick (throttled) | `play_random_overlapping(self)` |
| Cascade of deal-in slides | `play_random_overlapping` per card stagger |
| Single purchase | `play_random()` |

---

## Scene layout (recommended)

Under `ShopScreen` (or `ShopAudio` `Node`):

```
ShopAudio
├── OpenSfx          (RandomAudioPlayer)
├── CloseSfx         (RandomAudioPlayer)
├── DragPickupSfx    (RandomAudioPlayer)
├── DropValidSfx     (RandomAudioPlayer)   # optional hover tick
├── DropInvalidSfx   (RandomAudioPlayer)
├── ModifierAttachSfx
├── PieceTypeApplySfx
├── RelicAcquireSfx
├── ModifierRemoveSfx
├── RerollSfx
├── ChipSpendSfx
└── CantAffordSfx    # drag denied / invalid action
```

Export arrays on `shop_screen.gd` or dedicated `shop_audio.gd` for assignment in editor.

### Bus and volume

| Setting | Value |
|---------|-------|
| Bus | `SFX` (or `Master` if no bus) |
| Default `volume_db` | `-4` to `-8` for UI (tune in editor) |
| `overlapping_volume_db` on player | `-10` relative (built into `RandomAudioPlayer`) |

---

## Mute integration

Before any play:

```gdscript
func _shop_audio_enabled() -> bool:
    # Prefer shared flag from GameBoard's AnimLayer when shop is child of board
    if _anim_layer_ref != null:
        return not _anim_layer_ref.muted
    return true
```

Wire `GameBoard` to pass mute state into `ShopScreen.open()`, or use a group/query. Shop preview scene: default unmuted.

---

## Sound list (assets to provide)

Replace `TBD` with final path(s) under `res://assets/sfx/shop/` (or existing kenney folders). Multiple files per row = add all to that player’s `streams` array.

| ID | Purpose | When it plays | Overlap OK | Suggested character | File(s) |
|----|---------|---------------|------------|---------------------|---------|
| `shop_open` | Shop screen revealed | End of enter transition / shop visible | No | Soft curtain whoosh or card deck slide | `TBD` |
| `shop_close` | Leaving shop | Start of exit transition on Continue | No | Light whoosh out, descending optional | `TBD` |
| `drag_pickup` | Pick up offer card | `ShopOfferCard._start_drag()` | Yes | Short paper/card lift, tactile | `TBD` |
| `drop_valid_hover` | Valid target hover | Throttled while dragging over valid piece/relic slot (max 1 per 200ms) | Yes | Quiet tick or soft blip | `TBD` (optional) |
| `drop_invalid` | Invalid target / deny | Hover invalid slot or release without drop | Yes | Soft thud or muted “bonk”, low volume | `TBD` |
| `modifier_attach` | Modifier applied | After drop snap on piece, modifier badge appears | No | Positive chime, warm | `TBD` |
| `piece_type_apply` | Piece type changed | After drop snap, piece shader updates | No | Whoosh + soft crystalline hit | `TBD` |
| `relic_acquire` | Relic slotted | After drop snap on empty relic slot | No | Distinct two-tone flourish, slightly special | `TBD` |
| `modifier_remove` | Modifier removed | × button remove confirmed | No | Reverse chip/chime, shorter | `TBD` |
| `chip_spend` | Chips deducted | Chip tween/flash starts (attach, remove, type, relic, reroll) | Yes | Coin clink or chip tap | `TBD` |
| `reroll` | Offers replaced | Reroll button pressed, old offers exit | No | Card shuffle / riffle | `TBD` |
| `cant_afford` | Action blocked | Drag started on unaffordable card (optional) or click disabled reroll | Yes | Muted error, no harsh buzz | `TBD` |

### Notes per cue

- **`shop_open` / `shop_close`:** Single stream is fine; pitch vary ±5%.
- **`drag_pickup`:** Can share stream with `drop_valid_hover` at different pitch ranges if asset budget is tight — prefer separate for clarity.
- **`modifier_attach` / `piece_type_apply` / `relic_acquire`:** Must be distinguishable; player learns outcome by ear.
- **`chip_spend`:** Play on every paid transaction; skip when Patron cost is 0.
- **`reroll`:** Play once per press, not per card dealt.

---

## Trigger map (code locations)

| Sound ID | Call site |
|----------|-----------|
| `shop_open` | After feature 15 enter completes + deal-in starts |
| `shop_close` | `ShopScreen._on_continue` before transition |
| `drag_pickup` | `ShopOfferCard._start_drag` |
| `drop_valid_hover` | `ShopScreen._process` or slot `mouse_entered` while drag active (throttled) |
| `drop_invalid` | Invalid slot hover or drag end without purchase |
| `modifier_attach` | `_apply_modifier_offer` after snap |
| `piece_type_apply` | `_apply_piece_type_offer` after snap |
| `relic_acquire` | `_on_relic_dropped` after snap |
| `modifier_remove` | `_on_remove_modifier` |
| `chip_spend` | `ShopScreen._animate_chips_to` when `spent_delta > 0` |
| `reroll` | `_on_reroll` |
| `cant_afford` | `ShopOfferCard` when `_start_drag` blocked by `not _can_drag` |

---

## Filename worksheet (fill in when assets exist)

```text
shop_open:              TBD
shop_close:             TBD
drag_pickup:            TBD
drop_valid_hover:       TBD   # optional
drop_invalid:           TBD
modifier_attach:        TBD
piece_type_apply:       TBD
relic_acquire:          TBD
modifier_remove:        TBD
chip_spend:             TBD
reroll:                 TBD
cant_afford:            TBD
```

Example multi-variant entry (once known):

```text
modifier_attach:
  - res://assets/sfx/shop/modifier_attach_01.ogg
  - res://assets/sfx/shop/modifier_attach_02.ogg
```

---

## API sketch (`shop_audio.gd`)

```gdscript
class_name ShopAudio extends Node

@onready var _open: RandomAudioPlayer = $OpenSfx
# ...

var muted: bool = false

func play_open() -> void:
    if muted: return
    _open.play_random()
```

`ShopScreen` holds `var _audio: ShopAudio` and delegates.

---

## Acceptance criteria

- [ ] Every cue in the sound list has a wired `RandomAudioPlayer` (not raw `AudioStreamPlayer`)
- [ ] Each player’s `streams` array is used with `play_random()` / `play_random_overlapping()`
- [ ] `randomize_pitch` is enabled; single-file cues still vary in pitch
- [ ] Mute flag silences all shop SFX without errors
- [ ] Purchase sounds fire after drop snap, not on drag start
- [ ] Filename worksheet updated when assets are imported

---

## Related features

- 15 — Enter/exit (open/close)
- 17 — Drag (pickup, valid/invalid, attach timing)
- 21 — Reroll (reroll cue)
