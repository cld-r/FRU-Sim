extends MeshInstance3D

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func pulse():
	animation_player.play("pulse")
