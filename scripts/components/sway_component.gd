class_name SwayComponent
extends Node
## Adds a subtle vertical bob + tilt to a target Node2D while driving, so the
## car body feels alive on its suspension. Purely cosmetic and self-contained:
## feed it the current speed (usually by connecting a MovementComponent's
## speed_changed signal to set_speed) and it animates on its own.

## The node to sway — typically the car body sprite, NOT the whole car,
## so wheels stay planted on the road.
@export var target: Node2D
## Maximum vertical bob in pixels at full speed. Keep tiny for pixel art.
@export var max_offset := 1.5
## Maximum body tilt in degrees at full speed.
@export var max_tilt_deg := 1.2
## Bob oscillations per second at full speed.
@export var frequency := 8.0
## Speed (px/s) at which the sway reaches full amplitude.
@export var speed_for_full_sway := 350.0

var _time := 0.0
var _intensity := 0.0  # 0..1, driven by current speed
var _base_position := Vector2.ZERO
var _base_rotation := 0.0

func _ready() -> void:
	if target == null:
		push_warning("SwayComponent has no target assigned; disabling.")
		set_process(false)
		return
	_base_position = target.position
	_base_rotation = target.rotation


## Typically connected to MovementComponent.speed_changed.
func set_speed(speed: float) -> void:
	_intensity = clampf(absf(speed) / speed_for_full_sway, 0.0, 1.0)


func _process(delta: float) -> void:
	# Oscillate faster the quicker we drive; stand still => no sway.
	_time += delta * frequency * TAU * lerpf(0.4, 1.0, _intensity)
	var bob := sin(_time) * max_offset * _intensity
	var tilt := sin(_time * 0.6) * deg_to_rad(max_tilt_deg) * _intensity
	# Round the bob to whole pixels so the pixel-art body never renders "between" pixels.
	target.position = _base_position + Vector2(0.0, roundf(bob))
	target.rotation = _base_rotation + tilt
