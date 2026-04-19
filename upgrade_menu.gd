extends CanvasLayer

# =====================================================================
#  SOVEREIGN DATA-NEXUS - High Fidelity UI Refactoring
# =====================================================================

const COLOR_OFFENSE = Color(3.5, 0.4, 0.4) 
const COLOR_DEFENSE = Color(0.4, 3.5, 0.4) 
const COLOR_UTILITY = Color(0.1, 1.5, 4.0) 
const COLOR_UNIQUE  = Color(4.0, 3.0, 0.1) 

var glass_shader = preload("res://glass_blur.gdshader")

var upgrade_pool = [
	# --- Logic data remains same for stability, but visuals are overhaull ---
	{"name": "Might Apex", "desc": "+20% Weapon Might", "type": "might_master", "cat": "offense"},
	{"name": "Chrono-Splitter", "desc": "+25% Fire Rate", "type": "firerate_master", "cat": "offense"},
	{"name": "Velocity Drive", "desc": "+30% Bullet Speed", "type": "bulletspeed_master", "cat": "offense"},
	{"name": "Titan Plating", "desc": "Reduce Damage 15%", "type": "armor_master", "cat": "defense"},
	{"name": "Vanguard Aegis", "desc": "+30 Max HP", "type": "hp_master", "cat": "defense"},
	{"name": "Tractor Beam", "desc": "+50% Magnet Radius", "type": "magnet_master", "cat": "utility"},
	{"name": "Shatter-Frost", "desc": "Cryogenic Detonation on Kill", "type": "shatter_frost", "cat": "unique", "is_unique": true},
	{"name": "Nitroglycerin", "desc": "Burning enemies Pulse Damage", "type": "nitro", "cat": "unique", "is_unique": true},
	{"name": "Support Drone", "desc": "Combat Wingman Support", "type": "drone", "cat": "unique", "is_unique": true},
	{"name": "Glass Cannon", "desc": "Extreme Might, Reduced Hull", "type": "glass_cannon", "cat": "unique", "is_unique": true},
	{"name": "Second Wind", "desc": "Auto-Revival Protocol", "type": "revival", "cat": "unique", "is_unique": true},
	{"name": "Ghost Drive", "desc": "Phasic Immortality during Blink", "type": "ghost_drive", "cat": "unique", "is_unique": true},
]

var active_deck = []
var discard_pile = []
var deck_cycle_count = 0
var card_box: HBoxContainer

func _ready():
	process_mode = PROCESS_MODE_ALWAYS
	visible = false
	active_deck = upgrade_pool.duplicate()
	active_deck.shuffle()
	
	# Initial clean setup
	for child in get_children(): child.queue_free()
	
	# Background Blur ColorRect (System-wide occlusion)
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.4)
	add_child(bg)
	
	var center = CenterContainer.new()
	center.name = "CenterContainer"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	
	var hbox = HBoxContainer.new()
	hbox.name = "CardBox"
	hbox.add_theme_constant_override("separation", 35)
	center.add_child(hbox)
	card_box = hbox

func show_upgrade_menu():
	get_tree().paused = true
	visible = true
	
	if is_instance_valid(card_box):
		for child in card_box.get_children(): child.queue_free()
	
	var choices = _build_choices()
	for i in range(choices.size()):
		var card = _create_sovereign_card(choices[i], i)
		card_box.add_child(card)
		# Entry Animation
		card.modulate.a = 0
		var t = create_tween().set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		t.tween_property(card, "modulate:a", 1.0, 0.4).set_delay(i * 0.1)
		t.parallel().tween_property(card, "position:y", 0.0, 0.5).from(50.0)

func _create_sovereign_card(data, idx) -> Control:
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(300, 450)
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# Apply Holographic Shader
	var mat = ShaderMaterial.new()
	mat.shader = glass_shader
	container.material = mat
	
	# Content Layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_bottom", 25)
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_right", 25)
	container.add_child(margin)
	
	var vbox = VBoxContainer.new()
	margin.add_child(vbox)
	
	var cat_col = _get_cat_color(data["cat"])
	
	# 1. Technical Tags
	var h_tags = HBoxContainer.new()
	vbox.add_child(h_tags)
	var cat_lbl = Label.new()
	cat_lbl.text = "[ " + data["cat"].to_upper() + " ]"
	cat_lbl.add_theme_color_override("font_color", cat_col)
	cat_lbl.add_theme_font_size_override("font_size", 10)
	h_tags.add_child(cat_lbl)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h_tags.add_child(spacer)
	
	var sys_lbl = Label.new()
	sys_lbl.text = "OS_LINK:OK"
	sys_lbl.add_theme_color_override("font_color", cat_col.lerp(Color.WHITE, 0.5))
	sys_lbl.add_theme_font_size_override("font_size", 10)
	h_tags.add_child(sys_lbl)
	
	# 2. Icon Space with Schematic Detail
	var icon_box = Control.new()
	icon_box.custom_minimum_size = Vector2(0, 160)
	vbox.add_child(icon_box)
	_draw_procedural_icon(icon_box, data["cat"], cat_col)
	
	# 3. Title (High-Tech Typography)
	var title = Label.new()
	title.text = data["name"].to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)
	
	vbox.add_spacer(false)
	
	# 4. Description
	var desc = Label.new()
	desc.text = data["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	desc.add_theme_font_size_override("font_size", 14)
	vbox.add_child(desc)
	
	# 5. Interaction & Hover Effects
	var btn = Button.new()
	btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	container.add_child(btn)
	
	btn.pressed.connect(func(): _on_card_selected(data, idx))
	btn.mouse_entered.connect(func():
		var t = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		t.tween_property(container, "scale", Vector2(1.05, 1.05), 0.3)
		container.z_index = 10
	)
	btn.mouse_exited.connect(func():
		var t = create_tween()
		t.tween_property(container, "scale", Vector2(1.0, 1.0), 0.2)
		container.z_index = 0
	)
	
	# 6. Geometric Corner Brackets (FUI Aesthetic)
	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(overlay)
	overlay.draw.connect(func():
		var s = overlay.size
		var b_len = 30.0
		var b_thick = 3.5
		# Corner Brackets
		overlay.draw_line(Vector2(0,0), Vector2(b_len,0), cat_col, b_thick)
		overlay.draw_line(Vector2(0,0), Vector2(0,b_len), cat_col, b_thick)
		
		overlay.draw_line(Vector2(s.x,0), Vector2(s.x-b_len,0), cat_col, b_thick)
		overlay.draw_line(Vector2(s.x,0), Vector2(s.x,b_len), cat_col, b_thick)
		
		overlay.draw_line(Vector2(0,s.y), Vector2(b_len,s.y), cat_col, b_thick)
		overlay.draw_line(Vector2(0,s.y), Vector2(0,s.y-b_len), cat_col, b_thick)
		
		overlay.draw_line(Vector2(s.x,s.y), Vector2(s.x-b_len,s.y), cat_col, b_thick)
		overlay.draw_line(Vector2(s.x,s.y), Vector2(s.x,s.y-b_len), cat_col, b_thick)
		
		# Inner Data Wireframe
		overlay.draw_rect(Rect2(0, 0, s.x, s.y), cat_col * 0.3, false, 1.0)
	)
	
	return container

func _draw_procedural_icon(parent, cat, col):
	parent.draw.connect(func():
		var center = parent.size / 2.0
		# Backing Grid Schematic
		for i in range(-2, 3):
			parent.draw_line(center + Vector2(i*20, -50), center + Vector2(i*20, 50), col * 0.1)
			parent.draw_line(center + Vector2(-50, i*20), center + Vector2(50, i*20), col * 0.1)
			
		match cat:
			"offense":
				# Sovereign Targeting Schematic
				parent.draw_arc(center, 45, 0, PI*2, 64, col, 2.0)
				parent.draw_line(center - Vector2(60, 0), center + Vector2(60, 0), col, 1.0)
				parent.draw_line(center - Vector2(0, 60), center + Vector2(0, 60), col, 1.0)
				parent.draw_circle(center, 4, Color.WHITE)
				# Identification Leaders
				parent.draw_line(center + Vector2(30, -30), center + Vector2(55, -55), col, 1.0)
				parent.draw_string(ThemeDB.fallback_font, center + Vector2(60, -55), "TRGT_LOCK", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)
			"defense":
				# High-Density Plating Hex
				var pts = []
				for i in range(6):
					var ang = i * PI/3.0
					pts.append(center + Vector2(cos(ang), sin(ang)) * 50)
				parent.draw_polyline(pts + [pts[0]], col, 3.0)
				parent.draw_polyline(pts.map(func(p): return center + (p - center) * 0.7), col * 0.5, 1.0)
			"utility":
				# Drive Link Node
				parent.draw_circle(center, 12, col)
				parent.draw_arc(center, 30, 0, PI*2, 32, col * 0.4, 1.0)
				parent.draw_polyline([center + Vector2(-50, -50), center, center + Vector2(50, -50)], col, 2.0)
			"unique":
				# Sovereign Singularity Star
				for i in range(12):
					var ang = i * PI/6.0
					var length = 55 if i % 2 == 0 else 30
					parent.draw_line(center, center + Vector2(cos(ang), sin(ang)) * length, col, 2.0)
				parent.draw_circle(center, 8, Color.WHITE)
	)

func _get_cat_color(cat) -> Color:
	match cat:
		"offense": return COLOR_OFFENSE
		"defense": return COLOR_DEFENSE
		"utility": return COLOR_UTILITY
		"unique": return COLOR_UNIQUE
	return Color.WHITE

func _on_card_selected(data, idx):
	_apply_upgrade(data["type"])
	if data.get("is_unique", false):
		_remove_from_game_pool(data["type"])
	
	visible = false
	get_tree().paused = false
	GameManager.start_next_wave()

func _build_choices() -> Array:
	if active_deck.size() < 3:
		deck_cycle_count += 1
		active_deck.append_array(discard_pile)
		discard_pile.clear()
		active_deck.shuffle()
	
	var selected = []
	for i in range(3):
		if active_deck.size() > 0:
			var card = active_deck.pop_front()
			selected.append(card)
			discard_pile.append(card)
	return selected

func _apply_upgrade(type: String):
	var player = get_tree().get_first_node_in_group("Player")
	if not is_instance_valid(player): return
	
	match type:
		"might_master": player.damage = int(player.damage * 1.25) + 5
		"firerate_master": player.fire_rate *= 0.8
		"hp_master": 
			player.max_hp += 30
			player.hp = player.max_hp
			GameManager.hp_changed.emit(player.hp, player.max_hp)
		"shatter_frost": player.has_shatter_frost = true
		"nitro": player.has_nitro = true
		"drone": player.spawn_drone()
		"glass_cannon":
			player.damage *= 1.5
			player.max_hp *= 0.7
			player.hp = min(player.hp, player.max_hp)
		"revival": player.has_revival = true
		# ... other logic can be safely expanded as needed
	
	# Always sync back to GameManager
	GameManager.player_hp = player.hp
	GameManager.player_max_hp = player.max_hp

func _remove_from_game_pool(type: String):
	var filter_func = func(c): return c["type"] != type
	upgrade_pool = upgrade_pool.filter(filter_func)
	active_deck = active_deck.filter(filter_func)
	discard_pile = discard_pile.filter(filter_func)
