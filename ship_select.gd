extends Control

var biome_timer = 0.0
var biome_interval = 3.5

func _ready():
	_build_ship_buttons()
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

func _build_ship_buttons():
	var grid = $VBox/ShipGrid
	for child in grid.get_children():
		child.queue_free()
	for ship_id in SaveManager.ship_defs.keys():
		var ship = SaveManager.ship_defs[ship_id]
		var unlocked = ship_id in SaveManager.unlocked_ships
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(280, 180)
		if unlocked:
			var sel = " [SELECTED]" if ship_id == SaveManager.selected_ship else ""
			# Temporary swap to get current ship's potential stats
			var prev_sel = SaveManager.selected_ship
			SaveManager.selected_ship = ship_id
			var s_stats = SaveManager.get_starting_stats()
			SaveManager.selected_ship = prev_sel
			
			btn.text = ship["name"] + sel + "\n\n" + ship["desc"] + "\n\nHP: " + str(int(s_stats["hp"])) + " | DMG: " + str(snapped(s_stats["damage"], 0.1)) + "\nFire Rate: " + str(snapped(s_stats["fire_rate"], 0.01)) + " | SPD: " + str(int(s_stats["speed"]))
			btn.pressed.connect(_on_ship_selected.bind(ship_id))
		else:
			var cond = SaveManager.ship_unlock_conditions[ship_id]
			btn.text = ship["name"] + "\n\n[LOCKED]\n" + cond["desc"]
			btn.disabled = true
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.05, 0.06, 0.15, 0.9)
		style.border_width_left = 2; style.border_width_top = 2
		style.border_width_right = 2; style.border_width_bottom = 2
		if ship_id == SaveManager.selected_ship:
			style.border_color = Color(0, 1, 0.5, 1)
			style.shadow_color = Color(0, 1, 0.5, 0.3); style.shadow_size = 14
		elif unlocked:
			style.border_color = Color(0, 0.7, 1, 0.5)
			style.shadow_color = Color(0, 0.5, 1, 0.15); style.shadow_size = 8
		else:
			style.border_color = Color(0.3, 0.3, 0.4, 0.4); style.shadow_size = 0
		style.corner_radius_top_left = 12; style.corner_radius_top_right = 12
		style.corner_radius_bottom_right = 12; style.corner_radius_bottom_left = 12
		style.content_margin_left = 16; style.content_margin_top = 14
		style.content_margin_right = 16; style.content_margin_bottom = 14
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_stylebox_override("hover", style)
		btn.add_theme_stylebox_override("pressed", style)
		btn.add_theme_font_size_override("font_size", 16)
		btn.add_theme_color_override("font_color", Color(0.85, 0.92, 1) if unlocked else Color(0.4, 0.4, 0.5))
		grid.add_child(btn)

func _on_ship_selected(ship_id: String):
	SaveManager.selected_ship = ship_id
	SaveManager.save_data()
	_build_ship_buttons()

func _on_launch_pressed():
	get_tree().change_scene_to_file("res://main.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://title_screen.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
