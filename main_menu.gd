extends Control

@onready var title: VBoxContainer = $Title
@onready var level_select: VBoxContainer = $LevelSelect

var level_1: PackedScene = preload("res://scenes/level_1.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_start_button_pressed() -> void:
	GameManager.current_level = 1
	GameManager.trigger_transition()


func _on_quit_button_pressed() -> void:
	get_tree().free()


func _on_level_select_button_pressed() -> void:
	title.visible = false
	level_select.visible = true


func _on_back_button_pressed() -> void:
	title.visible = true
	level_select.visible = false


func _on_continue_button_pressed() -> void:
	GameManager.trigger_transition()


func _on_level_1_pressed() -> void:
	GameManager.current_level = 1
	GameManager.trigger_transition()


func _on_level_2_pressed() -> void:
	GameManager.current_level = 2
	GameManager.trigger_transition()


func _on_level_3_pressed() -> void:
	GameManager.current_level = 3
	GameManager.trigger_transition()


func _on_level_4_pressed() -> void:
	GameManager.current_level = 4
	GameManager.trigger_transition()


func _on_level_5_pressed() -> void:
	GameManager.current_level = 5
	GameManager.trigger_transition()
