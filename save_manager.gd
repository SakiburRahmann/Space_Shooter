extends Node

# Persistent save data
var void_credits = 0
var lifetime_kills = 0
var best_wave = 0

# Permanent upgrades (levels) - "Combat Cards"
var card_upgrades = {
	"hull": 0,       # +2 max HP per level
	"engine": 0,     # +0.5% move speed per level
	"weapon": 0,     # +0.2 base damage per level
	"cycling": 0,    # +0.5% fire rate per level
	"magnet": 0,     # +2% pickup radius per level
	"plating": 0,    # +0.2% damage reduction per level
	"second_chance": 0, # +1 revival (max 5)
	"lucky_start": 0,   # +1 starter upgrade (max 5)
}

# New upgrades for Ships (Abilities)
var ship_upgrades = {
	"viper": 0,    # -0.1s blink cooldown
	"fortress": 0, # +0.1s emp stun duration
	"striker": 0   # +0.2s overdrive duration
}

var upgrade_max_val = 50 # Default high cap for long-term progression

# Ship unlocks
var unlocked_ships = ["viper"] # default
var selected_ship = "viper"

var ship_defs = {
	"viper": {"name": "Viper", "hp": 100, "damage": 5, "fire_rate": 0.15, "speed": 400, "color": Color(0, 3.5, 3.5, 1), "desc": "Balanced all-rounder"},
	"fortress": {"name": "Fortress", "hp": 130, "damage": 5, "fire_rate": 0.15, "speed": 360, "color": Color(0, 3.5, 0, 1), "desc": "+30% HP, -10% Speed"},
	"striker": {"name": "Striker", "hp": 80, "damage": 6, "fire_rate": 0.12, "speed": 400, "color": Color(3.5, 0.3, 0.3, 1), "desc": "+20% Fire Rate, -20 HP"},
}

var ship_unlock_conditions = {
	"fortress": {"type": "best_wave", "value": 10, "desc": "Survive 10 waves"},
	"striker": {"type": "lifetime_kills", "value": 500, "desc": "Kill 500 enemies total"},
}

const SAVE_PATH = "user://save.dat"

func _ready():
	load_data()

func calculate_void_credits(gems: int) -> int:
	return gems * 1 # Re-scaled to 1:1 reward as requested

func earn_end_of_run(kills: int, waves: int, time: float, gems: int):
	var earned = calculate_void_credits(gems)
	void_credits += earned
	lifetime_kills += kills
	if waves > best_wave:
		best_wave = waves
	# Check ship unlocks
	_check_unlocks()
	save_data()
	return earned

func _check_unlocks():
	for ship_id in ship_unlock_conditions.keys():
		if ship_id in unlocked_ships: continue
		var cond = ship_unlock_conditions[ship_id]
		match cond["type"]:
			"best_wave":
				if best_wave >= cond["value"]:
					unlocked_ships.append(ship_id)
			"lifetime_kills":
				if lifetime_kills >= cond["value"]:
					unlocked_ships.append(ship_id)

func buy_upgrade(type: String, id: String) -> bool:
	var upgrades_dict = _get_dict_by_type(type)
	if upgrades_dict == null or id not in upgrades_dict: return false
	
	var current_lvl = upgrades_dict[id]
	var cost = get_upgrade_cost(type, id)
	
	if void_credits < cost: return false
	
	void_credits -= cost
	upgrades_dict[id] += 1
	save_data()
	return true

func get_upgrade_cost(type: String, id: String) -> int:
	var upgrades_dict = _get_dict_by_type(type)
	var lvl = upgrades_dict.get(id, 0)
	var base_cost = 50
	
	# Special base costs
	if id == "second_chance": base_cost = 500
	if id == "lucky_start": base_cost = 200
	if type == "ship": base_cost = 150
	
	# Geometric scaling for long-term grind
	return int(base_cost * pow(1.22, lvl))

func _get_dict_by_type(type: String):
	match type:
		"card": return card_upgrades
		"ship": return ship_upgrades
	return null

func get_starting_stats() -> Dictionary:
	var ship = ship_defs[selected_ship]
	return {
		"hp": ship["hp"],
		"damage": ship["damage"],
		"fire_rate": ship["fire_rate"],
		"speed": ship["speed"],
		"magnet_radius": 125.0,
		"damage_reduction": 0.0,
		"has_revival": false,
		"revival_count": 0,
		"lucky_starts": 0,
		"color": ship["color"],
		"ability_lvl": ship_upgrades.get(selected_ship, 0)
	}

func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var save_dict = {
			"void_credits": void_credits,
			"lifetime_kills": lifetime_kills,
			"best_wave": best_wave,
			"card_upgrades": card_upgrades,
			"ship_upgrades": ship_upgrades,
			"unlocked_ships": unlocked_ships,
			"selected_ship": selected_ship,
		}
		file.store_string(JSON.stringify(save_dict))
		file.close()

func load_data():
	if not FileAccess.file_exists(SAVE_PATH): return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		var json = JSON.new()
		if json.parse(text) == OK:
			var d = json.data
			if "void_credits" in d:
				void_credits = d["void_credits"]
			elif "data_cores" in d: # Migration
				void_credits = d["data_cores"]
			
			lifetime_kills = d.get("lifetime_kills", 0)
			best_wave = d.get("best_wave", 0)
			if "card_upgrades" in d:
				card_upgrades = d["card_upgrades"]
			elif "upgrades" in d: # Migration
				for k in d["upgrades"]:
					if k in card_upgrades:
						card_upgrades[k] = d["upgrades"][k]
			
			if "ship_upgrades" in d:
				ship_upgrades = d["ship_upgrades"]
				
			if "unlocked_ships" in d:
				unlocked_ships = d["unlocked_ships"]
			if "selected_ship" in d:
				selected_ship = d["selected_ship"]
