class_name TrafficCar
extends Area2D
## One oncoming vehicle. Dumb by design, like RoadChunk: it drives left at a
## cruise speed assigned on spawn and renders itself; TrafficManager owns
## spawning, pooling and despawning. Collision is one-way — the player's
## hitbox monitors this Area2D (layer "traffic"), so this script never needs
## to know the player exists.
##
## Reuses MovementComponent as its drivetrain (the Day 2 extension point the
## component was built for): spawn pre-sets speed = max_speed = cruise, so the
## car enters the screen already at cruising pace and holds it.

## The drivetrain component, same one the player uses.
@export var movement: MovementComponent
## Wheel sprites, spun according to speed (negative: the car drives left).
@export var front_wheel: Sprite2D
@export var back_wheel: Sprite2D
## Body sprite; its texture is re-rolled from body_variants on every spawn.
@export var body: Sprite2D
## Paint jobs to pick from (generated traffic_body_*.png textures).
@export var body_variants: Array[Texture2D] = []
## Visual wheel radius in pixels (used to convert speed into spin rate).
@export var wheel_radius_px := 6.0

## Lane this car occupies; TrafficManager uses it for fair spawn spacing.
var lane_index := -1

## Called by TrafficManager every time this car (re-)enters the world.
func setup(lane: int, lane_y: float, spawn_x: float, cruise_speed: float) -> void:
	lane_index = lane
	position = Vector2(spawn_x, lane_y)
	# Lower lanes are closer to the viewer, so draw over cars in upper lanes.
	z_index = int(lane_y)
	movement.max_speed = cruise_speed
	movement.speed = cruise_speed  # already cruising when it enters the screen
	movement.set_throttle(1.0)
	if not body_variants.is_empty():
		body.texture = body_variants.pick_random()


func _physics_process(delta: float) -> void:
	if movement == null:
		return
	var speed_px := movement.step(delta)
	# Oncoming lane: world-left, toward the player.
	position.x -= speed_px * delta
	_spin_wheels(-speed_px, delta)


func _spin_wheels(speed_px: float, delta: float) -> void:
	var spin := (speed_px / wheel_radius_px) * delta  # radians: v = ω·r
	for wheel in [front_wheel, back_wheel]:
		if wheel != null:
			wheel.rotation += spin
