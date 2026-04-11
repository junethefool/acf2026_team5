extends AnimatableBody3D

@onready var interactable: Interactable = $Interactable
@export var berries: AnimatableBody3D
@export var knife: AnimatableBody3D
@export var player: CharacterBody3D
var needed_item_list = ["moss", "mirror_shard", "twig", "mud"]
var present_item_list: Array = []
var difference = []

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(on_dialogic_signal)

func on_interact():
	print("you did it, dumbass")
	if Dialogic.VAR.game_state == 3:
		difference = needed_item_list.duplicate()
		for item in player.inventory:
			difference.erase(item)
			difference = difference.filter(func(initem): return initem != str(item.name))
		if difference.is_empty():
			Dialogic.VAR.all_things_gathered = 1
			for item in needed_item_list:
				player.inventory = player.inventory.filter(func(initem): return initem.name != item)
		else:
			Dialogic.VAR.all_things_gathered = 0
	Dialogic.start("crow")
	
func on_dialogic_signal(message):
	if message == "give berries":
		for child in berries.get_children():
			if child is Sprite3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true
		player.inventory.push_front(berries)
	elif message == "give knife":
		for child in knife.get_children():
			if child is Sprite3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true
		player.inventory.push_front(knife)
	elif message == "take knife":
		player.inventory.erase(knife)
