extends CanvasLayer

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var resume_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $CenterContainer/PanelContainer/VBoxContainer/MainMenuButton
@onready var exit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ExitButton

func _ready():
	resume_button.pressed.connect(_on_resume)
	main_menu_button.pressed.connect(_on_main_menu)
	exit_button.pressed.connect(_on_exit)
	_show_menu()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			_on_resume()
		get_tree().root.set_input_as_handled()

func _show_menu():
	visible = true
	get_tree().paused = true

func _on_resume():
	get_tree().paused = false
	_close_menu()



func _on_load():
	get_tree().paused = false
	GameManager.load_game()
	_close_menu()

func _on_main_menu():
	GameManager.go_to_main_menu()
	_close_menu()

func _on_exit():
	get_tree().quit()

func _close_menu():
	queue_free()
