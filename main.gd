extends Node2D

# --- ENEMY SCENE PRELOADS ---
var enemy_scene = preload("res://enemy.tscn")
var fast_enemy_scene = preload("res://fast_enemy.tscn")
var tank_enemy_scene = preload("res://tank_enemy.tscn")
var sniper_enemy_scene = preload("res://sniper_enemy.tscn")
var zigzag_enemy_scene = preload("res://zigzag_enemy.tscn")
var splitter_enemy_scene = preload("res://splitter_enemy.tscn")
var bomber_enemy_scene = preload("res://bomber_enemy.tscn")
var summoner_enemy_scene = preload("res://summoner_enemy.tscn")
# --- VOID-CLASS ELITES ---
var vanguard_enemy_scene = preload("res://vanguard_enemy.tscn")
var wraith_enemy_scene = preload("res://wraith_enemy.tscn")
var leech_enemy_scene = preload("res://leech_enemy.tscn")
var singularity_enemy_scene = preload("res://singularity_enemy.tscn")

# --- SPANWER STATE ---
var wave_type_map = {
	1: [enemy_scene],
	2: [fast_enemy_scene],
	3: [tank_enemy_scene],
	4: [sniper_enemy_scene],
	5: [zigzag_enemy_scene],
	6: [splitter_enemy_scene],
	7: [bomber_enemy_scene],
	8: [summoner_enemy_scene],
	9: [vanguard_enemy_scene],
	10: [wraith_enemy_scene],
	11: [leech_enemy_scene],
	12: [singularity_enemy_scene],
}

var spawn_bag = []
var spawn_timer: Timer
var is_spawning = true

func _ready():
	spawn_timer = Timer.new()
	spawn_timer.wait_time = 1.0
	spawn_timer.autostart = true
	spawn_timer.timeout.connect(_on_spawn_tick)
	add_child(spawn_timer)
	
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.wave_complete.connect(_on_wave_complete)
	GameManager.biome_changed.connect(_on_biome_changed)
	_on_biome_changed(GameManager.current_biome)

func _on_biome_changed(biome_data):
	var bg = $GridBG
	if bg: GameManager.apply_biome_to_shader(bg)

func _on_wave_complete():
	is_spawning = false
	spawn_timer.stop()
	var upgrade_menu = $UpgradeMenu
	if upgrade_menu: upgrade_menu.show_upgrade_menu()

func _on_wave_changed(wave_num):
	# Sovereign Escalation Protocol (Exponential Ramp-Up)
	var base_time = 3.0
	var decay_rate = 0.85
	var new_wait_time = base_time * pow(decay_rate, wave_num - 1)
	
	spawn_timer.wait_time = max(0.3, new_wait_time)
	is_spawning = true
	spawn_timer.start()
	spawn_bag.clear()

func _on_spawn_tick():
	if not is_spawning: return
	
	# Sovereign On-Screen Quota System
	# Pacing strictly caps on-screen swarms to prevent instant overwhelming
	var max_enemies_for_wave = 5 + int(pow(GameManager.current_wave, 1.6))
	var current_enemies = get_tree().get_nodes_in_group("Enemy").size()
	
	# Only spawn if the current count hasn't reached the cap
	if current_enemies < max_enemies_for_wave:
		_spawn_enemy()

func _spawn_enemy():
	if spawn_bag.is_empty():
		_refill_spawn_bag()
	
	var selected = spawn_bag.pop_back()
	if selected == null: return
	
	var enemy = selected.instantiate()
	enemy.add_to_group("Enemy")
	
	# Global difficulty scaling
	if "SPEED" in enemy:
		enemy.SPEED += (GameManager.current_wave * 4.0)
	if "hp" in enemy:
		enemy.hp = int(enemy.hp * (1.0 + GameManager.current_wave * 0.1))
	
	add_child(enemy)
	
	# Spawn in professional radius
	var player = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(player):
		var angle = randf() * PI * 2
		enemy.global_position = player.global_position + Vector2(cos(angle), sin(angle)) * 1200.0

func _refill_spawn_bag():
	var wave = GameManager.current_wave
	var unlocked = []
	
	# 1. Always include the "Featured" enemy for this wave
	var featured = wave_type_map.get(wave, [enemy_scene])
	for i in range(8): # High frequency for new type
		unlocked.append(featured[0])
	
	# 2. Add variety from previous waves
	for i in range(1, wave):
		if i in wave_type_map:
			unlocked.append(wave_type_map[i][0])
	
	# 3. For high waves (13+), include everything randomly
	if wave > 12:
		for k in wave_type_map.keys():
			unlocked.append(wave_type_map[k][0])
			
	for type in unlocked:
		spawn_bag.append(type)
	spawn_bag.shuffle()
