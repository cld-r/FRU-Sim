extends Node3D

class_name Usurper


@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]


func play_hands_in_cast() -> void:
	state_machine.travel("hands_in_cast_loop")


func play_hands_in_finish() -> void:
	state_machine.travel("hands_in_cast_finish")


func play_wings_out_cast() -> void:
	state_machine.travel("wings_out_cast")


func play_wings_out_finish() -> void:
	state_machine.travel("idle")


func play_fade_in() -> void:
	state_machine.travel("fade_in_idle")


func play_fade_out() -> void:
	state_machine.travel("fade_out_idle")
