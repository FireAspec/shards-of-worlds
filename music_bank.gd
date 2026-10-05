extends Node

const MIX_RATE: int = 22050
const LOOP_SECONDS: float = 12.0

var player: AudioStreamPlayer

func _ready() -> void:
    player = AudioStreamPlayer.new()
    player.volume_db = -25.0
    add_child(player)
    player.stream = _build_loop()
    player.play()

func _build_loop() -> AudioStreamWAV:
    var wav: AudioStreamWAV = AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.mix_rate = MIX_RATE
    wav.stereo = false
    wav.loop_mode = AudioStreamWAV.LOOP_FORWARD

    var sample_count: int = int(LOOP_SECONDS * float(MIX_RATE))
    var data: PackedByteArray = PackedByteArray()
    data.resize(sample_count * 2)
    var chord: Array[float] = [110.0, 164.81, 220.0, 329.63]

    for i in range(sample_count):
        var t: float = float(i) / float(MIX_RATE)
        var value: float = 0.0
        for n in range(chord.size()):
            var freq: float = chord[n]
            var drift: float = sin(TAU * (0.028 + float(n) * 0.006) * t) * 0.75
            value += sin(TAU * (freq + drift) * t + float(n) * 0.72) * (0.10 / float(n + 1))
        value += sin(TAU * 55.0 * t) * 0.022
        value *= 0.75 + sin(TAU * 0.0833 * t) * 0.09
        var fade: float = minf(1.0, t / 0.9)
        fade *= minf(1.0, (LOOP_SECONDS - t) / 0.9)
        var sample: int = int(clampf(value * maxf(fade, 0.0), -1.0, 1.0) * 32767.0)
        data.encode_s16(i * 2, sample)

    wav.data = data
    wav.loop_begin = 0
    wav.loop_end = sample_count
    return wav