extends KinematicBody2D

signal died

const FRICTION_COEFF = -60 # given physics process 60 fps
const FRICTION_GROUND = 0.9
const FRICTION_AIR = 1
const GRAVITY_ACC = 200

const TIME_TO_SHOOT = 0.5

export (Color) var aim_color = Color(0.98, 0.18, 0.18, 1)
export (Color) var shoot_color = Color(1, 1, 1, 1)

export (float) var aim_width = 2
export (float) var shoot_width = 0.5

export (bool) var stationary = true
export (bool) var start_facing_left = true

var STATE_STANDING = {
	"name": "Standing",
	"enter": null,
	"process": funcref(self, "_standing_process"),
	"exit": null,
	"get_next_state": funcref(self, "_standing_get_next_state")
}

var STATE_RUNNING = {
	"name": "Running",
	"speed": 40,
	"enter": null,
	"process": funcref(self, "_running_process"),
	"exit": null,
	"get_next_state": funcref(self, "_running_get_next_state")
}

var STATE_SHOOTING = {
	"name": "Shooting",
	"enter": funcref(self, "_shooting_enter"),
	"process": funcref(self, "_shooting_process"),
	"exit": null,
	"get_next_state": funcref(self, "_shooting_get_next_state")
}

var _state = STATE_RUNNING
var _prev_state = STATE_SHOOTING

var dir = 1
var velocity = Vector2(0, 0)

var _cliff_left_area
var _cliff_right_area
var _hit_area
var _vision_cone
var _pointer
var _gun_sprite

var _anim_tree
var _anim_state

var _shoot_sfx

var _player_in_sight
var _aim_timer
var _last_direction

func _ready():
	#connect("died", HitSFX, "someone_died", [self])
	
	_cliff_left_area = $CliffLeftArea2D
	_cliff_right_area = $CliffRightArea2D
	_hit_area = $HitArea2D
	_vision_cone = $VisionCone
	_pointer = $Pointer
	_gun_sprite = $GunSprite
	
	_anim_tree = $AnimationTree
	_anim_state = _anim_tree["parameters/State/playback"]
	
	_shoot_sfx = $ShootSFX
	
	_last_direction = null
	
	if stationary:
		_state = STATE_STANDING
	
	if start_facing_left:
		dir = -1
		_anim_tree.set("parameters/TurnLeft/active", true)
	else:
		dir = 1
		_anim_tree.set("parameters/TurnRight/active", true)
	_point_gun_forwards()

func _shooting_enter():
	_aim_timer = 0

func _point_gun_forwards():
	var direction = Vector2(dir, 0)
	var space_state = get_world_2d().direct_space_state
	var target = global_position + (direction * 999)
	var result = space_state.intersect_ray(global_position, target, [self])
	if not result.empty():
		target = result.position
	_pointer.set_point_position(1, target - global_position)
	_gun_sprite.look_at(target)

func _standing_process(delta):
	var friction = FRICTION_AIR
	if is_on_floor():
		friction = FRICTION_GROUND
		
	var acceleration = Vector2(0, 0)
	acceleration.y += GRAVITY_ACC
	
	velocity += acceleration * delta
	velocity = move_and_slide_with_snap(velocity, Vector2(0, 1), Vector2(0, -1), false, 4, 0.785398, false)
	
	velocity.x *= friction
	
	_pointer.default_color = aim_color
	_pointer.width = aim_width
	_point_gun_forwards()

func _running_process(delta):
	var friction = FRICTION_AIR
	if is_on_floor():
		friction = FRICTION_GROUND
	
	var acceleration = Vector2(0, 0)
	acceleration.x += STATE_RUNNING.speed * dir * (friction - 1) * FRICTION_COEFF
	acceleration.y += GRAVITY_ACC
	
	velocity += acceleration * delta
	velocity = move_and_slide_with_snap(velocity, Vector2(0, 1), Vector2(0, -1), false, 4, 0.785398, false)
	
	velocity.x *= friction
	
	var switch_dir = false
	for idx in range(get_slide_count()):
		var coll = get_slide_collision(idx)
		if coll.collider.is_in_group("ground") and coll.normal.x != 0:
			switch_dir = true
			break
	if not switch_dir and is_on_floor():
		switch_dir = true
		var cliff_area = _cliff_left_area
		if dir > 0:
			cliff_area = _cliff_right_area
		for body in cliff_area.get_overlapping_bodies():
			if body.is_in_group("ground"):
				switch_dir = false
				break
	if switch_dir:
		dir *= -1
	if dir < 0:
		_anim_tree.set("parameters/TurnLeft/active", true)
	else:
		_anim_tree.set("parameters/TurnRight/active", true)
	
	_pointer.default_color = aim_color
	_pointer.width = aim_width
	_point_gun_forwards()

func _shooting_process(delta):
	var friction = FRICTION_AIR
	if is_on_floor():
		friction = FRICTION_GROUND
		
	var acceleration = Vector2(0, 0)
	acceleration.y += GRAVITY_ACC
	
	velocity += acceleration * delta
	velocity = move_and_slide_with_snap(velocity, Vector2(0, 1), Vector2(0, -1), true, 4, 1.05, false)
	
	velocity.x *= friction
	
	_aim_timer += delta
	var aim_percent = clamp(_aim_timer / TIME_TO_SHOOT, 0, 1)
	
	var player_direction = (_player_in_sight.global_position - global_position).normalized()	
	var direction = Vector2(dir, 0)
	
	_pointer.default_color = aim_color.linear_interpolate(shoot_color, aim_percent)
	_pointer.width = aim_width * (1 - aim_percent) + shoot_width * aim_percent
	
	var space_state = get_world_2d().direct_space_state
	var target = global_position + (player_direction * 999)
	var result = space_state.intersect_ray(global_position, target, [self])
	if (_last_direction == null) or (not result.empty() and result.collider == _player_in_sight):
		direction = direction.linear_interpolate(player_direction, aim_percent)
		target = global_position + (direction * 999)
	else:
		direction = _last_direction
		target = global_position + (direction * 999)
	
	result = space_state.intersect_ray(global_position, target, [self])
	if not result.empty():
		target = result.position
	_last_direction = direction
	
	_pointer.set_point_position(1, target - global_position)
	_gun_sprite.look_at(target)
	
	if _aim_timer >= TIME_TO_SHOOT:
		if not result.empty() and result.collider.has_method("hit"):
			_shoot_sfx.play()
			result.collider.hit(self)
			_last_direction = null

func _is_seeing_player():
	for body in _vision_cone.get_overlapping_bodies():
		if body.is_in_group("player"):
			var space_state = get_world_2d().direct_space_state
			var result = space_state.intersect_ray(global_position, body.global_position, [self])
			if not result.empty() and result.collider == body:
				_player_in_sight = body
				return true
	return false

func _standing_get_next_state():
	if _is_seeing_player():
		return STATE_SHOOTING
	return STATE_STANDING

func _running_get_next_state():
	if _is_seeing_player():
		return STATE_SHOOTING
	return STATE_RUNNING

func _shooting_get_next_state():
	if _aim_timer >= TIME_TO_SHOOT:
		if stationary:
			return STATE_STANDING
		else:
			return STATE_RUNNING
	return STATE_SHOOTING

func _physics_process(delta):
	_state = _state.get_next_state.call_func()
	if _prev_state != _state:
		if _prev_state.exit:
			_prev_state.exit.call_func()
		_prev_state = _state
		if _state.enter:
			_state.enter.call_func()
		_anim_state.start(_state.name)
	
	if _state.process:
		_state.process.call_func(delta)
	
	for body in _hit_area.get_overlapping_bodies():
		if body != self and body.has_method("hit"):
			body.hit(self)

func hit(_hitter):
	HitSFX.someone_died(self)
	get_parent().remove_child(self)

func get_velocity():
	return velocity
