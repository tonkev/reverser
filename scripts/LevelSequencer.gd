extends CanvasLayer

const fade_time = 0.5

var is_fading = true
var fade_timer = fade_time
var in_out = -1
var level_idx = 1

func _ready():
	$ColorRect.rect_size = get_viewport().size
	$ColorRect.color = Color(0, 0, 0, 1)

func _on_LevelFinish_player_entered():
	is_fading = true

func _on_Player_died():
	if not is_fading:
		get_tree().paused = true
		level_idx -= 1
		is_fading = true

func _process(delta):
	if is_fading:
		fade_timer += delta * in_out
		if fade_timer >= fade_time:
			level_idx += 1
			var level_idx_str = str(level_idx)
			if level_idx < 10:
				level_idx_str = "0" + level_idx_str
			get_tree().change_scene("res://scenes/Level" + level_idx_str + ".tscn")
			get_tree().paused = false
			in_out = -1
		elif fade_timer < 0:
			fade_timer = 0
			in_out = 1
			is_fading = false
		$ColorRect.color = Color(0, 0, 0, fade_timer / fade_time)
	else:
		if Input.is_action_just_pressed("gp_restart"):
			get_tree().paused = true
			level_idx -= 1
			is_fading = true
