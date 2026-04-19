extends CanvasLayer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_resume()
		else:
			_pause()

func _pause():
	get_tree().paused = true
	visible = true

func _resume():
	visible = false
	get_tree().paused = false

func _on_resume_pressed():
	_resume()

func _on_menu_pressed():
	visible = false
	get_tree().paused = false
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://title_screen.tscn")

func _on_quit_pressed():
	get_tree().quit()
