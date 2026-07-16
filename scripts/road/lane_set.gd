class_name LaneSet
extends Resource
## The single source of truth for the road's driving lanes.
##
## Shared as one .tres by everything lane-aware (player lane switching,
## traffic spawning), so lane geometry can never drift apart between systems.
## Values are world-space Y baselines — the line a car's wheels sit on —
## ordered top (far) to bottom (near). They match the lane separators drawn
## into road.png by tools/generate_placeholder_art.py.

## Wheel-contact Y for each lane, topmost lane first.
@export var lane_ys := PackedFloat32Array([290.0, 317.0, 344.0])

func count() -> int:
	return lane_ys.size()


## Baseline Y of a lane; index is clamped so callers can't escape the road.
func y_of(index: int) -> float:
	return lane_ys[clampi(index, 0, lane_ys.size() - 1)]
