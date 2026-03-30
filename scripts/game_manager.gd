extends Node

var current_level: int = 2
var total_levels: int = 3
var is_transitioning: bool = false

# Track which players are touching
var players_touching: Array = []

func register_player_touch(player) -> void:
	if player in players_touching:
		return
	players_touching.append(player)
	print("Registered: ", player.name, " | Total: ", players_touching.size())
	if players_touching.size() >= 2:
		trigger_transition()

func unregister_player_touch(player) -> void:
	players_touching.erase(player)

func trigger_transition() -> void:
	if is_transitioning:
		return
	print("Transitioning to: ", get_next_level_path())
	is_transitioning = true
	var next_path = get_next_level_path()
	advance_level()
	
	# Find overlay and do transition
	var overlay = get_tree().current_scene.find_child("ColorRect")
	print("Overlay found: ", overlay)
	if overlay == null:
		get_tree().change_scene_to_file(next_path)
		return
	
	var tween = get_tree().create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.5)
	tween.tween_interval(0.5)
	tween.tween_callback(func():
		players_touching.clear()
		get_tree().change_scene_to_file(next_path)
	)

func get_next_level_path() -> String:
	return "res://scenes/level_%d.tscn" % current_level

func advance_level() -> void:
	current_level += 1
