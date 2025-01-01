extends CanvasLayer


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_on_pause_keybind_pressed()


func _on_pause_keybind_pressed() -> void:
	self.visible = !self.visible
	get_tree().paused = !get_tree().paused
