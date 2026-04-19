extends CanvasLayer

@onready var wave_label = $TopBar/WavePanel/WaveLabel
@onready var hp_bar = $TopBar/HPPanel/HPBar
@onready var hp_label = $TopBar/HPPanel/HPLabel
@onready var objective_label = $ObjectivePanel/ObjectiveLabel
@onready var ability_label = $AbilityAnchor/AbilityPanel/VBox/AbilityLabel
@onready var ability_bar = $AbilityAnchor/AbilityPanel/VBox/AbilityBar

var player_ref: Node2D = null

func _ready():
	GameManager.hp_changed.connect(_on_hp_changed)
	GameManager.wave_changed.connect(_on_wave_changed)
	GameManager.objective_updated.connect(_on_objective_updated)
	
	wave_label.text = "WAVE " + str(GameManager.current_wave)
	hp_bar.max_value = GameManager.player_max_hp
	hp_bar.value = GameManager.player_hp
	hp_label.text = str(GameManager.player_hp) + " / " + str(GameManager.player_max_hp)
	
	_find_player()

func _process(_delta):
	if not is_instance_valid(player_ref):
		_find_player()

func _find_player():
	var p = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(p) and p != player_ref:
		player_ref = p
		if not player_ref.ability_cooldown_updated.is_connected(_on_ability_cooldown):
			player_ref.ability_cooldown_updated.connect(_on_ability_cooldown)
		if not player_ref.ability_used.is_connected(_on_ability_used):
			player_ref.ability_used.connect(_on_ability_used)
		_update_ability_ui(player_ref.ability_type, 0, player_ref.ability_max_cooldown)

func _on_ability_cooldown(current, max_val):
	_update_ability_ui(player_ref.ability_type, current, max_val)

func _on_ability_used():
	_update_ability_ui(player_ref.ability_type, player_ref.ability_max_cooldown, player_ref.ability_max_cooldown)

func _update_ability_ui(type, current, max_val):
	var percent = 1.0 - (current / max_val)
	ability_bar.value = percent * 100.0
	
	if current <= 0:
		ability_label.text = type.to_upper() + " [READY]"
		ability_label.modulate = Color(0, 1, 1, 1)
	else:
		ability_label.text = type.to_upper() + " [" + str(snapped(current, 0.1)) + "s]"
		ability_label.modulate = Color(0.6, 0.6, 0.6, 1)

func _on_hp_changed(new_hp, max_hp):
	hp_bar.max_value = max_hp
	hp_bar.value = new_hp
	hp_label.text = str(new_hp) + " / " + str(max_hp)

func _on_wave_changed(new_wave):
	wave_label.text = "WAVE " + str(new_wave)

func _on_objective_updated(prog, tgt):
	var txt = "[center]"
	for color in tgt.keys():
		if tgt[color] > 0:
			var color_hex = ""
			match color:
				"RED": color_hex = "ff3355"
				"BLUE": color_hex = "33aaff"
				"GREEN": color_hex = "33ff77"
			var done = prog[color] >= tgt[color]
			if done:
				txt += "[color=#888888][s]" + color + ": " + str(prog[color]) + "/" + str(tgt[color]) + "[/s][/color]  "
			else:
				txt += "[color=#" + color_hex + "]" + color + ": " + str(prog[color]) + "/" + str(tgt[color]) + "[/color]  "
	txt += "[/center]"
	objective_label.text = txt
