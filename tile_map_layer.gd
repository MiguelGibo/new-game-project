extends TileMapLayer

@export var block_atlas_coord_blue: Vector2i = Vector2i(2,1)
@export var drop_atlas_coord_blue: Vector2i = Vector2i(3,2)

var reserved_cells: Array[Vector2i] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _physics_process(_delta: float) -> void:
	var used_cells = get_used_cells()
	
	for cell in used_cells:
		var source = get_cell_source_id(cell)
		var atlas = get_cell_atlas_coords(cell)
		
		if source == 0 and atlas == block_atlas_coord_blue:
			var cell_below = cell + Vector2i(0, 1)
			
			if get_cell_source_id(cell_below) == -1 and not is_tile_occupied(cell_below) and cell_below not in reserved_cells:
				var drop_end = get_drop_target(cell)
				
				if drop_end != cell:
					set_cell(cell, -1)
					drop_block(cell, drop_end)
				
func get_drop_target(start_grid: Vector2i) -> Vector2i:
	var current_pos = start_grid
	
	for i in range(50):
		var next_pos = current_pos + Vector2i(0, 1)
		if get_cell_source_id(next_pos) != -1 or is_tile_occupied(next_pos) or next_pos in reserved_cells:
			break
		current_pos = next_pos
	return current_pos
	
func drop_block(start_grid: Vector2i, end_grid: Vector2i) -> void:
	reserved_cells.append(end_grid) 
	
	var drop_sprite = Sprite2D.new()
	var t_source = tile_set.get_source(0) as TileSetAtlasSource
	var t_size = tile_set.tile_size
	
	drop_sprite.texture = t_source.texture
	drop_sprite.region_enabled = true
	drop_sprite.region_rect = Rect2(drop_atlas_coord_blue.x * t_size.x, drop_atlas_coord_blue.y * t_size.y, t_size.x, t_size.y)
	
	var start_global = to_global(map_to_local(start_grid))
	var end_global = to_global(map_to_local(end_grid))
	
	drop_sprite.global_position = start_global
	add_child(drop_sprite) 
	
	var tween = create_tween()
	var distance_in_tiles = abs(end_grid.y - start_grid.y)
	var drop_time = distance_in_tiles * 0.10
	
	tween.tween_property(drop_sprite, "global_position", end_global, drop_time)
	
	var on_drop_finished = func():
		reserved_cells.erase(end_grid) 
	
		if get_cell_source_id(end_grid) == -1 and not is_tile_occupied(end_grid):
			set_cell(end_grid, 0, block_atlas_coord_blue)
			
		drop_sprite.queue_free() 
		
	tween.finished.connect(on_drop_finished)
	
func is_tile_occupied(grid_pos: Vector2i) -> bool:
	var target_global = to_global(map_to_local(grid_pos))
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsShapeQueryParameters2D.new()
	var shape = RectangleShape2D.new()
	var t_size = tile_set.tile_size
	
	shape.size = Vector2(t_size.x - 2, t_size.y - 2) 
	
	query.shape = shape
	query.transform = Transform2D(0, target_global)
	query.collision_mask = 2
	
	return space_state.intersect_shape(query).size() > 0
