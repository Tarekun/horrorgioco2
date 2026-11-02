## The area that sets off a TensionEvent: it emits `triggered` when the player
## enters it. Give it a CollisionShape3D child covering the room or stretch of
## corridor.
##
## It only watches the player's layer and is invisible to everything else.

class_name TensionTrigger
extends Area3D

## Emitted when the player sets it off.
signal triggered


func _ready() -> void:
	collision_layer = 0
	collision_mask = CombatLayers.PLAYER
	monitorable = false
	body_entered.connect(_on_body_entered)


## Stops watching for the player, once its event has fired.
func disarm() -> void:
	set_deferred(&"monitoring", false)


## Called with the player as it enters the area. Emits `triggered`.
func _on_player_entered(_player: Player) -> void:
	triggered.emit()


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player:
		_on_player_entered(player)
