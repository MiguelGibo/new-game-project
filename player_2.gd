extends CharacterBody2D

const SPEED = 75
const AIR_CONTROL = 0.80
const JUMP_VELOCITY = -175

@export var tilemaplayer: TileMapLayer
@export var block_atlas_coord_green: Vector2i = Vector2i(2,0)
@export var block_atlas_coord_blue: Vector2i = Vector2i(2,1)
@export var dir_facing: int = 1
@onready var sprite_2d: Sprite2D = $Sprite2D
var green_charges: int = 0
var blue_charges: int = 3
var placed_blocks: int = 0
var highlight_mode: String = "none"
@onready var highlight: Sprite2D = $Highlight
var highlight_frame = 3
var is_pushing: bool = false
@export var drop_atlas_coord_blue: Vector2i = Vector2i(3,2)
@export var grate_atlas_coord: Vector2i = Vector2i(1,2)
@onready var hearts: Sprite2D = $Hearts

# Block mode vars (from controller version)
var block_mode: bool = false
var block_cursor: Vector2i = Vector2i(1, 0)  # offset from player, starts to the right
var _cursor_move_timer: float = 0.0
const CURSOR_MOVE_DELAY: float = 0.2

# Controller support
@export var device_id: int = 1  # Set in inspector (0 for player 1, 1 for player 2)
var _just_pressed: Dictionary = {}

# Action button mapping for controller
var ACTION_BUTTONS: Dictionary = {
	"up_move":    0,   # Cross / A
	"down_move":  12,  # D-pad Down
	"left_move":  13,  # D-pad Left
	"right_move": 14,  # D-pad Right
	"mine_block": 2,   # Square / X
	"block_mode": 10,  # R2 / Right Trigger
}

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.device == device_id and event.pressed:
		_just_pressed[event.button_index] = true

func _ajp(action: String) -> bool:
	# Check keyboard (original actions with "2" suffix)
	if Input.is_action_just_pressed(action + "2"):
		return true
	
	# Check controller
	if action in ACTION_BUTTONS:
		if _just_pressed.get(ACTION_BUTTONS[action], false):
			_just_pressed.erase(ACTION_BUTTONS[action])
			return true
	return false

func _is_action_held(action: String) -> bool:
	# Check keyboard
	if Input.is_action_pressed(action):
		return true
	
	# Check controller
	if action in ACTION_BUTTONS:
		return Input.is_joy_button_pressed(device_id, ACTION_BUTTONS[action])
	return false

func _get_move_axis() -> float:
	# Keyboard first (original actions with "2" suffix)
	var kb := Input.get_axis("left_move2", "right_move2")
	if abs(kb) > 0.0:
		return kb
	
	# Controller
	var axis := Input.get_joy_axis(device_id, JOY_AXIS_LEFT_X)
	if abs(axis) > 0.2:
		return axis
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_LEFT):
		return -1.0
	if Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_RIGHT):
		return 1.0
	return 0.0

func _physics_process(delta: float) -> void:
	var current_speed = SPEED
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		current_speed = SPEED * AIR_CONTROL

	# Check if block mode is active (hold R2 or block_mode2 key)
	block_mode = _is_action_held("block_mode")
	
	if block_mode and block_cursor == Vector2i(0, 0):
		block_cursor = Vector2i(1, 0)
	
	if block_mode:
		_handle_block_mode(delta)
	else:
		_handle_normal_mode(delta, current_speed)
		
	update_highlight()
	update_color()
	
	if hearts.visible:
		hearts.position = global_position
	
	move_and_slide()
	
	# Only try to push blocks in normal mode (original behavior)
	if not block_mode and _get_move_axis() != 0 and is_on_wall() and is_on_floor():
		try_push_block()
	
	# Check if touching other player.
	check_player_collision()

func _handle_normal_mode(delta: float, current_speed: float) -> void:
	# Handle jump.
	if _ajp("up_move") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var direction := _get_move_axis()
	
	if direction != 0:
		dir_facing = sign(direction)
		
	if dir_facing == -1:
		sprite_2d.flip_h = true
	else:
		sprite_2d.flip_h = false
		
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		
	if _ajp("down_move"):
		if highlight_mode == "build":
			place_block()
		else:
			highlight_mode = "build"
	elif _ajp("mine_block"):
		if highlight_mode == "mine":
			mine_block()
		else:
			highlight_mode = "mine"

func _handle_block_mode(delta: float) -> void:
	# Allow jumping in block mode
	if _ajp("up_move") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movement in block mode
	var direction := _get_move_axis()
	if direction != 0:
		dir_facing = sign(direction)
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Cursor movement with right stick or keyboard
	var up_action = "up_move2"
	var down_action = "down_move2"
	var left_action = "left_move2"
	var right_action = "right_move2"
	
	var kb_ax := Input.get_axis(left_action, right_action)
	var kb_ay := Input.get_axis(up_action, down_action)
	var ax := kb_ax if abs(kb_ax) > 0.0 else Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_X)
	var ay := kb_ay if abs(kb_ay) > 0.0 else Input.get_joy_axis(device_id, JOY_AXIS_RIGHT_Y)

	var cx := 0
	var cy := 0

	if abs(ax) > 0.5:
		cx = int(sign(ax))
	elif Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_LEFT):
		cx = -1
	elif Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_RIGHT):
		cx = 1

	if abs(ay) > 0.5:
		cy = int(sign(ay))
	elif Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_UP):
		cy = -1
	elif Input.is_joy_button_pressed(device_id, JOY_BUTTON_DPAD_DOWN):
		cy = 1

	if cx != 0 or cy != 0:
		_cursor_move_timer -= delta
		if _cursor_move_timer <= 0.0:
			block_cursor.x = clamp(block_cursor.x + cx, -1, 1)
			block_cursor.y = clamp(block_cursor.y + cy, -1, 1)
			_cursor_move_timer = CURSOR_MOVE_DELAY
	else:
		_cursor_move_timer = 0.0

	# Don't allow cursor on player's tile
	if block_cursor == Vector2i(0, 0):
		block_cursor = Vector2i(1, 0)

	# Place or absorb block with mine button in block mode
	if _ajp("mine_block"):
		var target = get_cursor_grid_pos()
		var source = tilemaplayer.get_cell_source_id(target)
		if source != -1:
			absorb_block_at_cursor()
		else:
			place_block_at_cursor()

func get_player_grid_pos() -> Vector2i:
	var player_local_pos = tilemaplayer.to_local(global_position)
	return tilemaplayer.local_to_map(player_local_pos)

func get_cursor_grid_pos() -> Vector2i:
	return get_player_grid_pos() + block_cursor

func is_cursor_valid() -> bool:
	var target = get_cursor_grid_pos()

	# Can't place on a wall tile
	if tilemaplayer.get_cell_source_id(target) != -1:
		return false

	# Can't place on occupied tile (player group)
	if is_tile_occupied(target):
		return false

	return true

func place_block_at_cursor() -> void:
	if not is_cursor_valid():
		return

	var target = get_cursor_grid_pos()

	if green_charges > 0:
		tilemaplayer.set_cell(target, 0, block_atlas_coord_green)
		green_charges -= 1
		placed_blocks += 1
		update_size()
	elif blue_charges > 0:
		tilemaplayer.set_cell(target, 0, block_atlas_coord_blue)
		blue_charges -= 1
		placed_blocks += 1
		update_size()

func absorb_block_at_cursor() -> void:
	var target = get_cursor_grid_pos()
	var source = tilemaplayer.get_cell_source_id(target)
	var atlas = tilemaplayer.get_cell_atlas_coords(target)

	if source == 0 and atlas == block_atlas_coord_green and green_charges < 4:
		tilemaplayer.set_cell(target, -1)
		green_charges += 1
		placed_blocks -= 1
		update_size()
	elif source == 0 and atlas == block_atlas_coord_blue and blue_charges < 4:
		tilemaplayer.set_cell(target, -1)
		blue_charges += 1
		placed_blocks -= 1
		update_size()

func check_player_collision() -> void:
	var touching_player = false
	
	for player in get_tree().get_nodes_in_group("player"):
		if player == self:
			continue
		
		print("Checking against: ", player.name)
		print("My pos: ", global_position, " | Other pos: ", player.global_position)
		
		var distance = global_position.distance_to(player.global_position)
		print("Distance: ", distance)
		
		if distance < 20:
			touching_player = true
			break
	
	if touching_player:
		print("Registered: ", name)
		hearts.visible = true
		GameManager.register_player_touch(self)
	else:
		hearts.visible = false
		GameManager.unregister_player_touch(self)

func place_block() -> void:
	var target_grid_pos: Vector2i = get_build_target()
	
	if placed_blocks > 3:
		return

	var player_local_pos = tilemaplayer.to_local(global_position)
	var player_grid_pos = tilemaplayer.local_to_map(player_local_pos)
	var tile_below_player = player_grid_pos + Vector2i(0, 1)
	
	if blue_charges > 0 and tilemaplayer.get_cell_source_id(tile_below_player) == 0 and tilemaplayer.get_cell_atlas_coords(tile_below_player) == grate_atlas_coord:
		var drop_start = tile_below_player + Vector2i(0, 1)
		
		if tilemaplayer.get_cell_source_id(drop_start) == -1 and not tilemaplayer.is_tile_occupied(drop_start):
			tilemaplayer.set_cell(drop_start, 0, block_atlas_coord_blue)
			blue_charges -= 1
			placed_blocks += 1
			update_size()
			return
			
	if is_tile_occupied(target_grid_pos):
		return
		
	if tilemaplayer.get_cell_source_id(target_grid_pos) == -1 and blue_charges > 0:
		tilemaplayer.set_cell(target_grid_pos, 0, block_atlas_coord_blue)
		blue_charges -= 1
		placed_blocks += 1
		update_size()
	elif tilemaplayer.get_cell_source_id(target_grid_pos) == -1 and green_charges > 0:
		tilemaplayer.set_cell(target_grid_pos, 0, block_atlas_coord_green)
		green_charges -= 1
		placed_blocks += 1
		update_size()

func mine_block() -> void:
	var target_grid_pos: Vector2i = get_mine_target()
	var target_source = tilemaplayer.get_cell_source_id(target_grid_pos)
	var target_atlas = tilemaplayer.get_cell_atlas_coords(target_grid_pos)
	
	if placed_blocks == 0:
		return
	
	if target_source == 0 and target_atlas == block_atlas_coord_blue and blue_charges < 4:
		tilemaplayer.set_cell(target_grid_pos, -1)
		blue_charges += 1
		placed_blocks -= 1
		update_size()
	elif target_source == 0 and target_atlas == block_atlas_coord_green and green_charges < 4:
		tilemaplayer.set_cell(target_grid_pos, -1)
		green_charges += 1
		placed_blocks -= 1
		update_size()

func update_size() -> void:
	var scale_factor = float(3 - placed_blocks + 1) / 4.0
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
		if tilemaplayer.get_cell_source_id(pos) == 0 and (tilemaplayer.get_cell_atlas_coords(pos) == block_atlas_coord_green or tilemaplayer.get_cell_atlas_coords(pos) == block_atlas_coord_blue):
			return pos

	return player_grid_pos + Vector2i(dir_facing, 0)

func update_highlight() -> void:
	if block_mode:
		# Show cursor at the block mode target position
		highlight.visible = true
		var target = get_cursor_grid_pos()
		var local_pos = tilemaplayer.map_to_local(target)
		highlight.global_position = tilemaplayer.to_global(local_pos)

		# Change frame based on validity
		if is_cursor_valid():
			highlight.frame = 7   # green/valid frame
		else:
			highlight.frame = 3   # red/invalid frame
		return

	# Normal highlight mode (original behavior)
	if highlight_mode == "none":
		highlight.visible = false
		return
	
	highlight.visible = true
	var target_grid_pos: Vector2i
	
	if highlight_mode == "build":
		target_grid_pos = get_build_target()
		var source = tilemaplayer.get_cell_source_id(target_grid_pos)
		
		if source == -1 and placed_blocks < 3 and not is_tile_occupied(target_grid_pos):
			highlight.visible = true
			highlight_frame = 7
			highlight.frame = highlight_frame
		else:
			highlight.visible = false

	elif highlight_mode == "mine":
		target_grid_pos = get_mine_target()
		var source = tilemaplayer.get_cell_source_id(target_grid_pos)
		var atlas = tilemaplayer.get_cell_atlas_coords(target_grid_pos)
		if source == 0 and (atlas == block_atlas_coord_green or atlas == block_atlas_coord_blue):
			highlight.visible = true
			highlight_frame = 3
			highlight.frame = highlight_frame
		else:
			highlight.visible = false
	
	var local_pos = tilemaplayer.map_to_local(target_grid_pos)
	highlight.global_position = tilemaplayer.to_global(local_pos)
	
func update_color() -> void:
	var green_intensity = 0.2 * green_charges
	green_intensity = clamp(green_intensity, 0.0, 1.0)
	sprite_2d.modulate = Color.WHITE.lerp(Color.GREEN, green_intensity)

func try_push_block() -> void:
	var player_local_pos = tilemaplayer.to_local(global_position)
	var player_grid_pos = tilemaplayer.local_to_map(player_local_pos)
	var block_pos = player_grid_pos + Vector2i(dir_facing,0)
	
	var source = tilemaplayer.get_cell_source_id(block_pos)
	var atlas = tilemaplayer.get_cell_atlas_coords(block_pos)

	if source == 0 and atlas == block_atlas_coord_blue:
		var next_pos = block_pos + Vector2i(dir_facing, 0)
		var slide_dest = block_pos
		var distance_checked = 0
		var max_distance = 1
		
		while tilemaplayer.get_cell_source_id(next_pos) == -1 and distance_checked < max_distance:
			slide_dest = next_pos
			next_pos += Vector2i(dir_facing, 0)
			distance_checked += 1
			
		if slide_dest != block_pos:
			slide_blue_block(block_pos, slide_dest)

func slide_blue_block(start_grid: Vector2i, end_grid: Vector2i) -> void:
	is_pushing = true
	
	tilemaplayer.set_cell(start_grid, -1)
	
	var slide_sprite = Sprite2D.new()
	var tile_source = tilemaplayer.tile_set.get_source(0) as TileSetAtlasSource
	var tile_size = tilemaplayer.tile_set.tile_size
	
	slide_sprite.texture = tile_source.texture
	slide_sprite.region_enabled = true
	slide_sprite.region_rect = Rect2(block_atlas_coord_blue.x * tile_size.x, block_atlas_coord_blue.y * tile_size.y, tile_size.x, tile_size.y)
	
	var start_global = tilemaplayer.to_global(tilemaplayer.map_to_local(start_grid))
	var end_global = tilemaplayer.to_global(tilemaplayer.map_to_local(end_grid))
	
	slide_sprite.global_position = start_global
	get_tree().current_scene.add_child(slide_sprite)
	
	var tween = create_tween()
	var distance_in_tiles = abs(end_grid.x - start_grid.x)
	var slide_time = distance_in_tiles * 0.09 
	
	tween.tween_property(slide_sprite, "global_position", end_global, slide_time)
	
	var on_slide_finished = func():
		tilemaplayer.set_cell(end_grid, 0, block_atlas_coord_blue)
		slide_sprite.queue_free()
		is_pushing = false
	tween.finished.connect(on_slide_finished)

func is_tile_occupied(grid_pos: Vector2i) -> bool:
	var target_global = tilemaplayer.to_global(tilemaplayer.map_to_local(grid_pos))
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	var t_size = tilemaplayer.tile_set.tile_size
	
	shape.size = Vector2(t_size.x - 2, t_size.y - 2) 
	
	query.shape = shape
	query.transform = Transform2D(0, target_global)
	query.collision_mask = 2 
	
	return space_state.intersect_shape(query).size() > 0
