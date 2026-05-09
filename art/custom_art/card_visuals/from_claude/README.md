# Nine-patch Textures

PNG textures for use with Godot's `NinePatchRect`. All sources are
rendered at **3× scale** so they upscale cleanly to any card size.

## Files

| File                | Source size | Patch margins (L/T/R/B) | Use as       |
|---------------------|-------------|-------------------------|--------------|
| `card_body.png`     | 90 × 90     | 12 / 12 / 12 / 12       | NinePatchRect |
| `art_frame.png`     | 72 × 72     | 12 / 12 / 12 / 12       | NinePatchRect |
| `name_plate.png`    | 48 × 42     | 12 / 12 / 12 / 18       | NinePatchRect |
| `art_recess.png`    | 48 × 48     | 12 / 12 / 12 / 12       | NinePatchRect |
| `tier_red.png`      | 36 × 12     | 12 / 3 / 12 / 3         | NinePatchRect |
| `tier_yellow.png`   | 36 × 12     | 12 / 3 / 12 / 3         | NinePatchRect |
| `tier_blue.png`     | 36 × 12     | 12 / 3 / 12 / 3         | NinePatchRect |
| `cost_coin.png`     | 36 × 36     | (round — see below)     | TextureRect (NOT nine-patch) |
| `replay_badge.png`  | 36 × 36     | (round — see below)     | TextureRect (NOT nine-patch) |

## Why the coins aren't nine-patch

Round shapes can't be nine-patched cleanly — stretching a circle's
middle row distorts it. Use `TextureRect` (or `Sprite2D`) for the cost
coin and replay badge and keep them at their native 36 × 36 px (or
scale uniformly).

## Importing into Godot 4

1. Drop the PNGs into your project (e.g. `res://assets/ninepatch/`).
2. Select each PNG → **Import** tab → ensure **Mipmaps** = off,
   **Filter** = Linear (or Nearest if you want pixel-crisp edges).
3. Add a `NinePatchRect` node, set its `texture` to the PNG, and set
   the `patch_margin_left/top/right/bottom` values from the table above.

## Example: replacing the card body StyleBox with a NinePatchRect

In `scenes/card.tscn`, swap the root from `PanelContainer` (with
`StyleBoxFlat`) to a layout where the nine-patch is the visual layer:

```gdscript
# Approach: keep PanelContainer for layout, use a NinePatchRect as
# its background via a child Control that fills the parent.
NinePatchRect (anchored to fill parent)
    texture = preload("res://assets/ninepatch/card_body.png")
    patch_margin_left   = 12
    patch_margin_top    = 12
    patch_margin_right  = 12
    patch_margin_bottom = 12
```

Or use the simpler route: a `StyleBoxTexture` resource pointing at
`card_body.png` with the same margins, applied via
`theme_override_styles/panel`. This keeps the PanelContainer working
exactly as before with no scene restructuring.

## Sizing guidance

The textures are intended to be displayed at any size ≥ the patch
margins on each side. Some practical examples for the default 124×184
card:

- Card body: stretched to **124 × 184**
- Art frame: stretched to ~**112 × 100**
- Name plate: stretched to ~**108 × 22**
- Art recess: stretched to ~**108 × 64**
- Tier strip: stretched to ~**112 × 4**
- Cost coin / replay: native **18 × 18** (or **24 × 24** if you want
  them larger; uniform scale only)

## Regenerating

The `_generate.py` script in this folder produces all PNGs from
scratch using Pillow. Edit colors, sizes, or margins there and re-run:

```
python3 _generate.py
```
