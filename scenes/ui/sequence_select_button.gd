# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

extends OptionButton

@onready var main_sequence: Sequence = $"../.."


func _ready() -> void:
	selected = SavedVariables.get_data("settings", "selected_seq")


func _on_item_selected(index : int) -> void:
	var current_scene = SavedVariables.get_data("settings", "selected_seq")
	GameEvents.emit_variable_saved("settings", "selected_seq", index)
	if index != current_scene:
		main_sequence.save_variables()
		get_tree().change_scene_to_file("res://scenes/menus/main.tscn")
