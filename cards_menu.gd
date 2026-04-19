extends Control

var biome_timer = 0.0
var biome_interval = 4.0

var all_cards = {
	"might_2": {"name": "Spinach Extract", "desc": "+2% base weapon\ndamage"},
	"might_3": {"name": "Power Shard", "desc": "+3% base weapon\ndamage"},
	"armor_1": {"name": "Plated Hull", "desc": "Reduce all incoming\ndamage by 1%"},
	"armor_2": {"name": "Reactive Coating", "desc": "Reduce all incoming\ndamage by 2%"},
	"movespeed_2": {"name": "Lightweight Frame", "desc": "+2% movement\nspeed"},
	"movespeed_3": {"name": "Jet Thrusters", "desc": "+3% movement\nspeed"},
	"firerate_2": {"name": "Quick Loader", "desc": "+2% fire rate"},
	"firerate_3": {"name": "Auto-Feeder", "desc": "+3% fire rate"},
	"bulletspeed_3": {"name": "Velocity Chamber", "desc": "+3% bullet travel\nspeed"},
	"bulletspeed_4": {"name": "Railgun Coil", "desc": "+4% bullet travel\nspeed"},
	"hp_5": {"name": "Hollow Heart", "desc": "+5 max HP\nHeal to full"},
	"hp_8": {"name": "Vitality Core", "desc": "+8 max HP\nHeal to full"},
	"hp_12": {"name": "Life Matrix", "desc": "+12 max HP\nHeal to full"},
	"regen_03": {"name": "Nano-Meds", "desc": "Regenerate 0.3 HP\nper second"},
	"regen_06": {"name": "Pummarola", "desc": "Regenerate 0.6 HP\nper second"},
	"magnet_4": {"name": "Attractorb", "desc": "+4% gem pickup\nradius"},
	"magnet_5": {"name": "Tractor Core", "desc": "+5% gem pickup\nradius"},
	"dodge_1": {"name": "Phase Module", "desc": "+1% chance to\ndodge attacks"},
	"dodge_2": {"name": "Blink Drive", "desc": "+2% chance to\ndodge attacks"},
	"knockback_3": {"name": "Impact Driver", "desc": "Push enemies back\n+3% on hit"},
	"double_shot": {"name": "Duplicator", "desc": "Fire 1 extra\nprojectile forward"},
	"rear_gun": {"name": "Backfire Engine", "desc": "Auto-fire a weaker\ngun behind you"},
	"piercing": {"name": "Piercing Rounds", "desc": "Bullets pass through\nenemies"},
	"homing": {"name": "Seeking Core", "desc": "Bullets gently curve\ntoward enemies"},
	"explosive": {"name": "Blast Shells", "desc": "Bullets deal small\nAOE on impact"},
	"chain_lightning": {"name": "Arc Discharge", "desc": "Hits chain to one\nnearby enemy"},
	"crit_3": {"name": "Weak Spot Scanner", "desc": "+3% chance for\ncritical hit"},
	"crit_4": {"name": "Targeting Matrix", "desc": "+4% chance for\ncritical hit"},
	"crit_mult": {"name": "Lethal Precision", "desc": "Crits deal +5%\nmore damage"},
	"thorns": {"name": "Reactive Spines", "desc": "Deal 3 damage to\nenemies touching you"},
	"lifesteal_1": {"name": "Vampiric Rounds", "desc": "Heal 1 HP for\nevery enemy killed"},
	"lifesteal_2": {"name": "Soul Siphon", "desc": "Heal 2 HP for\nevery enemy killed"},
	"freeze_3": {"name": "Cryo Emitter", "desc": "Slow nearby enemies\nby 3%"},
	"freeze_4": {"name": "Ice Nova", "desc": "Slow nearby enemies\nby 4%"},
	"burn": {"name": "Incendiary Tips", "desc": "Enemies burn for\n2 dmg/sec on hit"},
	"combo_dmg_fire": {"name": "Tactical Module", "desc": "+1% damage and\n+1% fire rate"},
	"combo_spd_fire": {"name": "Combat Stims", "desc": "+1% speed and\n+1% fire rate"},
	"combo_hp_armor": {"name": "Hardened Plating", "desc": "+3 max HP and\n+1% armor"},
	"combo_mag_hp": {"name": "Scavenger Kit", "desc": "+3% magnet and\n+3 max HP"},
	"combo_regen_dodge": {"name": "Survival Kit", "desc": "+0.3 HP regen and\n+1% dodge"},
	"shotgun": {"name": "Shotgun Module", "desc": "Fire 5 projectiles\nin a wide arc"},
	"orbital": {"name": "Orbiting Guard", "desc": "2 rotating orbs\ndamage nearby foes"},
	"orbital_add": {"name": "Orbital Expansion", "desc": "+2 more orbital\nshield orbs"},
	"revival": {"name": "Second Wind", "desc": "Revive once with\n30% HP on death"},
	"curse": {"name": "Curse Engine", "desc": "+4% damage but\nenemies get +3% HP"},
	"glass_cannon": {"name": "Glass Cannon", "desc": "+5% damage but\ntake +3% more dmg"},
	"berserker": {"name": "Berserker Chip", "desc": "+4% fire rate\nbut -3 max HP"},
	"fortify": {"name": "Fortress Core", "desc": "+15 max HP but\n-2% move speed"},
	"adrenaline": {"name": "Adrenaline Surge", "desc": "+3% speed and\n+3% fire rate"},
	"explosion_radius": {"name": "Blast Radius+", "desc": "+4% explosion\nradius"},
	"ricochet": {"name": "Ricochet Core", "desc": "Bullets bounce to\n1 nearby enemy"},
	"reaper": {"name": "Reaper Rounds", "desc": "Enemies explode on\ndeath for 3 AOE dmg"},
	"extra_drops": {"name": "Crown", "desc": "Enemies drop +1\nextra gem on kill"},
	"shield": {"name": "Energy Barrier", "desc": "Block first hit\nevery 10 seconds"}
}

var current_selected_id = "might_2"

@onready var list = $HBox/Scroll/List
@onready var detail_name = $HBox/Details/Name
@onready var detail_desc = $HBox/Details/Desc
@onready var detail_stats = $HBox/Details/Stats
@onready var preview_icon = $HBox/Details/Preview/IconLabel
@onready var upgrade_btn = $HBox/Details/UpgradeBtn
@onready var credits_label = $CreditsLabel

func _ready():
	# Fix migration empty dicts for cards
	for card_id in all_cards:
		if not SaveManager.card_upgrades.has(card_id):
			SaveManager.card_upgrades[card_id] = 0
			
	_populate_list()
	if all_cards.keys().size() > 0:
		_show_details(all_cards.keys()[0])
	_cycle_bg()

func _process(delta):
	biome_timer += delta
	if biome_timer >= biome_interval:
		biome_timer = 0.0
		_cycle_bg()
		
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

func _cycle_bg():
	GameManager._generate_procedural_biome()
	var bg = $BG
	if bg and bg.material:
		GameManager.apply_biome_to_shader(bg)

func _update_credits():
	credits_label.text = "VOID CREDITS: " + str(int(SaveManager.void_credits))

func _populate_list():
	for child in list.get_children():
		child.queue_free()
	for card_id in all_cards:
		var btn = Button.new()
		var real_lvl = int(SaveManager.card_upgrades.get(card_id, 0))
		btn.text = all_cards[card_id]["name"] + " (Lv. " + str(real_lvl + 1) + ")"
		btn.pressed.connect(_show_details.bind(card_id))
		btn.custom_minimum_size = Vector2(0, 60)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		list.add_child(btn)

func _show_details(id: String):
	current_selected_id = id
	_update_credits()
	
	var data = all_cards.get(id, {"name": "Unknown", "desc": "Error loading card"})
	var real_lvl = int(SaveManager.card_upgrades.get(id, 0))
	var cost = SaveManager.get_upgrade_cost("card", id)
	
	detail_name.text = data.get("name", "Unknown").to_upper()
	detail_desc.text = data.get("desc", "") + "\n\n(Purchasing upgrades for this card permanently boosts its effectiveness by 10% in combat when acquired!)"
	detail_stats.text = "Current Level: " + str(real_lvl + 1)
	preview_icon.text = "🃏"
	
	upgrade_btn.text = "UPGRADE | %d VC" % cost
	upgrade_btn.disabled = SaveManager.void_credits < cost

func _on_upgrade_pressed():
	if SaveManager.buy_upgrade("card", current_selected_id):
		_populate_list()
		_show_details(current_selected_id)

func _on_back_pressed():
	get_tree().change_scene_to_file("res://title_screen.tscn")
