extends CharacterBody2D

var base_speed = 400.0
var SPEED = 400.0
var fire_rate = 0.15 
var fire_timer = 0.0
var damage = 5

var hp = 100.0
var max_hp = 100
var is_invincible = false
var invincibility_timer = 0.0

# === WEAPONS ===
var has_shotgun = false
var has_rear_gun = false
var has_piercing = false
var has_homing = false
var has_double_shot = false
var has_explosive = false
var has_ricochet = false
var has_chain_lightning = false

# === DEFENSE ===
var has_thorns = false
var thorns_damage = 0
var lifesteal_flat = 0
var hp_regen_rate = 0.0
var damage_reduction = 0.0
var dodge_chance = 0.0
var revival_count = 0
var has_revival = false
var has_shield = false
var shield_timer = 0.0
var shield_cooldown = 10.0
var shield_active = true

# === OFFENSE ===
var crit_chance = 0.0
var crit_multiplier = 1.5
var bullet_size_mult = 1.0
var bullet_speed_mult = 1.0
var explosion_radius = 80.0
var burn_damage = 0
var has_reaper = false
var knockback_force = 0.0
var magnet_radius = 125.0

# === ORBITAL ===
var has_orbital = false
var orbital_count = 0
var orbital_damage = 3
var orbital_speed = 3.0
var orbital_radius = 100.0
var orbital_timer = 0.0

# === ABILITIES ===
var ability_type = "blink" # default for viper
var ability_cooldown = 0.0
var ability_max_cooldown = 8.0
var ability_active_timer = 0.0
var is_ability_active = false

# === SOVEREIGN DECK MECHANICS ===
var luck_stat = 1.0
var bounty_kills = 0
var has_bounty_hunter = false
var has_siege_protocol = false
var has_ghost_drive = false
var is_stationary = false
var has_shatter_frost = false
var has_nitro = false
var has_drone = false
var drone_scene = preload("res://drone.tscn")

signal ability_used()
signal ability_cooldown_updated(current, max_val)

var bullet_scene = preload("res://bullet.tscn")
var game_over_scene = preload("res://game_over.tscn")

func _ready():
	# Apply permanent upgrades + ship stats from SaveManager
	if Engine.has_singleton("SaveManager") or get_node_or_null("/root/SaveManager") != null:
		var stats = SaveManager.get_starting_stats()
		max_hp = stats["hp"]
		hp = max_hp
		damage = stats["damage"]
		fire_rate = stats["fire_rate"]
		SPEED = stats["speed"]
		base_speed = SPEED
		magnet_radius = stats["magnet_radius"]
		revival_count = stats["revival_count"]
		damage_reduction = stats["damage_reduction"]
		
		# Initialize Procedural Ship
		var abl_lvl = stats["ability_lvl"]
		match SaveManager.selected_ship:
			"viper":
				ability_type = "blink"
				ability_max_cooldown = max(2.5, 5.0 - (abl_lvl * 0.1))
				$ProceduralShip.set_ship_type("viper")
			"fortress":
				ability_type = "emp"
				ability_max_cooldown = max(8.0, 15.0 - (abl_lvl * 0.2))
				$ProceduralShip.set_ship_type("fortress")
			"striker":
				ability_type = "overdrive"
				ability_max_cooldown = 12.0
				$ProceduralShip.set_ship_type("striker")
		
		# Sync sleek hitboxes
		$CollisionPolygon2D.polygon = $ProceduralShip.get_hull_points()
		
		# Force Electronic Blue theme for player (Calibrated for realism)
		$ProceduralShip.accent_color = Color(0.0, 2.0, 4.0) 
	
	GameManager.player_hp = int(hp)
	GameManager.player_max_hp = max_hp
	GameManager.hp_changed.emit(int(hp), max_hp)
	
	# No glow pulse needed yet, ProceduralShip handles internal animations

func _physics_process(delta: float) -> void:
	var direction = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_action_pressed("ui_down"):
		direction.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_action_pressed("ui_right"):
		direction.x += 1
		
	direction = direction.normalized()
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
		$ProceduralShip.is_thrusting = true
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 10.0)
		$ProceduralShip.is_thrusting = false

	look_at(get_global_mouse_position())
	move_and_slide()
	
	# Siege Protocol Detection
	is_stationary = (velocity.length() < 10.0)

	# Feed camera position to grid background shader
	var bg = get_parent().get_node_or_null("GridBG")
	if bg and bg.material:
		bg.material.set_shader_parameter("camera_pos", global_position)

	# HP Regeneration
	if hp_regen_rate > 0 and hp < max_hp:
		hp = min(hp + hp_regen_rate * delta, max_hp)
		GameManager.player_hp = int(hp)
		GameManager.hp_changed.emit(int(hp), max_hp)

	# Shield cooldown
	if has_shield and not shield_active:
		shield_timer += delta
		if shield_timer >= shield_cooldown:
			shield_active = true
			shield_timer = 0.0


	# Orbital Shield
	if has_orbital and orbital_count > 0:
		orbital_timer += delta * orbital_speed
		_process_orbitals(delta)

	# I-Frames flashing
	if is_invincible:
		invincibility_timer -= delta
		$ProceduralShip.visible = int(invincibility_timer * 15) % 2 == 0
		if invincibility_timer <= 0:
			is_invincible = false
			$ProceduralShip.visible = true

	# Camera Shake
	if ShakeManager.trauma > 0:
		ShakeManager.trauma = max(ShakeManager.trauma - delta * 2.5, 0.0)
		var shake = pow(ShakeManager.trauma, 2)
		$Camera2D.offset = Vector2(
			randf_range(-1, 1) * ShakeManager.max_x * shake,
			randf_range(-1, 1) * ShakeManager.max_y * shake
		)
		$Camera2D.rotation = randf_range(-1, 1) * ShakeManager.max_r * shake
	else:
		$Camera2D.offset = Vector2.ZERO
		$Camera2D.rotation = 0

	# Ability Cooldown/Active Logic
	if is_ability_active:
		ability_active_timer -= delta
		if ability_active_timer <= 0:
			_deactivate_ability()
	elif ability_cooldown > 0:
		ability_cooldown = max(0, ability_cooldown - delta)
		ability_cooldown_updated.emit(ability_cooldown, ability_max_cooldown)

	if Input.is_key_pressed(KEY_SHIFT) and ability_cooldown <= 0 and not is_ability_active:
		_activate_ability()

	# Auto-Firing

	# Auto-Firing
	fire_timer -= delta
	if fire_timer <= 0:
		fire_bullet()
		fire_timer = fire_rate

func _process_orbitals(delta):
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if not is_instance_valid(enemy): continue
		for i in range(orbital_count):
			var angle = orbital_timer + (i * TAU / orbital_count)
			var orb_pos = global_position + Vector2(cos(angle), sin(angle)) * orbital_radius
			if enemy.global_position.distance_to(orb_pos) < 25:
				if enemy.has_method("take_damage"):
					enemy.take_damage(orbital_damage)

func fire_bullet():
	if bullet_scene == null: return
	
	var actual_damage = damage
	var is_crit = randf() < crit_chance
	
	# Siege Protocol Multiplier
	if has_siege_protocol and is_stationary:
		actual_damage *= 2
		
	if is_crit:
		actual_damage = int(actual_damage * crit_multiplier)
	
	if has_shotgun:
		var spread = deg_to_rad(60.0)
		for port in $ProceduralShip.gun_ports:
			for i in range(5):
				var bullet = _create_bullet(actual_damage)
				bullet.global_position = global_position + port.rotated(global_rotation)
				bullet.global_rotation = global_rotation + (-spread / 2.0) + (spread / 4.0 * i)
				get_parent().call_deferred("add_child", bullet)
	elif has_double_shot:
		for port in $ProceduralShip.gun_ports:
			var bullet = _create_bullet(actual_damage)
			bullet.global_position = global_position + port.rotated(global_rotation)
			bullet.global_rotation = global_rotation
			get_parent().call_deferred("add_child", bullet)
	else:
		for port in $ProceduralShip.gun_ports:
			var bullet = _create_bullet(actual_damage)
			bullet.global_position = global_position + port.rotated(global_rotation)
			bullet.global_rotation = global_rotation
			get_parent().call_deferred("add_child", bullet)
	
	if has_rear_gun:
		var rear = _create_bullet(int(actual_damage * 0.5))
		rear.global_position = global_position
		rear.global_rotation = global_rotation + PI
		get_parent().call_deferred("add_child", rear)

func _create_bullet(dmg: int) -> Node:
	var bullet = bullet_scene.instantiate()
	bullet.damage = dmg
	bullet.piercing = has_piercing
	bullet.homing = has_homing
	bullet.explosive = has_explosive
	bullet.explosion_radius = explosion_radius
	bullet.chain_lightning = has_chain_lightning
	bullet.speed_mult = bullet_speed_mult
	bullet.burn_damage = burn_damage
	bullet.has_reaper = has_reaper
	bullet.knockback_force = knockback_force
	bullet.has_freeze = has_shatter_frost
	return bullet

func take_damage(amount: int = 10):
	if is_invincible: return
	
	if has_shield and shield_active:
		shield_active = false
		shield_timer = 0.0
		return
	
	if randf() < dodge_chance:
		return
	
	var final_damage = int(amount * (1.0 - damage_reduction))
	final_damage = max(final_damage, 1)
	
	hp -= final_damage
	GameManager.player_hp = int(hp)
	GameManager.hp_changed.emit(int(hp), max_hp)
	ShakeManager.add_trauma(0.6)
	
	if has_thorns and thorns_damage > 0:
		for enemy in get_tree().get_nodes_in_group("Enemy"):
			if is_instance_valid(enemy):
				if global_position.distance_to(enemy.global_position) < 60:
					if enemy.has_method("take_damage"):
						enemy.take_damage(thorns_damage)
	
	if hp <= 0:
		if revival_count > 0:
			revival_count -= 1
			hp = max_hp * 0.35
			GameManager.player_hp = int(hp)
			GameManager.hp_changed.emit(int(hp), max_hp)
			is_invincible = true
			invincibility_timer = 2.5
			ShakeManager.add_trauma(1.0)
			return
		_show_game_over()
	else:
		is_invincible = true
		invincibility_timer = 0.8

func on_enemy_killed():
	# Bounty Hunter Logic
	if has_bounty_hunter:
		bounty_kills += 1
		if bounty_kills >= 10:
			bounty_kills = 0
			SaveManager.void_credits += 1
			SaveManager.save_data()
	
	if lifesteal_flat > 0:
		hp = min(hp + lifesteal_flat, max_hp)
		GameManager.player_hp = int(hp)
		GameManager.hp_changed.emit(int(hp), max_hp)

func spawn_drone():
	if drone_scene == null: return
	var d = drone_scene.instantiate()
	d.target_player = self
	get_parent().add_child(d)
	has_drone = true

func _activate_ability():
	is_ability_active = true
	ability_cooldown = ability_max_cooldown
	ability_used.emit()
	
	match ability_type:
		"blink":
			_trigger_blink()
		"emp":
			_trigger_emp()
		"overdrive":
			_trigger_overdrive()

func _deactivate_ability():
	is_ability_active = false
	if ability_type == "overdrive":
		SPEED = base_speed
		$ProceduralShip.modulate = Color(1, 1, 1, 1)

func _trigger_blink():
	# Teleport forward in direction of mouse
	var target_dir = (get_global_mouse_position() - global_position).normalized()
	var prev_pos = global_position
	global_position += target_dir * 300.0
	
	# Visual flare
	_create_blink_trail(prev_pos, global_position)
	is_ability_active = false # Instant effect
	
	if has_ghost_drive:
		is_invincible = true
		invincibility_timer = 1.2 # Extended ghosting
	else:
		is_invincible = true
		invincibility_timer = 0.5
		
	ShakeManager.add_trauma(0.4)

var shockwave_scene = preload("res://shockwave.tscn")

func _trigger_emp():
	ability_active_timer = 0.2
	ShakeManager.add_trauma(0.7)
	# Clear bullets
	for bullet in get_tree().get_nodes_in_group("EnemyBullets"):
		bullet.queue_free()
	# Stun enemies
	var stun_bonus = SaveManager.ship_upgrades.get("fortress", 0) * 0.1
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if global_position.distance_to(enemy.global_position) < 500:
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(2.0 + stun_bonus)
	
	# Visual effect
	var sw = shockwave_scene.instantiate()
	sw.global_position = global_position
	get_parent().add_child(sw)

func _trigger_overdrive():
	var dur_bonus = SaveManager.ship_upgrades.get("striker", 0) * 0.2
	ability_active_timer = 3.5 + dur_bonus
	SPEED = base_speed * 1.6
	$ProceduralShip.modulate = Color(2.5, 1.8, 0.2, 1) # Intense golden overdrive glow

func _create_blink_trail(start: Vector2, _end: Vector2):
	# Create a ghosting effect
	for i in range(4):
		var ghost = $ProceduralShip.duplicate()
		get_parent().add_child(ghost)
		ghost.global_position = start.lerp(global_position, float(i)/4.0)
		ghost.modulate.a = 0.5
		var t = create_tween()
		t.tween_property(ghost, "modulate:a", 0.0, 0.3)
		t.tween_property(ghost, "scale", Vector2.ZERO, 0.3)
		t.tween_callback(ghost.queue_free)

func _show_game_over():
	var go = game_over_scene.instantiate()
	get_tree().current_scene.call_deferred("add_child", go)
	set_physics_process(false)
	visible = false
