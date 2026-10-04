extends Node

const MIX_RATE: int = 22050

var players: Array[AudioStreamPlayer] = []
var cursor: int = 0
var sounds: Dictionary = {}

func _ready() -> void:
    for i in range(6):
        var player := AudioStreamPlayer.new()
        player.bus = "Master"
        add_child(player)
        players.append(player)

    sounds = {
        "click": _make_tone(520.0, 0.055, 0.16, 0.25),
        "crit": _make_tone(920.0, 0.12, 0.22, 0.55),
        "buy": _make_tone(660.0, 0.10, 0.18, 0.35),
        "bonus": _make_tone(1180.0, 0.16, 0.20, 0.50),
        "unlock": _make_tone(760.0, 0.34, 0.17, 0.70),
        "open": _make_tone(430.0, 0.09, 0.12, 0.20)
    }

func play(kind: String) -> void:
    if players.is_empty() or not sounds.has(kind):
        return
    var player := players[cursor]
    cursor = (cursor + 1) % players.size()
    player.stream = sounds[kind]
    player.play()

func _make_tone(freq: float, duration: float, volume: float, harmonic: float) -> AudioStreamWAV:
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = MIX_RATE
    wav.stereo = false

    var sample_count: int = maxi(1, int(duration * float(MIX_RATE)))
    var data := PackedByteArray()
    data.resize(sample_count * 2)

    for i in range(sample_count):
        var t: float = float(i) / float(MIX_RATE)
        var attack: float = minf(1.0, t / 0.006)
        var release: float = pow(maxf(0.0, 1.0 - t / duration), 2.0)
        var wave: float = sin(TAU * freq * t)
        wave = wave * 0.82 + sin(TAU * freq * 2.0 * t) * 0.18 * harmonic
        var sample: int = int(clampf(wave * attack * release * volume, -1.0, 1.0) * 32767.0)
        data.encode_s16(i * 2, sample)

    wav.data = data
    return wav
