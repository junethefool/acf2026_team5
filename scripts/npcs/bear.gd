extends AnimatableBody3D

@onready var interactable: Interactable = $Interactable
@export var berries: AnimatableBody3D
@export var faun:AnimatableBody3D
signal berry
var awake = false

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	berry.connect(on_berry)

func on_interact():
	Dialogic.start("bear asleep")

func _process(delta: float) -> void:
	if global_position.distance_to(berries.global_position) < 5 and awake == false and berries.get_node("CollisionShape3D").disabled == false:
		awake = true
		berry.emit()
		
func on_berry():
		Dialogic.VAR.game_state = 5
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		berries.queue_free()
		faun.global_position = $faun_position.global_position
		interactable.Interact.disconnect(on_interact)
		queue_free()
		await get_tree().create_timer(wait + duration).timeout
