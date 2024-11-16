extends Node2D

var arena: TileMapLayer
var flowers: TileMapLayer
var food: TileMapLayer

var snake: Node2D
var respawn_point: Marker2D

var follower_scene = preload("res://sprites/flaming skull/skull.tscn")
var head_scene = preload("res://sprites/walky_guy.tscn")

const COLLISION_LAYER_FOOD = 1
const COLLISION_LAYER_ARENA = 2
const COLLISION_LAYER_GHOST = 4

const TOP_VALID_ROW = 2
const BOTTOM_VALID_ROW = 12
const LEFT_VALID_COL = 2
const RIGHT_VALID_COL = 19

const BLOCK_SIZE = 48 # px
const BASE_SNAKE_SPEED = 2*BLOCK_SIZE # px/s
const SPEED_PER_LENGTH = BASE_SNAKE_SPEED/4 # px/s
var snake_speed = BASE_SNAKE_SPEED
var direction: Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	arena = $Game/Background/Arena
	flowers = $Game/Background/flowers
	food = $Game/Foreground/Food
	
	snake = $Game/Foreground/Snake
	respawn_point = $Game/Foreground/RespawnPoint
	
	reset_snake()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func reset_snake() -> void:
	for child in snake.get_children():
		snake.remove_child(child)
	var head = make_head()
	head.position = respawn_point.position
	snake.add_child(head)

	snake_speed = BASE_SNAKE_SPEED
	direction = Vector2.ZERO
	
	for rep in range(2):
		grow_snake()

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
	var new_dir = Input.get_vector("move_left", "move_right", "move_up", "move_down", 1)
	if new_dir.length() < 0.5:
		return
	direction = new_dir.normalized() * snake_speed
	if snake.get_child_count() > 0:
		snake.get_child(0).velocity = direction

func _physics_process(delta: float) -> void:
	move_snake(delta)

func move_snake(delta: float) -> void:
	move_snake_smooth(delta)
	
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
		
		var diff = prev.position - curr.position
		if diff.length() > BLOCK_SIZE:
			var speed = diff.length() - BLOCK_SIZE
			speed = pow(speed, 1.3)
			var vel = speed * diff.normalized()
			curr.velocity = vel
			curr.move_and_collide(vel * delta)

func grow_snake() -> void:
	var tail = make_follower()
	tail.position = respawn_point.position + 2 * BLOCK_SIZE * Vector2.DOWN
	snake.add_child(tail)
	snake_speed += SPEED_PER_LENGTH
	
func kill_snake() -> void:
	reset_snake()

func generate_food() -> void:
	var r = randi_range(TOP_VALID_ROW, BOTTOM_VALID_ROW)
	var c = randi_range(LEFT_VALID_COL, RIGHT_VALID_COL)
	
	food.set_cell(Vector2i(c,r), 0, Vector2i(10,2 + randi() % 2))
	
	
