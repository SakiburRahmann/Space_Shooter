extends Control

var enemy_info = {
	"scout": {
		"name": "VOID SCOUT",
		"desc": "Agile frontline interceptor. Features a chrome-plated chisel blade and dual-pulse engines.",
		"hp": 15, "speed": 180, "threat": "Low",
		"color": Color(0.8, 0.4, 2.5)
	},
	"tank": {
		"name": "VOID DREADNOUGHT",
		"desc": "Massive armored fortress. Built with reinforced hull slabs and internal kinetic radiators.",
		"hp": 80, "speed": 60, "threat": "High",
		"color": Color(2.5, 0.5, 0.2)
	},
	"striker": {
		"name": "DUAL-BOOM STRIKER",
		"desc": "High-velocity hunter-killer. Equipped with an aggressive split-fuselage and white-hot boosters.",
		"hp": 25, "speed": 240, "threat": "Moderate",
		"color": Color(0.2, 1.5, 3.5)
	},
	"wraith": {
		"name": "VOID WRAITH",
		"desc": "Electronic-warfare specialist. Features a shimmering obsidian hull and neon edge-lighting.",
		"hp": 30, "speed": 160, "threat": "Moderate",
		"color": Color(1.5, 0.2, 3.5)
	},
	"singularity": {
		"name": "VOID SINGULARITY",
		"desc": "Dimensional heavyweight. Stabilized by a rotating outer ring and dimensional gold plasma trails.",
		"hp": 120, "speed": 40, "threat": "Extreme",
		"color": Color(3.5, 2.5, 0.5)
	},
	"leech": {
		"name": "LIFE-STREAK LEECH",
		"desc": "Aggressive bio-mechanical construct. Uses kinetic siphons and viridian plasma trails.",
		"hp": 20, "speed": 200, "threat": "Moderate",
		"color": Color(0.5, 3.5, 0.8)
	}
}

var preview_node: Node2D

@onready var list = $HBox/Scroll/List
@onready var detail_name = $HBox/Details/Name
@onready var detail_desc = $HBox/Details/Desc
@onready var detail_stats = $HBox/Details/Stats
@onready var preview_anchor = $HBox/Details/Preview

var biome_timer = 0.0
var biome_interval = 4.0

func _ready():
	_setup_live_preview()
	_populate_list()
	_show_details("scout")
	_cycle_bg()

func _process(delta):
	biome_timer += delta
	if biome_timer >= biome_interval:
		biome_timer = 0.0
		_cycle_bg()

func _populate_list():
	for key in enemy_info.keys():
		var btn = Button.new()
		btn.text = enemy_info[key]["name"]
		btn.pressed.connect(_show_details.bind(key))
		btn.custom_minimum_size = Vector2(0, 60)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		list.add_child(btn)

func _show_details(key: String):
	var data = enemy_info[key]
	detail_name.text = data["name"]
	detail_desc.text = data["desc"]
	detail_stats.text = "HP: " + str(data["hp"]) + " | Speed: " + str(data["speed"]) + " | Threat: " + data["threat"]
	
	if preview_node and preview_node.has_method("setup"):
		preview_node.setup(key, data["color"])
		preview_node.is_moving = true # Ignite engine in preview

func _setup_live_preview():
	var ProceduralEnemy = load("res://procedural_enemy.gd")
	preview_node = Node2D.new()
	preview_node.set_script(ProceduralEnemy)
	preview_node.scale = Vector2(3.0, 3.0) # Larger preview
	preview_node.position = Vector2(100, 100)
	preview_anchor.add_child(preview_node)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://title_screen.tscn")

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _cycle_bg():
	GameManager._generate_procedural_biome()
	var bg = $BG
	if bg and bg.material:
		GameManager.apply_biome_to_shader(bg)
