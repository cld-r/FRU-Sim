extends CheckButton


func _ready() -> void:
	button_pressed = Global.p3_t1_bait


func _on_pressed() -> void:
	Global.p3_t1_bait = button_pressed
