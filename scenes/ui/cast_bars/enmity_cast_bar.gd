# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

## The clone cast bar should be used used to mimic the enmity cast bar in game.
## Currently it copies the same cast 3 times. It needs to be updated to handle multiple casts.


extends CanvasLayer
class_name EnmityCastBar


const ENMITY_CB = preload("res://scenes/ui/cast_bars/enmity_cb_singleton.tscn")

@onready var cast_bar_container: VBoxContainer = %CastBarContainer


func cast(cast_name : String, cast_time : float, bars: int = 1) -> void:
	for i in bars:
		var new_cast_bar = ENMITY_CB.instantiate()
		cast_bar_container.add_child(new_cast_bar)
		new_cast_bar.cast(cast_name, cast_time)
