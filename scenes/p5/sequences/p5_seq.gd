# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

extends Node

enum Strat {NA, EU, JP}

# Debuff Icon Scenes
const DARK_WATER_ICON = preload("res://scenes/ui/auras/debuff_icons/p3/dark_water_icon.tscn")
const CHAINS_LOCKED_ICON = preload("res://scenes/ui/auras/debuff_icons/p2/chains_locked.tscn")
const CHAINS_ICON = preload("res://scenes/ui/auras/debuff_icons/p2/chains.tscn")
const LIGHTSTEEPED_ICON = preload("res://scenes/ui/auras/debuff_icons/p2/lightsteeped.tscn")

# AoE Dimensions
# Ahk Arai baits
const AHK_RADIUS := 14.0
const AHK_LIFETIME := 0.2
const AHK_COLOR := Color(0.416, 0.733, 0.949, 0.4)
# Light Rampant Chains
const CHAINS_MAX_DIST := 9999
const CHAINS_MIN_DIST := 200
const CHAINS_WIDTH := 0.15
const CHAINS_LOCKED_DURATION := 14
# Path of Light Cones
const PROTEAN_ANGLE := 90
const PROTEAN_LENGTH := 150
const PROTEAN_LIFETIME := 0.5
const PROTEAN_COLOR := Color(0.8, 0.647059, 0, 0.06)
# Spirit Taker Jump
const JUMP_BUFFER := 15.0
const JUMP_DURATION := 0.5
const JUMP_RADIUS := 13.0
const JUMP_LIFETIME := 0.3
const JUMP_COLOR := Color.REBECCA_PURPLE
# Dark Water
const WATER_RADIUS := 16.0
const WATER_LIFETIME := 0.4
const WATER_COLOR := Color.DODGER_BLUE
# Hallowed Wings
const HALLOWED_SOURCE := Vector2(-50, -25)
const HALLOWED_TARGET := Vector2(50, -25)
const HALLOWED_WIDTH := 50
const HALLOWED_LENGTH := 100
const HALLOWED_LIFETIME := 0.3
const HALLOWED_COLOR := Color.SKY_BLUE
# Akh Morn
const AM_RADIUS := 12.0
const AM_LIFETIME := 0.3
const AM_LIGHT_COLOR := Color.GOLD
const AM_DARK_COLOR := Color.DARK_VIOLET
# Misc
const TOWER_LIFETIME := 8.0
const MID_BAIT_THRESHOLD := 4.0

# NA Prios. West to East prio for Path of Light baits
const NAUR_WE_PRIO := ["h1", "h2", "t1", "t2", "r2", "r1", "m1", "m2"]
const NAUR_LINEUP := ["h1", "h2", "t1", "t2", "r1", "r2", "m1", "m2"]
# EU/JP Prios. West to East for Tower positions, South to North for baits.
# If you want to change the dps lineup, do it here.
const EU_JP_WE_PRIO := ["t1", "t2", "h1", "h2", "m1", "m2", "r1", "r2"]
const EU_JP_DPS_LINEUP := ["m1", "m2", "r1", "r2"]  # W>E or S>N

# Entity Positions
const USURPER_POS := {"final": Vector3(0, 0, -6), "final_rota": 135.0}
const ORACLE_POS := {"final": Vector3(0, 0, 6), "final_rota": -135.0}
const TOWER_POS := {"north": Vector2(19, 0), "south": Vector2(-19, 0)}

const DEBUFF_ASSIGNMENTS := {
	"nw_tether": {LIGHTSTEEPED_ICON: 12, CHAINS_ICON: 7},
	"ne_tether": {LIGHTSTEEPED_ICON: 12, CHAINS_ICON: 7},
	"sw_tether": {LIGHTSTEEPED_ICON: 12, CHAINS_ICON: 7},
	"se_tether": {LIGHTSTEEPED_ICON: 12, CHAINS_ICON: 7},
	"nw_bait": {LIGHTSTEEPED_ICON: 12},
	"ne_bait": {LIGHTSTEEPED_ICON: 12},
	"sw_bait": {LIGHTSTEEPED_ICON: 12},
	"se_bait": {LIGHTSTEEPED_ICON: 12},
	"water": {DARK_WATER_ICON: 19}
}

@onready var p5_anim: AnimationPlayer = %P5Anim
@onready var cast_bar: CastBar = %CastBar
@onready var ground_aoe_controller: GroundAoeController = %GroundAoEController
@onready var oracle_boss: Node3D = %OracleBoss
@onready var oracle: Oracle = %Oracle
@onready var fail_list: FailList = %FailList

var party: Dictionary  # Standard role keys (m1, r1, etc.)
var party_dd := {
	"nw_tether": "", "ne_tether": "", "se_tether": "", "sw_tether": "",
	"nw_bait": "", "ne_bait": "", "se_bait": "", "sw_bait": ""
	}
var tether_keys := ["nw_tether", "ne_tether", "se_tether", "sw_tether"]
var ahk_snapshots: Dictionary
var water_keys: Array  # [tether, non-tether]
var spirit_jump_target: String
var spirit_jump_pos: Vector3
var jump_snap_pos: Vector3
var jump_snap_key: String
# List of party keys in order of chaining (0 > 1 > 2 > 3 > 0). 0 should be anchor (healer).
var tether_links := []
var water_lockons := []
var lr_towers := []
var east_wing: bool
var pre_swap_party_dd: Dictionary
var spirit_spread_dd: Dictionary


func start_sequence(new_party: Dictionary) -> void:
	assert(new_party != null, "Error. Where the party at?")
	ground_aoe_controller.preload_aoe(["line", "circle", "cone"])
	# If strat is invalid, fix SavedVariable
	# Setup debuff and random assignments.
	instantiate_party(new_party)
	# Start DD sequence.
	p5_anim.play("p5_seq")


### START OF TIMELINE ###

## 2.1
# Start Oracle Swing animation
func oracle_swing():
	pass

## 4.3
# Start Exaline seq



### END OF TIMELINE ###


func instantiate_party(new_party: Dictionary) -> void:
	# Standard role keys
	party = new_party
	# NAUR Party setup
	if strat == Strat.NA:
		na_party_setup()
	elif strat == Strat.EU or strat == Strat.JP:
		eu_jp_party_setup()
	else:
		assert(false, "Error. Invalid Strat selection in party setup.")
	# Pick Usurper Jump target
	spirit_jump_target = party_dd.keys().pick_random()
	east_wing = randi() % 2 == 0


func na_party_setup() -> void:
	# Shuffle tank, healers and dps (tank/healer/dps[0] + dps[1] will be LR tethers)
	var tanks = Global.TANK_ROLE_KEYS.duplicate()
	var healers = Global.HEALER_ROLE_KEYS.duplicate()
	var dps = Global.DPS_ROLE_KEYS.duplicate()
	tanks.shuffle()
	healers.shuffle()
	dps.shuffle()
	
	# If user is forcing tethers, swap player to tether index.
	if Global.p4_dd_force_tether:
		var player_key: String = get_tree().get_first_node_in_group("player").get_role()
		if Global.TANK_ROLE_KEYS.has(player_key) and tanks[0] != player_key:
			tanks[1] = tanks[0]
			tanks[0] = player_key
		elif Global.HEALER_ROLE_KEYS.has(player_key) and healers[0] != player_key:
			healers[1] = healers[0]
			healers[0] = player_key
		elif Global.DPS_ROLE_KEYS.has(player_key) and (dps[0] != player_key and dps[1] != player_key):
			var player_index = dps.find(player_key)
			var swap_index = randi_range(0, 1)
			dps[player_index] = dps[swap_index]
			dps[swap_index] = player_key
	
	# Build shuffled tether link list (0 linked to 1 and 3, etc.)
	tether_links.append(tanks[0])
	tether_links.append(dps[0])
	tether_links.append(dps[1])
	tether_links.shuffle()
	# Add healer at index 0 (Healer always NW anchor)
	tether_links.push_front(healers[0])
	
	# Handle tether swap to make bowtie shape
	# Use lineup to determine which dps is East/West
	var east_dps
	var west_dps 
	if NAUR_LINEUP.find(dps[0]) < NAUR_LINEUP.find(dps[1]):
		west_dps = dps[0]
		east_dps = dps[1]
	else:
		east_dps = dps[0]
		west_dps = dps[1]
	# Default bowtie shape (no swaps needed)
	var bowtie_tethers := [healers[0], tanks[0], east_dps, west_dps]  # [nw, ne, se, sw]
	# Get the pair of keys linked to the healer
	var linked_to_nw := [tether_links[1], tether_links[3]]
	# If box shape, swap tank with east dps
	if linked_to_nw.has(tanks[0]) and linked_to_nw.has(west_dps):
		bowtie_tethers[1] = east_dps # ne
		bowtie_tethers[2] = tanks[0] # se
	# If hourglass shape, swap tank with west dps
	elif linked_to_nw.has(tanks[0]) and linked_to_nw.has(east_dps):
		bowtie_tethers[1] = west_dps # ne
		bowtie_tethers[3] = tanks[0] # sw
	# If bowtie shape, no swaps needed
	else:
		assert(!linked_to_nw.has(tanks[0]), "Bowtie shape with tank linked to healer should not be possible.")
	
	# Handle water debuffs and potential swap
	var non_tethers := [healers[1], tanks[1], dps[2], dps[3]]  # [nw, ne, se, sw]
	# Swap DPS based on W>E prio
	if NAUR_WE_PRIO.find(dps[2]) < NAUR_WE_PRIO.find(dps[3]):
		non_tethers[2] = dps[3]
		non_tethers[3] = dps[2]
	# Store pre-swap positions, to be used for bot movement.
	var pre_water_swap_non_tethers = non_tethers.duplicate()
	# Pick Waters, swap non-tethers if they are on same N/S side.
	var tether_water = bowtie_tethers.pick_random()
	var non_tether_water = non_tethers.pick_random()
	var west_swapped := false
	var east_swapped := false
	# Check if both waters are North
	if (tether_water == bowtie_tethers[0] or tether_water == bowtie_tethers[1]) and\
		(non_tether_water == non_tethers[0] or non_tether_water == non_tethers[1]):
		# 0 swaps with 3, 1 swaps with 2
		if non_tether_water == non_tethers[0]:
			var temp = non_tethers[0]
			non_tethers[0] = non_tethers[3]
			non_tethers[3] = temp
			west_swapped = true
		elif non_tether_water == non_tethers[1]:
			var temp = non_tethers[1]
			non_tethers[1] = non_tethers[2]
			non_tethers[2] = temp
			east_swapped = true
	# Check if both waters are South
	elif (tether_water == bowtie_tethers[2] or tether_water == bowtie_tethers[3]) and\
		(non_tether_water == non_tethers[2] or non_tether_water == non_tethers[3]):
		# 0 swaps with 3, 1 swaps with 2
		if non_tether_water == non_tethers[3]:
			var temp = non_tethers[0]
			non_tethers[0] = non_tethers[3]
			non_tethers[3] = temp
			west_swapped = true
		elif non_tether_water == non_tethers[2]:
			var temp = non_tethers[1]
			non_tethers[1] = non_tethers[2]
			non_tethers[2] = temp
			east_swapped = true
	assert(!(west_swapped and east_swapped), "Error in E/W swap logic.")
	# Build party_dd Dictionary
	party_dd = {
		"nw_tether": bowtie_tethers[0], "ne_tether": bowtie_tethers[1],
		"se_tether": bowtie_tethers[2], "sw_tether": bowtie_tethers[3],
		"nw_bait": non_tethers[0], "ne_bait": non_tethers[1],
		"se_bait": non_tethers[2], "sw_bait": non_tethers[3]
		}
	# Build pre-swap Dictionary (for positioning before waters swap)
	pre_swap_party_dd = party_dd.duplicate()
	pre_swap_party_dd["nw_bait"] = pre_water_swap_non_tethers[0]
	pre_swap_party_dd["ne_bait"] = pre_water_swap_non_tethers[1]
	pre_swap_party_dd["se_bait"] = pre_water_swap_non_tethers[2]
	pre_swap_party_dd["sw_bait"] = pre_water_swap_non_tethers[3]
	water_keys = [tether_water, non_tether_water]
	# Build Spirit Spread Dictionary (need to distinguish Supp from DPS for spread positions).
	spirit_spread_dd = {
		"nw_tether": party_dd["nw_tether"], "ne_tether": party_dd["ne_tether"],
		"se_tether": party_dd["se_tether"], "sw_tether": party_dd["sw_tether"],
		"w_sup": party_dd["nw_bait"], "w_dps": party_dd["sw_bait"],
		"e_sup": party_dd["ne_bait"], "e_dps": party_dd["se_bait"]
	}
	if west_swapped:
		spirit_spread_dd["w_sup"] = party_dd["sw_bait"]
		spirit_spread_dd["w_dps"] = party_dd["nw_bait"]
	elif east_swapped:
		spirit_spread_dd["e_sup"] = party_dd["se_bait"]
		spirit_spread_dd["e_dps"] = party_dd["ne_bait"]


func eu_jp_party_setup() -> void:
	# Shuffle tank, healers and dps (tank/healer/dps[0] + dps[1] will be LR tethers)
	var tanks = Global.TANK_ROLE_KEYS.duplicate()
	var healers = Global.HEALER_ROLE_KEYS.duplicate()
	var dps = Global.DPS_ROLE_KEYS.duplicate()
	tanks.shuffle()
	healers.shuffle()
	dps.shuffle()
	
	# If user is forcing tethers, swap player to tether index.
	if Global.p4_dd_force_tether:
		var player_key: String = get_tree().get_first_node_in_group("player").get_role()
		if Global.TANK_ROLE_KEYS.has(player_key) and tanks[0] != player_key:
			tanks[1] = tanks[0]
			tanks[0] = player_key
		elif Global.HEALER_ROLE_KEYS.has(player_key) and healers[0] != player_key:
			healers[1] = healers[0]
			healers[0] = player_key
		elif Global.DPS_ROLE_KEYS.has(player_key) and (dps[0] != player_key and dps[1] != player_key):
			var player_index = dps.find(player_key)
			var swap_index = randi_range(0, 1)
			dps[player_index] = dps[swap_index]
			dps[swap_index] = player_key
	
	# Build shuffled tether link list (0 linked to 1 and 3, etc.)
	tether_links.append(tanks[0])
	tether_links.append(dps[0])
	tether_links.append(dps[1])
	tether_links.shuffle()
	# Add healer at index 0 (Healer always North anchor)
	tether_links.push_front(healers[0])
	
	# Handle tether swap to make bowtie shape
	# Get the pair of keys linked to the healer. These will be south_tower
	var south_tethers := [tether_links[1], tether_links[3]]  # [SW, SE]
	var north_tethers := [tether_links[0], tether_links[2]]  # [NW, NE]
	# Order tethers based on W>E prio.
	if EU_JP_WE_PRIO.find(south_tethers[0]) > EU_JP_WE_PRIO.find(south_tethers[1]):
		south_tethers = [tether_links[3], tether_links[1]]
	if EU_JP_WE_PRIO.find(north_tethers[0]) > EU_JP_WE_PRIO.find(north_tethers[1]):
		north_tethers = [tether_links[2], tether_links[0]]
	var west_baits := [healers[1], tanks[1]]  # [NW, SW]
	var east_baits := [dps[2], dps[3]]  # [NE, SE]
	# Order dps baits based on S>N prio
	if EU_JP_WE_PRIO.find(east_baits[1]) > EU_JP_WE_PRIO.find(east_baits[0]):
		east_baits = [dps[3], dps[2]]
	# [NW, NE, SE, SW]
	var tethers := [north_tethers[0], north_tethers[1], south_tethers[1], south_tethers[0]]
	var baits := [west_baits[0], east_baits[0], east_baits[1], west_baits[1]]
	# Pick waters
	var tether_water = tethers.pick_random()
	var non_tether_water = baits.pick_random()
	
	# Store pre-swap positions, to be used for bot positions before waters swap.
	var pre_water_swap_non_tethers = baits.duplicate()
	
	# Check for water swaps
	var west_swapped := false
	var east_swapped := false
	# Check if both waters are North
	if (tether_water == tethers[0] or tether_water == tethers[1]) and\
		(non_tether_water == baits[0] or non_tether_water == baits[1]):
		# 0 swaps with 3, 1 swaps with 2
		if non_tether_water == baits[0]:
			var temp = baits[0]
			baits[0] = baits[3]
			baits[3] = temp
			west_swapped = true
		elif non_tether_water == baits[1]:
			var temp = baits[1]
			baits[1] = baits[2]
			baits[2] = temp
			east_swapped = true
	# Check if both waters are South
	elif (tether_water == tethers[2] or tether_water == tethers[3]) and\
		(non_tether_water == baits[2] or non_tether_water == baits[3]):
		# 0 swaps with 3, 1 swaps with 2
		if non_tether_water == baits[3]:
			var temp = baits[0]
			baits[0] = baits[3]
			baits[3] = temp
			west_swapped = true
		elif non_tether_water == baits[2]:
			var temp = baits[1]
			baits[1] = baits[2]
			baits[2] = temp
			east_swapped = true
	assert(!(west_swapped and east_swapped), "Error in E/W swap logic (multiple swaps).")
	# Build party_dd Dictionary
	party_dd = {
		"nw_tether": tethers[0], "ne_tether": tethers[1],
		"se_tether": tethers[2], "sw_tether": tethers[3],
		"nw_bait": baits[0], "ne_bait": baits[1],
		"se_bait": baits[2], "sw_bait": baits[3]
		}
	# Build pre-swap Dictionary (for positioning before waters swap)
	pre_swap_party_dd = party_dd.duplicate()
	pre_swap_party_dd["nw_bait"] = pre_water_swap_non_tethers[0]
	pre_swap_party_dd["ne_bait"] = pre_water_swap_non_tethers[1]
	pre_swap_party_dd["se_bait"] = pre_water_swap_non_tethers[2]
	pre_swap_party_dd["sw_bait"] = pre_water_swap_non_tethers[3]
	water_keys = [tether_water, non_tether_water]
	
	# Build Spirit Spread Dictionary (need to distinguish Supp from DPS for spread positions).
	# Shouldn't be needed for current EU/JP strats.
	spirit_spread_dd = {
		"nw_tether": party_dd["nw_tether"], "ne_tether": party_dd["ne_tether"],
		"se_tether": party_dd["se_tether"], "sw_tether": party_dd["sw_tether"],
		"w_sup": party_dd["nw_bait"], "w_dps": party_dd["sw_bait"],
		"e_sup": party_dd["ne_bait"], "e_dps": party_dd["se_bait"]
	}
	if west_swapped:
		spirit_spread_dd["w_sup"] = party_dd["sw_bait"]
		spirit_spread_dd["w_dps"] = party_dd["nw_bait"]
	elif east_swapped:
		spirit_spread_dd["e_sup"] = party_dd["se_bait"]
		spirit_spread_dd["e_dps"] = party_dd["ne_bait"]

# Returns the PlayableCharacter for the assigned key.
func get_char(dd_key) -> PlayableCharacter:
	return party[party_dd[dd_key]]


# Moves given party of CharacterBodies to given positions, make sure keys match.
func move_party(pos: Dictionary) -> void:
	for key: String in pos:
		var pc: PlayableCharacter = party[key]
		pc.move_to(pos[key])


# Moves UR Party to gives pos dictionary (must match UR keys)
func move_party_dd(pos: Dictionary) -> void:
	for key: String in pos:
		var pc: PlayableCharacter = get_char(key)
		pc.move_to(pos[key])


# Triggered when a spell hits Roomates. Check if avoidable AoE
func _on_area_3d_area_entered(area: Area3D) -> void:
	if area is CircleAoe or area is DonutAoe:
		if area.spell_name == "" or area.spell_name == "Hallowed Wings":
			return
		fail_list.add_fail("Fragment of Fate was hit by %s." % area.spell_name)


# Returns an Array of the given number of target party keys nearest to the given source position.
func get_nearest_target_list(source_pos: Vector2, number_of_targets) -> Array:
	#var dist_keys_dict: Dictionary
	var dist_list := []
	var keys_list := []
	for key in party:
		dist_list.append(v2(party[key].global_position).distance_squared_to(source_pos))
		keys_list.append(key)
	# Manually sort parallel arrays
	assert(dist_list.size() == keys_list.size())
	var n = dist_list.size()
	for i in range(n):
		for j in range(0, n - i - 1):
			if dist_list[j] > dist_list[j + 1]:
				# Swap distance
				var tmp = dist_list[j]
				dist_list[j] = dist_list[j + 1]
				dist_list[j + 1] = tmp
				# Swap key
				var tmp_key = keys_list[j]
				keys_list[j] = keys_list[j + 1]
				keys_list[j + 1] = tmp_key
	
	keys_list.resize(number_of_targets)
	return keys_list


func v2(vec3: Vector3) -> Vector2:
	return Vector2(vec3.x, vec3.z)


func v3(vec2: Vector2) -> Vector3:
	return Vector3(vec2.x, 0, vec2.y)
