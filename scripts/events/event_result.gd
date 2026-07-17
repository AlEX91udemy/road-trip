class_name EventResult
extends Resource
## The gameplay consequence of picking one EventChoice. Deliberately just a
## flat bundle of optional effects — no scripting, no branching, no chained
## consequences. New effect types get added here only when an event
## actually needs one, never speculatively.

## Text shown to the player describing what happened. Empty = no message.
@export var show_message: String = ""
## Money change applied when this result is applied. 0 = no effect.
@export var money_delta: int = 0
## Fuel change (percent) applied when this result is applied. 0 = no effect.
@export var fuel_delta: float = 0.0
