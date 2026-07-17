class_name EventChoiceData
extends Resource
## One selectable option inside an EventData. Deliberately generic — no
## event-specific fields — so new events add choices by filling in
## resources, never by touching EventManager, EventPopup, or Main.

## Button text shown to the player.
@export var label: String = ""
## What happens when this choice is picked. Null = nothing happens beyond
## closing the popup — e.g. "drive on" needs no EventResult at all.
@export var result: EventResult
