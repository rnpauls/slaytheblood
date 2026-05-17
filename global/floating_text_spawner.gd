## Listens to combat damage / heal events and spawns a FloatingText over the
## victim. Spawns parented to the combatant so the text inherits its world
## transform; if the combatant is freed mid-tween the text goes with it.
##
## Color/label semantics:
##   PHYSICAL unblocked → red number
##   PHYSICAL blocked   → steel "BLOCK" text
##   ARCANE unblocked   → azure number (arcane bypasses block)
##   heal               → green number (prefixed with +)
extends Node

const FLOATING_TEXT_SCENE := preload("res://scenes/effects/floating_text.tscn")
const BURST_SCENE := preload("res://scenes/effects/burst.tscn")
const DICE_ROLL_SCENE := preload("res://scenes/effects/dice_roll.tscn")
## Where the text spawns relative to the combatant's origin (just above the
## sprite — combatant.gd's sprite_2d typically sits with feet at origin and
## extends up by stats.display_height pixels).
const SPAWN_OFFSET := Vector2(0, -180)
## Camera shake on each unblocked hit. Kept conservative so it doesn't drown
## out the visual; bumped to BIG on heavy hits in spawn().
const SHAKE_STRENGTH_SMALL := 4.0
const SHAKE_STRENGTH_BIG := 10.0
const SHAKE_DURATION := 0.15
## Damage threshold (post-block) above which we kick the bigger shake.
const BIG_HIT_THRESHOLD := 8

func _ready() -> void:
	Events.damage_floated.connect(_on_damage_floated)
	Events.combatant_healed.connect(_on_combatant_healed)
	Events.dice_rolled.connect(_on_dice_rolled)


func _on_damage_floated(target: Node, amount: int, kind: int, blocked: bool) -> void:
	if not is_instance_valid(target):
		return
	var color: Color
	var text: String
	if blocked:
		color = Palette.STEEL_BRIGHT
		text = "BLOCK"
	elif kind == Card.DamageKind.ARCANE:
		color = Palette.MANA_AZURE
		text = str(amount)
	else:
		color = Palette.BLOOD_CRIMSON
		text = str(amount)
	_spawn(target, text, color)
	_spawn_burst(target, color, 18 if not blocked else 10, 70.0, 0.45)
	if not blocked and amount > 0:
		var strength := SHAKE_STRENGTH_BIG if amount >= BIG_HIT_THRESHOLD else SHAKE_STRENGTH_SMALL
		Shaker.shake_camera(strength, SHAKE_DURATION)


func _on_dice_rolled(target: Node, value: int) -> void:
	if not is_instance_valid(target) or not target is Node2D:
		return
	var dice: DiceRoll = DICE_ROLL_SCENE.instantiate()
	(target as Node2D).add_child(dice)
	dice.position = SPAWN_OFFSET + Vector2(0, -40)
	dice.setup(value)


func _on_combatant_healed(target: Node, amount: int) -> void:
	if not is_instance_valid(target) or amount <= 0:
		return
	# No dedicated palette green yet; use bright steel as a stand-in until a
	# heal-coloured token is added. Reads as "positive" against the dark bg.
	_spawn(target, "+%d" % amount, Color(0.50, 0.85, 0.55, 1.0))


func _spawn(target: Node, text: String, color: Color) -> void:
	if not target is Node2D:
		return
	var ft: FloatingText = FLOATING_TEXT_SCENE.instantiate()
	(target as Node2D).add_child(ft)
	ft.position = SPAWN_OFFSET
	ft.setup(text, color)


func _spawn_burst(target: Node, color: Color, count: int, distance: float, lifetime: float) -> void:
	if not target is Node2D:
		return
	# Set params BEFORE add_child so Burst._ready sees the final color/count
	# (its particle children are created in _ready — calling setup() after
	# add_child would be too late, and the children would render in the
	# default white/16-count config).
	var b: Burst = BURST_SCENE.instantiate()
	b.setup(color, count, distance, lifetime)
	(target as Node2D).add_child(b)
	b.position = SPAWN_OFFSET


# Public helpers so UI panels (ManaUI / ActionPointsUI) can spawn a small
# colored pop on resource gain without owning a separate Burst preload.
func spawn_burst_at(parent: Node, local_position: Vector2, color: Color,
		count: int = 12, distance: float = 40.0, lifetime: float = 0.35) -> void:
	if not parent:
		return
	var b: Burst = BURST_SCENE.instantiate()
	b.setup(color, count, distance, lifetime)
	parent.add_child(b)
	b.position = local_position
