extends CanvasLayer

@onready var panel: PanelContainer = $CenterContainer/PanelContainer
@onready var resume_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ResumeButton
@onready var save_button: Button = $CenterContainer/PanelContainer/VBoxContainer/SaveButton
@onready var load_button: Button = $CenterContainer/PanelContainer/VBoxContainer/LoadButton
@onready var main_menu_button: Button = $CenterContainer/PanelContainer/VBoxContainer/MainMenuButton
@onready var exit_button: Button = $CenterContainer/PanelContainer/VBoxContainer/ExitButton
@onready var saved_label: Label = $CenterContainer/PanelContainer/VBoxContainer/SavedLabel

func _ready():
	visible = false
	resume_button.pressed.connect(_on_resume)
	save_button.pressed.connect(_on_save)
	load_button.pressed.connect(_on_load)
	main_menu_button.pressed.connect(_on_main_menu)
	exit_button.pressed.connect(_on_exit)
	saved_label.visible = false

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if visible:
			_on_resume()
		else:
			_show_menu()
		get_viewport().set_input_as_handled()

func _show_menu():
	load_button.visible = GameManager.has_save()
	saved_label.visible = false
	visible = true
	get_tree().paused = true

func _on_resume():
	visible = false
	get_tree().paused = false

func _on_save():
	var success = GameManager.save_game()
	if success:
		saved_label.visible = true
		load_button.visible = true

func _on_load():
	visible = false
	get_tree().paused = false
	GameManager.load_game()

func _on_main_menu():
	visible = false
	GameManager.go_to_main_menu()

func _on_exit():
	get_tree().quit()
