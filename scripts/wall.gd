extends StaticBody3D

func _ready():
	call_deferred("_ready2")
	
func _ready2():
	get_tree().root.find_child("item_tree",true,false).items_received.connect(_on_items_received)
	if get_tree().root.find_child("item_tree",true,false).is_connected("items_received",_on_items_received):
		print("connected")
func _on_items_received():
	get_tree().root.find_child("item_tree",true,false).items_received.disconnect(_on_items_received)
	queue_free()
