class_name GasStation
extends Node2D
## Roadside gas station — the current trip goal, placed in the world by Main.
##
## Dumb by design, like RoadChunk: it renders itself, shows a refuel hint
## while the player's car is inside its trigger zone, and emits intents.
## It never touches fuel or money — Main routes refuel_requested to the
## GameManager, and `passed` tells Main to advance the goal and spawn the
## next station further down the road.

## The player pressed the refuel action inside the trigger zone.
signal refuel_requested
## The player has driven past this station (left the zone on the far side).
signal passed

## Label shown while the player can refuel here.
@export var hint_label: Label
## Zone around the pumps; only the player's hitbox layer can trigger it.
@export var trigger: Area2D

const ACTION_REFUEL := "refuel"

var _player_inside := false

func _ready() -> void:
	hint_label.text = "E — refuel (%s)" % UiFormat.money_text(GameManager.REFUEL_COST)
	hint_label.visible = false
	trigger.area_entered.connect(_on_trigger_area_entered)
	trigger.area_exited.connect(_on_trigger_area_exited)


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed(ACTION_REFUEL):
		refuel_requested.emit()


func _on_trigger_area_entered(_area: Area2D) -> void:
	_player_inside = true
	hint_label.visible = true


func _on_trigger_area_exited(area: Area2D) -> void:
	_player_inside = false
	hint_label.visible = false
	if area.global_position.x > global_position.x:
		passed.emit()
