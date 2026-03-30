extends Node

const SAVE_PATH: String = "user://savegame.dat"
var current_level: int = 1
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
		advance_level()
		trigger_transition()

func unregister_player_touch(player) -> void:
	players_touching.erase(player)

func trigger_transition() -> void:
	if is_transitioning:
		return
	print("Transitioning to: ", get_next_level_path())
	is_transitioning = true
	save_game()
	
	var next_path = get_next_level_path()
	
	# Find overlay and do transition
	var overlay = get_tree().current_scene.find_child("ColorRect")
	print("Overlay found: ", overlay)
	if overlay == null:
		get_tree().change_scene_to_file(next_path)
		return
	
	var tween = get_tree().create_tween()
	tween.tween_property(overlay, "color", Color(0, 0, 0, 1), 0.5)
	tween.tween_interval(0.15)
	tween.tween_callback(func():
		is_transitioning = false
		players_touching.clear()
		get_tree().change_scene_to_file(next_path)
	)

func get_next_level_path() -> String:
	return "res://scenes/level_%d.tscn" % current_level

func advance_level() -> void:
	current_level += 1

func _ready() -> void:
	load_game()
	
func save_game() -> void:
	if current_level > total_levels:
		current_level = 1
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	
	if file:
		file.store_var(current_level)
		file.close()
		print("Game saved! Current level: ", current_level)
		
func load_game() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var saved_data = file.get_var()
			
			if saved_data == null:
				current_level = 1
			else:
				current_level = saved_data
			file.close()
			print("Save loaded! Current level: ", current_level)
	else:
		print("No save data found. Starting fresh.")
