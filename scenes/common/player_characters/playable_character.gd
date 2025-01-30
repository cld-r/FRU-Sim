# Copyright 2025
# All rights reserved.
# This file is released under "GNU General Public License 3.0".
# Please see the LICENSE file that should have been included as part of this package.

extends CharacterBody3D
class_name PlayableCharacter


@export var move_speed : = 14.3
@export var acceleration : = 20.0
@export var gravity : = 25.0
@export var model_scale := 1.25
@export var model_scene : PackedScene

@onready var party_list : PartyList = get_tree().get_first_node_in_group("party_list")

var model: Node3D
var anim_tree: AnimationTree
var rotation_anim: AnimationPlayer
var anim_state: AnimationNodeStateMachinePlayback
var last_frame_floor := true
var sliding := false
var kb_resist := false
var role_key : String

var facing_angle: float
var rotation_speed := 0.7
var target: Vector3
var at_target := true
var look_direction := Vector3.ZERO
var xiv_model : bool

var is_player_character: bool
var spectate_mode: bool


# Party list handles addition/removal of player debuffs.
# Returns debuff timeout signal.
func add_debuff(debuff_icon_scene : PackedScene, duration := 0.0, stackable := false, debuff_name := "") -> Signal:
	return party_list.add_debuff(role_key, debuff_icon_scene, duration, stackable, debuff_name)


# Party list handles addition/removal of player debuffs.
func remove_debuff(debuff_name: String) -> void:
	party_list.remove_debuff(role_key, debuff_name)


func get_debuff_stacks(debuff_name: String) -> int:
	return party_list.get_debuff_stacks(role_key, debuff_name)


func has_debuff(debuff_name: String) -> bool:
	return party_list.has_debuff(role_key, debuff_name)


func get_model_rotation() -> Vector3:
	return self.model.rotation


func get_role() -> String:
	return self.role_key


# This is for bot movement.
# Player movement reset is handled in PlayerMovementController
func reset_movement() -> void:
	anim_tree.set("parameters/conditions/idle", true)


func knockback(distance : float, source : Vector2, time: float = 0.5) -> void:
	if kb_resist:
		return
	reset_movement()
	sliding = true
	var target_v2 : Vector2 = source.direction_to(v2(global_position))
	target_v2 = (target_v2 * distance) + v2(global_position)
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position",
		Vector3(target_v2.x, 0, target_v2.y), time)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished
	sliding = false
	


func slide(slide_target: Vector2, time: float = 0.3) -> void:
	reset_movement()
	sliding = true
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position",
		Vector3(slide_target.x, 0, slide_target.y), time)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	sliding = false


# Slide with easing that more resembles a knockback
func kb_slide(slide_target: Vector2, time: float = 0.3) -> void:
	if kb_resist:
		return
	reset_movement()
	sliding = true
	var tween : Tween = get_tree().create_tween()
	tween.tween_property(self, "global_position",
		Vector3(slide_target.x, 0, slide_target.y), time)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await tween.finished
	sliding = false


func set_active_target() -> void:
	pass


func remove_active_target() -> void:
	pass


# Converts Vector3(x,z) -> Vectors2
func v2(v3: Vector3) -> Vector2:
	return Vector2(v3.x, v3.z)


## Bot Movement Functions

func _ready() -> void:
	spectate_mode = Global.spectate_mode
	GameEvents.spectate_mode_changed.connect(on_spectate_mode_changed)
	model = model_scene.instantiate()
	add_child(model)
	xiv_model = model.get_meta("xiv_model", false)
	set_model_meta(model.get_meta("xiv_model", false))
	model.scale = Vector3.ONE * model_scale
	anim_tree = model.get_node("AnimationTree")
	anim_state = model.get_node("AnimationTree").get("parameters/playback")
	look_at_direction(look_direction)


func _physics_process(delta: float) -> void:
	if is_player_character and !spectate_mode:
		return
	
	if not is_on_floor():
		velocity.y -= gravity * delta
		move_and_slide()
	elif !at_target and !sliding:
		# Move bot
		_move_to_target()
		# Check if arrived
		if global_position.distance_squared_to(target) < 0.1:
			look_at_direction(look_direction)
			if xiv_model:
				anim_tree.set("parameters/conditions/idle", true)
				anim_tree.set("parameters/conditions/running", false)
			else:
				anim_tree.set("parameters/IWR/blend_position", Vector2.ZERO)
			at_target = true


func _move_to_target() -> void:
	var dir := global_position.direction_to(target)
	velocity.x = dir.x * move_speed
	velocity.z = dir.z * move_speed
	if velocity != Vector3.ZERO:
		var tmp = model.scale
		model.basis = model.basis.orthonormalized().slerp(Basis.looking_at(velocity), 0.05)
		model.scale = tmp
		#model.basis = Basis.looking_at(velocity)
	var vl := velocity * transform.basis
	if xiv_model:
		anim_tree.set("parameters/conditions/running", true)
		anim_tree.set("parameters/conditions/idle", false)
	else:
		anim_tree.set("parameters/IWR/blend_position", Vector2(vl.x, -vl.z) / move_speed)
	move_and_slide()


func _check_if_falling() -> void:
	if is_on_floor():
		if !last_frame_floor:
			anim_tree.set("parameters/conditions/jumping", false) # TEST: needed?
			anim_tree.set("parameters/conditions/grounded", true)
			last_frame_floor = true
	# Not on floor and not jumping (e.g. walk off ledge, knock up)
	else:
		anim_state.travel("Jump_Idle")
		anim_tree.set("parameters/conditions/grounded", false)
		last_frame_floor = false


func move_to(other_target : Vector2) -> void:
	at_target = false
	target = Vector3(other_target.x, 0, other_target.y)


# Spectate changes may have broken this for DSR.
func get_arrow_vector(length: float, arrow: String) -> Vector3:
	# Player
	if is_player_character and !spectate_mode:
		var arrow_vector := Vector3.ZERO
		arrow_vector.z = -1 if arrow == "up" else 1
		return global_position + ((model.transform.basis * arrow_vector).normalized() * length)
	# Bot
	else:
		var model_basis := transform.basis
		var arrow_vector := Vector3.ZERO
		arrow_vector.z = -1 if arrow == "up" else 1
		arrow_vector = global_position + ((model_basis * arrow_vector).normalized() * length)
		return arrow_vector


func look_at_direction(direction: Vector3) -> void:
	if is_player_character and !spectate_mode:
		return
	var look_target := (global_position.direction_to(direction) * 100) + global_position
	look_target.y = 0
	model.look_at(look_target)


func set_look_direction(new_look_direction : Vector3) -> void:
	if is_player_character and !spectate_mode:
		return
	
	look_direction = new_look_direction


# Used for setting player_movement_controller, see Player.gd.
func set_model_meta(_meta_data):
	return


func is_player() -> bool:
	return is_player_character


func on_spectate_mode_changed() -> void:
	spectate_mode = Global.spectate_mode


#func get_name() -> StringName:
	#return Global.ROLE_NAMES[role_key]
