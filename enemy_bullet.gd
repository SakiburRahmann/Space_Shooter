extends Area2D

# Enemy bullet - fired by Sniper enemies at the player
var speed = 500.0
var damage = 15

var projectile_color = Color(3.5, 0.4, 0.4) # Default Neon Red

func _ready():
	_setup_thrust_particles()
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(self):
		queue_free()

func setup_color(col: Color):
	projectile_color = col
	modulate = col
	_setup_thrust_particles()

func _setup_thrust_particles():
	# Clear old if re-setup
	for child in get_children():
		if child is CPUParticles2D: child.queue_free()
		
	var p = CPUParticles2D.new()
	p.amount = 20
	p.lifetime = 0.25
	p.local_coords = false
	p.direction = Vector2(-1, 0)
	p.spread = 10.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 150.0
	p.initial_velocity_max = 300.0
	
	# Sovereign Visuals: Team-Colored Neon Fire
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	var ramp = Gradient.new()
	ramp.set_color(0, Color.WHITE)
	ramp.set_color(1, projectile_color * 2.0) # High-intensity tail
	p.color_ramp = ramp
	
	add_child(p)
	p.emitting = true

func _physics_process(delta):
	position += transform.x * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
