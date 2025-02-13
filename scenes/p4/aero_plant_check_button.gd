# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

extends CheckButton


func _ready() -> void:
	button_pressed = SavedVariables.save_data["settings"]["p4_ct_aero_plant"]


func _on_pressed() -> void:
	GameEvents.emit_variable_saved("settings", "p4_ct_aero_plant", button_pressed)
