extends AnimatableBody3D

@onready var interactable: Interactable = $Interactable
@export var berries: AnimatableBody3D
@export var knife: AnimatableBody3D
@export var player: AnimatableBody3D
var needed_item_list = ["bucket", "knife", "shovel"]
var present_item_list: Array = []
var difference = []
@export var filled: bool = false

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(on_dialogic_signal)

func on_interact():
	print("you did it, dumbass")
	Dialogic.start("flower observation")
	if Dialogic.VAR.game_state == 3:
		difference = needed_item_list.duplicate()
		for item in player.inventory:
			difference.erase(item)
		if difference.is_empty():
			filled = true
			Dialogic.VAR.all_things_gathered = 1
		else:
			Dialogic.VAR.all_things_gathered = 0
	
func on_dialogic_signal(message):
	if message == "give berries":
		for child in berries.get_children():
			if child is Sprite3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true
		get_tree().get_first_node_in_group("player").inventory.push_front(berries)
	elif message == "give knife":
		for child in knife.get_children():
			if child is Sprite3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true
		get_tree().get_first_node_in_group("player").inventory.push_front(knife)
	elif message == "take knife":
		get_tree().get_first_node_in_group("player").inventory.erase(knife)
