class_name TrafficManager
extends Node2D
## Spawns oncoming TrafficCars ahead of the view and recycles them once they
## have driven past, mirroring RoadManager's design: it watches a generic
## "view anchor" (the camera), takes instances from a NodePool child, and
## never talks to the player or the HUD. Collisions are the player's problem;
## this system only places cars on lanes.
##
## Fairness rule: a spawn is skipped unless it would leave at least one lane
## free within clear_gap of the spawn point, so an undodgeable wall of cars
## can never appear (assuming similar cruise speeds, which Day 1 traffic has).

## Pool providing TrafficCar instances (child node; owns the car scene).
@export var pool: NodePool
## The node whose x-position drives spawning — typically the active Camera2D.
@export var view_anchor: Node2D
## Lane geometry shared with the player via the same LaneSet resource.
@export var lanes: LaneSet
## How far ahead of the anchor new cars appear, in pixels (off-screen right).
@export var spawn_ahead := 900.0
## How far behind the anchor passed cars are recycled, in pixels.
@export var despawn_behind := 700.0
## Seconds between spawn attempts, re-rolled in this range every attempt.
@export var spawn_interval_min := 0.8
@export var spawn_interval_max := 1.8
## Cruise speed range for spawned cars, in px/s.
@export var cruise_speed_min := 130.0
@export var cruise_speed_max := 220.0
## Window around the spawn point that must keep at least one free lane, px.
@export var clear_gap := 280.0

var _active: Array[TrafficCar] = []
var _cooldown := 1.0  # small grace period before the first car appears

func _physics_process(delta: float) -> void:
	if view_anchor == null or pool == null or lanes == null:
		return
	var anchor_x := to_local(view_anchor.global_position).x

	_despawn_passed(anchor_x)

	_cooldown -= delta
	if _cooldown <= 0.0:
		_cooldown = randf_range(spawn_interval_min, spawn_interval_max)
		_try_spawn(anchor_x + spawn_ahead)


func _try_spawn(spawn_x: float) -> void:
	var lane := _pick_fair_lane(spawn_x)
	if lane < 0:
		return  # skipping keeps the road dodgeable; next attempt re-rolls
	var car := pool.acquire() as TrafficCar
	add_child(car)
	car.setup(lane, lanes.y_of(lane), spawn_x, randf_range(cruise_speed_min, cruise_speed_max))
	_active.push_back(car)


## Picks a random lane among those free around spawn_x — but only if the spawn
## would still leave another lane free, otherwise returns -1 (skip).
func _pick_fair_lane(spawn_x: float) -> int:
	var free_lanes: Array[int] = []
	for lane in lanes.count():
		if _lane_is_clear(lane, spawn_x):
			free_lanes.push_back(lane)
	if free_lanes.size() <= 1:
		return -1
	return free_lanes.pick_random()


func _lane_is_clear(lane: int, spawn_x: float) -> bool:
	for car in _active:
		if car.lane_index == lane and absf(car.position.x - spawn_x) < clear_gap:
			return false
	return true


func _despawn_passed(anchor_x: float) -> void:
	# Iterate backwards so releasing while iterating stays safe.
	for i in range(_active.size() - 1, -1, -1):
		var car := _active[i]
		if car.position.x < anchor_x - despawn_behind:
			_active.remove_at(i)
			pool.release(car)
