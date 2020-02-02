extends KinematicBody2D

signal died

const Reverser = preload("res://scenes/RepairGun.tscn")

const FRICTION_COEFF = -60 # given physics process 60 fps
const FRICTION_GROUND = 0.9
const FRICTION_AIR = 0.983
const GRAVITY_ACC = 200
const TOP_SPEED_X = 100
const ROAD_RUNNER_TIME = 0.25
const PRE_JUMP_TIME = 0.25
const HIT_JUMP_HEIGHT = 20
const HIT_JUMP_X_SPEED = 50
const MAX_INVULNERABLE_TIME = 2

var MOVE_STATE_STANDING = {
	"name": "Standing",
	"gravity_acc": GRAVITY_ACC,
	"friction_multiplier": 0.7,
	"enter": null,
	"process": null,
	"exit": null,
	"get_next_state": funcref(self, "_common_get_next_state")
}

var MOVE_STATE_RUNNING = {
	"name": "Running",
	"gravity_acc": GRAVITY_ACC,
	"friction_multiplier": 1,
	"enter": null,
	"process": null,
	"exit": null,
	"get_next_state": funcref(self, "_common_get_next_state")
}

var MOVE_STATE_JUMPING = {
	"name": "Jumping",
	"jump_height": 50,
	"gravity_acc": 50,
	"friction_multiplier": 1,
	"enter": funcref(self, "_jumping_enter"),
	"process": null,
	"exit": null,
	"get_next_state": funcref(self, "_jumping_get_next_state")
}

var MOVE_STATE_FALLING = {
	"name": "Falling",
	"gravity_acc": GRAVITY_ACC,
	"friction_multiplier": 1,
	"enter": funcref(self, "_falling_enter"),
	"process": funcref(self, "_falling_process"),
	"exit": null,
	"get_next_state": funcref(self, "_falling_get_next_state")
}

var _move_state = MOVE_STATE_STANDING
var _prev_move_state = MOVE_STATE_RUNNING

var _invulnerable = false
var _invulnerable_time = 0

var velocity = Vector2(0, 0)

var _fall_time = 0
var _pre_jump_time = INF

var _anim_tree
var _anim_move_state

func _ready():
	#connect("died", HitSFX, "someone_died", [self])
	
	_anim_tree = $AnimationTree
	_anim_move_state = _anim_tree["parameters/MoveState/playback"]
	
	connect("died", LevelSequencer, "_on_Player_died")

func _jumping_enter():
	var jump_vel = sqrt(2 * _move_state.gravity_acc * _move_state.jump_height)
	velocity.y = -jump_vel

func _falling_enter():
	if velocity.y > 0:
		_fall_time = 0
	else:
		_fall_time = INF

func _falling_process(delta):
	_fall_time += delta
	if Input.is_action_just_pressed("gp_jump") or Input.is_action_just_released("gp_jump"):
		_pre_jump_time = 0
	else:
		_pre_jump_time += delta

func _common_get_next_state():
	if is_on_floor():
		if Input.is_action_just_pressed("gp_jump") or _pre_jump_time < PRE_JUMP_TIME:
			return MOVE_STATE_JUMPING
		if Input.is_action_pressed("gp_move_left") \
				or Input.is_action_pressed("gp_move_right"):
			return MOVE_STATE_RUNNING
		return MOVE_STATE_STANDING
	return MOVE_STATE_FALLING

func _jumping_get_next_state():
	if velocity.y > 0 or not Input.is_action_pressed("gp_jump"):
		return MOVE_STATE_FALLING
	return MOVE_STATE_JUMPING

func _falling_get_next_state():
	if is_on_floor():
		return _common_get_next_state()
	elif _fall_time < ROAD_RUNNER_TIME and Input.is_action_just_pressed("gp_jump"):
		return MOVE_STATE_JUMPING
	return MOVE_STATE_FALLING

func hit(_hitter):
	HitSFX.someone_died(self)
	emit_signal("died")

func _physics_process(delta):
	_move_state = _move_state.get_next_state.call_func()
	if _prev_move_state != _move_state:
		if _prev_move_state.exit:
			_prev_move_state.exit.call_func()
		_prev_move_state = _move_state
		if _move_state.enter:
			_move_state.enter.call_func()
		_anim_move_state.start(_move_state.name)
	
	if _move_state.process:
		_move_state.process.call_func(delta)
	
	if Input.is_action_pressed("gp_move_left"):
		_anim_tree.set("parameters/TurnLeft/active", true)
	elif Input.is_action_pressed("gp_move_right"):
		_anim_tree.set("parameters/TurnRight/active", true)
	
	if _invulnerable:
		_invulnerable_time += delta
		if _invulnerable_time > MAX_INVULNERABLE_TIME:
			_invulnerable = false
			set_collision_mask_bit(1, true)
	_anim_tree.set("parameters/InvulnerableBlend/blend_amount", _invulnerable)
	
	var step = Vector2(0, 0)
	if Input.is_action_pressed("gp_move_left"):
		step.x -= 1
	if Input.is_action_pressed("gp_move_right"):
		step.x += 1
	step = step.normalized()
	
	var acceleration = Vector2(0, 0)
	
	var friction = FRICTION_AIR
	if is_on_floor():
		friction = FRICTION_GROUND
	
	var h_acc = TOP_SPEED_X * (friction - 1) * FRICTION_COEFF
	acceleration.x += step.x * h_acc
	
	acceleration.y += _move_state.gravity_acc
	
	velocity += acceleration * delta
	velocity = move_and_slide_with_snap(velocity, Vector2(0, 1), Vector2(0, -1), true, 4, 1.05, false)
	
	velocity.x *= friction * _move_state.friction_multiplier
	
	for idx in range(get_slide_count()):
		var coll = get_slide_collision(idx)
		if coll.collider.has_method("push"):
			coll.collider.push(self)

func get_reverser():
	for child in get_children():
		if child.name == "RepairGun":
			return
	var reverser = Reverser.instance()
	add_child(reverser)
	move_child(reverser, 0)

func get_velocity():
	return velocity
