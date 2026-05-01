# meta-name: EnemyAction
# meta-description: An action which can be performed byu an enemy during its turn
extends EnemyAction

@export var damage := 4

func perform_action() -> void:
	if not enemy or not target:
		return
	
	var tween := create_tween().set_trans(Tween.TRANS_QUINT)
	var start := enemy.global_position
	var end := target.global_position + Vector2.RIGHT * 32
	
	SFXPlayer.play(sound)
	
	Events.enemy_action_completed.emit(enemy)

#override for dynamic intent text
#eg modifiers
func update_intent_text() -> void:
	if not target:
		return
	intent.current_text = intent.base_text % Hook.get_damage(enemy, target, damage)
