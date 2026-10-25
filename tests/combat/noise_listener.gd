## Records the radius of every noise it hears. Helper for the noise tests.

extends Node

var sink: Array[float] = []


func hear_noise(_position: Vector3, radius: float) -> void:
	sink.append(radius)
