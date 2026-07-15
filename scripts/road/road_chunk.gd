class_name RoadChunk
extends Node2D
## One pooled segment of road. Dumb by design: it renders its strip of
## asphalt and offers "roadside slots" (Marker2D positions) where future
## systems (gas stations, signs, trees, events) can attach content.

## Width of this chunk in pixels. RoadManager uses it to lay chunks
## seamlessly end to end. Must match the visual width of the Surface sprite.
@export var width := 512.0
## Container of Marker2D slots for future roadside objects.
@export var roadside_slots: Node2D

## Sequential index assigned on spawn; lets Day 2 systems seed deterministic
## content per chunk ("a gas station every N chunks").
var chunk_index := -1

## Called by RoadManager every time this chunk (re-)enters the world.
func setup(index: int) -> void:
	chunk_index = index


## Remove anything that was attached to the roadside slots, so a recycled
## chunk always re-enters the pool clean. Safe no-op on Day 1.
func clear_decorations() -> void:
	if roadside_slots == null:
		return
	for slot in roadside_slots.get_children():
		for decoration in slot.get_children():
			decoration.queue_free()
