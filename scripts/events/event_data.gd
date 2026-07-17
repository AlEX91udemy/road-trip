class_name EventData
extends Resource
## Data for one roadside event: what the player sees, how likely/often it
## is to fire, and the choices they can make. New content is added by
## creating a new EventData resource (its own .tres file) and registering
## it with EventManager — the manager and the popup never change.

## Short heading shown at the top of the event popup.
@export var title: String = ""
## Body text describing the situation.
@export var description: String = ""
## Probability this event fires each time EventManager checks (0..1).
@export_range(0.0, 1.0) var chance: float = 0.2
## Minimum distance (meters) that must pass before this same event can fire
## again.
@export var cooldown: float = 500.0
## Selectable outcomes. The popup builds one button per entry.
@export var choices: Array[EventChoiceData] = []
