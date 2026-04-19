extends NPC

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var berries: AnimatableBody3D
@export var faun:AnimatableBody3D
@export var player: CharacterBody3D
signal berry
var awake = false

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	berry.connect(on_berry)

func on_interact():
	if global_position.distance_to(berries.global_position) < 5 and awake == false and berries.get_node("CollisionShape3D").disabled == false:
		awake = true
		berry.emit()
		queue_free()
	else:
		Dialogic.start("bear asleep")

func _process(_delta: float) -> void:
	pass
	
func on_berry():
		Dialogic.VAR.game_state = 5
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		animation_player.stop()
		berries.queue_free()
		faun.global_position = $faun_position.global_position
		player.global_position = $player_position.global_position
		$Sprite3D.visible = false
		$Zsprite.visible = false
		await get_tree().create_timer(wait + duration).timeout
		Dialogic.start("faun")
		interactable.Interact.disconnect(on_interact)
		queue_free()
