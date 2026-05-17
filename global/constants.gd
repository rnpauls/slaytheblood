## Global layout and design constants shared across the game.
## When changing a value here, check the comment for any scene nodes that must
## be updated to match (Godot's layout engine does not enforce these at edit time).
extends Node

## Height of the TopBar CanvasLayer in pixels.
## Must match custom_minimum_size.y on:
##   TopBar/Background, TopBar/BarItems children (RelicHandler, InventoryButton, DeckButton)
const TOP_BAR_HEIGHT := 80

# ── Tween durations ─────────────────────────────────────────────────────────
# Grouped semantically (by what the tween represents), not by raw number.
# Same numeric value can appear under different names if the contexts should
# stay independently tunable.

## scale:x flip animation when a card is revealed/flipped in hand or battle.
const TWEEN_CARD_FLIP        := 0.10
## Snappier flip used inside card_stack_panel pile previews.
const TWEEN_CARD_FLIP_FAST   := 0.08
## Enemy card flip-reveal (slightly slower for emphasis).
const TWEEN_CARD_FLIP_ENEMY  := 0.12

## Hover zoom on staged or static cards.
const TWEEN_UI_HOVER         := 0.15
## Block-badge pop-in/scale.
const TWEEN_BADGE_POP        := 0.18
## Card-stack pile rearrange after a card leaves.
const TWEEN_PILE_REARRANGE   := 0.18

## Position/scale slides used by card preview/staging panels.
const TWEEN_PANEL_SLIDE      := 0.20
## Relic carousel scroll.
const TWEEN_RELIC_SCROLL     := 0.20
## End Turn / Block button slide on/off screen.
const TWEEN_END_TURN_BUTTON  := 0.4

## Generic fade-in/out (tooltip, preview, NAA card resolution, block badge).
const TWEEN_FADE             := 0.25
## Hand entry animation when a drawn card finishes flying into the hand.
const TWEEN_HAND_ENTRY       := 0.25
## Staged-card center move (player and enemy staged displays).
const TWEEN_CARD_STAGE       := 0.30

## Enemy lurch-toward-player attack animation. Distance in pixels; FWD/RETURN in seconds.
const ENEMY_LURCH_DISTANCE := 40.0
const ENEMY_LURCH_FWD      := 0.10
const ENEMY_LURCH_RETURN   := 0.18

#Colors
const RED_PITCH = Color(0xb83c3cFF)
const YELLOW_PITCH = Color(0xd8ae3bFF)
const BLUE_PITCH = Color(0x4988beFF)
const RARITY_COLORS := {
	0: Palette.IVORY_DIM,
	1: Palette.STEEL_BRIGHT,
	2: Palette.GOLD_HIGHLIGHT,

}

# ── SFX names ───────────────────────────────────────────────────────────────
# StringName keys consumed by SFXRegistry.play(). The actual AudioStream
# preloads live in SFXRegistry; these names are the lookup keys. Centralized
# here so callsites get a compile-time-resolvable identifier instead of bare
# &"" literals scattered through the codebase.
const SFX_HOVER_CARD: StringName = &"HOVER_CARD"
const SFX_HOVER_UI: StringName = &"HOVER_UI"
const SFX_CLICK_BUTTON: StringName = &"CLICK_BUTTON"
const SFX_CLICK_MENU: StringName = &"CLICK_MENU"
const SFX_DRAW_CARD: StringName = &"DRAW_CARD"
const SFX_CONFIRM: StringName = &"CONFIRM"
const SFX_CANCEL: StringName = &"CANCEL"

# ── Pitch sound sequence ────────────────────────────────────────────────────
# Played pitch_value times, with frequency pitch increasing by PITCH_SOUND_STEP
# each iteration (so 3 mana = three ascending pops).
const PITCH_SOUND := preload("uid://buhipb81h8ym1")#preload("res://art/music/sound_effects/400 Sounds Pack/UI/pop_1.wav")
const PITCH_SOUND_GAP := 0.08
const PITCH_SOUND_STEP := 0.6
