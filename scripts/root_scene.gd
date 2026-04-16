extends Node3D

var pause_menu = preload("res://scenes/pause_menu.tscn")

func _ready():
	call_deferred("_deferred_ready")

func _deferred_ready():
	if GameManager.is_loading:
		GameManager.apply_load($TestMap)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		add_child(pause_menu.instantiate())
		get_tree().root.set_input_as_handled()
