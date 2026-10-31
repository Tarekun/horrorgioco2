## A phone to look at (Luca's, in room 22): no signal, and a battery a little
## lower each time he looks.
##
## A line with `{battery}` in it shows the battery's percentage, then the
## battery drops by `drain`, never below `min_battery`: it runs down too fast
## and never quite dies. The battery isn't saved; a loaded save finds it where
## it started.

class_name PhoneExaminable
extends Examinable

## The placeholder a line uses for the battery's percentage.
const BATTERY_TAG: String = "{battery}"

## Percentage at the first look.
@export_range(0, 100) var battery: int = 9

## Percentage points lost each time the battery is read.
@export_range(0, 100) var drain: int = 1

## Lowest percentage it shows.
@export_range(0, 100) var min_battery: int = 1


func _show_line(line: String) -> String:
	if not line.contains(BATTERY_TAG):
		return line
	var shown: String = line.replace(BATTERY_TAG, str(battery))
	battery = maxi(battery - drain, min_battery)
	return shown
