extends Node2D

export (Color) var aim_color = Color(1, 1, 0, 1)
export (Color) var repair_color = Color(0, 0, 1, 1)

var _pointer
var _sprite
var _repair_sfx

func _ready():
	_pointer = $Pointer
	_sprite = $Sprite
	_repair_sfx = $RepairSFX

func _physics_process(_delta):
	_pointer.default_color = aim_color
	var target = get_global_mouse_position()
	var direction = (target - global_position).normalized()
	var space_state = get_world_2d().direct_space_state
	var result = space_state.intersect_ray(global_position, global_position + (direction * 999), [get_parent()])
	if not result.empty():
		target = result.position
		if Input.is_action_just_pressed("gp_shoot"):
			if result.collider.has_method("repair"):
				if result.collider.repair():
					_repair_sfx.play()
					_pointer.default_color = repair_color
	_pointer.set_point_position(1, target - global_position)
	_sprite.look_at(target)
