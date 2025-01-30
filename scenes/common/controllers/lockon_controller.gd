# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

## Lockon Controller
## Handles the loading and instantiation of lockon nodes.
## When adding a new lockon node:
##  - Add node to enums.
##  - Add res path and meta id#.
##  - Add meta id# to root node in new lockon scene.

# TODO: Add hide/show functionality here if we need in the future.

extends Node
class_name LockonController

enum {PS_CROSS, PS_CIRCLE, PS_SQUARE, PS_TRIANGLE,
	DEFAM, DIVEBOMB, DOOM, LC_1, LC_2, LC_3, LR_ORB,
	SPREAD_MARKER, GAZE, STACK_MARKER, CD_COG, SPREAD_MARKER_APOC}

var res_paths := {
	PS_CROSS: "",
	PS_CIRCLE: "",
	PS_SQUARE: "",
	PS_TRIANGLE: "",
	DEFAM: "",
	DIVEBOMB: "",
	DOOM: "",
	LC_1: "",
	LC_2: "",
	LC_3: "",
	LR_ORB: "res://scenes/p2/lockon/lr_light_orb.tscn",
	SPREAD_MARKER: "res://scenes/p2/lockon/spread_marker.tscn",
	GAZE: "res://scenes/common/player_characters/lockon/gaze.tscn",
	STACK_MARKER: "res://scenes/common/player_characters/lockon/stack_marker.tscn",
	CD_COG: "res://scenes/p3/lockon/cd_cog.tscn",
	SPREAD_MARKER_APOC: "res://scenes/p3/lockon/spread_marker_apoc.tscn"
}
var meta_ids := {
	PS_CROSS: 0, PS_CIRCLE: 1, PS_SQUARE: 2, PS_TRIANGLE: 3,
	DEFAM: 4, DIVEBOMB: 5, DOOM: 6, LC_1: 7, LC_2: 8, LC_3: 9, 
	LR_ORB: 10, SPREAD_MARKER: 11, GAZE: 12, STACK_MARKER: 13, CD_COG: 14,
	SPREAD_MARKER_APOC: 15
}

var lockon_node_path := "Lockon"
var loaded_scenes: Dictionary


func pre_load(lockon_id_list: Array) -> void:
	for lockon_id: int in lockon_id_list:
		ResourceLoader.load_threaded_request(res_paths[lockon_id])


# If null instance, make sure you pre_loaded the lockon.
func add_marker(lockon_id: int, target: Node3D) -> Node3D:
	assert(target.get_node(lockon_node_path), "Error. Missing lockon node (invalid path?).")
	if !loaded_scenes.has(lockon_id):
		loaded_scenes[lockon_id] = ResourceLoader.load_threaded_get(res_paths[lockon_id])
	var new_marker: Node3D = loaded_scenes[lockon_id].instantiate()
	target.get_node(lockon_node_path).add_child(new_marker)
	return new_marker


# Returns true if successful.
func remove_marker(lockon_id: int, target: Node3D) -> bool:
	assert(target.get_node(lockon_node_path), "Error. Missing lockon node (invalid path?).")
	var lockon_nodes := target.get_node(lockon_node_path).get_children()
	for node in lockon_nodes:
		assert(node.has_meta("id"), "Error. Missing lockon node meta data (id).")
		if node.get_meta("id") == meta_ids[lockon_id]:
			node.queue_free()
			return true
	return false
