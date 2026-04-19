extends Node2D

var enemy_type = "basic"
var accent_color = Color(3.5, 0.4, 0.4) 
var hull_main = Color(0.15, 0.15, 0.2)
var hull_armor = Color(0.6, 0.6, 0.7)
var sensor_glow = Color(4.0, 0.2, 0.1)  

var is_moving = false
var flicker_timer = 0.0
var anim_factor = 0.0 
var ring_rot = 0.0

# Sovereign Neon Particle System
var exhaust_emitter : CPUParticles2D

var muzzle_port = Vector2(20, 0) # Default muzzle tip for warships

func setup(type: String, col: Color):
	enemy_type = type
	accent_color = col
	
	# Cap the HDR brightness for the ship's physical hull so the geometry remains visible
	var safe_col = col
	if safe_col.v > 1.5:
		safe_col.v = 1.5
		
	sensor_glow = safe_col * 1.2
	hull_armor = safe_col.lerp(Color.WHITE, 0.3)
	hull_armor.v = 1.0
	
	# Adjust muzzle based on hull type
	match type:
		"sniper": muzzle_port = Vector2(40, 0)
		"tank": muzzle_port = Vector2(25, 0)
		"striker": muzzle_port = Vector2(30, 0)
		"singularity": muzzle_port = Vector2(0, 0) # Center spawn
		_: muzzle_port = Vector2(20, 0)
		
	# Rebuild the engine thrust with the new color immediately
	if is_inside_tree():
		_reconstruct_neon_thruster()

func _ready():
	_reconstruct_neon_thruster()

func _physics_process(delta):
	flicker_timer += delta * 25.0
	ring_rot += delta * 12.0
	anim_factor = lerp(anim_factor, 1.0 if is_moving else 0.0, 5.0 * delta)
	
	if is_instance_valid(exhaust_emitter):
		exhaust_emitter.emitting = is_moving
		if is_moving:
			# Correct rotation for Newtonian trail
			exhaust_emitter.direction = (-transform.x).rotated(randf_range(-0.1, 0.1))
	
	queue_redraw()

func _reconstruct_neon_thruster():
	if is_instance_valid(exhaust_emitter):
		exhaust_emitter.queue_free()
	
	exhaust_emitter = CPUParticles2D.new()
	exhaust_emitter.position = Vector2(-15, 0)
	exhaust_emitter.amount = 8
	exhaust_emitter.lifetime = 0.1
	exhaust_emitter.show_behind_parent = true
	exhaust_emitter.local_coords = false 
	
	exhaust_emitter.direction = Vector2(-1, 0)
	exhaust_emitter.spread = 2.0
	exhaust_emitter.gravity = Vector2.ZERO
	exhaust_emitter.initial_velocity_min = 600.0
	exhaust_emitter.initial_velocity_max = 1000.0
	exhaust_emitter.damping_min = 0.0
	exhaust_emitter.damping_max = 0.0
	
	# Sovereign Visuals: Tapered High-Speed Needle
	exhaust_emitter.scale_amount_min = 2.0
	exhaust_emitter.scale_amount_max = 4.0
	var s_curve = Curve.new()
	s_curve.add_point(Vector2(0, 1.0))
	s_curve.add_point(Vector2(1, 0.0))
	exhaust_emitter.scale_amount_curve = s_curve
	var ramp = Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, accent_color * 1.5) # Reduced from 3.0 to keep thrust detailed
	exhaust_emitter.color_ramp = ramp
	
	# Soft flare texture
	exhaust_emitter.texture = _get_neo_flare_texture()
	add_child(exhaust_emitter)

func _get_neo_flare_texture():
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	for y in range(16):
		for x in range(16):
			var dist = Vector2(x-8, y-8).length()
			var alpha = clamp(1.0 - (dist / 8.0), 0.0, 1.0)
			alpha = pow(alpha, 2.0)
			img.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(img)

func _draw():
	# 1. Hull Outlines (For Clarity)
	match enemy_type:
		"tank": draw_polyline(_get_points_for_outline(), Color.BLACK, 4.0)
		_: draw_polyline(_get_points_for_outline(), Color.BLACK, 2.5)

	# 2. Hull Reconstruction
	match enemy_type:
		"scout": _draw_warship_scout()
		"tank": _draw_warship_tank()
		"striker": _draw_warship_striker()
		"sniper": _draw_warship_sniper()
		"elite": _draw_warship_elite()
		"wraith": _draw_warship_wraith()
		"bomber": _draw_warship_bomber()
		"leech": _draw_warship_leech()
		"shield": _draw_warship_shield()
		"fortress": _draw_warship_fortress()
		"singularity": _draw_warship_singularity()
		"void": _draw_warship_void()
		_: _draw_warship_scout()

# [Warship Series Implementations]
func _draw_warship_scout():
	var blade = [Vector2(20, 0), Vector2(-15, -15), Vector2(-25, 0), Vector2(-15, 15)]
	draw_colored_polygon(blade, hull_main)
	draw_colored_polygon([Vector2(20, 0), Vector2(0, -10), Vector2(0, 10)], hull_armor)
	draw_rect(Rect2(-5, -2, 12, 4), sensor_glow)

func _draw_warship_tank():
	var base = [Vector2(25, -20), Vector2(25, 20), Vector2(-25, 25), Vector2(-35, 0), Vector2(-25, -25)]
	draw_colored_polygon(base, hull_main)
	draw_rect(Rect2(-20, -18, 40, 36), hull_armor)
	draw_rect(Rect2(15, -15, 10, 30), sensor_glow)

func _draw_warship_striker():
	var wing1 = [Vector2(25, -5), Vector2(-20, -20), Vector2(-15, -5)]
	var wing2 = [Vector2(25, 5), Vector2(-20, 20), Vector2(-15, 5)]
	draw_colored_polygon(wing1, hull_main)
	draw_colored_polygon(wing2, hull_main)
	draw_colored_polygon([Vector2(30, 0), Vector2(0, -8), Vector2(0, 8)], hull_armor)

func _draw_warship_sniper():
	var needle = [Vector2(40, 0), Vector2(0, -8), Vector2(-30, -5), Vector2(-30, 5), Vector2(0, 8)]
	draw_colored_polygon(needle, hull_main)
	draw_rect(Rect2(5, -3, 30, 6), sensor_glow)

func _draw_warship_elite():
	var star = [Vector2(30, 0), Vector2(0, -25), Vector2(-30, 0), Vector2(0, 25)]
	draw_colored_polygon(star, hull_main)
	draw_circle(Vector2(0, 0), 12, hull_armor)
	draw_circle(Vector2(0, 0), 6, sensor_glow)

func _draw_warship_wraith():
	var pts = [Vector2(20, -15), Vector2(35, 0), Vector2(20, 15), Vector2(-10, 30), Vector2(-25, 0), Vector2(-10, -30)]
	draw_colored_polygon(pts, hull_main)
	draw_polyline(pts + [pts[0]], accent_color, 1.5)

func _draw_warship_bomber():
	draw_circle(Vector2(0, 0), 22, hull_main)
	draw_circle(Vector2(0, 0), 15, hull_armor)
	for i in range(8):
		var ang = i * PI/4 + ring_rot * 0.1
		draw_circle(Vector2(cos(ang)*18, sin(ang)*18), 4, sensor_glow)

func _draw_warship_leech():
	var heart = [Vector2(0, -20), Vector2(15, 0), Vector2(0, 20), Vector2(-15, 0)]
	draw_colored_polygon(heart, hull_main)
	for i in range(4):
		var ang = i * PI/2 + ring_rot
		draw_line(Vector2(0,0), Vector2(cos(ang)*25, sin(ang)*25), accent_color, 3.0)

func _draw_warship_shield():
	draw_arc(Vector2(0, 0), 30, -PI/2, PI/2, 32, accent_color, 5.0)
	draw_rect(Rect2(-20, -20, 25, 40), hull_main)

func _draw_warship_fortress():
	draw_rect(Rect2(-30, -30, 60, 60), hull_main)
	draw_rect(Rect2(-20, -20, 40, 40), hull_armor)
	draw_rect(Rect2(-5, -5, 10, 10), sensor_glow)

func _draw_warship_singularity():
	draw_circle(Vector2(0,0), 25, Color.BLACK)
	for i in range(12):
		var ang = i * PI/6 + ring_rot
		var l = 30 + sin(Time.get_ticks_msec()*0.01 + i) * 10
		draw_line(Vector2(0,0), Vector2(cos(ang)*l, sin(ang)*l), accent_color, 2.0)

func _draw_warship_void():
	var diamond = [Vector2(40, 0), Vector2(0, -25), Vector2(-40, 0), Vector2(0, 25)]
	draw_colored_polygon(diamond, Color.BLACK)
	draw_polyline(diamond + [diamond[0]], sensor_glow, 3.0)

func _get_points_for_outline() -> PackedVector2Array:
	match enemy_type:
		"scout": return [Vector2(20, 0), Vector2(-15, -15), Vector2(-25, 0), Vector2(-15, 15), Vector2(20, 0)]
		"tank": return [Vector2(25, -20), Vector2(25, 20), Vector2(-25, 25), Vector2(-35, 0), Vector2(-25, -25), Vector2(25, -20)]
		"striker": return [Vector2(30, 0), Vector2(-20, -20), Vector2(-15, -5), Vector2(-15, 5), Vector2(-20, 20), Vector2(30, 0)]
		"wraith": return [Vector2(20, -15), Vector2(35, 0), Vector2(20, 15), Vector2(-10, 30), Vector2(-25, 0), Vector2(-10, -30), Vector2(20, -15)]
		_: return [Vector2(25, 0), Vector2(-15, -20), Vector2(-15, 20), Vector2(25, 0)]

func get_hull_points() -> PackedVector2Array:
	return _get_points_for_outline()
