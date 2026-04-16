extends NPC

var needed_item_list = ["shovel", "knife", "bucket", "key"]
var present_item_list: Array = []
var difference = []
@export var player: CharacterBody3D

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	Dialogic.signal_event.connect(_on_dialogic_signal)
	call_deferred("ready2")
	
func ready2():
	find_child("NPC Talk Range",true, false).body_entered.connect(_on_body_entered)
	if find_child("NPC Talk Range",true, false).is_connected("body_entered",_on_body_entered):
		print ("here")
	find_child("NPC Talk Range",true, false).body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if str(body.name) == "key":
		Dialogic.VAR.key_on_the_floor = 1
		
func _on_body_exited(body):
	if str(body.name) == "key":
		Dialogic.VAR.key_on_the_floor = 0
		
func on_interact():
	difference = needed_item_list.duplicate()
	for item in player.inventory:
		difference = difference.filter(func(initem): return initem != str(item.name))
	if Dialogic.VAR.all_items == 0:
		ListsForDialogic.tutorial_missing = difference.duplicate()
		ListsForDialogic.tutorial_size = ListsForDialogic.tutorial_missing.size()
		if difference.is_empty():
			Dialogic.VAR.all_items = 1
	var key_here = false
	for item in get_tree().get_first_node_in_group("player").inventory:
		if str(item.name) == "key":
			key_here = true
	if key_here == false:
		Dialogic.VAR.key = 0
	else:
		Dialogic.VAR.key = 1
		
	Dialogic.start("tutorial")
	
func _on_dialogic_signal(message):
	if message == "tutorial done":
		var body = get_tree().get_first_node_in_group("player")
		var fade = get_tree().get_first_node_in_group("fade")
		var duration = 0.5
		var wait = 0.5
		fade.fade(duration,wait)
		await get_tree().create_timer(duration).timeout
		body.inventory = body.inventory.filter(func(initem): return initem.name != "key")
		body.global_position = $Marker3D.global_position
		await get_tree().create_timer(wait + duration).timeout
