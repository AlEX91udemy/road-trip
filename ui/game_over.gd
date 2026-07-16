class_name GameOverScreen
extends CanvasLayer
## Game-over overlay. Pure presentation like the HUD: Main opens it with the
## final distance and it emits restart_requested when the player asks to go
## again — it never touches the scene tree, pause state or game systems.
##
## The scene sets process_mode = ALWAYS so the restart action still reaches
## it while the tree is paused.

## The player pressed the restart action while this screen was open.
signal restart_requested

@export var distance_label: Label

const ACTION_RESTART := "restart"

func _ready() -> void:
	visible = false


## Called by Main (via GameManager.run_ended) with the final run distance.
func open(distance_m: float) -> void:
	distance_label.text = "You drove %s" % UiFormat.distance_text(distance_m)
	visible = true


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(ACTION_RESTART):
		restart_requested.emit()
