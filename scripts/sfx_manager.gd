class_name SfxManager
extends Node
## Procedural & Custom File SFX Manager:
## - Synthesizes crisp 16-bit PCM `AudioStreamWAV` sound effects at startup for combat, skills,
##   healing, targeting, mining, Talic upgrading, and portal warps (zero external dependencies).
## - Automatically loads custom `.wav` or `.ogg` files if placed in `res://assets/sfx/<event_name>.wav`!

const SAMPLE_RATE := 22050
const POOL_SIZE := 8

var volume_pct := 80
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _pool_idx := 0


func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)
	_build_sound_bank()


func play(sfx_name: String, pitch_scale: float = 1.0) -> void:
	if volume_pct <= 0:
		return
	var stream: AudioStream = _streams.get(sfx_name)
	if stream == null:
		return
	var p := _players[_pool_idx]
	_pool_idx = (_pool_idx + 1) % _players.size()
	var linear_gain := clampf(float(volume_pct) / 100.0, 0.0, 1.0) * 0.55
	p.volume_db = linear_to_db(maxf(0.001, linear_gain))
	p.pitch_scale = pitch_scale * randf_range(0.96, 1.04)
	p.stream = stream
	p.play()


func _build_sound_bank() -> void:
	# Check for custom user-supplied .wav/.ogg files in res://assets/sfx/ first;
	# otherwise synthesize procedural waveforms in memory.
	_register_sfx("target_lock", _synth_tone(0.09, 780.0, 1180.0, 0.05, "sine"))
	_register_sfx("attack_hit", _synth_tone(0.13, 210.0, 72.0, 0.45, "punch"))
	_register_sfx("ranged_shot", _synth_tone(0.14, 920.0, 210.0, 0.25, "saw"))
	_register_sfx("skill_cast", _synth_chord(0.28, [320.0, 480.0, 640.0], 180.0, 0.30))
	_register_sfx("buff_cast", _synth_arpeggio(0.38, [392.0, 493.88, 587.33, 783.99, 987.77]))
	_register_sfx("damage_taken", _synth_tone(0.16, 155.0, 58.0, 0.55, "saw"))
	_register_sfx("heal", _synth_arpeggio(0.26, [440.0, 554.37, 659.25, 880.0]))
	_register_sfx("mine_ore", _synth_arpeggio(0.20, [880.0, 1174.66, 1318.5]))
	_register_sfx("upgrade_success", _synth_arpeggio(0.42, [523.25, 659.25, 783.99, 1046.5]))
	_register_sfx("upgrade_fail", _synth_tone(0.34, 240.0, 68.0, 0.65, "saw"))
	_register_sfx("warp_portal", _synth_chord(0.38, [220.0, 330.0, 440.0], 660.0, 0.15))
	_register_sfx("level_up", _synth_arpeggio(0.48, [440.0, 554.37, 659.25, 880.0, 1108.73]))


func _register_sfx(sfx_name: String, fallback_wav: AudioStreamWAV) -> void:
	var custom_wav := "res://assets/sfx/%s.wav" % sfx_name
	var custom_ogg := "res://assets/sfx/%s.ogg" % sfx_name
	if ResourceLoader.exists(custom_wav):
		_streams[sfx_name] = load(custom_wav)
	elif ResourceLoader.exists(custom_ogg):
		_streams[sfx_name] = load(custom_ogg)
	else:
		_streams[sfx_name] = fallback_wav


func _synth_tone(duration: float, f_start: float, f_end: float, noise_mix: float, wave_kind: String) -> AudioStreamWAV:
	var count := maxi(1, int(SAMPLE_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var env := sin(minf(1.0, t * 12.0) * PI * 0.5) * pow(1.0 - t, 1.65)
		var freq := lerpf(f_start, f_end, pow(t, 0.75))
		phase += TAU * freq / float(SAMPLE_RATE)
		var osc := sin(phase)
		if wave_kind == "saw":
			osc = 2.0 * (fposmod(phase / TAU, 1.0)) - 1.0
		elif wave_kind == "punch":
			osc = tanh(sin(phase) * 2.2)
		var noise := randf_range(-1.0, 1.0)
		var sample := ((1.0 - noise_mix) * osc + noise_mix * noise) * env * 0.75
		var pcm := clampi(int(sample * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, pcm)
	return _make_wav(bytes)


func _synth_arpeggio(duration: float, notes: Array) -> AudioStreamWAV:
	var count := maxi(1, int(SAMPLE_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var phase := 0.0
	var n_size := maxi(1, notes.size())
	for i in range(count):
		var t := float(i) / float(count)
		var step_idx := mini(n_size - 1, int(t * float(n_size)))
		var local_t := fposmod(t * float(n_size), 1.0)
		var local_env := sin(minf(1.0, local_t * 8.0) * PI * 0.5) * pow(1.0 - local_t * 0.65, 1.2)
		var global_env := pow(1.0 - t, 0.45)
		var freq := float(notes[step_idx])
		phase += TAU * freq / float(SAMPLE_RATE)
		var sample := (sin(phase) * 0.75 + sin(phase * 2.0) * 0.25) * local_env * global_env * 0.65
		var pcm := clampi(int(sample * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, pcm)
	return _make_wav(bytes)


func _synth_chord(duration: float, freqs: Array, sweep_delta: float, noise_mix: float) -> AudioStreamWAV:
	var count := maxi(1, int(SAMPLE_RATE * duration))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var n_freqs := maxi(1, freqs.size())
	for i in range(count):
		var t := float(i) / float(count)
		var sec := float(i) / float(SAMPLE_RATE)
		var env := sin(minf(1.0, t * 10.0) * PI * 0.5) * pow(1.0 - t, 1.25)
		var sum_osc := 0.0
		for f_val in freqs:
			var f := float(f_val) + sweep_delta * t
			sum_osc += sin(TAU * f * sec)
		sum_osc /= float(n_freqs)
		var noise := randf_range(-1.0, 1.0)
		var sample := ((1.0 - noise_mix) * sum_osc + noise_mix * noise) * env * 0.72
		var pcm := clampi(int(sample * 32767.0), -32768, 32767)
		bytes.encode_s16(i * 2, pcm)
	return _make_wav(bytes)


func _make_wav(pcm_bytes: PackedByteArray) -> AudioStreamWAV:
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = pcm_bytes
	return wav
