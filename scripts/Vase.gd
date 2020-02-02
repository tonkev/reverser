extends RigidBody2D

onready var LeftHalf = load("res://scenes/LeftHalveVase.tscn")
onready var RightHalf = load("res://scenes/RightHalveVase.tscn")

export (float) var push_force = 10
export (float) var min_split_speed = 100
export (float) var min_hit_speed = 30

var repaired_sfx

func _ready():
	repaired_sfx = $RepairedSFX

func push(_pusher):
	var direction = (global_position - _pusher.global_position).normalized()
	apply_central_impulse(direction * push_force)

func split():
	var left = LeftHalf.instance()
	var right = RightHalf.instance()
	left.global_position = global_position - Vector2(8, 0)
	right.global_position = global_position + Vector2(8, 0)
	left.other_halve = right
	right.other_halve = left
	get_parent().add_child(left)
	get_parent().add_child(right)
	left.split_sfx.play()
	get_parent().remove_child(self)

func hit(_hitter):
	split()

func _physics_process(_delta):
	var will_split = false
	for body in get_colliding_bodies():
		if not body.is_in_group("player"):
			if body.has_method("get_velocity"):
				var velocity_diff = linear_velocity - body.get_velocity()
				var hit_speed = min_hit_speed
				if velocity_diff.length() >= hit_speed:
					if body.has_method("hit"):
						body.hit(self)
		if body.is_in_group("ground"):
			if linear_velocity.length() >= min_split_speed:
				will_split = true
				
	if will_split:
		split()
