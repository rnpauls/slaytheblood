## Lightweight, code-driven particle burst. Spawns N small ColorRect children
## at the origin and tweens each one outward in a random direction while
## fading. Free-after-lifetime. Kept off GPUParticles2D so we don't have to
## carry a ParticleProcessMaterial per variant — color/count/distance are
## just script params.
##
## Spawner usage:
##   var b: Burst = BURST_SCENE.instantiate()
##   parent.add_child(b)
##   b.global_position = where
##   b.setup(Palette.BLOOD_CRIMSON, 20, 70.0, 0.45)
class_name Burst
extends Node2D

const PARTICLE_SIZE := Vector2(4, 4)

@export var color: Color = Color.WHITE
@export var particle_count: int = 16
@export var max_distance: float = 60.0
@export var lifetime: float = 0.4
## Spread half-angle in radians; TAU/2 (≈π) gives a full omnidirectional burst.
## Smaller values cone the burst (e.g. PI/4 = 90° forward arc).
@export var spread_half_angle: float = PI
## Base angle (radians) for the burst direction (only relevant if spread_half_angle < PI).
@export var base_angle: float = -PI / 2.0

## Bundle config so callers can avoid setting fields individually. Returns self
## for chaining.
func setup(c: Color, count: int = 16, distance: float = 60.0, life: float = 0.4) -> Burst:
	color = c
	particle_count = count
	max_distance = distance
	lifetime = life
	return self

func _ready() -> void:
	for i in particle_count:
		var p := ColorRect.new()
		p.color = color
		p.size = PARTICLE_SIZE
		p.position = -PARTICLE_SIZE / 2.0
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(p)
		var angle := base_angle + randf_range(-spread_half_angle, spread_half_angle)
		var dist := randf_range(max_distance * 0.4, max_distance)
		var target := Vector2.from_angle(angle) * dist
		var t := create_tween().set_parallel(true)
		t.tween_property(p, "position", target - PARTICLE_SIZE / 2.0, lifetime) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(p, "modulate:a", 0.0, lifetime) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Free after the longest particle finishes.
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
