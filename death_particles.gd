extends Node2D

func _ready():
	# Standardize startup for multiple emitters
	for child in get_children():
		if child is GPUParticles2D:
			child.emitting = true
	
	# Match with longest lifetime
	await get_tree().create_timer(1.5).timeout
	queue_free()

func setup(_col: Color):
	# Unified yellow fire; placeholder for compat
	pass
