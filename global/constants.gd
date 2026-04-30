## Global layout and design constants shared across the game.
## When changing a value here, check the comment for any scene nodes that must
## be updated to match (Godot's layout engine does not enforce these at edit time).
extends Node

## Height of the TopBar CanvasLayer in pixels.
## Must match custom_minimum_size.y on:
##   TopBar/Background, TopBar/BarItems children (RelicHandler, InventoryButton, DeckButton)
const TOP_BAR_HEIGHT := 80
