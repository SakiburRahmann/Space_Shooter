extends Control

var biome_timer = 0.0
var biome_interval = 4.0

var current_selected_id = "viper"

@onready var list = $HBox/Scroll/List
@onready var detail_name = $HBox/Details/Name
@onready var detail_desc = $HBox/Details/Desc
@onready var detail_stats = $HBox/Details/Stats
@onready var detail_ability = $HBox/Details/AbilityDesc
@onready var preview_poly = $HBox/Details/Preview/Polygon2D
@onready var upgrade_btn = $HBox/Details/UpgradeBtn
@onready var credits_label = $CreditsLabel

func _ready():
	_populate_list()
	if "viper" in SaveManager.unlocked_ships:
		_show_details("viper")
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

func _update_credits():
	credits_label.text = "VOID CREDITS: " + str(int(SaveManager.void_credits))

func _populate_list():
	for child in list.get_children():
		child.queue_free()
	for key in SaveManager.ship_defs.keys():
		var btn = Button.new()
		var is_unlocked = key in SaveManager.unlocked_ships
		var lvl = SaveManager.ship_upgrades.get(key, 0)
		
		if is_unlocked:
			btn.text = SaveManager.ship_defs[key]["name"] + " (Lv. " + str(int(lvl) + 1) + ")"
		else:
			btn.text = "??? [LOCKED]"
		
		btn.pressed.connect(_on_list_item_pressed.bind(key))
		btn.custom_minimum_size = Vector2(0, 60)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		list.add_child(btn)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _on_list_item_pressed(key: String):
	if key in SaveManager.unlocked_ships:
		_show_details(key)

func _show_details(key: String):
	current_selected_id = key
	_update_credits()
	
	var data = SaveManager.ship_defs[key]
	var lvl = int(SaveManager.ship_upgrades.get(key, 0))
	var cost = SaveManager.get_upgrade_cost("ship", key)
	
	detail_name.text = data["name"].to_upper()
	detail_desc.text = data["desc"]
	detail_stats.text = "Base HP: " + str(data["hp"]) + " | Base DMG: " + str(data["damage"]) + " | SPD: " + str(data["speed"])
	
	# Determine ability desc
	var abl = ""
	if key == "viper": abl = "Blink - Teleport forward (Reduces cooldown per lvl)"
	elif key == "fortress": abl = "EMP - Stuns enemies (Increases stun duration per lvl)"
	elif key == "striker": abl = "Overdrive - Massive speed boost (Increases boost duration per lvl)"
	
	detail_ability.text = "Ship Special: " + abl + "\nCurrent Level: " + str(lvl + 1)
	
	preview_poly.polygon = PackedVector2Array([Vector2(25, 0), Vector2(-15, -20), Vector2(-5, 0), Vector2(-15, 20)])
	preview_poly.color = data["color"]
	preview_poly.modulate = Color(1.5, 1.5, 1.5, 1) # Gentle neon glow
	
	upgrade_btn.text = "UPGRADE ABILITY | %d VC" % cost
	upgrade_btn.disabled = SaveManager.void_credits < cost

func _on_upgrade_pressed():
	if SaveManager.buy_upgrade("ship", current_selected_id):
		_populate_list()
		_show_details(current_selected_id)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://title_screen.tscn")
