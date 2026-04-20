extends Control

@onready var start_button: Button = $CenterContainer/VBoxContainer/StartButton
@onready var exit_button: Button = $CenterContainer/VBoxContainer/ExitButton

func _ready():
	get_tree().paused = false
	start_button.pressed.connect(_on_start)
	exit_button.pressed.connect(_on_exit)

func _on_start():
	GameManager.new_game()

func _on_exit():
	get_tree().quit()
