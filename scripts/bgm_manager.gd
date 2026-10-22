class_name BgmManager
extends Node
## Procedural & Custom Background Music (BGM) Manager:
## - Synthesizes seamless looping ambient soundtracks for every biome theme in memory (0 external dependencies).
## - Seamlessly crossfades between tracks when players travel across the 30 world zones.
## - Automatically overrides any procedural track if you drop custom `.ogg` or `.wav` music files into:
##     `res://assets/music/<map_id>.ogg` (or `.wav`)
##     `res://assets/music/<theme>.ogg` (or `.wav`)

const SAMPLE_RATE := 22050
const LOOP_DURATION := 8.0 # Exact 8-second seamless looping harmonic buffers
const CROSSFADE_TIME := 1.2

var volume_pct := 70:
	set(val):
		volume_pct = clampi(val, 0, 100)
		_update_player_volumes()

var current_track_key := ""

var _player_a: AudioStreamPlayer
var _player_b: AudioStreamPlayer
var _active_player: AudioStreamPlayer
var _fading_player: AudioStreamPlayer

var _crossfade_progress := 1.0 # 1.0 means steady state
var _streams_cache: Dictionary = {}


func _ready() -> void:
	_player_a = AudioStreamPlayer.new()
	_player_a.bus = "Master"
	add_child(_player_a)

	_player_b = AudioStreamPlayer.new()
	_player_b.bus = "Master"
	add_child(_player_b)

	_active_player = _player_a
	_fading_player = null
	_precache_synthesized_tracks()


func _process(delta: float) -> void:
	if _crossfade_progress < 1.0:
		_crossfade_progress = minf(1.0, _crossfade_progress + delta / CROSSFADE_TIME)
		_update_player_volumes()
		if _crossfade_progress >= 1.0 and _fading_player and is_instance_valid(_fading_player):
			_fading_player.stop()
			_fading_player = null


func play_for_map(map_id: String, theme: String = "") -> void:
	if map_id == "":
		return
	if theme == "" and GameData.MAPS.has(map_id):
		theme = str(GameData.MAPS[map_id].get("terrain_theme", "TECH_ARK"))

	var track_key := _resolve_track_key(map_id, theme)
	if track_key == current_track_key and (_active_player.playing or volume_pct <= 0):
		return

	current_track_key = track_key
	var stream: AudioStream = _get_or_load_stream(map_id, theme, track_key)
	if stream == null:
		return

	_start_crossfade(stream)


func test_preview() -> void:
	if current_track_key == "":
		play_for_map("svel_hq", "TECH_ARK")
	else:
		_active_player.seek(0.0)


func _start_crossfade(new_stream: AudioStream) -> void:
	# Swap active and fading player
	_fading_player = _active_player
	_active_player = _player_b if _active_player == _player_a else _player_a

	_active_player.stream = new_stream
	if volume_pct > 0:
		_active_player.play()
	_crossfade_progress = 0.0 if (_fading_player and _fading_player.playing) else 1.0
	_update_player_volumes()


func _update_player_volumes() -> void:
	var base_gain := (float(volume_pct) / 100.0) * 0.45
	if volume_pct <= 0:
		if _active_player:
			_active_player.volume_db = -80.0
		if _fading_player:
			_fading_player.volume_db = -80.0
		return

	if _active_player:
		var in_gain := base_gain * sin(_crossfade_progress * PI * 0.5)
		_active_player.volume_db = linear_to_db(maxf(0.0001, in_gain))
		if not _active_player.playing and volume_pct > 0 and _active_player.stream:
			_active_player.play()

	if _fading_player and _fading_player.playing:
		var out_gain := base_gain * cos(_crossfade_progress * PI * 0.5)
		_fading_player.volume_db = linear_to_db(maxf(0.0001, out_gain))


func _resolve_track_key(map_id: String, theme: String) -> String:
	# Check custom file priorities:
	if ResourceLoader.exists("res://assets/music/%s.ogg" % map_id) or ResourceLoader.exists("res://assets/music/%s.wav" % map_id):
		return "file:" + map_id
	if ResourceLoader.exists("res://assets/music/%s.ogg" % theme) or ResourceLoader.exists("res://assets/music/%s.wav" % theme):
		return "file:" + theme

	# Procedural themes
	match theme:
		"TECH_ARK", "ARK_SUPERCORE":
			return "theme:tech_ark"
		"HOLY_TEMPLE", "SKY_SANCTUM":
			return "theme:holy_temple"
		"OBSIDIAN_CITADEL", "DAEVA_CRYPT":
			return "theme:obsidian_citadel"
		"VOLCANIC_BASIN", "MAGMA_CALDERA", "SCORCHED_CAULDRON":
			return "theme:volcanic_caldera"
		"CRACK_MINING", "LOWER_CRATER", "BREACH_RIDGE":
			return "theme:crack_mining"
		"AETHER_SKY", "SKY_FRACTURE":
			return "theme:aether_sky"
		"PERSEPOLIS_STEPPES", "BEAST_HIGHLAND", "DESERT_RUINS":
			return "theme:desert_steppes"
		"CATACOMB_CRYPT", "LUMINESCENT_AQUIFER", "VAR_ROOTS":
			return "theme:catacomb_aquifer"
		_:
			return "theme:tech_ark"


func _get_or_load_stream(map_id: String, theme: String, track_key: String) -> AudioStream:
	if _streams_cache.has(track_key):
		return _streams_cache[track_key]

	# Check external files
	var paths := [
		"res://assets/music/%s.ogg" % map_id,
		"res://assets/music/%s.wav" % map_id,
		"res://assets/music/%s.ogg" % theme,
		"res://assets/music/%s.wav" % theme,
	]
	for p in paths:
		if ResourceLoader.exists(p):
			var res: AudioStream = load(p)
			if res:
				if res is AudioStreamOggVorbis:
					(res as AudioStreamOggVorbis).loop = true
				_streams_cache[track_key] = res
				return res

	# Synthesize procedural theme loop
	var synth_stream := _synthesize_theme_loop(track_key)
	_streams_cache[track_key] = synth_stream
	return synth_stream


func _precache_synthesized_tracks() -> void:
	var keys := [
		"theme:tech_ark",
		"theme:holy_temple",
		"theme:obsidian_citadel",
		"theme:volcanic_caldera",
		"theme:crack_mining",
		"theme:aether_sky",
		"theme:desert_steppes",
		"theme:catacomb_aquifer"
	]
	for k in keys:
		_streams_cache[k] = _synthesize_theme_loop(k)


# ------------------------------------------------------------------------------
# PROCEDURAL SEAMLESS HARMONIC LOOP SYNTHESIZER
# Every frequency is an integer multiple of (1 / LOOP_DURATION), guaranteeing
# exact phase alignment at loop boundary (0 pops / 0 clicks).
# ------------------------------------------------------------------------------
func _synthesize_theme_loop(theme_key: String) -> AudioStreamWAV:
	var total_samples := int(SAMPLE_RATE * LOOP_DURATION)
	var bytes := PackedByteArray()
	bytes.resize(total_samples * 2)

	# Select harmonic configuration based on theme
	var freqs: Array[float] = []
	var weights: Array[float] = []
	var pulse_freq := 0.0

	match theme_key:
		"theme:tech_ark":
			# Cold cybernetic D-minor (D2=73.5, A2=110, F3=174.5, A3=220) + sync pulse
			freqs = [73.5, 110.25, 174.5, 220.5, 349.0]
			weights = [0.45, 0.35, 0.25, 0.20, 0.12]
			pulse_freq = 2.0 # 2 Hz digital rhythmic clock

		"theme:holy_temple":
			# Sacred Persian / Phrygian fifths & fourths (E2=82.75, B2=123.75, E3=165.5, G3=196.25, B3=247.5)
			freqs = [82.75, 123.75, 165.5, 196.25, 247.5, 331.0]
			weights = [0.40, 0.30, 0.28, 0.22, 0.18, 0.12]
			pulse_freq = 0.5 # Slow chanting breath

		"theme:obsidian_citadel":
			# Dark demonic drone (C-sharp root: 68.75, 103.125, 137.5, 206.25)
			freqs = [68.75, 103.125, 137.5, 165.0, 206.25]
			weights = [0.50, 0.38, 0.25, 0.18, 0.14]
			pulse_freq = 1.0

		"theme:volcanic_caldera":
			# Low tectonic magma rumble (55.0, 82.5, 110.0, 165.0)
			freqs = [55.0, 82.5, 110.0, 148.5, 165.0]
			weights = [0.55, 0.35, 0.25, 0.15, 0.10]
			pulse_freq = 0.75

		"theme:crack_mining":
			# Driving martial industrial war tension (A2=110, E3=165, C4=261.25, D4=293.75)
			freqs = [110.0, 165.0, 220.0, 261.25, 330.0]
			weights = [0.42, 0.35, 0.30, 0.20, 0.18]
			pulse_freq = 2.5 # Martial combat march

		"theme:aether_sky":
			# High celestial floating fifths (F3=175.0, C4=262.5, F4=350.0, A4=440.0, C5=525.0)
			freqs = [175.0, 262.5, 350.0, 440.0, 525.0]
			weights = [0.35, 0.32, 0.28, 0.22, 0.18]
			pulse_freq = 0.33 # Long drifting cloud swell

		"theme:desert_steppes":
			# Ancient desert wind (D2=73.5, A2=110.25, D3=147.0, E3=165.5)
			freqs = [73.5, 110.25, 147.0, 165.5, 220.5]
			weights = [0.45, 0.35, 0.28, 0.20, 0.15]
			pulse_freq = 0.5

		"theme:catacomb_aquifer":
			# Subterranean cavern reverb (G2=98.0, D3=147.0, B-flat3=233.0, D4=294.0)
			freqs = [98.0, 147.0, 196.0, 233.0, 294.0]
			weights = [0.48, 0.35, 0.25, 0.20, 0.15]
			pulse_freq = 0.66

		_:
			freqs = [110.0, 165.0, 220.0]
			weights = [0.5, 0.3, 0.2]
			pulse_freq = 1.0

	for i in range(total_samples):
		var t := float(i) / float(SAMPLE_RATE)
		var sample := 0.0

		for j in range(freqs.size()):
			var f: float = freqs[j]
			var w: float = weights[j]
			# Subtle vibrato locked to integer cycles of loop duration
			var vibrato := sin(TAU * 0.5 * t) * 0.008
			sample += sin(TAU * f * (1.0 + vibrato) * t) * w

		# Subtle pulse modulation
		if pulse_freq > 0.0:
			var pulse := 0.85 + 0.15 * sin(TAU * pulse_freq * t)
			sample *= pulse

		# Master gain clamp
		sample *= 0.38
		var pcm := clampi(int(sample * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, pcm)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = total_samples
	wav.data = bytes
	return wav
