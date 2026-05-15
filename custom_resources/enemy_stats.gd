class_name EnemyStats
extends Stats

@export var ai: PackedScene = preload("uid://5aef0ltsrkxq")
@export var death_sound: AudioStream = preload("uid://co6w7ahwuqyra")

## Statuses applied to this enemy at battle start, after the AI is wired up.
## EnemyHandler.setup_enemies (and spawn_enemy) iterates and adds each via
## status_handler.add_status — pattern of choice for "this enemy has X passive
## for the whole fight" mechanics like Splitter, Disease Carrier, Reassemble.
## Each status is duplicate()'d on apply so multiple enemies sharing the same
## resource don't share live status state.
##
## Typed as Array[Resource] (not Array[Status]) so .tres files don't need to
## ext_resource the Status base script just to declare the array type — they
## can reference the concrete status .tres directly.
@export var passives: Array[Resource] = []
