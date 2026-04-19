extends Node

var current_wave = 1
var player_hp = 100
var player_max_hp = 100
var total_kills = 0
var run_time = 0.0
var is_wave_clearing = false
var enemy_hp_mult = 1.0
var extra_gem_drops = 0
var total_gems_collected = 0

signal hp_changed(new_hp, max_hp)
signal wave_changed(new_wave)
signal wave_complete()
signal biome_changed(biome_data)

var wave_progress = {"RED": 0, "BLUE": 0, "GREEN": 0}
var wave_targets = {"RED": 0, "BLUE": 0, "GREEN": 0}
signal objective_updated(prog, tgt)

var palette_bases = [
	{"hue": 0.55, "name": "DEEP SPACE"},      # cyan/blue
	{"hue": 0.0,  "name": "CRIMSON VOID"},     # red
	{"hue": 0.3,  "name": "TOXIC ZONE"},       # green
	{"hue": 0.6,  "name": "FROZEN CORE"},       # blue
	{"hue": 0.1,  "name": "SOLAR FLARE"},       # orange
	{"hue": 0.8,  "name": "NEON DISTRICT"},     # purple/pink
	{"hue": 0.45, "name": "ACID RAIN"},         # teal
	{"hue": 0.15, "name": "MOLTEN CORE"},       # gold
	{"hue": 0.7,  "name": "PHANTOM REALM"},     # violet
	{"hue": 0.35, "name": "EMERALD GRID"},      # emerald
	{"hue": 0.05, "name": "BLOOD MOON"},        # dark red
	{"hue": 0.9,  "name": "ULTRAVIOLET"},       # magenta
	{"hue": 0.5,  "name": "COBALT WAVE"},       # cobalt
	{"hue": 0.25, "name": "AMBER VOID"},        # amber
	{"hue": 0.65, "name": "INDIGO DEPTHS"},     # indigo
	{"hue": 0.95, "name": "ELECTRIC ROSE"},     # rose
]

var used_seeds = []
var current_biome = {}
var biome_seed_counter = 0

func _ready():
	_generate_new_objective()
	_generate_procedural_biome()

func _process(delta):
	if not get_tree().paused:
		run_time += delta

func _hue_to_rgb(h: float, s: float, v: float) -> Vector3:
	# HSV to RGB conversion
	var c = v * s
	var x = c * (1.0 - abs(fmod(h * 6.0, 2.0) - 1.0))
	var m = v - c
	var r = 0.0; var g = 0.0; var b = 0.0
	if h < 1.0/6.0: r = c; g = x; b = 0
	elif h < 2.0/6.0: r = x; g = c; b = 0
	elif h < 3.0/6.0: r = 0; g = c; b = x
	elif h < 4.0/6.0: r = 0; g = x; b = c
	elif h < 5.0/6.0: r = x; g = 0; b = c
	else: r = c; g = 0; b = x
	return Vector3(r + m, g + m, b + m)

func _generate_procedural_biome():
	biome_seed_counter += 1
	var seed_val = randf() * 10000.0
	# Ensure uniqueness
	while seed_val in used_seeds:
		seed_val = randf() * 10000.0
	used_seeds.append(seed_val)
	if used_seeds.size() > 50: used_seeds.pop_front()
	
	# Pick a random palette base, but add variation
	var base = palette_bases[randi() % palette_bases.size()]
	var hue = fmod(base["hue"] + randf_range(-0.08, 0.08), 1.0)
	var hue2 = fmod(hue + randf_range(0.05, 0.15), 1.0) # Complementary accent
	
	# Generate dark background colors from hue
	var color_top = _hue_to_rgb(hue, 0.6, 0.04 + randf() * 0.03)
	var color_bottom = _hue_to_rgb(hue, 0.5, 0.02 + randf() * 0.02)
	
	# Bright accent colors (Neon High-Efficiency)
	var accent_1 = _hue_to_rgb(hue, 0.8 + randf() * 0.2, 0.4 + randf() * 0.3)
	var accent_2 = _hue_to_rgb(hue2, 0.6 + randf() * 0.3, 0.2 + randf() * 0.2)
	
	# Random pattern selection (0-11)
	var pattern_id = float(randi() % 12)
	
	current_biome = {
		"name": base["name"],
		"color_top": color_top,
		"color_bottom": color_bottom,
		"accent_1": accent_1,
		"accent_2": accent_2,
		"pattern_id": pattern_id,
		"pattern_scale": randf_range(40.0, 120.0),
		"pattern_intensity": randf_range(0.3, 0.7),
		"secondary_scale": randf_range(20.0, 60.0),
		"vignette": randf_range(0.7, 1.1),
		"warp": randf_range(0.0, 0.6),
		"anim_speed": randf_range(0.15, 0.6),
		"seed": seed_val,
	}
	biome_changed.emit(current_biome)

func apply_biome_to_shader(bg_node: Node):
	if not bg_node or not bg_node.material: return
	var mat = bg_node.material
	var b = current_biome
	mat.set_shader_parameter("color_top", b["color_top"])
	mat.set_shader_parameter("color_bottom", b["color_bottom"])
	mat.set_shader_parameter("accent_1", b["accent_1"])
	mat.set_shader_parameter("accent_2", b["accent_2"])
	mat.set_shader_parameter("pattern_id", b["pattern_id"])
	mat.set_shader_parameter("pattern_scale", b["pattern_scale"])
	mat.set_shader_parameter("pattern_intensity", b["pattern_intensity"])
	mat.set_shader_parameter("secondary_scale", b["secondary_scale"])
	mat.set_shader_parameter("vignette_strength", b["vignette"])
	mat.set_shader_parameter("warp_amount", b["warp"])
	mat.set_shader_parameter("anim_speed", b["anim_speed"])
	mat.set_shader_parameter("seed_val", b["seed"])

func get_spawning_intensity() -> float:
	# Wave scaling (faster/more intense over time)
	return 1.0 + (current_wave * 0.1)

func _generate_new_objective():
	wave_progress = {"RED": 0, "BLUE": 0, "GREEN": 0}
	wave_targets = {"RED": 0, "BLUE": 0, "GREEN": 0}
	var total = 2 + (current_wave * 2)
	var colors = ["RED", "BLUE", "GREEN"]
	for i in range(total):
		wave_targets[colors[randi() % colors.size()]] += 1
	objective_updated.emit(wave_progress, wave_targets)

func collect_node(color: String):
	total_gems_collected += 1
	if wave_targets[color] > 0 and wave_progress[color] < wave_targets[color]:
		wave_progress[color] += 1
		objective_updated.emit(wave_progress, wave_targets)
		_check_win_condition()
	else:
		var player = get_tree().get_first_node_in_group("Player")
		if is_instance_valid(player) and player.has_method("take_damage"):
			player.take_damage(5)

func _check_win_condition():
	for k in wave_targets.keys():
		if wave_progress[k] < wave_targets[k]:
			return
	is_wave_clearing = true
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy.has_method("die"):
			enemy.die()
	call_deferred("_cleanup_gems")
	wave_complete.emit()

func _cleanup_gems():
	await get_tree().process_frame
	await get_tree().process_frame
	for gem in get_tree().get_nodes_in_group("Gems"):
		gem.queue_free()
	is_wave_clearing = false
	
func start_next_wave():
	current_wave += 1
	_generate_procedural_biome()
	var player = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(player):
		player.global_position = Vector2(960, 540)
		player.hp = player.max_hp
		player_hp = player.max_hp
		hp_changed.emit(int(player.hp), player.max_hp)
	_generate_new_objective()
	wave_changed.emit(current_wave)

func register_kill():
	total_kills += 1

func reset_run():
	current_wave = 1
	player_hp = 100
	player_max_hp = 100
	total_kills = 0
	run_time = 0.0
	is_wave_clearing = false
	enemy_hp_mult = 1.0
	extra_gem_drops = 0
	total_gems_collected = 0
	biome_seed_counter = randi() % 1000
	wave_progress = {"RED": 0, "BLUE": 0, "GREEN": 0}
	wave_targets = {"RED": 0, "BLUE": 0, "GREEN": 0}
	_generate_new_objective()
	_generate_procedural_biome()

func gain_xp(a): pass
