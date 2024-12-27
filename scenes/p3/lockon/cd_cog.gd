extends Node3D

class_name CDCog

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func start_countdown():
	animation_player.play("countdown")


func free_self():
	self.queue_free()
