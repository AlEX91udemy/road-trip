class_name FuelGauge
extends HBoxContainer
## Segmented fuel gauge: a fixed row of blocks that fill and color
## according to the current fuel percentage. Pure presentation, like the
## rest of the HUD — Hud only ever calls set_percent(); sizing, segment
## count and coloring live entirely here.

@export var segment_count := 10
@export var segment_size := Vector2(9, 14)
## Below this percent the gauge reads critical (red). Purely a visual
## threshold — matches PlayerCar's low_fuel_threshold by convention only;
## this script has no reference to PlayerCar or GameManager.
@export_range(0.0, 100.0) var low_threshold := 15.0

const COLOR_EMPTY := Color(0.16, 0.16, 0.19, 1.0)
const COLOR_CRITICAL := Color(0.86, 0.32, 0.28, 1.0)
const COLOR_LOW := Color(0.92, 0.72, 0.3, 1.0)
const COLOR_HEALTHY := Color(0.42, 0.8, 0.44, 1.0)

var _segments: Array[ColorRect] = []

func _ready() -> void:
	add_theme_constant_override("separation", 2)
	for i in segment_count:
		var seg := ColorRect.new()
		seg.custom_minimum_size = segment_size
		seg.color = COLOR_EMPTY
		add_child(seg)
		_segments.append(seg)


func set_percent(percent: float) -> void:
	var lit := int(round(percent / 100.0 * segment_count))
	var color := _color_for(percent)
	for i in _segments.size():
		_segments[i].color = color if i < lit else COLOR_EMPTY


func _color_for(percent: float) -> Color:
	if percent <= low_threshold:
		return COLOR_CRITICAL
	if percent <= low_threshold * 2.0:
		return COLOR_LOW
	return COLOR_HEALTHY
