extends Node

var seq_scene_paths := {
	0: "res://scenes/p2/p2_main.tscn",
	1: "res://scenes/p3/p3_main.tscn",
	2: "res://scenes/p4/p4_main.tscn"
}


func _ready() -> void:
	var selected_seq: int = SavedVariables.get_data("settings", "selected_seq")
	var loaded_scene = load(seq_scene_paths[selected_seq])
	await get_tree().process_frame
	get_tree().change_scene_to_packed(loaded_scene)
