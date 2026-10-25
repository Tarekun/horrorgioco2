## Generates the placeholder audio: footstep variants and a looping ambient drone.
##
## Everything is synthesized from noise and sine waves with a fixed seed, so the
## output is reproducible and has no third-party content. The WAV files are
## committed; rerun this only to change the placeholders.
## Run with: godot --headless --path . --script res://tools/generate_placeholder_audio.gd
extends SceneTree

const OUTPUT_DIR: String = "res://assets/audio/"
const MIX_RATE: int = 22050
const FOOTSTEP_VARIANTS: int = 3
const FOOTSTEP_SECONDS: float = 0.22
const AMBIENCE_SECONDS: float = 16.0
const AMBIENCE_CROSSFADE_SECONDS: float = 2.0


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1903
	var is_ok: bool = true
	for variant in FOOTSTEP_VARIANTS:
		var samples := _footstep(rng, 700.0 + 350.0 * variant)
		is_ok = _save("footstep_%d.wav" % (variant + 1), samples, false) and is_ok
	is_ok = _save("ambience_drone.wav", _ambience(rng), true) and is_ok
	quit(0 if is_ok else 1)


## A dull thump: lowpassed noise with a fast decay plus a low sine body.
func _footstep(rng: RandomNumberGenerator, cutoff_hz: float) -> PackedFloat32Array:
	var count: int = int(FOOTSTEP_SECONDS * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var coefficient: float = 1.0 - exp(-TAU * cutoff_hz / MIX_RATE)
	var filtered: float = 0.0
	for i in count:
		var t: float = float(i) / MIX_RATE
		filtered += coefficient * (rng.randf_range(-1.0, 1.0) - filtered)
		var envelope: float = exp(-t * 28.0)
		var body: float = sin(TAU * 85.0 * t) * exp(-t * 18.0)
		samples[i] = (filtered * 1.6 * envelope + body * 0.5) * minf(t * 800.0, 1.0)
	return samples


## A dark drone of low sines and slow, soft noise. The sine frequencies fit a
## whole number of cycles in the clip and the noise is crossfaded, so it loops
## without a click.
func _ambience(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(AMBIENCE_SECONDS * MIX_RATE)
	var fade: int = int(AMBIENCE_CROSSFADE_SECONDS * MIX_RATE)
	var raw := PackedFloat32Array()
	raw.resize(count + fade)
	var filtered: float = 0.0
	var coefficient: float = 1.0 - exp(-TAU * 180.0 / MIX_RATE)
	for i in raw.size():
		filtered += coefficient * (rng.randf_range(-1.0, 1.0) - filtered)
		raw[i] = filtered

	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var noise: float = raw[i]
		if i < fade:
			var weight: float = float(i) / fade
			noise = raw[i] * weight + raw[i + count] * (1.0 - weight)
		var t: float = float(i) / MIX_RATE
		var swell: float = 0.75 + 0.25 * sin(TAU * t / AMBIENCE_SECONDS * 2.0)
		var tone: float = (
			sin(TAU * 55.0 * t) * 0.5
			+ sin(TAU * 82.5 * t + 1.3) * 0.3
			+ sin(TAU * 110.0 * t + 0.4) * 0.15
		)
		samples[i] = (tone * swell + noise * 2.5) * 0.45
	return samples


func _save(file_name: String, samples: PackedFloat32Array, is_loop: bool) -> bool:
	var peak: float = 0.0001
	for value in samples:
		peak = maxf(peak, absf(value))
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] / peak * 0.8, -1.0, 1.0) * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	stream.data = data
	if is_loop:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = samples.size()
	var error: int = stream.save_to_wav(OUTPUT_DIR + file_name)
	if error != OK:
		printerr("Failed to write %s (error %d)" % [file_name, error])
		return false
	print("Wrote %s%s" % [OUTPUT_DIR, file_name])
	return true
