class_name NodePool
extends Node
## Generic object pool for scene instances. Used by RoadManager for road
## chunks today; reusable as-is for Day 2 traffic cars, roadside props, etc.
##
## Leak-free by design: released instances are re-parented UNDER this node
## (hidden, processing disabled) instead of floating detached in memory, so
## everything is freed automatically with the scene tree.

## The scene this pool instantiates.
@export var scene: PackedScene
## Instances created up-front to avoid first-use hitches.
@export var prewarm_count := 4

var _free_nodes: Array[Node] = []

func _ready() -> void:
	assert(scene != null, "NodePool needs a scene to instantiate.")
	for i in prewarm_count:
		_park(scene.instantiate())


## Take an instance out of the pool (or instantiate a fresh one if empty).
## The returned node has no parent; the caller add_child()s it where needed.
func acquire() -> Node:
	if _free_nodes.is_empty():
		return scene.instantiate()
	var node := _free_nodes.pop_back() as Node
	remove_child(node)
	node.process_mode = Node.PROCESS_MODE_INHERIT
	if node is CanvasItem:
		node.visible = true
	return node


## Return an instance to the pool for later reuse.
func release(node: Node) -> void:
	if node.get_parent() != null:
		node.get_parent().remove_child(node)
	_park(node)


## Store a node inside the pool: invisible, not processing, but still owned
## by the tree so it can never leak.
func _park(node: Node) -> void:
	node.process_mode = Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:
		node.visible = false
	add_child(node)
	_free_nodes.push_back(node)
