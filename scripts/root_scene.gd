extends Node3D

func _ready():
	call_deferred("_deferred_ready")

func _deferred_ready():
	if GameManager.is_loading:
		GameManager.apply_load($TestMap)
