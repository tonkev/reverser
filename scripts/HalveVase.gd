extends RigidBody2D

onready var fixed_scene = load("res://scenes/Vase.tscn")

export (NodePath) var other_halve_path = "NA"
export (float) var repair_force = 100
export (float) var repair_time = 1
export (float) var push_force = 10
export (float) var min_hit_speed = 30

var other_halve

var split_sfx

var _repair_timer

func _ready():
	if not other_halve_path == "NA":
		other_halve = get_node(other_halve_path)
	
	split_sfx = $SplitSFX
	
	_repair_timer = repair_time

func _physics_process(delta):
	if _repair_timer < repair_time:
		_repair_timer += delta
		
	for body in get_colliding_bodies():
		if not body.is_in_group("player"):
			if body.has_method("get_velocity"):
				var velocity_diff = linear_velocity - body.get_velocity()
				if body.has_method("hit"):
					body.hit(self)
		if body == other_halve and _repair_timer < repair_time:
			var fixed_vase = fixed_scene.instance()
			fixed_vase.global_position = global_position
			get_parent().add_child(fixed_vase)
			other_halve.get_parent().remove_child(other_halve)
			fixed_vase.repaired_sfx.play()
			get_parent().remove_child(self)
			return true

func repair():
	_repair_timer = 0
	var distance = global_position - other_halve.global_position
	var direction = distance.normalized()
	other_halve.apply_central_impulse(direction * repair_force)
	return true

func push(_pusher):
	var direction = (global_position - _pusher.global_position).normalized()
	apply_central_impulse(direction * push_force)
