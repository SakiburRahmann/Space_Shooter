extends CanvasLayer

@onready var wave_stat = $Panel/VBox/WaveStat
@onready var enemies_stat = $Panel/VBox/EnemiesStat
@onready var time_stat = $Panel/VBox/TimeStat
@onready var cores_stat = $Panel/VBox/CoresStat

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	
	wave_stat.text = "Waves Survived: " + str(GameManager.current_wave - 1)
	enemies_stat.text = "Enemies Destroyed: " + str(GameManager.total_kills)
	
	var mins = int(GameManager.run_time) / 60
	var secs = int(GameManager.run_time) % 60
	time_stat.text = "Survival Time: " + str(mins) + "m " + str(secs) + "s"
	
	# Earn and display Void Currency
	var earned = SaveManager.earn_end_of_run(GameManager.total_kills, GameManager.current_wave - 1, GameManager.run_time, GameManager.total_gems_collected)
	cores_stat.text = "+" + str(earned) + " Void Currency earned!"

func _on_retry_pressed():
	get_tree().paused = false
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://main.tscn")

func _on_menu_pressed():
	get_tree().paused = false
	GameManager.reset_run()
	get_tree().change_scene_to_file("res://title_screen.tscn")

func _on_quit_pressed():
	get_tree().quit()
