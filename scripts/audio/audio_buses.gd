## Names of the audio buses defined in default_bus_layout.tres.

class_name AudioBuses
extends RefCounted

const MASTER: StringName = &"Master"
const MUSIC: StringName = &"Music"
const AMBIENCE: StringName = &"Ambience"
const SFX: StringName = &"SFX"
const UI: StringName = &"UI"

## Every bus except Master, in layout order.
const ALL: Array[StringName] = [MUSIC, AMBIENCE, SFX, UI]
