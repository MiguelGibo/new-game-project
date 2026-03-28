extends CharacterBody2D


const SPEED = 75
const AIR_CONTROL = 0.75
const JUMP_VELOCITY = -175

@export var tilemaplayer: TileMapLayer
@export var block_atlas_coord: Vector2i = Vector2i(2,0)
@export var dir_facing: int = 1
@onready var sprite_2d: Sprite2D = $Sprite2D

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
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		
	if Input.is_action_just_pressed("down_move"):
		place_block()
		
	move_and_slide()
	
func place_block() -> void:
	var target_block_pos = global_position + Vector2(dir_facing * 16, 16)
	var grid_pos = tilemaplayer.local_to_map(target_block_pos)
	if tilemaplayer.get_cell_source_id(grid_pos) == -1:
		tilemaplayer.set_cell(grid_pos, 0, block_atlas_coord)
