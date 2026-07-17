class_name EventManager
extends Node
## Registers, selects, triggers and completes roadside events as the player
## drives. Contains no gameplay logic of its own — applying a choice's
## consequences (money, story flags, anything) is the caller's job, wired
## through Main like every other system; this script only ever decides
## *when* and *which* EventData fires.
##
## Adding new content is purely data: create a new EventData resource (its
## own .tres) and add it to the `events` array in the scene. This script
## never needs to change.

## An event was selected and should be shown to the player.
signal event_triggered(event: EventData)

## Registered event pool — the "registration" step. Filled in the scene;
## nothing here inspects what any individual event contains.
@export var events: Array[EventData] = []
## How often (in meters travelled) the manager re-evaluates whether an
## event should fire.
@export var check_interval_m := 50.0

var _active := false
var _distance_m := 0.0
var _last_check_m := 0.0
var _last_triggered_m: Dictionary = {}  # EventData -> distance it last fired at

## Fed the player's distance telemetry by Main — the same signal that
## drives fuel burn.
func report_distance(distance_m: float) -> void:
	_distance_m = distance_m
	if _active or events.is_empty():
		return
	if _distance_m - _last_check_m < check_interval_m:
		return
	_last_check_m = _distance_m
	_try_trigger()


## Called once the player has resolved the current event's choice —
## the completion step. Re-arms the manager for future checks.
func complete_event() -> void:
	_active = false


func _try_trigger() -> void:
	var eligible: Array[EventData] = []
	for event in events:
		var last_m: float = _last_triggered_m.get(event, -INF)
		if _distance_m - last_m < event.cooldown:
			continue
		if randf() < event.chance:
			eligible.append(event)
	if eligible.is_empty():
		return

	var chosen: EventData = eligible.pick_random()
	_active = true
	_last_triggered_m[chosen] = _distance_m
	event_triggered.emit(chosen)
