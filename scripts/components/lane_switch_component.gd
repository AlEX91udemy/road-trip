class_name LaneSwitchComponent
extends Node
## Reusable lane-changing logic: holds a discrete lane index on a LaneSet and
## eases the owner's Y toward that lane's baseline at a constant speed.
##
## Same contract as MovementComponent: knows nothing about input or the scene
## tree. The owner requests moves (from input today, from AI later) and calls
## step() from its own _physics_process, applying the returned Y itself.

## Emitted when the *target* lane changes (the glide to it may still be running).
signal lane_changed(index: int)

## Lane geometry shared with every other lane-aware system.
@export var lanes: LaneSet
## Lane the owner starts in (clamped to the LaneSet).
@export var start_index := 1
## Vertical glide speed between lanes, in px/s.
@export var switch_speed := 110.0

## Current target lane index. Read-only for owners; write via move_up/down.
var lane_index := 0

var _y := 0.0

func _ready() -> void:
	if lanes == null or lanes.count() == 0:
		push_error("LaneSwitchComponent needs a LaneSet with at least one lane.")
		return
	lane_index = clampi(start_index, 0, lanes.count() - 1)
	_y = lanes.y_of(lane_index)


## Move one lane up (toward the top of the screen). Clamped at the edge.
func move_up() -> void:
	_set_lane(lane_index - 1)


## Move one lane down (toward the bottom of the screen). Clamped at the edge.
func move_down() -> void:
	_set_lane(lane_index + 1)


## Advance the glide by delta seconds; returns the Y the owner should be at.
func step(delta: float) -> float:
	if lanes != null:
		_y = move_toward(_y, lanes.y_of(lane_index), switch_speed * delta)
	return _y


func _set_lane(index: int) -> void:
	var clamped := clampi(index, 0, lanes.count() - 1)
	if clamped == lane_index:
		return
	lane_index = clamped
	lane_changed.emit(lane_index)
