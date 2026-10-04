extends Control

const SAVE_PATH := "user://shards_save.json"
const AUTOSAVE_INTERVAL := 5.0

var shards: float = 0.0
var total_shards: float = 0.0
var click_power: float = 1.0
var auto_rate: float = 0.0
var crit_chance: float = 0.05
var crit_multiplier: float = 5.0
var current_chapter: int = 0
var last_unix: int = 0
var autosave_clock: float = 0.0
var rng := RandomNumberGenerator.new()

var upgrades := [
    {"name":"Укрепить импульс", "base":25.0, "growth":1.65, "count":0, "kind":"click", "value":1.0, "desc":"+1 к силе ручного импульса"},
    {"name":"Микродрон", "base":60.0, "growth":1.72, "count":0, "kind":"auto", "value":1.0, "desc":"+1 осколок/сек"},
    {"name":"Рой дронов", "base":650.0, "growth":1.78, "count":0, "kind":"auto", "value":12.0, "desc":"+12 осколков/сек"},
    {"name":"Станция стабилизации", "base":8500.0, "growth":1.82, "count":0, "kind":"auto", "value":160.0, "desc":"+160 осколков/сек"},
    {"name":"Фабрика осколков", "base":125000.0, "growth":1.86, "count":0, "kind":"auto", "value":2400.0, "desc":"+2.4K осколков/сек"},
    {"name":"Орбитальный сборщик", "base":2500000.0, "growth":1.9, "count":0, "kind":"auto", "value":42000.0, "desc":"+42K осколков/сек"},
    {"name":"Межмировой комплекс", "base":60000000.0, "growth":1.94, "count":0, "kind":"auto", "value":900000.0, "desc":"+900K осколков/сек"},
    {"name":"Сингулярный экстрактор", "base":1800000000.0, "growth":1.98, "count":0, "kind":"auto", "value":22000000.0, "desc":"+22M осколков/сек"}
]

var chapters := [
    {"need":0.0, "title":"Глава I — Пустая комната", "subtitle":"Ты находишь устройство, которое помнит исчезнувшие миры.", "symbol":"◇"},
    {"need":100.0, "title":"Глава II — Первый голос", "subtitle":"В шуме осколков звучит голос неизвестной девушки.", "symbol":"✦"},
    {"need":1000.0, "title":"Глава III — Сад под двумя лунами", "subtitle":"В памяти устройства проявляется первый восстановленный мир.", "symbol":"☾"},
    {"need":10000.0, "title":"Глава IV — Город без утра", "subtitle":"В городе всегда ночь, но окна продолжают гореть.", "symbol":"▦"},
    {"need":100000.0, "title":"Глава V — Девушка из архива", "subtitle":"Она наконец называет своё имя, но просит не верить устройству.", "symbol":"✧"},
    {"need":1000000.0, "title":"Глава VI — Машина лжёт", "subtitle":"Часть восстановленных воспоминаний противоречит другой части.", "symbol":"⌁"},
    {"need":10000000.0, "title":"Глава VII — Мир до катастрофы", "subtitle":"Ты видишь момент, когда всё ещё можно было остановить.", "symbol":"◉"},
    {"need":100000000.0, "title":"Глава VIII — Последний протокол", "subtitle":"Устройство открывает скрытую функцию: выбрать один мир для полного возврата.", "symbol":"⬡"},
    {"need":1000000000.0, "title":"Глава IX — Цена возвращения", "subtitle":"Каждый восстановленный мир стирает часть другого.", "symbol":"✺"},
    {"need":1000000000000.0, "title":"Глава X — Осколки миров", "subtitle":"Финальная память показывает, кем был тот, кто запустил катастрофу.", "symbol":"∞"}
]

var shard_label: Label
var total_label: Label
var click_label: Label
var auto_label: Label
var chapter_label: Label
var chapter_subtitle: Label
var chapter_progress: ProgressBar
var chapter_need_label: Label
var core_button: Button
var core_glow: ColorRect
var event_label: Label
var upgrades_box: VBoxContainer
var offline_label: Label
var chapter_symbol: Label

func _ready() -> void:
    rng.randomize()
    _build_ui()
    _load_game()
    _recalculate_stats()
    _apply_offline_progress()
    _refresh_all()
    _start_idle_animation()

func _process(delta: float) -> void:
    if auto_rate > 0.0:
        var gain: float = auto_rate * delta
        shards += gain
        total_shards += gain
        _check_chapter_unlocks()
    autosave_clock += delta
    if autosave_clock >= AUTOSAVE_INTERVAL:
        autosave_clock = 0.0
        _save_game()
    _refresh_topbar()
    _refresh_chapter_progress()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_game()
        get_tree().quit()

func _build_ui() -> void:
    var bg := ColorRect.new()
    bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    bg.color = Color("090b18")
    add_child(bg)

    var margin := MarginContainer.new()
    margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    margin.add_theme_constant_override("margin_left", 28)
    margin.add_theme_constant_override("margin_right", 28)
    margin.add_theme_constant_override("margin_top", 24)
    margin.add_theme_constant_override("margin_bottom", 24)
    add_child(margin)

    var root := VBoxContainer.new()
    root.add_theme_constant_override("separation", 16)
    margin.add_child(root)

    var header := HBoxContainer.new()
    header.add_theme_constant_override("separation", 22)
    root.add_child(header)

    var title := Label.new()
    title.text = "ОСКОЛКИ МИРОВ"
    title.add_theme_font_size_override("font_size", 28)
    title.add_theme_color_override("font_color", Color("dce7ff"))
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    header.add_child(title)

    shard_label = _stat_label("Осколки: 0")
    total_label = _stat_label("Всего: 0")
    click_label = _stat_label("Клик: +1")
    auto_label = _stat_label("/сек: 0")
    header.add_child(shard_label)
    header.add_child(total_label)
    header.add_child(click_label)
    header.add_child(auto_label)

    offline_label = Label.new()
    offline_label.text = ""
    offline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    offline_label.add_theme_color_override("font_color", Color("8ddcff"))
    root.add_child(offline_label)

    var body := HBoxContainer.new()
    body.size_flags_vertical = Control.SIZE_EXPAND_FILL
    body.add_theme_constant_override("separation", 18)
    root.add_child(body)

    var left_panel := PanelContainer.new()
    left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    left_panel.size_flags_stretch_ratio = 1.45
    left_panel.add_theme_stylebox_override("panel", _panel_style(Color("11172b"), 22))
    body.add_child(left_panel)

    var left_margin := MarginContainer.new()
    left_margin.add_theme_constant_override("margin_left", 24)
    left_margin.add_theme_constant_override("margin_right", 24)
    left_margin.add_theme_constant_override("margin_top", 24)
    left_margin.add_theme_constant_override("margin_bottom", 24)
    left_panel.add_child(left_margin)

    var left := VBoxContainer.new()
    left.alignment = BoxContainer.ALIGNMENT_CENTER
    left.add_theme_constant_override("separation", 14)
    left_margin.add_child(left)

    chapter_label = Label.new()
    chapter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_label.add_theme_font_size_override("font_size", 26)
    chapter_label.add_theme_color_override("font_color", Color("f3f6ff"))
    left.add_child(chapter_label)

    chapter_subtitle = Label.new()
    chapter_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    chapter_subtitle.add_theme_font_size_override("font_size", 17)
    chapter_subtitle.add_theme_color_override("font_color", Color("aab8d8"))
    left.add_child(chapter_subtitle)

    var stage := CenterContainer.new()
    stage.custom_minimum_size = Vector2(0, 330)
    stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
    left.add_child(stage)

    var stage_holder := Control.new()
    stage_holder.custom_minimum_size = Vector2(360, 300)
    stage.add_child(stage_holder)

    core_glow = ColorRect.new()
    core_glow.position = Vector2(55, 25)
    core_glow.size = Vector2(250, 250)
    core_glow.color = Color(0.24, 0.48, 1.0, 0.08)
    core_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage_holder.add_child(core_glow)

    core_button = Button.new()
    core_button.text = "◇"
    core_button.position = Vector2(80, 50)
    core_button.size = Vector2(200, 200)
    core_button.add_theme_font_size_override("font_size", 74)
    core_button.add_theme_color_override("font_color", Color("eaf2ff"))
    core_button.add_theme_stylebox_override("normal", _round_button_style(Color("243966"), Color("5f8cff"), 100))
    core_button.add_theme_stylebox_override("hover", _round_button_style(Color("2d477b"), Color("7ba0ff"), 100))
    core_button.add_theme_stylebox_override("pressed", _round_button_style(Color("18284b"), Color("9ab7ff"), 100))
    core_button.pressed.connect(_on_core_pressed)
    stage_holder.add_child(core_button)

    chapter_symbol = Label.new()
    chapter_symbol.text = ""
    chapter_symbol.position = Vector2(142, 258)
    chapter_symbol.size = Vector2(80, 40)
    chapter_symbol.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_symbol.add_theme_font_size_override("font_size", 20)
    chapter_symbol.add_theme_color_override("font_color", Color("7388b9"))
    stage_holder.add_child(chapter_symbol)

    chapter_progress = ProgressBar.new()
    chapter_progress.show_percentage = false
    chapter_progress.custom_minimum_size = Vector2(0, 18)
    left.add_child(chapter_progress)

    chapter_need_label = Label.new()
    chapter_need_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_need_label.add_theme_color_override("font_color", Color("7f90b8"))
    left.add_child(chapter_need_label)

    event_label = Label.new()
    event_label.text = "Импульс стабилен. Нажми на ядро."
    event_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    event_label.add_theme_color_override("font_color", Color("bcd0ff"))
    left.add_child(event_label)

    var right_panel := PanelContainer.new()
    right_panel.custom_minimum_size = Vector2(390, 0)
    right_panel.add_theme_stylebox_override("panel", _panel_style(Color("0e1427"), 22))
    body.add_child(right_panel)

    var right_margin := MarginContainer.new()
    right_margin.add_theme_constant_override("margin_left", 18)
    right_margin.add_theme_constant_override("margin_right", 18)
    right_margin.add_theme_constant_override("margin_top", 18)
    right_margin.add_theme_constant_override("margin_bottom", 18)
    right_panel.add_child(right_margin)

    var right := VBoxContainer.new()
    right.add_theme_constant_override("separation", 10)
    right_margin.add_child(right)

    var upgrades_title := Label.new()
    upgrades_title.text = "ПРОКАЧКА СИСТЕМЫ"
    upgrades_title.add_theme_font_size_override("font_size", 21)
    upgrades_title.add_theme_color_override("font_color", Color("e4ebff"))
    right.add_child(upgrades_title)

    var scroll := ScrollContainer.new()
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    right.add_child(scroll)

    upgrades_box = VBoxContainer.new()
    upgrades_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    upgrades_box.add_theme_constant_override("separation", 9)
    scroll.add_child(upgrades_box)

    _rebuild_upgrade_buttons()

func _stat_label(text_value: String) -> Label:
    var label := Label.new()
    label.text = text_value
    label.add_theme_font_size_override("font_size", 16)
    label.add_theme_color_override("font_color", Color("a9b9db"))
    return label

func _panel_style(color: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = Color(0.28, 0.37, 0.62, 0.25)
    return style

func _round_button_style(bg_color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = bg_color
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.border_width_left = 4
    style.border_width_top = 4
    style.border_width_right = 4
    style.border_width_bottom = 4
    style.border_color = border_color
    style.shadow_color = Color(0.2, 0.45, 1.0, 0.28)
    style.shadow_size = 18
    return style

func _upgrade_style(can_buy: bool) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = Color("18223f") if can_buy else Color("101729")
    style.corner_radius_top_left = 14
    style.corner_radius_top_right = 14
    style.corner_radius_bottom_left = 14
    style.corner_radius_bottom_right = 14
    style.border_width_left = 1
    style.border_width_top = 1
    style.border_width_right = 1
    style.border_width_bottom = 1
    style.border_color = Color("4f6fb0") if can_buy else Color("29334e")
    return style

func _on_core_pressed() -> void:
    var amount: float = click_power
    var critical: bool = rng.randf() < crit_chance
    if critical:
        amount *= crit_multiplier
    shards += amount
    total_shards += amount
    event_label.text = ("КРИТИЧЕСКИЙ ИМПУЛЬС! +%s" if critical else "+%s осколков") % _compact(amount)
    _spawn_float_text(amount, critical)
    _animate_click(critical)
    _check_chapter_unlocks()
    _refresh_all()

func _spawn_float_text(amount: float, critical: bool) -> void:
    var pop := Label.new()
    pop.text = "+%s" % _compact(amount)
    pop.add_theme_font_size_override("font_size", 24 if not critical else 30)
    pop.add_theme_color_override("font_color", Color("a9c2ff") if not critical else Color("fff0a6"))
    pop.position = core_button.global_position + Vector2(74, 50)
    pop.z_index = 50
    add_child(pop)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(pop, "position", pop.position + Vector2(rng.randf_range(-35.0, 35.0), -95), 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(pop, "modulate:a", 0.0, 0.75)
    tween.finished.connect(pop.queue_free)

func _animate_click(critical: bool) -> void:
    core_button.pivot_offset = core_button.size / 2.0
    var tween := create_tween()
    tween.tween_property(core_button, "scale", Vector2(0.92, 0.92), 0.06)
    tween.tween_property(core_button, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK)
    if critical:
        var base := position
        var shake := create_tween()
        shake.tween_property(self, "position", base + Vector2(-7, 0), 0.035)
        shake.tween_property(self, "position", base + Vector2(7, 0), 0.035)
        shake.tween_property(self, "position", base, 0.05)

func _start_idle_animation() -> void:
    core_glow.pivot_offset = core_glow.size / 2.0
    var tween := create_tween().set_loops()
    tween.tween_property(core_glow, "scale", Vector2(1.08, 1.08), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(core_glow, "scale", Vector2(0.94, 0.94), 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _rebuild_upgrade_buttons() -> void:
    for child in upgrades_box.get_children():
        child.queue_free()
    for i in range(upgrades.size()):
        var up = upgrades[i]
        var cost: float = _upgrade_cost(i)
        var btn := Button.new()
        btn.custom_minimum_size = Vector2(0, 82)
        btn.text = "%s  Lv.%d
%s
Цена: %s" % [up["name"], up["count"], up["desc"], _compact(cost)]
        btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
        btn.add_theme_font_size_override("font_size", 15)
        btn.add_theme_color_override("font_color", Color("d7e1ff"))
        btn.add_theme_stylebox_override("normal", _upgrade_style(shards >= cost))
        btn.add_theme_stylebox_override("hover", _upgrade_style(true))
        btn.add_theme_stylebox_override("pressed", _upgrade_style(true))
        btn.pressed.connect(_buy_upgrade.bind(i))
        upgrades_box.add_child(btn)

func _buy_upgrade(index: int) -> void:
    var cost: float = _upgrade_cost(index)
    if shards < cost:
        event_label.text = "Не хватает осколков: нужно %s." % _compact(cost)
        return
    shards -= cost
    upgrades[index]["count"] = int(upgrades[index]["count"]) + 1
    _recalculate_stats()
    event_label.text = "%s улучшен до уровня %d." % [upgrades[index]["name"], upgrades[index]["count"]]
    _refresh_all()
    _save_game()

func _upgrade_cost(index: int) -> float:
    var up = upgrades[index]
    return float(up["base"]) * pow(float(up["growth"]), int(up["count"]))

func _recalculate_stats() -> void:
    click_power = 1.0
    auto_rate = 0.0
    for up in upgrades:
        var contribution: float = float(up["value"]) * float(int(up["count"]))
        if up["kind"] == "click":
            click_power += contribution
        elif up["kind"] == "auto":
            auto_rate += contribution

func _check_chapter_unlocks() -> void:
    var unlocked: int = current_chapter
    for i in range(chapters.size()):
        if total_shards >= float(chapters[i]["need"]):
            unlocked = i
    if unlocked > current_chapter:
        current_chapter = unlocked
        _chapter_reveal()

func _chapter_reveal() -> void:
    var ch = chapters[current_chapter]
    event_label.text = "ОТКРЫТА НОВАЯ ГЛАВА: %s" % ch["title"]
    chapter_symbol.text = ch["symbol"]
    var tween := create_tween()
    chapter_label.modulate.a = 0.0
    chapter_subtitle.modulate.a = 0.0
    tween.set_parallel(true)
    tween.tween_property(chapter_label, "modulate:a", 1.0, 0.7)
    tween.tween_property(chapter_subtitle, "modulate:a", 1.0, 1.0)
    _save_game()

func _refresh_all() -> void:
    _refresh_topbar()
    _refresh_chapter()
    _refresh_chapter_progress()
    _rebuild_upgrade_buttons()

func _refresh_topbar() -> void:
    shard_label.text = "Осколки: %s" % _compact(shards)
    total_label.text = "Всего: %s" % _compact(total_shards)
    click_label.text = "Клик: +%s" % _compact(click_power)
    auto_label.text = "/сек: %s" % _compact(auto_rate)

func _refresh_chapter() -> void:
    var ch = chapters[current_chapter]
    chapter_label.text = ch["title"]
    chapter_subtitle.text = ch["subtitle"]
    chapter_symbol.text = ch["symbol"]
    core_button.text = ch["symbol"]
    var hue: float = float(current_chapter) / maxf(1.0, float(chapters.size() - 1))
    core_glow.color = Color.from_hsv(0.58 + hue * 0.18, 0.55, 1.0, 0.10)

func _refresh_chapter_progress() -> void:
    if current_chapter >= chapters.size() - 1:
        chapter_progress.value = 100
        chapter_need_label.text = "Все 10 глав открыты. Финальная иллюстрация доступна."
        return
    var from_need: float = float(chapters[current_chapter]["need"])
    var next_need: float = float(chapters[current_chapter + 1]["need"])
    var span: float = maxf(1.0, next_need - from_need)
    var pct: float = clampf((total_shards - from_need) / span * 100.0, 0.0, 100.0)
    chapter_progress.value = pct
    chapter_need_label.text = "До следующей главы: %s" % _compact(maxf(0.0, next_need - total_shards))

func _compact(value: float) -> String:
    var suffixes := ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"]
    var idx: int = 0
    var n: float = value
    while abs(n) >= 1000.0 and idx < suffixes.size() - 1:
        n /= 1000.0
        idx += 1
    if idx == 0:
        return str(int(round(value)))
    if abs(n) >= 100.0:
        return "%.0f%s" % [n, suffixes[idx]]
    if abs(n) >= 10.0:
        return "%.1f%s" % [n, suffixes[idx]]
    return "%.2f%s" % [n, suffixes[idx]]

func _save_game() -> void:
    var counts := []
    for up in upgrades:
        counts.append(int(up["count"]))
    var data := {
        "shards": shards,
        "total_shards": total_shards,
        "current_chapter": current_chapter,
        "upgrade_counts": counts,
        "last_unix": int(Time.get_unix_time_from_system())
    }
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file:
        file.store_string(JSON.stringify(data))

func _load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        last_unix = int(Time.get_unix_time_from_system())
        return
    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if not file:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    shards = float(parsed.get("shards", 0.0))
    total_shards = float(parsed.get("total_shards", 0.0))
    current_chapter = int(parsed.get("current_chapter", 0))
    last_unix = int(parsed.get("last_unix", Time.get_unix_time_from_system()))
    var counts = parsed.get("upgrade_counts", [])
    for i in range(min(counts.size(), upgrades.size())):
        upgrades[i]["count"] = int(counts[i])

func _apply_offline_progress() -> void:
    var now: int = int(Time.get_unix_time_from_system())
    if last_unix <= 0 or auto_rate <= 0.0:
        return
    var seconds: int = clampi(now - last_unix, 0, 8 * 60 * 60)
    if seconds <= 0:
        return
    var gain: float = auto_rate * float(seconds)
    shards += gain
    total_shards += gain
    offline_label.text = "Пока тебя не было: +%s осколков за %d мин." % [_compact(gain), int(seconds / 60)]
    _check_chapter_unlocks()
