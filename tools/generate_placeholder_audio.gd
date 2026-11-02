## Generates the placeholder audio: footstep variants, a looping ambient drone, a
## heartbeat, a heavy breath, the main switch being thrown, the lift machinery
## groaning awake, the slide down the rubble chute, and the sounds of the
## hotel's tension events (docs/design/slice.md): a running shower, a ringing
## phone, cutlery, a creak, a gust of wind, a draught like the sea, a buzzing
## lamp, footsteps on the floor above, swinging hangers, a simmering pot and
## rustling fabric.
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
const HEARTBEAT_SECONDS: float = 0.9
const BREATH_SECONDS: float = 2.2
const SWITCH_SECONDS: float = 0.7
const GROAN_SECONDS: float = 4.5
## Crossfade (seconds) that hides the seam of the looping tension sounds.
const LOOP_CROSSFADE_SECONDS: float = 0.5
const SLIDE_SECONDS: float = 2.2
## When the slide lands in the skip, in seconds from its start.
const SLIDE_LANDING_SECONDS: float = 1.7
const SHUTTER_SECONDS: float = 3.3


func _init() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1903
	var is_ok: bool = true
	for variant in FOOTSTEP_VARIANTS:
		var samples := _footstep(rng, 700.0 + 350.0 * variant)
		is_ok = _save("footstep_%d.wav" % (variant + 1), samples, false) and is_ok
	is_ok = _save("ambience_drone.wav", _ambience(rng), true) and is_ok
	is_ok = _save("heartbeat.wav", _heartbeat(rng), false) and is_ok
	is_ok = _save("breath_heavy.wav", _breath(rng), false) and is_ok
	is_ok = _save("switch_thrown.wav", _switch_thrown(rng), false) and is_ok
	is_ok = _save("machinery_groan.wav", _machinery_groan(rng), false) and is_ok
	is_ok = _save("shower_running.wav", _shower(rng), true) and is_ok
	is_ok = _save("phone_ring.wav", _phone_ring(), true) and is_ok
	var clinks: Array[float] = [0.0, 0.28]
	is_ok = _save("cutlery_clink.wav", _clinks(rng, clinks, 2600.0, 0.8), false) and is_ok
	is_ok = _save("creak.wav", _creak(rng), false) and is_ok
	is_ok = _save("wind_gust.wav", _gust(rng), false) and is_ok
	is_ok = _save("sea_draught.wav", _sea(rng), true) and is_ok
	is_ok = _save("lamp_buzz.wav", _buzz(rng), false) and is_ok
	is_ok = _save("footsteps_above.wav", _steps_above(rng), false) and is_ok
	var knocks: Array[float] = [0.0, 0.18, 0.31, 0.55, 0.72, 1.02]
	is_ok = _save("hangers.wav", _clinks(rng, knocks, 1800.0, 1.4), false) and is_ok
	is_ok = _save("pot_simmer.wav", _simmer(rng), true) and is_ok
	is_ok = _save("fabric_rustle.wav", _rustle(rng), false) and is_ok
	# Last, so the sounds above keep their random numbers.
	is_ok = _save("chute_slide.wav", _slide(rng), false) and is_ok
	is_ok = _save("shutter_rattle.wav", _shutter_rattle(rng), false) and is_ok
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


## Two dull thumps ("lub-dub"): a low sine that drops in pitch, with a soft tick
## of lowpassed noise on the attack.
func _heartbeat(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(HEARTBEAT_SECONDS * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var coefficient: float = 1.0 - exp(-TAU * 220.0 / MIX_RATE)
	var filtered: float = 0.0
	for beat in 2:
		var start: int = int((0.0 if beat == 0 else 0.3) * MIX_RATE)
		var gain: float = 1.0 if beat == 0 else 0.7
		var phase: float = 0.0
		for i in count - start:
			var t: float = float(i) / MIX_RATE
			phase += TAU * (45.0 + 30.0 * exp(-t * 30.0)) / MIX_RATE
			filtered += coefficient * (rng.randf_range(-1.0, 1.0) - filtered)
			var body: float = sin(phase) * exp(-t * 16.0)
			var tick: float = filtered * exp(-t * 60.0) * 1.5
			samples[start + i] += (body + tick) * gain * minf(t * 600.0, 1.0)
	return samples


## One heavy breath: an inhale that swells and an exhale that fades, both
## filtered noise, with a short pause between.
func _breath(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(BREATH_SECONDS * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var fast: float = 1.0 - exp(-TAU * 1400.0 / MIX_RATE)
	var slow: float = 1.0 - exp(-TAU * 250.0 / MIX_RATE)
	var low: float = 0.0
	var band: float = 0.0
	for i in count:
		var t: float = float(i) / MIX_RATE
		low += fast * (rng.randf_range(-1.0, 1.0) - low)
		band += slow * (low - band)
		var inhale: float = sin(PI * clampf(t / 0.7, 0.0, 1.0))
		var exhale: float = sin(PI * clampf((t - 0.95) / 1.1, 0.0, 1.0)) * 0.8
		samples[i] = (low - band) * (inhale * inhale + exhale * exhale) * 2.0
	return samples


## A heavy lever slammed home: a sharp metal clack of bright noise and two
## ringing partials over a low thump, then the relays clicking in.
func _switch_thrown(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(SWITCH_SECONDS * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		var t: float = float(i) / MIX_RATE
		var clack: float = rng.randf_range(-1.0, 1.0) * exp(-t * 90.0)
		var ring: float = (
			(sin(TAU * 410.0 * t) * 0.6 + sin(TAU * 1130.0 * t) * 0.3) * exp(-t * 14.0)
		)
		var thump: float = sin(TAU * 70.0 * t) * exp(-t * 20.0)
		samples[i] = (clack + ring * 0.5 + thump * 0.8) * minf(t * 2000.0, 1.0)
	for relay in 3:
		var start: int = int((0.28 + 0.09 * relay) * MIX_RATE)
		for i in mini(int(0.03 * MIX_RATE), count - start):
			var t: float = float(i) / MIX_RATE
			samples[start + i] += rng.randf_range(-1.0, 1.0) * exp(-t * 250.0) * 0.4
	return samples


## Old machinery starting behind a wall: a low motor tone that winds up in
## pitch and loudness, a rumble of filtered noise and a slow mechanical tick.
func _machinery_groan(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(GROAN_SECONDS * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var coefficient: float = 1.0 - exp(-TAU * 120.0 / MIX_RATE)
	var rumble: float = 0.0
	var phase: float = 0.0
	for i in count:
		var t: float = float(i) / MIX_RATE
		var progress: float = t / GROAN_SECONDS
		phase += TAU * (28.0 + 30.0 * minf(progress * 1.6, 1.0)) / MIX_RATE
		rumble += coefficient * (rng.randf_range(-1.0, 1.0) - rumble)
		var motor: float = sin(phase) * 0.6 + sin(phase * 2.0 + 0.7) * 0.3 + sin(phase * 3.0) * 0.15
		var swell: float = minf(t * 1.5, 1.0) * minf((GROAN_SECONDS - t) * 1.2, 1.0)
		var tick_time: float = fmod(t, 0.42)
		var tick: float = rng.randf_range(-1.0, 1.0) * exp(-tick_time * 180.0) * progress
		samples[i] = (motor + rumble * 3.0 + tick * 0.5) * swell
	return samples


## A shower running behind a door: bright hiss with the patter of drops.
func _shower(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var raw := PackedFloat32Array()
	raw.resize(int((4.0 + LOOP_CROSSFADE_SECONDS) * MIX_RATE))
	var low: float = 0.0
	var coefficient: float = 1.0 - exp(-TAU * 900.0 / MIX_RATE)
	var drop: float = 0.0
	for i in raw.size():
		var noise: float = rng.randf_range(-1.0, 1.0)
		low += coefficient * (noise - low)
		if rng.randf() < 0.004:
			drop = rng.randf_range(0.3, 1.0)
		drop *= 0.996
		raw[i] = (noise - low) * 0.6 + low * 0.4 + rng.randf_range(-1.0, 1.0) * drop * 0.5
	return _loop(raw)


## An old room phone: two bursts of a clapper on two bells, then silence.
func _phone_ring() -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(4.0 * MIX_RATE))
	for burst: float in [0.0, 0.6]:
		var start: int = int(burst * MIX_RATE)
		for strike in 9:
			var offset: int = start + int(strike * MIX_RATE / 20.0)
			for i in int(0.12 * MIX_RATE):
				var t: float = float(i) / MIX_RATE
				var bell: float = sin(TAU * 1250.0 * t) + 0.7 * sin(TAU * 1510.0 * t)
				bell += 0.3 * sin(TAU * 3410.0 * t)
				samples[offset + i] += bell * exp(-t * 30.0)
	return samples


## Small metallic knocks at `times` (seconds): inharmonic partials over `base_hz`
## with a fast decay, each a little quieter than the one before.
func _clinks(
	rng: RandomNumberGenerator, times: Array[float], base_hz: float, seconds: float
) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	samples.resize(int(seconds * MIX_RATE))
	var gain: float = 1.0
	for time: float in times:
		var start: int = int(time * MIX_RATE)
		var pitch: float = base_hz * rng.randf_range(0.9, 1.15)
		for i in mini(int(0.25 * MIX_RATE), samples.size() - start):
			var t: float = float(i) / MIX_RATE
			var ring: float = sin(TAU * pitch * t) + 0.6 * sin(TAU * pitch * 2.76 * t)
			ring += 0.4 * sin(TAU * pitch * 5.4 * t)
			samples[start + i] += ring * exp(-t * 22.0) * gain
		gain *= 0.8
	return samples


## A slow wooden creak: a resonant body knocked by a stick-slip pulse train whose
## rate rises and falls.
func _creak(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var seconds: float = 1.6
	var count: int = int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var phase: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0
	var radius: float = 0.995
	var a1: float = 2.0 * radius * cos(TAU * 620.0 / MIX_RATE)
	for i in count:
		var t: float = float(i) / MIX_RATE
		phase += (35.0 + 55.0 * sin(PI * t / seconds)) / MIX_RATE
		var pulse: float = rng.randf_range(-0.05, 0.05)
		if phase >= 1.0:
			phase -= 1.0
			pulse += rng.randf_range(0.7, 1.0)
		var y: float = pulse + a1 * y1 - radius * radius * y2
		y2 = y1
		y1 = y
		samples[i] = y * sin(PI * t / seconds)
	return samples


## A gust of wind through a gap: low noise that swells and dies away.
func _gust(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var seconds: float = 4.0
	var count: int = int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var low: float = 0.0
	for i in count:
		var t: float = float(i) / MIX_RATE
		var swell: float = sin(PI * t / seconds)
		var cutoff: float = 300.0 + 900.0 * swell * swell
		low += (1.0 - exp(-TAU * cutoff / MIX_RATE)) * (rng.randf_range(-1.0, 1.0) - low)
		samples[i] = low * swell * swell
	return samples


## A cold draught that sounds like the sea: dark noise swelling like two slow
## waves, which fit the clip so it loops.
func _sea(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var seconds: float = 10.0
	var raw := PackedFloat32Array()
	raw.resize(int((seconds + LOOP_CROSSFADE_SECONDS) * MIX_RATE))
	var low: float = 0.0
	var coefficient: float = 1.0 - exp(-TAU * 400.0 / MIX_RATE)
	for i in raw.size():
		low += coefficient * (rng.randf_range(-1.0, 1.0) - low)
		raw[i] = low
	var samples: PackedFloat32Array = _loop(raw)
	for i in samples.size():
		var wave: float = sin(PI * float(i) / MIX_RATE / (seconds / 2.0))
		samples[i] *= 0.35 + 0.65 * wave * wave
	return samples


## An old fitting buzzing as the lamps go: mains hum cut on and off, with hiss.
func _buzz(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(0.9 * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	# On from each even entry to the next odd one (seconds).
	var gates: Array[float] = [0.0, 0.12, 0.2, 0.33, 0.4, 0.62]
	for i in count:
		var t: float = float(i) / MIX_RATE
		var level: float = 0.05
		for k in range(0, gates.size(), 2):
			if t >= gates[k] and t < gates[k + 1]:
				level = 1.0
		var hum: float = 0.0
		for harmonic: int in [1, 2, 3, 5, 7]:
			hum += sin(TAU * 100.0 * harmonic * t) / harmonic
		var tail: float = exp(-maxf(t - 0.62, 0.0) * 20.0)
		samples[i] = (hum * 0.6 + rng.randf_range(-0.2, 0.2)) * level * tail
	return samples


## Unhurried, heavy footsteps heard through a floor: dull thumps, low-passed hard.
func _steps_above(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(5.6 * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var coefficient: float = 1.0 - exp(-TAU * 160.0 / MIX_RATE)
	for step in 7:
		var start: int = int((0.1 + step * 0.75) * MIX_RATE)
		var gain: float = 1.0 if step < 6 else 0.7
		var filtered: float = 0.0
		for i in mini(int(0.35 * MIX_RATE), count - start):
			var t: float = float(i) / MIX_RATE
			filtered += coefficient * (rng.randf_range(-1.0, 1.0) - filtered)
			var body: float = sin(TAU * 55.0 * t) * exp(-t * 14.0)
			samples[start + i] += (filtered * 3.0 * exp(-t * 20.0) + body) * gain
	return samples


## A pot simmering: a low rumble with bubbles that pop at random.
func _simmer(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var raw := PackedFloat32Array()
	raw.resize(int((6.0 + LOOP_CROSSFADE_SECONDS) * MIX_RATE))
	var low: float = 0.0
	var coefficient: float = 1.0 - exp(-TAU * 250.0 / MIX_RATE)
	for i in raw.size():
		low += coefficient * (rng.randf_range(-1.0, 1.0) - low)
		raw[i] = low * 0.8
	var samples: PackedFloat32Array = _loop(raw)
	var bubble: int = int(0.04 * MIX_RATE)
	for k in 70:
		var start: int = rng.randi_range(0, samples.size() - bubble - 1)
		var pitch: float = rng.randf_range(250.0, 600.0)
		var gain: float = rng.randf_range(0.2, 0.6)
		var phase: float = 0.0
		for i in bubble:
			var t: float = float(i) / MIX_RATE
			phase += TAU * pitch * (1.0 + t * 25.0) / MIX_RATE
			samples[start + i] += sin(phase) * sin(PI * t / 0.04) * gain
	return samples


## Fabric brushed and settling: bright noise in a few soft, uneven bursts.
func _rustle(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(1.5 * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var low: float = 0.0
	var coefficient: float = 1.0 - exp(-TAU * 1500.0 / MIX_RATE)
	# Each burst: start (seconds) and gain.
	var bursts: Array[Vector2] = [Vector2(0.05, 1.0), Vector2(0.35, 0.6), Vector2(0.8, 0.35)]
	for i in count:
		var t: float = float(i) / MIX_RATE
		var noise: float = rng.randf_range(-1.0, 1.0)
		low += coefficient * (noise - low)
		var envelope: float = 0.0
		for burst: Vector2 in bursts:
			var x: float = (t - burst.x) / 0.25
			if x > 0.0 and x < 1.0:
				envelope += sin(PI * x) * burst.y
		samples[i] = (noise - low) * envelope
	return samples


## Folds the last LOOP_CROSSFADE_SECONDS of `raw` over its start, so it loops
## without a click.
func _loop(raw: PackedFloat32Array) -> PackedFloat32Array:
	var fade: int = int(LOOP_CROSSFADE_SECONDS * MIX_RATE)
	var count: int = raw.size() - fade
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in count:
		samples[i] = raw[i]
		if i < fade:
			var weight: float = float(i) / fade
			samples[i] = raw[i] * weight + raw[i + count] * (1.0 - weight)
	return samples


## Sliding down a plastic rubble chute: a rushing scrape of filtered noise that speeds
## up, rattled by the joints between segments, then a crash into the rubble.
func _slide(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(SLIDE_SECONDS * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var hiss: float = 1.0 - exp(-TAU * 2200.0 / MIX_RATE)
	var rumble: float = 1.0 - exp(-TAU * 160.0 / MIX_RATE)
	var crash: float = 1.0 - exp(-TAU * 900.0 / MIX_RATE)
	var bright: float = 0.0
	var low: float = 0.0
	var rubble: float = 0.0
	for i in count:
		var t: float = float(i) / MIX_RATE
		var noise: float = rng.randf_range(-1.0, 1.0)
		bright += hiss * (noise - bright)
		low += rumble * (noise - low)
		rubble += crash * (noise - rubble)
		var slide: float = 0.0
		if t < SLIDE_LANDING_SECONDS:
			var progress: float = t / SLIDE_LANDING_SECONDS
			# A knock at every joint, closer together as the slide speeds up.
			var joints: float = pow(sin(PI * 5.0 * progress * progress), 16.0)
			var swell: float = minf(t * 6.0, 1.0) * (0.5 + 0.5 * progress)
			slide = (bright * 0.6 + low * 3.0 * (1.0 + joints * 2.0)) * swell
		var landed: float = 0.0
		if t >= SLIDE_LANDING_SECONDS:
			var after: float = t - SLIDE_LANDING_SECONDS
			var thump: float = sin(TAU * 60.0 * after) * exp(-after * 14.0)
			landed = (rubble * 5.0 * exp(-after * 6.0) + thump * 1.5) * minf(after * 400.0, 1.0)
		samples[i] = slide + landed
	return samples


## A steel roller shutter going up: a motor whine under the fast clatter of
## the slats winding onto the drum, ending in a clang as it stops at the top.
func _shutter_rattle(rng: RandomNumberGenerator) -> PackedFloat32Array:
	var count: int = int(SHUTTER_SECONDS * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var stop: float = SHUTTER_SECONDS - 0.4
	var phase: float = 0.0
	for i in count:
		var t: float = float(i) / MIX_RATE
		var is_running: bool = t < stop
		phase += TAU * (95.0 + 25.0 * minf(t * 2.0, 1.0)) / MIX_RATE
		var motor: float = (sin(phase) * 0.5 + sin(phase * 2.0 + 0.3) * 0.25) if is_running else 0.0
		var slat_time: float = fmod(t, 1.0 / 14.0)
		var clatter: float = rng.randf_range(-1.0, 1.0) * exp(-slat_time * 120.0)
		clatter *= (0.6 + 0.4 * sin(TAU * 410.0 * t)) if is_running else 0.0
		var clang: float = 0.0
		if not is_running:
			var after: float = t - stop
			clang = (
				(sin(TAU * 230.0 * after) * 0.7 + sin(TAU * 610.0 * after) * 0.4)
				* exp(-after * 9.0)
			)
			clang += rng.randf_range(-1.0, 1.0) * exp(-after * 60.0)
		samples[i] = (motor * 0.6 + clatter + clang * 1.2) * minf(t * 40.0, 1.0)
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
