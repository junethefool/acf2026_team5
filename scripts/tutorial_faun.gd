extends AnimatableBody3D
class_name NPC

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	interactable.Interact.connect(on_interact)
	call_deferred("ready2")
	
func ready2():
	find_child("NPC Talk Range",true, false).body_entered.connect(_on_body_entered)
	if find_child("NPC Talk Range",true, false).is_connected("body_entered",_on_body_entered):
		print ("here")
	find_child("NPC Talk Range",true, false).body_exited.connect(_on_body_exited)

func _on_body_entered(body):
	if str(body.name) == "key":
		Dialogic.VAR.key_on_the_floor = "1"
		
func _on_body_exited(body):
	if str(body.name) == "key":
		Dialogic.VAR.key_on_the_floor = "0"
		
func on_interact():
	print("you did it, dumbass")
	var key_here = false
	for item in get_tree().get_first_node_in_group("player").inventory:
		if str(item.name) == "key":
			key_here = true
	if key_here == false:
		Dialogic.VAR.key = "0"
	
	else:
		Dialogic.VAR.key = "1"
		
	Dialogic.start("tutorial")
	
