extends CharacterBody2D


const SPEED = 75
const AIR_CONTROL = 0.80
const JUMP_VELOCITY = -175

@export var tilemaplayer: TileMapLayer
@export var block_atlas_coord: Vector2i = Vector2i(2,0)
@export var dir_facing: int = 1
@onready var sprite_2d: Sprite2D = $Sprite2D
var charges: int = 6
var highlight_mode: String = "none"
@onready var highlight: Sprite2D = $Highlight

func _physics_process(delta: float) -> void:
	var current_speed = SPEED
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		current_speed = SPEED * AIR_CONTROL

	# Handle jump.
	if Input.is_action_just_pressed("up_move") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("left_move", "right_move")
	
	if direction != 0:
		dir_facing = sign(direction)
		
	if dir_facing == -1:
		sprite_2d.flip_h = true
	else:
		sprite_2d.flip_h = false
		
	if direction:
		#highlight_mode = "none"
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		
	if Input.is_action_just_pressed("down_move"):
		if highlight_mode == "build":
			place_block()
		else:
			highlight_mode = "build"
	elif Input.is_action_just_pressed("mine_block"):
		if highlight_mode == "mine":
			mine_block()
		else:
			highlight_mode = "mine"
		
	update_highlight()
	
	move_and_slide()
	
func place_block() -> void:
	var target_grid_pos: Vector2i =get_build_target()

	if tilemaplayer.get_cell_source_id(target_grid_pos) == -1 and charges > 3:
		tilemaplayer.set_cell(target_grid_pos, 0, block_atlas_coord)
		charges -= 1
		update_size()

func mine_block() -> void:
	var target_grid_pos: Vector2i = get_mine_target()
	var target_source = tilemaplayer.get_cell_source_id(target_grid_pos)
	var target_atlas = tilemaplayer.get_cell_atlas_coords(target_grid_pos)
	
	if target_source == 0 and target_atlas == block_atlas_coord and charges < 6:
		tilemaplayer.set_cell(target_grid_pos, -1)
		charges += 1
		update_size()

func update_size() -> void:
	var effective_charges = max(1, charges)
	var scale_factor = float(effective_charges) / 6.0
	scale = Vector2(scale_factor, scale_factor)
	
func get_build_target() -> Vector2i:
	var player_local_pos = tilemaplayer.to_local(global_position)
	var player_grid_pos = tilemaplayer.local_to_map(player_local_pos)
	var tile_below_player = player_grid_pos + Vector2i(0, 1)
	
	if tilemaplayer.get_cell_source_id(tile_below_player) == -1:
		return tile_below_player
	else:
		return player_grid_pos + Vector2i(dir_facing, 1)
		
func get_mine_target() -> Vector2i:
	var player_local_pos = tilemaplayer.to_local(global_position)
	var player_grid_pos = tilemaplayer.local_to_map(player_local_pos)
	
	var check_positions = [
		player_grid_pos + Vector2i(dir_facing, 0),   # Front
		player_grid_pos + Vector2i(dir_facing, -1),  # Diagonal Top
		player_grid_pos + Vector2i(dir_facing, 1),   # Diagonal Bottom
		player_grid_pos + Vector2i(0, 1),            # Below
		player_grid_pos + Vector2i(0, -1)            # Above
	]
	
	for pos in check_positions:
		if tilemaplayer.get_cell_source_id(pos) == 0 and tilemaplayer.get_cell_atlas_coords(pos) == block_atlas_coord:
			return pos

	return player_grid_pos + Vector2i(dir_facing, 0)

func update_highlight() -> void:
	if highlight_mode == "none":
		highlight.visible = false
		return
	
	highlight.visible = true
	var target_grid_pos: Vector2i
	
	if highlight_mode == "build":
		if charges > 3:
			target_grid_pos = get_build_target()
			highlight.modulate = Color(0.502, 1.0, 0.502, 1.0)
		else:
			highlight.visible = false
	elif highlight_mode == "mine":
		target_grid_pos = get_mine_target()
		var source = tilemaplayer.get_cell_source_id(target_grid_pos)
		var atlas = tilemaplayer.get_cell_atlas_coords(target_grid_pos)
		if source == 0 and atlas == block_atlas_coord:
			highlight.visible = true
			highlight.modulate = Color(1, 0.5, 0.5, 0.7)
		else:
			highlight.visible = false
	
	var local_pos = tilemaplayer.map_to_local(target_grid_pos)
	highlight.global_position = tilemaplayer.to_global(local_pos)
	
