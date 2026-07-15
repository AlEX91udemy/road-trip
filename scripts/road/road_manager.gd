class_name RoadManager
extends Node2D
## Streams an endless road out of pooled RoadChunk instances.
##
## Decoupling: it watches a generic "view anchor" (the camera) instead of the
## player, spawning chunks ahead of it and recycling chunks behind it. It
## never talks to the player or the HUD. Day 2 systems (gas stations, props,
## traffic spawn points) subscribe to chunk_spawned / chunk_despawned and
## decorate chunks via their roadside slots — no changes needed here.
##
## Chunks come from a NodePool child, so scrolling forever allocates a fixed,
## small number of nodes: no churn, no leaks.

## A chunk became active at chunk.global_position. Decorators hook in here.
signal chunk_spawned(chunk: RoadChunk)
## A chunk is about to be recycled; anything attached to it must let go now.
signal chunk_despawned(chunk: RoadChunk)

## Pool providing RoadChunk instances (child node; owns the chunk scene).
@export var pool: NodePool
## The node whose x-position drives streaming — typically the active Camera2D.
@export var view_anchor: Node2D
## How far ahead of the anchor the road must always exist, in pixels.
@export var spawn_ahead := 1000.0
## How far behind the anchor chunks are kept before recycling, in pixels.
@export var keep_behind := 600.0

var _active_chunks: Array[RoadChunk] = []
var _next_spawn_x := 0.0  # local x where the next chunk starts
var _chunk_index := 0     # monotonically increasing id, useful for Day 2 seeding
var _initialized := false

func _process(_delta: float) -> void:
	if view_anchor == null or pool == null:
		return
	var anchor_x := to_local(view_anchor.global_position).x

	if not _initialized:
		_initialized = true
		_next_spawn_x = anchor_x - keep_behind

	# Guarantee road coverage ahead of the view...
	while _next_spawn_x < anchor_x + spawn_ahead:
		_spawn_chunk()
	# ...and recycle everything that fell far enough behind it.
	while not _active_chunks.is_empty() and _chunk_end_x(_active_chunks[0]) < anchor_x - keep_behind:
		_despawn_oldest()


func _spawn_chunk() -> void:
	var chunk := pool.acquire() as RoadChunk
	add_child(chunk)
	chunk.position = Vector2(_next_spawn_x, 0.0)
	chunk.setup(_chunk_index)
	_next_spawn_x += chunk.width
	_chunk_index += 1
	_active_chunks.push_back(chunk)
	chunk_spawned.emit(chunk)


func _despawn_oldest() -> void:
	var chunk: RoadChunk = _active_chunks.pop_front()
	chunk_despawned.emit(chunk)          # listeners detach their content first
	chunk.clear_decorations()            # then drop anything left behind
	pool.release(chunk)


func _chunk_end_x(chunk: RoadChunk) -> float:
	return chunk.position.x + chunk.width
