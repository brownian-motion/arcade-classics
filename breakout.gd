extends Control

const BLOCK_SIZE = 48 # px

const TOP_WALL_Y = BLOCK_SIZE*3
const LEFT_WALL_X = BLOCK_SIZE*3
const RIGHT_WALL_X = BLOCK_SIZE*13

const BASE_PADDLE_VELOCITY = 4 * BLOCK_SIZE
const BASE_BALL_VELOCITY = 5 * BLOCK_SIZE
const BALL_BOUNCE_ACCELERATION_SCALE = 1.05
const MAX_BALL_SPEED = 20 * BLOCK_SIZE

const KICK_DELAY_SEC = 3 # seconds

var ball
var paddle
var walls
var death_wall
var ball_spawn_point
var bricks

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ball = $Game/Foreground/Ball
	paddle = $Game/Foreground/Paddle
	walls = $Game/Foreground/Walls
	death_wall = $Game/Foreground/DeathWall
	ball_spawn_point = $Game/Foreground/BallSpawnPoint
	bricks = $Game/Foreground/Bricks
	
	ball.get_child(0).play()
	paddle.get_child(0).play()
	
	reset_ball()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	
	pass
	
func _physics_process(delta: float) -> void:
	if ball == null:
		print("no physics")
		return
	var collision = ball.move_and_collide(ball.velocity * delta)
	if collision:
		var collider = collision.get_collider()
		if walls.is_ancestor_of(collider):
			bounce_ball(collision)
				
		if collider == paddle:
			bounce_ball(collision)
			
		if collider == death_wall:
			reset_ball()
			
		if bricks == collider:
			collide_brick(collision)
			
	paddle.move_and_collide(paddle.velocity * delta)

func _unhandled_input(event) -> void:
	paddle.velocity.x = BASE_PADDLE_VELOCITY * (Input.get_action_strength("move_right") - Input.get_action_strength("move_left"))
	
func kick_ball() -> void:
	print("kick")
	ball.velocity = Vector2(1,0).rotated(randf_range(-PI /3, -PI * 2 / 3)) * BASE_BALL_VELOCITY
	
func bounce_ball(collision: KinematicCollision2D) -> void:
	print("bounce")
	var normal = collision.get_normal().normalized()
	var dot = abs(normal.dot(ball.velocity))
	ball.velocity += normal * dot * (1 + BALL_BOUNCE_ACCELERATION_SCALE) # speed up in the reflected direction only
	ball.velocity += collision.get_collider_velocity()
	if ball.velocity.length() > MAX_BALL_SPEED:
		ball.velocity = ball.velocity.normalized() * MAX_BALL_SPEED

func reset_ball() -> void:
	print("reset")
	
	ball.velocity = Vector2.ZERO
	ball.position = ball_spawn_point.position
	
	var kick_timer = Timer.new()
	ball.add_child(kick_timer)
	kick_timer.start(KICK_DELAY_SEC)
	var timeout_lambda = func ():
		self.kick_ball()
		ball.remove_child(kick_timer)
	kick_timer.connect("timeout", timeout_lambda)

func collide_brick(collision: KinematicCollision2D) -> void:
	print("brick hit")
	bounce_ball(collision)
	var pos = collision.get_position()
	var cell_coords = bricks.local_to_map(bricks.to_local(pos))
	print(cell_coords)
	bricks.erase_cell(cell_coords)
