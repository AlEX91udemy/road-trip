class_name EventManager
extends Node
## Registers and selects roadside events, and dispatches the chosen one.
## Owns only "WHICH event should fire" — never "WHEN to check". The caller
## decides when attempt_trigger() is worth calling, and on what basis
## (distance, real time, entering a region, passing a gas station, a
## scripted story beat...) — EventManager has no opinion and no knowledge
## of any of that, so wiring up a new trigger source never touches this
## script.
##
## Adding new event content is purely data: create a new EventData resource
## (its own .tres) and add it to the `events` array in the scene. This
## script never needs to change either way.

## An event was selected and should be shown to the player.
signal event_triggered(event: EventData)

## Registered event pool — the "registration" step. Filled in the scene;
## nothing here inspects what any individual event contains.
@export var events: Array[EventData] = []

var _active := false
var _attempts := 0
var _last_triggered_attempt: Dictionary = {}  # EventData -> _attempts value when it last fired

## Ask the manager to try firing an event right now. Safe to call as often
## as the caller likes: the busy guard and each event's cooldown make an
## unproductive call a harmless no-op.
func attempt_trigger() -> void:
	_attempts += 1
	if _active or events.is_empty():
		return
	_select_and_fire()


## Called once the player has resolved the current event's choice —
## re-arms the manager so a future attempt_trigger() can fire again.
func complete_event() -> void:
	_active = false


func _select_and_fire() -> void:
	var eligible: Array[EventData] = []
	for event in events:
		var last_attempt = _last_triggered_attempt.get(event)
		if last_attempt != null and _attempts - last_attempt < event.cooldown:
			continue
		if randf() < event.chance:
			eligible.append(event)
	if eligible.is_empty():
		return

	var chosen: EventData = eligible.pick_random()
	_active = true
	_last_triggered_attempt[chosen] = _attempts
	event_triggered.emit(chosen)
