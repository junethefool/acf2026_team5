extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var load_button: Button = $CenterContainer/VBoxContainer/LoadButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton

func _ready():
	get_tree().paused = false
	load_button.visible = GameManager.has_save()
	start_button.pressed.connect(_on_start)
	load_button.pressed.connect(_on_load)
	exit_button.pressed.connect(_on_exit)

func _on_start():
	GameManager.new_game()

func _on_load():
	GameManager.load_game()

func _on_exit():
	get_tree().quit()
