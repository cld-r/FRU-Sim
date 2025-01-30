# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

extends CheckButton


func _ready() -> void:
	button_pressed = Global.p3_t1_bait


func _on_pressed() -> void:
	Global.p3_t1_bait = button_pressed
