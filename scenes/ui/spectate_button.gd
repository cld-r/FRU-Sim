extends CheckButton


func _ready() -> void:
	button_pressed = Global.spectate_mode


func _on_pressed() -> void:
	Global.spectate_mode = button_pressed
	GameEvents.emit_spectate_mode_changed()
