extends Node3D

class_name Oracle

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var state_machine: AnimationNodeStateMachinePlayback = animation_tree["parameters/playback"]


func play_ur_cast() -> void:
	state_machine.travel("big_cast_start")


func play_flip_special() -> void:
	state_machine.travel("flip_cast")


func play_ct_cast() -> void:
	state_machine.travel("short_cast")


# TODO: animate
func play_hide() -> void:
	self.visible = false


func play_show() -> void:
	self.visible = true
