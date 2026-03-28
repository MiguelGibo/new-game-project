extends CharacterBody2D


const SPEED = 75
const AIR_CONTROL = 0.75
const JUMP_VELOCITY = -175


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
	if direction:
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)

	move_and_slide()
