extends Node2D

var arena: TileMapLayer
var flowers: TileMapLayer
var food: TileMapLayer

var snake: Node2D
var respawn_point: Marker2D
var snake_positions = []

var follower_scene = preload("res://sprites/flaming skull/skull.tscn")
var head_scene = preload("res://sprites/walky_guy.tscn")

const COLLISION_LAYER_FOOD = 1
const COLLISION_LAYER_ARENA = 2
const COLLISION_LAYER_GHOST = 4

const TOP_VALID_ROW = 2
const BOTTOM_VALID_ROW = 12
const LEFT_VALID_COL = 2
const RIGHT_VALID_COL = 19

var VALID_FLOWERS = [Vector2i(8,6), Vector2i(9,6), Vector2i(10,6), Vector2i(10,5)]

const BLOCK_SIZE = 48 # px
const BASE_SNAKE_SPEED = 2*BLOCK_SIZE # px/s
const SPEED_PER_LENGTH = BASE_SNAKE_SPEED/4 # px/s per section
var snake_speed = BASE_SNAKE_SPEED

var direction: Vector2i = Vector2i.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	arena = $Game/Background/Arena
	flowers = $Game/Background/Flowers
	food = $Game/Foreground/Food
	
	snake = $Game/Foreground/Snake
	respawn_point = $Game/Foreground/RespawnPoint
	
	reset_snake()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Game/Foreground/DebugHighlights.clear()
	if direction.length_squared() != 0:
		var target_cell = get_head_target_cell()
		$Game/Foreground/DebugHighlights.set_cell(target_cell, 1, Vector2i(1,0))

func reset_snake() -> void:
	for child in snake.get_children():
		snake.remove_child(child)
	var head = make_head()
	head.position = respawn_point.position
	snake.add_child(head)
	snake_positions = [global_to_tile(head.position)]

	snake_speed = BASE_SNAKE_SPEED
	direction = Vector2.ZERO
	
	for rep in range(2):
		grow_snake()
	for idx in range(1,2):
		snake.get_child(idx).collision_layer = 0 # don't collide with the first 2 trailers because they should never cause a collision
	

func make_head() -> Node2D:
	var head: CharacterBody2D = head_scene.instantiate()
	# every layer this object exists in
	head.collision_layer = COLLISION_LAYER_ARENA | COLLISION_LAYER_GHOST
	# every layer this object needs to detect colliding with
	head.collision_mask = COLLISION_LAYER_FOOD | COLLISION_LAYER_ARENA | COLLISION_LAYER_GHOST
	return head
	
func make_follower() -> Node2D:
	var tail = follower_scene.instantiate()
	# every layer this object exists in
	tail.collision_layer = COLLISION_LAYER_GHOST
	# every layer this object needs to detect colliding with
	tail.collision_mask = 0
	return tail

func _unhandled_input(event: InputEvent) -> void:
	var new_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down", .1)
	if new_dir.length() > 0:
		direction = get_head_target_vel(new_dir)
	if event.is_action_released("pause_toggle"):
		print("pausing")
		$PauseModal.show_menu()
		get_tree().paused = true
		get_viewport().set_input_as_handled()
		return

func _physics_process(delta: float) -> void:
	move_snake(delta)

func move_snake(delta: float) -> void:
	move_snake_square(delta)
	
func move_snake_smooth(delta: float) -> void:
	var pieces = snake.get_children()
	var head = snake.get_child(0)
	var collision: KinematicCollision2D = head.move_and_collide(delta * direction)
	if collision:
		var collider = collision.get_collider()
		if snake.is_ancestor_of(collider) || arena == collider:
			kill_snake()
			return
		if food == collider:
			var food_rc: Vector2i = food.local_to_map(food.to_local(collision.get_position()))
			# todo: plant flower
			food.erase_cell(food_rc)
			grow_snake()
			generate_food()
			return
			
	for idx in range(1, pieces.size()):
		var prev = snake.get_child(idx-1)
		var curr = snake.get_child(idx)
		
		var diff = prev.position - curr.position  # points from 'prev' to 'curr'
		if diff.length() > BLOCK_SIZE:
			var speed = diff.length() - BLOCK_SIZE
			speed = pow(speed, 1.3)
			var vel = speed * diff.normalized()
			curr.velocity = vel
			curr.move_and_collide(vel * delta)
	
func move_snake_square(delta: float) -> void:
	var pieces = snake.get_children()
	
	assert(pieces.size() == snake_positions.size())
	
	move_snake_head_square(delta)
			
	for idx in range(1, pieces.size()):
		if idx >= pieces.size() || idx >= snake_positions.size():
			# handle concurrent modifications of the snake by just skipping stale elements
			break
			
		var curr = snake.get_child(idx)
		var target_cell = snake_positions[idx]
		
		var new_vel = get_snake_piece_velocity(curr, target_cell)
		curr.velocity = new_vel
		curr.move_and_slide()
		
func distance_in_tiles(a: Vector2, b: Vector2) -> float:
	return (abs(b.x-a.x) + abs(b.y-a.y)) / BLOCK_SIZE
		
func move_snake_head_square(delta: float) -> void:
	if direction.length_squared() == 0:
		# no collisions, no movement
		return
		
	var head = snake.get_child(0)
	var head_tile = global_to_tile(head.position)
	var target_cell = snake_positions[0]
	var offset_from_target = center_of_tile(target_cell) - head.position
	var is_close_to_target = offset_from_target.length() < snake_speed*delta
	if is_close_to_target:
		target_cell = get_head_target_cell()
		snake_positions.pop_back()
		snake_positions.push_front(target_cell)
		
	var head_vel = get_snake_piece_velocity(head,target_cell)
	head.velocity = head_vel
	var collision: KinematicCollision2D = head.move_and_collide(delta * head_vel)
	if collision:
		var collider = collision.get_collider()
		if snake.is_ancestor_of(collider) || arena == collider:
			kill_snake()
			return
		if food == collider:
			var food_cell: Vector2i = food.local_to_map(food.to_local(collision.get_position()))
			# todo: plant flower
			food.erase_cell(food_cell)
			grow_snake()
			generate_food()
			plant_flower(food_cell)
			return

func grow_snake() -> void:
	var tail = make_follower()
	if snake.get_child_count() <= 1:
		tail.position = respawn_point.position + 2 * BLOCK_SIZE * Vector2.DOWN
	else:
		tail.position = snake.get_child(snake.get_child_count() - 1).position
	snake.add_child(tail)
	snake_positions.push_back(global_to_tile(tail.position))
	snake_speed += SPEED_PER_LENGTH
	
func kill_snake() -> void:
	reset_snake()

func generate_food() -> void:
	var target
	while !target or has_flower(target):
		var r = randi_range(TOP_VALID_ROW, BOTTOM_VALID_ROW)
		var c = randi_range(LEFT_VALID_COL, RIGHT_VALID_COL)
		target = Vector2i(c,r)
	
	food.set_cell(target, 0, Vector2i(10,2 + randi() % 2))
	
func get_snake_piece_velocity(piece: CharacterBody2D, target_cell: Vector2i) -> Vector2:
	var target_cell_center = center_of_tile(target_cell)
	var direction_to_next_tile = target_cell_center - piece.position
	return snake_speed * direction_to_next_tile.normalized()
	
func global_to_tile(global_vec: Vector2) -> Vector2i:
	return food.local_to_map(food.to_local(global_vec))
	
func center_of_tile(map_vec: Vector2i) -> Vector2:
	return food.to_global(food.map_to_local(map_vec))

func get_head_target_cell() -> Vector2i:
	if snake.get_child_count() == 0 || direction.length_squared() == 0:
		return Vector2i.ZERO
	var head = snake.get_child(0)
	var head_tile = global_to_tile(head.position)
	return head_tile + direction	


# we should queue button presses tbh
func get_head_target_vel(input_dir: Vector2) -> Vector2i:
	if snake.get_child_count() == 0:
		return Vector2i.ZERO
	var head = snake.get_child(0)
	var snapped_angle = snapped(input_dir.angle(), PI/2)
	var intended_direction_offset = Vector2.from_angle(snapped_angle) * BLOCK_SIZE
	if head.velocity.length() > BLOCK_SIZE * 0.05 && head.velocity.dot(intended_direction_offset) < -0.1:
		# refuse to turn around iff we're already moving
		return direction
	var head_tile = global_to_tile(head.position)
	
	var center_of_head_tile_coord = center_of_tile(head_tile)
	var target_cell = global_to_tile(head.position + intended_direction_offset)
	return target_cell - head_tile
	
func plant_flower(cell_coord: Vector2i) -> void:
	var atlas_coord = VALID_FLOWERS[randi() % VALID_FLOWERS.size()]
	flowers.set_cell(cell_coord, 0, atlas_coord)
	update_grass(flowers.get_neighbor_cell(cell_coord, TileSet.CELL_NEIGHBOR_LEFT_SIDE))
	update_grass(flowers.get_neighbor_cell(cell_coord, TileSet.CELL_NEIGHBOR_RIGHT_SIDE))
	update_grass(flowers.get_neighbor_cell(cell_coord, TileSet.CELL_NEIGHBOR_TOP_SIDE))
	update_grass(flowers.get_neighbor_cell(cell_coord, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE))

func update_grass(cell_coord: Vector2i) -> void:
	if cell_coord.y < TOP_VALID_ROW || cell_coord.y > BOTTOM_VALID_ROW || cell_coord.x < LEFT_VALID_COL || cell_coord.x > RIGHT_VALID_COL:
		return
	if has_flower(cell_coord):
		return
	var needs_above = (cell_coord.y == TOP_VALID_ROW) || has_flower(flowers.get_neighbor_cell(cell_coord, TileSet.CELL_NEIGHBOR_TOP_SIDE))
	var needs_left = (cell_coord.x == LEFT_VALID_COL) || has_flower(flowers.get_neighbor_cell(cell_coord, TileSet.CELL_NEIGHBOR_LEFT_SIDE))
	var needs_below = (cell_coord.y == BOTTOM_VALID_ROW) || has_flower(flowers.get_neighbor_cell(cell_coord, TileSet.CELL_NEIGHBOR_BOTTOM_SIDE))
	var needs_right = (cell_coord.x == RIGHT_VALID_COL) || has_flower(flowers.get_neighbor_cell(cell_coord, TileSet.CELL_NEIGHBOR_RIGHT_SIDE))
	
	var idx = (8 if needs_left else 0) + (4 if needs_above else 0) + (2 if needs_right else 0) + (1 if needs_below else 0)
	
	const GRASSES = [
		Vector2i(1,1), # empty,
		Vector2i(2,3), # just below
		Vector2i(3,2), # just right
		Vector2i(3,3), # right and below
		
		Vector2i(2,0), # just above
		Vector2i(3,0), # above and right
		Vector2i(4,2), # above and below
		Vector2i(3,0), # above and right and below
		
		Vector2i(0,1), # just left,
		Vector2i(3,0), # left and just below
		Vector2i(5,2), # left and right
		Vector2i(1,3), # left and right and below
		
		Vector2i(0,0), # left and above
		Vector2i(0,3), # left and above and right
		Vector2i(0,0), # left and above and below
		Vector2i(1,5), # full
		Vector2i.ZERO
	];
	var atlas_coords = GRASSES[idx]
	flowers.set_cell(cell_coord, 0, atlas_coords)
	
	
func has_flower(cell_coord: Vector2i) -> bool:
	var atlas_coords = flowers.get_cell_atlas_coords(cell_coord)
	return VALID_FLOWERS.has(atlas_coords)
	
