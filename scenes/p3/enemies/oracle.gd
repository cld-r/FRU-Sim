extends Node3D


@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]


func play_ur_cast() -> void:
	state_machine.travel("big_cast_start")

func play_flip_special() -> void:
	state_machine.travel("flip_cast")
