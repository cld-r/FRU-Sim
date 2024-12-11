extends Node3D

class_name P2LargeOrb

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func play_orb_spawn():
	animation_player.play("orb_grow_in")


func play_tele_spawn():
	animation_player.play("tele_grow_in")
	
