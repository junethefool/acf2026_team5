extends NPC

@export var fiddle: AnimatableBody3D
@export var crow: AnimatableBody3D
@export var seelie: AnimatableBody3D
@export var unicorn: AnimatableBody3D
@export var player: CharacterBody3D
@export var credits: Control
@export var hair: AnimatableBody3D
@export var wood: AnimatableBody3D
@export var flute_sprite: CompressedTexture2D

var old_sprite: CompressedTexture2D 
var gone = false
var needed_item_list = ["hair", "knife", "wood"]
var present_item_list: Array = []
var difference = []

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(on_dialogic_signal)
	for room_transition in get_tree().get_nodes_in_group("room_transitions"):
		room_transition.room_transition.connect(_on_room_transition)

func on_interact():
	if Dialogic.VAR.game_state == 6:
		difference = needed_item_list.duplicate()
		for item in player.inventory:
			difference = difference.filter(func(initem): return initem != str(item.name))
		ListsForDialogic.faun_missing = difference.duplicate()
		ListsForDialogic.faun_size = ListsForDialogic.faun_missing.size()
		if difference.is_empty():
			Dialogic.VAR.materials_gathered = 1
		else:
			Dialogic.VAR.materials_gathered = 0
	
	Dialogic.start("faun")
	
func on_dialogic_signal(message):
	if message == "take fiddle materials":
		for child in fiddle.get_children():
			if child is Sprite3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true
		for item in needed_item_list:
			player.inventory = player.inventory.filter(func(initem): return initem.name != item)
	elif message == "give fiddle":
		player.inventory.push_front(fiddle)
	elif message == "leaving":
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		for child in find_children("*"):
			if child is Sprite3D:
				child.visible = false
			if child is CollisionShape3D:
				child.disabled = true
		gone = true
		interactable.can_interact = false
		
		await get_tree().create_timer(wait + duration).timeout
	elif message == "party":
		get_tree().get_first_node_in_group("fade").fade(0.5,0.5)
		var duration = 0.5
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		old_sprite = $Sprite3D.texture
		$Sprite3D.texture = flute_sprite
		crow.global_position = $crow_position.global_position
		seelie.global_position = $seelie_position.global_position
		unicorn.global_position = $unicorn_position.global_position
		player.global_position = $player_position.global_position
		global_position = $faun_position.global_position
		await get_tree().create_timer(wait + duration).timeout
	
	elif message == "dance":
		player.state = 6
		player.fiddle_time = true
	elif message == "dance end":
		get_tree().get_first_node_in_group("fade").get_node("ColorRect").modulate = Color(1.0, 1.0, 1.0, 0.0)
		get_tree().get_first_node_in_group("fade").fade(2,0.5)
		var duration = 2
		var wait = 0.5
		await get_tree().create_timer(duration).timeout
		player.fiddle_time = false
		player.animated_sprite.play("player_back")
		$Sprite3D.texture = old_sprite
		await get_tree().create_timer(wait + duration).timeout
		get_tree().get_first_node_in_group("fade").get_node("ColorRect").modulate = Color(0.0, 0.0, 0.0, 0.0)
		player.state = 0
		Dialogic.start("faun")
	elif message == "end":
		player.state = 6
		#await get_tree().get_first_node_in_group("fade").fade_out(0.5)
		credits.visible = true
func _on_room_transition():
	if gone == true and player.inventory.find(hair) != -1 and player.inventory.find(wood) != -1:
		for child in find_children("*"):
			if child is Sprite3D:
				child.visible = true
			if child is CollisionShape3D:
				child.disabled = false
		gone = false
		Dialogic.VAR.went_and_returned = 1
