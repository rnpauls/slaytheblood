## Autoload. Single source of truth for the painterly dark-fantasy palette
## used across the HUD. Locked to the card-redesign aesthetic:
## midnight base + warm gold + cool steel + crimson accents + ivory text.
##
## Two metal families coexist semantically:
##   - GOLD  for warm/offensive elements (cost, AP, frame trim)
##   - STEEL for cool/defensive elements (pitch, defense, mana)
##
## Usage:
##   panel.modulate = Palette.MIDNIGHT_VIOLET
##   label.add_theme_color_override("font_color", Palette.IVORY)
extends Node

# --- Base / structure -------------------------------------------------------
const MIDNIGHT_VIOLET := Color(0.155, 0.140, 0.225, 1.0)  # panel fill (matches card body)
const MIDNIGHT_DEEP   := Color(0.075, 0.060, 0.115, 1.0)  # recessed wells, art-panel bg
const CHARCOAL_SCRIM  := Color(0.04,  0.04,  0.06,  0.92) # modal scrim

# --- Text -------------------------------------------------------------------
const IVORY     := Color(0.96, 0.94, 0.90, 1.0)  # primary text (HP/mana/title)
const IVORY_DIM := Color(0.78, 0.76, 0.72, 1.0)  # secondary text ("Attack" type label)

# --- Warm metal (offense, cost, frame trim) --------------------------------
const GOLD_ORNATE    := Color(0.78, 0.62, 0.28, 1.0)  # frame trim, cost ring, L-brackets
const GOLD_HIGHLIGHT := Color(0.96, 0.84, 0.48, 1.0)  # hover/focus, victory title

# --- Cool metal (defense, pitch, magical/arcane) ---------------------------
const STEEL_COOL   := Color(0.78, 0.80, 0.85, 1.0)  # pitch ring, defense shield, mana
const STEEL_BRIGHT := Color(0.92, 0.94, 0.97, 1.0)  # steel highlights / hover

# --- Blood accents ----------------------------------------------------------
const BLOOD_CRIMSON := Color(0.66, 0.13, 0.16, 1.0)  # HP fill, top accent stripe + bead
const BLOOD_DARK    := Color(0.22, 0.04, 0.05, 1.0)  # HP background trough

# --- Semantic ---------------------------------------------------------------
const MANA_AZURE    := Color(0.34, 0.50, 0.78, 1.0)  # mana gem (cool, sits in steel socket)
const AP_CRIMSON    := Color(0.66, 0.13, 0.16, 1.0)  # AP gem (warm, sits in gold socket)
const INTENT_ATTACK := Color(0.78, 0.18, 0.18, 1.0)
const INTENT_DEFEND := Color(0.50, 0.62, 0.74, 1.0)
const INTENT_BUFF   := Color(0.78, 0.62, 0.28, 1.0)
