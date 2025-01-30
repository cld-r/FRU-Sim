# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

extends Node
class_name LRChainsController

const CHAIN_WIDTH := 0.15

var chain_path := "res://scenes/common/player_characters/lockon/lr_chain.tscn"
var chain_scene : PackedScene
var active_chains : Array


func preload_resources() -> void:
	ResourceLoader.load_threaded_request(chain_path, "PackedScene")


# Can connect to LRChain chain_stretched signal for fail condition
func spawn_chain(source: Node3D, target: Node3D, max_length: float = 9999,
	min_length: float = 0.0, size: float = CHAIN_WIDTH) -> LRChain:
	if !chain_scene:
		chain_scene = ResourceLoader.load_threaded_get(chain_path)
	var new_chain: LRChain = chain_scene.instantiate()
	new_chain.set_variables(source, target, max_length, min_length, size)
	new_chain.visible = true
	new_chain.active = true
	source.add_child(new_chain)
	active_chains.append(new_chain)
	return new_chain


# NOTE: This will remove all chains connected to source.
# TODO: update to handle multiple chains on one target.
func remove_chain(source: Node3D) -> void:
	for chain: LRChain in active_chains:
		if chain.source == source:
			chain.queue_free()


func remove_all_chains() -> void:
	for i in active_chains.size():
		var chain: LRChain = active_chains.pop_back()
		chain.queue_free()


func activate_chains() -> void:
	for chain: LRChain in active_chains:
		chain.set_active(true)
