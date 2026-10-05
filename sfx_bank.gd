extends Node

const MIX_RATE: int = 32000

var players: Array[AudioStreamPlayer] = []
var cursor: int = 0
var sounds: Dictionary = {}
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    rng.randomize()
    for i in range(12):
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        player.bus = "Master"
        add_child(player)
        players.append(player)

    sounds = {
        "click": _make_effect(720.0, 480.0, 0.070, 0.15, 0.16, 0.08),
        "crit": _make_effect(1120.0, 540.0, 0.165, 0.22, 0.38, 0.12),
        "buy": _make_effect(510.0, 900.0, 0.125, 0.17, 0.24, 0.03),
        "bonus": _make_effect(850.0, 1320.0, 0.185, 0.19, 0.32, 0.04),
        "unlock": _make_effect(520.0, 1180.0, 0.330, 0.18, 0.42, 0.025),
        "open": _make_effect(390.0, 640.0, 0.105, 0.12, 0.20, 0.02),
        "select": _make_effect(470.0, 790.0, 0.145, 0.15, 0.27, 0.025)
    }

func play(kind: String) -> void:
    if players.is_empty() or not sounds.has(kind):
        return

    var player: AudioStreamPlayer = players[cursor]
    cursor = (cursor + 1) % players.size()
    player.stop()
    player.stream = sounds[kind]
    player.pitch_scale = _pitch_for(kind)
    player.volume_db = _volume_for(kind)
    player.play()

func _pitch_for(kind: String) -> float:
    match kind:
        "click":
            return rng.randf_range(0.965, 1.045)
        "crit":
            return rng.randf_range(0.985, 1.025)
        "buy":
            return rng.randf_range(0.985, 1.035)
        "select":
            return rng.randf_range(0.99, 1.025)
        _:
            return rng.randf_range(0.99, 1.015)

func _volume_for(kind: String) -> float:
    match kind:
        "click":
            return -1.5
        "crit":
            return 0.0
        "buy":
            return -0.8
        "select":
            return -1.0
        _:
            return -1.5

func _make_effect(
    start_freq: float,
    end_freq: float,
    duration: float,
    volume: float,
    harmonic: float,
    transient: float
) -> AudioStreamWAV:
    var wav: AudioStreamWAV = AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = MIX_RATE
    wav.stereo = false

    var sample_count: int = maxi(1, int(duration * float(MIX_RATE)))
    var data: PackedByteArray = PackedByteArray()
    data.resize(sample_count * 2)

    var phase: float = 0.0
    for i in range(sample_count):
        var t: float = float(i) / float(MIX_RATE)
        var p: float = clampf(t / duration, 0.0, 1.0)
        var curve: float = pow(p, 0.72)
        var freq: float = lerpf(start_freq, end_freq, curve)
        phase += TAU * freq / float(MIX_RATE)

        var attack: float = minf(1.0, t / 0.0035)
        var release: float = pow(maxf(0.0, 1.0 - p), 2.25)
        var body: float = sin(phase)
        body += sin(phase * 2.0 + 0.35) * harmonic
        body += sin(phase * 0.5) * harmonic * 0.16

        var transient_env: float = pow(maxf(0.0, 1.0 - p * 7.5), 2.0)
        var transient_wave: float = sin(TAU * (3100.0 + 900.0 * sin(t * 170.0)) * t)
        var value: float = (body * attack * release + transient_wave * transient_env * transient) * volume

        var sample: int = int(clampf(value, -1.0, 1.0) * 32767.0)
        data.encode_s16(i * 2, sample)

    wav.data = data
    return wav
