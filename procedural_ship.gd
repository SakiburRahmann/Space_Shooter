extends Node2D

# --- Sovereign Neon Interceptor ---
enum ShipType { VIPER, FORTRESS, STRIKER }
var current_ship = ShipType.VIPER

var hull_main = Color(0.12, 0.12, 0.16)
var hull_armor = Color(0.7, 0.7, 0.8)
var accent_color = Color(2.0, 4.0, 12.0) # PIERCING NEON BLUE
var cockpit_glass = Color(0.1, 0.4, 0.6, 0.8)
var sensor_glow = Color(1.0, 1.5, 4.0) * 0.4

var is_thrusting = false
var thrust_ports = []
var gun_ports = []

# High-Grade Neon Particle System
var particle_emitters = []

func _ready():
	_update_ship_specs()
	_reconstruct_neon_thrusters()

func _physics_process(_delta):
	_sync_particle_states()
	queue_redraw()

func _reconstruct_neon_thrusters():
	# Clear old nodes
	for p in particle_emitters:
		p.queue_free()
	particle_emitters.clear()
	
	# Create extreme neon emitters for each port
	for port in thrust_ports:
		var p = CPUParticles2D.new()
		p.position = port
		p.amount = 12
		p.lifetime = 0.12
		p.speed_scale = 1.0
		p.explosiveness = 0.0
		p.randomness = 0.5
		
		# Hull Priority: Draw behind the ship
		p.show_behind_parent = true
		
		# Newtonian Physics: Trails stay in world space
		p.local_coords = false
		
		# Movement: Sovereign High-Velocity Needle
		p.direction = Vector2(-1, 0)
		p.spread = 1.0
		p.gravity = Vector2.ZERO
		p.initial_velocity_min = 800.0
		p.initial_velocity_max = 1200.0
		p.damping_min = 0.0 # No damping for high-speed look
		p.damping_max = 0.0
		
		# Visuals: Tapered Triangle Flare
		p.scale_amount_min = 3.0
		p.scale_amount_max = 5.0
		var s_curve = Curve.new()
		s_curve.add_point(Vector2(0, 1.0))
		s_curve.add_point(Vector2(1, 0.0)) # Tapers to a point
		p.scale_amount_curve = s_curve
		var ramp = Gradient.new()
		ramp.set_color(0, Color.WHITE) # White-hot core
		ramp.set_color(1, Color(0.0, 0.5, 5.0, 1.0)) # Extreme Neon Blue
		ramp.add_point(0.4, Color(0.2, 0.8, 8.0, 1.0)) # Bright Flare
		p.color_ramp = ramp
		
		# Soft-Glow Flare Texture (Procedural)
		p.texture = _get_neo_flare_texture()
		
		add_child(p)
		particle_emitters.append(p)

func _get_neo_flare_texture():
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var dist = Vector2(x-8, y-8).length()
			var alpha = clamp(1.0 - (dist / 8.0), 0.0, 1.0)
			alpha = pow(alpha, 2.0) # Soft edges
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _sync_particle_states():
	for p in particle_emitters:
		p.emitting = is_thrusting
		# Correct rotation for the nozzle in global space
		p.direction = (-transform.x).rotated(randf_range(-0.1, 0.1))

func _draw():
	# 1. Hull Outlines
	var out_pts = _get_player_outline()
	draw_polyline(out_pts, Color.BLACK, 2.5)

	# 2. HULL SYNTHESIS
	match current_ship:
		ShipType.VIPER: _draw_sovereign_viper()
		ShipType.FORTRESS: _draw_sovereign_fortress()
		ShipType.STRIKER: _draw_sovereign_striker()

func _draw_sovereign_viper():
	var chassis = [Vector2(40, 0), Vector2(15, -12), Vector2(-25, -12), Vector2(-25, 12), Vector2(15, 12)]
	draw_colored_polygon(chassis, hull_main)
	var wing_l = [Vector2(10, -5), Vector2(-15, -28), Vector2(-25, -10)]
	var wing_r = [Vector2(10, 5), Vector2(-15, 28), Vector2(-25, 10)]
	draw_colored_polygon(wing_l, hull_armor)
	draw_colored_polygon(wing_r, hull_armor)
	draw_polyline(wing_l + [wing_l[0]], Color(1, 2, 8), 1.5)
	draw_polyline(wing_r + [wing_r[0]], Color(1, 2, 8), 1.5)
	var canopy = [Vector2(28, 0), Vector2(15, -7), Vector2(0, -7), Vector2(0, 7), Vector2(15, 7)]
	draw_colored_polygon(canopy, cockpit_glass)
	draw_rect(Rect2(12, -2, 8, 4), sensor_glow)

func _draw_sovereign_fortress():
	var chassis = [Vector2(35, -20), Vector2(35, 20), Vector2(15, 35), Vector2(-40, 30), Vector2(-40, -30), Vector2(15, -35)]
	draw_colored_polygon(chassis, hull_main)
	draw_rect(Rect2(-15, -32, 40, 8), hull_armor)
	draw_rect(Rect2(-15, 24, 40, 8), hull_armor)
	var bridge = [Vector2(32, -15), Vector2(32, 15), Vector2(10, 15), Vector2(10, -15)]
	draw_colored_polygon(bridge, cockpit_glass)
	draw_rect(Rect2(18, -10, 10, 20), sensor_glow.lerp(Color.WHITE, 0.5))
	draw_polyline(chassis + [chassis[0]], Color(1, 2, 8), 2.0)

func _draw_sovereign_striker():
	var boom_l = [Vector2(-30, -22), Vector2(45, -18), Vector2(45, -10), Vector2(-20, -5)]
	var boom_r = [Vector2(-30, 22), Vector2(45, 18), Vector2(45, 10), Vector2(-20, 5)]
	draw_colored_polygon(boom_l, hull_main)
	draw_colored_polygon(boom_r, hull_main)
	var core = [Vector2(-35, -12), Vector2(15, -12), Vector2(15, 12), Vector2(-35, 12)]
	draw_colored_polygon(core, hull_armor)
	draw_polyline(boom_l + [boom_l[0]], Color(1, 2, 8), 1.2)
	draw_polyline(boom_r + [boom_r[0]], Color(1, 2, 8), 1.2)
	var canopy = [Vector2(12, 0), Vector2(-5, -6), Vector2(-5, 6)]
	draw_colored_polygon(canopy, sensor_glow)

func _get_player_outline() -> PackedVector2Array:
	match current_ship:
		ShipType.VIPER: return [Vector2(40, 0), Vector2(15, -12), Vector2(-25, -12), Vector2(-25, 12), Vector2(15, 12), Vector2(40, 0)]
		ShipType.FORTRESS: return [Vector2(35, -20), Vector2(35, 20), Vector2(15, 35), Vector2(-40, 30), Vector2(-40, -30), Vector2(15, -35), Vector2(35, -20)]
		_: return [Vector2(45, -18), Vector2(45, 18), Vector2(-35, 12), Vector2(-35, -12), Vector2(45, -18)]

func _update_ship_specs():
	match current_ship:
		ShipType.VIPER:
			thrust_ports = [Vector2(-25, 0)]
			gun_ports = [Vector2(38, 0)]
		ShipType.FORTRESS:
			thrust_ports = [Vector2(-38, -15), Vector2(-38, 15)]
			gun_ports = [Vector2(33, -12), Vector2(33, 12)]
		ShipType.STRIKER:
			thrust_ports = [Vector2(-28, -16), Vector2(-28, 16)]
			gun_ports = [Vector2(45, -15), Vector2(45, 15)]

func set_ship_type(type_name: String):
	match type_name:
		"viper": current_ship = ShipType.VIPER
		"fortress": current_ship = ShipType.FORTRESS
		"striker": current_ship = ShipType.STRIKER
	_update_ship_specs()
	_reconstruct_neon_thrusters()
	queue_redraw()

func get_hull_points() -> PackedVector2Array:
	match current_ship:
		ShipType.VIPER:
			return PackedVector2Array([Vector2(40, 0), Vector2(-15, -28), Vector2(-25, -12), Vector2(-25, 12), Vector2(-15, 28)])
		ShipType.FORTRESS:
			return PackedVector2Array([Vector2(35, -20), Vector2(35, 20), Vector2(15, 35), Vector2(-40, 30), Vector2(-40, -30), Vector2(15, -35)])
		ShipType.STRIKER:
			return PackedVector2Array([Vector2(45, -18), Vector2(45, 18), Vector2(-35, 12), Vector2(-35, -12)])
		_:
			return PackedVector2Array([Vector2(30, 0), Vector2(-15, -20), Vector2(-15, 20)])
