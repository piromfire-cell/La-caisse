extends Node
## Sons du jeu, entièrement FABRIQUÉS EN CODE (aucun fichier audio à fournir).
## Usage : Sfx.play("dice"), Sfx.play("clink"), Sfx.shout_menteur() …
##
## Sons disponibles : click, tick, dice, clink, gulp, slam, buzzer, win, fail, caisse.

const RATE := 22050
const VOICES := 8

var _cache: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 99
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_warm_up()


## Fabrique les sons un par image pour ne pas figer l'écran au démarrage.
func _warm_up() -> void:
	for sound_name in ["click", "tick", "dice", "clink", "gulp", "slam", "buzzer", "win", "fail", "caisse"]:
		await get_tree().process_frame
		_get_stream(sound_name)


## Joue un son (ignoré si le son est coupé dans les réglages).
func play(sound_name: String, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not Settings.sound_on:
		return
	var stream := _get_stream(sound_name)
	if stream == null or _players.is_empty():
		return
	var p := _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = pitch
	p.play()


## Crie « Menteur ! » avec la voix de l'appareil si elle existe (français), sinon rien.
func shout_menteur() -> void:
	if not (Settings.sound_on and Settings.voice_on):
		return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return
	var voices := DisplayServer.tts_get_voices_for_language("fr")
	if voices.is_empty():
		return
	DisplayServer.tts_stop()
	DisplayServer.tts_speak("Menteur !", voices[0], 100, 1.0, 1.0)


## Petite vibration (téléphones seulement).
func vibrate(ms: int = 200) -> void:
	if Settings.vibration_on:
		Input.vibrate_handheld(ms)


func _get_stream(sound_name: String) -> AudioStreamWAV:
	if _cache.has(sound_name):
		return _cache[sound_name]
	var data: PackedFloat32Array
	match sound_name:
		"click": data = _gen_click(1100.0, 0.05)
		"tick": data = _gen_click(1700.0, 0.04)
		"dice": data = _gen_dice()
		"clink": data = _gen_clink()
		"gulp": data = _gen_gulp()
		"slam": data = _gen_slam()
		"buzzer": data = _gen_buzzer()
		"win": data = _gen_win()
		"fail": data = _gen_fail()
		"caisse": data = _gen_caisse()
		_:
			return null
	var stream := _make_stream(data)
	_cache[sound_name] = stream
	return stream


# ── Fabrication des échantillons ──────────────────────────────────────────────

func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = bytes
	return stream


func _blank(seconds: float) -> PackedFloat32Array:
	var d := PackedFloat32Array()
	d.resize(int(RATE * seconds))
	return d


## Un « clic » d'interface : sinus très court qui s'éteint vite.
func _gen_click(freq: float, seconds: float) -> PackedFloat32Array:
	var d := _blank(seconds)
	for i in d.size():
		var t := float(i) / RATE
		d[i] = sin(TAU * freq * t) * exp(-t * 90.0) * 0.45
	return d


## Dés qui roulent : une rafale de « clacs » de plus en plus espacés.
func _gen_dice() -> PackedFloat32Array:
	var d := _blank(1.0)
	var hits: Array[float] = [0.0, 0.07, 0.15, 0.25, 0.37, 0.5, 0.64, 0.77, 0.88]
	var amps: Array[float] = [1.0, 0.9, 0.8, 0.85, 0.6, 0.5, 0.38, 0.3, 0.22]
	for h in hits.size():
		var start := int(hits[h] * RATE)
		var freq := 700.0 + _rng.randf() * 800.0
		for j in int(RATE * 0.09):
			var idx := start + j
			if idx >= d.size():
				break
			var t := float(j) / RATE
			var noise := _rng.randf() * 2.0 - 1.0
			d[idx] += (noise * 0.55 + sin(TAU * freq * t) * 0.5) * exp(-t * 70.0) * amps[h] * 0.6
	return d


## Tintement de verre : trois sinus aigus qui s'éteignent lentement.
func _gen_clink() -> PackedFloat32Array:
	var d := _blank(1.1)
	for i in d.size():
		var t := float(i) / RATE
		var attack := 1.0 - exp(-t * 2500.0)
		var s := sin(TAU * 2637.0 * t) * exp(-t * 6.0) \
			+ 0.6 * sin(TAU * 3951.0 * t) * exp(-t * 9.0) \
			+ 0.35 * sin(TAU * 5274.0 * t) * exp(-t * 14.0)
		d[i] = s * attack * 0.33
	return d


## « Glou glou glou » : trois descentes de fréquence graves.
func _gen_gulp() -> PackedFloat32Array:
	var d := _blank(0.75)
	var starts: Array[float] = [0.02, 0.26, 0.5]
	for st in starts:
		var phase := 0.0
		var n := int(RATE * 0.17)
		for j in n:
			var u := float(j) / n
			var freq := 330.0 - 170.0 * u
			phase += TAU * freq / RATE
			var idx := int(st * RATE) + j
			if idx < d.size():
				d[idx] += (sin(phase) + 0.3 * sin(phase * 2.0)) * sin(PI * u) * 0.5
	return d


## Gros « BOUM » grave (le mot MENTEUR qui s'écrase à l'écran).
func _gen_slam() -> PackedFloat32Array:
	var d := _blank(0.55)
	var phase := 0.0
	for i in d.size():
		var t := float(i) / RATE
		phase += TAU * (110.0 * exp(-t * 6.0) + 38.0) / RATE
		var noise := (_rng.randf() * 2.0 - 1.0) * exp(-t * 40.0) * 0.4
		d[i] = (sin(phase) * exp(-t * 7.0) + noise) * 0.9
	return d


## Sirène « MENTEUR ! » : deux notes de cuivre graves, descendantes.
func _gen_buzzer() -> PackedFloat32Array:
	var d := _blank(0.9)
	var notes: Array[Vector3] = [Vector3(196.0, 0.0, 0.3), Vector3(147.0, 0.31, 0.58)]  # fréquence, début, durée
	for note in notes:
		var phase := 0.0
		var n := int(RATE * note.z)
		for j in n:
			var t := float(j) / RATE
			phase += TAU * note.x / RATE
			var saw := 0.0
			for k in range(1, 8):
				saw += sin(phase * k) / k
			var env := minf(1.0, t * 120.0) * (1.0 - float(j) / n)
			var idx := int(note.y * RATE) + j
			if idx < d.size():
				d[idx] += tanh(saw * 1.6) * env * 0.55
	return d


## Petite fanfare montante (bluff démasqué).
func _gen_win() -> PackedFloat32Array:
	var d := _blank(0.9)
	var freqs: Array[float] = [523.25, 659.25, 783.99, 1046.5]
	for i in freqs.size():
		var start := int(i * 0.11 * RATE)
		var n := int(RATE * (0.5 if i == freqs.size() - 1 else 0.13))
		var phase := 0.0
		for j in n:
			var t := float(j) / RATE
			phase += TAU * freqs[i] / RATE
			var s := sin(phase) + 0.35 * sin(phase * 2.0) + 0.2 * sin(phase * 3.0)
			var idx := start + j
			if idx < d.size():
				d[idx] += s * minf(1.0, t * 200.0) * exp(-t * (3.0 if i == freqs.size() - 1 else 6.0)) * 0.3
	return d


## « Wah wah wah waaah » du trombone triste (accusation à tort).
func _gen_fail() -> PackedFloat32Array:
	var d := _blank(1.25)
	var notes: Array[Vector3] = [Vector3(311.0, 0.0, 0.26), Vector3(294.0, 0.29, 0.26), Vector3(277.0, 0.58, 0.26), Vector3(233.0, 0.87, 0.36)]
	for ni in notes.size():
		var note := notes[ni]
		var phase := 0.0
		var n := int(RATE * note.z)
		for j in n:
			var t := float(j) / RATE
			var vibrato := 1.0 + (0.02 * sin(TAU * 6.0 * t) if ni == notes.size() - 1 else 0.0)
			var glide := 1.0 - (0.12 * float(j) / n if ni == notes.size() - 1 else 0.0)
			phase += TAU * note.x * vibrato * glide / RATE
			var s := 0.0
			for k in range(1, 6):
				s += sin(phase * k) / (k * k)
			var env := minf(1.0, t * 60.0) * (1.0 - 0.6 * float(j) / n)
			var idx := int(note.y * RATE) + j
			if idx < d.size():
				d[idx] += s * env * 0.6
	return d


## Fanfare « TA-DAAA » : un accord qui claque, pour LA CAISSE.
func _gen_caisse() -> PackedFloat32Array:
	var d := _blank(1.1)
	var chords: Array[Vector3] = [Vector3(392.0, 0.0, 0.12), Vector3(523.25, 0.14, 0.12), Vector3(659.25, 0.28, 0.8)]
	for ch in chords:
		var n := int(RATE * ch.z)
		for j in n:
			var t := float(j) / RATE
			var s := 0.0
			for mult in [1.0, 1.25, 1.5]:
				var f: float = ch.x * mult
				s += sin(TAU * f * t) + 0.3 * sin(TAU * f * 2.0 * t)
			var env := minf(1.0, t * 150.0) * exp(-t * (2.5 if ch.z > 0.5 else 9.0))
			var idx := int(ch.y * RATE) + j
			if idx < d.size():
				d[idx] += s * env * 0.16
	return d
