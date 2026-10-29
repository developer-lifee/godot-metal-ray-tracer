extends Node

class_name SoundFX

## Generador y reproductor procedural de efectos de sonido
## Genera tonos en memoria para evitar dependencias de archivos de audio externos pesados

static var _instance: SoundFX

func _enter_tree() -> void:
	_instance = self

static func get_instance() -> SoundFX:
	return _instance

var _players: Array[AudioStreamPlayer] = []
const MAX_PLAYERS = 8

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(MAX_PLAYERS):
		var p = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)

func _get_free_player() -> AudioStreamPlayer:
	for p in _players:
		if not p.playing:
			return p
	return _players[0]

## 1. Disparo de Láser
func play_laser(volume_db: float = -6.0) -> void:
	var stream = _generate_sweep(880.0, 220.0, 0.12, 0.35, "sawtooth")
	var p = _get_free_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.95, 1.05)
	p.play()

## 2. Impacto de Láser en NPC / Objeto (No suena como agua)
func play_laser_hit(volume_db: float = -4.0) -> void:
	var stream = _generate_noise_burst(0.08, 0.5, 440.0)
	var p = _get_free_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = randf_range(1.1, 1.3)
	p.play()

## 3. Chapoteo de Agua (sólo al zambullirse o moverse en agua)
func play_splash(volume_db: float = -5.0) -> void:
	var stream = _generate_water_splash(0.22, 0.45)
	var p = _get_free_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = randf_range(0.85, 1.15)
	p.play()

## 4. Trampolín de Clavados (Boing / Rebote Elástico)
func play_spring(volume_db: float = -3.0) -> void:
	var stream = _generate_sweep(140.0, 520.0, 0.28, 0.5, "sine")
	var p = _get_free_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0
	p.play()

## 5. Flash Warp (Woosh cuántico instantáneo)
func play_warp(volume_db: float = -4.0) -> void:
	var stream = _generate_sweep(200.0, 1200.0, 0.18, 0.45, "sine")
	var p = _get_free_player()
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0
	p.play()

## 6. Slow-Mo (Ralentización del tiempo)
func play_slowmo(active: bool) -> void:
	var start_f = 600.0 if active else 180.0
	var end_f = 180.0 if active else 600.0
	var stream = _generate_sweep(start_f, end_f, 0.25, 0.4, "sine")
	var p = _get_free_player()
	p.stream = stream
	p.volume_db = -6.0
	p.play()

## 7. Cobertura / Agachado en roca
func play_cover() -> void:
	var stream = _generate_sweep(160.0, 90.0, 0.08, 0.3, "triangle")
	var p = _get_free_player()
	p.stream = stream
	p.volume_db = -10.0
	p.pitch_scale = 1.0
	p.play()

# -------------------------------------------------------------
# Generadores de forma de onda PCM en memoria (AudioStreamWAV)
# -------------------------------------------------------------

func _generate_sweep(start_freq: float, end_freq: float, duration: float, amplitude: float, wave_type: String) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples)

	var phase: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var freq = lerp(start_freq, end_freq, t)
		var delta_phase = (freq * 2.0 * PI) / float(sample_rate)
		phase += delta_phase

		var env = 1.0 - t
		var sample_val: float = 0.0

		if wave_type == "sine":
			sample_val = sin(phase)
		elif wave_type == "sawtooth":
			sample_val = fmod(phase / PI, 2.0) - 1.0
		elif wave_type == "triangle":
			sample_val = 2.0 * abs(fmod(phase / PI, 2.0) - 1.0) - 1.0

		var int_val = int(clamp(sample_val * amplitude * env * 127.0, -128.0, 127.0))
		byte_array[i] = (int_val + 256) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

func _generate_noise_burst(duration: float, amplitude: float, filter_freq: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples)

	var prev_sample: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var white_noise = randf_range(-1.0, 1.0)
		# Filtro pasa-bajas simple
		var alpha = clamp(filter_freq / float(sample_rate), 0.05, 0.95)
		var filtered = prev_sample + alpha * (white_noise - prev_sample)
		prev_sample = filtered

		var env = exp(-t * 12.0)
		var int_val = int(clamp(filtered * amplitude * env * 127.0, -128.0, 127.0))
		byte_array[i] = (int_val + 256) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream

func _generate_water_splash(duration: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate = 22050
	var num_samples = int(duration * sample_rate)
	var byte_array = PackedByteArray()
	byte_array.resize(num_samples)

	var phase: float = 0.0
	var prev_noise: float = 0.0
	for i in range(num_samples):
		var t = float(i) / float(num_samples)
		var bubble_freq = lerp(450.0, 120.0, t)
		phase += (bubble_freq * 2.0 * PI) / float(sample_rate)

		var noise = randf_range(-1.0, 1.0)
		prev_noise = prev_noise + 0.25 * (noise - prev_noise)

		var env = sin(t * PI) * exp(-t * 3.5)
		var combined = (sin(phase) * 0.45 + prev_noise * 0.55) * amplitude * env

		var int_val = int(clamp(combined * 127.0, -128.0, 127.0))
		byte_array[i] = (int_val + 256) & 0xFF

	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = byte_array
	return stream
