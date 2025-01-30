# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

extends CheckButton


func _ready() -> void:
	self.button_pressed = Global.p2_force_puddles


func _on_pressed() -> void:
	Global.p2_force_puddles = button_pressed
