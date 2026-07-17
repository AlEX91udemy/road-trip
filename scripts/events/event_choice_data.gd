class_name EventChoiceData
extends Resource
## One selectable option inside an EventData. Deliberately generic — no
## event-specific fields, no consequences beyond text — so new events add
## choices by filling in a resource, never by touching EventManager or the
## event popup script.

## Button text shown to the player.
@export var label: String = ""
## Optional line shown in place of the description after this choice is
## picked (e.g. "Спасибо."). Empty = the popup just closes.
@export var message: String = ""
