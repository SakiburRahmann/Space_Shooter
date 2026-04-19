extends Control

var biome_timer = 0.0
var biome_interval = 4.0
var current_biome_idx = 0

func _ready():
	var tween = create_tween().set_loops()
	tween.tween_property($VBox/Title, "modulate:a", 0.7, 1.5)
	tween.tween_property($VBox/Title, "modulate:a", 1.0, 1.5)
	
	if Engine.has_singleton("SaveManager") or get_node_or_null("/root/SaveManager") != null:
		$VBox/Stats.text = "Best Wave: " + str(SaveManager.best_wave) + "  |  Total Kills: " + str(SaveManager.lifetime_kills) + "  |  Void Credits: " + str(int(SaveManager.void_credits))
	
	# Hide retired power-up button
	if has_node("VBox/PowerupsBtn"):
		$VBox/PowerupsBtn.visible = false
	
	# Start with procedural biome
	_cycle_bg()

func _process(delta):
	biome_timer += delta
	if biome_timer >= biome_interval:
		biome_timer = 0.0
		_cycle_bg()

func _cycle_bg():
	GameManager._generate_procedural_biome()
	var bg = $BG
	if bg and bg.material:
		GameManager.apply_biome_to_shader(bg)

func _on_play_pressed():
	get_tree().change_scene_to_file("res://ship_select.tscn")

func _on_fleet_pressed():
	get_tree().change_scene_to_file("res://fleet_menu.tscn")

func _on_cards_pressed():
	get_tree().change_scene_to_file("res://cards_menu.tscn")

func _on_bestiary_pressed():
	get_tree().change_scene_to_file("res://bestiary.tscn")

func _on_quit_pressed():
	get_tree().quit()
