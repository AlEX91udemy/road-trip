class_name UiFormat
## Shared, stateless text formatting for UI values, so the HUD and the
## game-over screen can never drift apart on how numbers are displayed.

static func distance_text(distance_m: float) -> String:
	if distance_m < 1000.0:
		return "%.0f m" % distance_m
	return "%.2f km" % (distance_m / 1000.0)


static func speed_text(speed_kmh: float) -> String:
	return "%3.0f km/h" % speed_kmh
