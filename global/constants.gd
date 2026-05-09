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

## Generic fade-in/out (tooltip, preview, NAA card resolution, block badge).
const TWEEN_FADE             := 0.25
## Hand entry animation when a drawn card finishes flying into the hand.
const TWEEN_HAND_ENTRY       := 0.25
## Staged-card center move (player and enemy staged displays).
const TWEEN_CARD_STAGE       := 0.30

#Colors
const RED_PITCH = 0xb83c3c
const YELLOW_PITCH = 0xd8ae3b
const BLUE_PITCH = 0x4988be
