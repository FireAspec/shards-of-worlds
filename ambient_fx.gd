extends Control

var rng := RandomNumberGenerator.new()
var shard_count: int = 26

func _ready() -> void:
    rng.randomize()
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    z_index = 0
    for i in range(shard_count):
        _spawn_shard(i)

func _spawn_shard(seed_offset: int = 0) -> void:
    var shard := ColorRect.new()
    var side: float = rng.randf_range(3.0, 8.0)
    shard.size = Vector2(side, side)
    shard.rotation = PI / 4.0
    shard.mouse_filter = Control.MOUSE_FILTER_IGNORE
    shard.color = Color.from_hsv(rng.randf_range(0.56, 0.78), 0.42, 1.0, rng.randf_range(0.10, 0.36))
    add_child(shard)

    var view := get_viewport_rect().size
    shard.position = Vector2(
        rng.randf_range(0.0, maxf(view.x, 1.0)),
        rng.randf_range(0.0, maxf(view.y, 1.0))
    )
    shard.scale = Vector2.ONE * rng.randf_range(0.65, 1.35)

    var drift_x: float = rng.randf_range(-90.0, 90.0)
    var drift_y: float = rng.randf_range(-170.0, -80.0)
    var duration: float = rng.randf_range(5.5, 11.0)
    var start: Vector2 = shard.position
    var target: Vector2 = start + Vector2(drift_x, drift_y)

    var tween := create_tween()
    tween.set_loops()
    tween.set_parallel(true)
    tween.tween_property(shard, "position", target, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(shard, "rotation", shard.rotation + rng.randf_range(-2.2, 2.2), duration)
    tween.tween_property(shard, "modulate:a", rng.randf_range(0.18, 0.55), duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.chain()
    tween.set_parallel(true)
    tween.tween_property(shard, "position", start, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(shard, "rotation", shard.rotation, duration)
    tween.tween_property(shard, "modulate:a", rng.randf_range(0.08, 0.30), duration * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
