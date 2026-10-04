extends Control

const SAVE_PATH := "user://shards_save.json"
const AUTOSAVE_INTERVAL := 5.0
const SfxBank = preload("res://sfx_bank.gd")
const AmbientFx = preload("res://ambient_fx.gd")
const MusicBank = preload("res://music_bank.gd")

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
    {"name":"Сингулярный экстрактор", "base":1800000000.0, "growth":1.98, "count":0, "kind":"auto", "value":22000000.0, "desc":"+22M осколков/сек"},
    {"name":"Контур вероятностей", "base":35000000000.0, "growth":1.92, "count":0, "kind":"auto", "value":400000000.0, "desc":"+400M осколков/сек"},
    {"name":"Лунный кластер", "base":800000000000.0, "growth":1.9, "count":0, "kind":"auto", "value":12000000000.0, "desc":"+12B осколков/сек"},
    {"name":"Ткацкий станок времени", "base":20000000000000.0, "growth":1.88, "count":0, "kind":"auto", "value":400000000000.0, "desc":"+400B осколков/сек"},
    {"name":"Реконструктор миров", "base":500000000000000.0, "growth":1.85, "count":0, "kind":"auto", "value":15000000000000.0, "desc":"+15T осколков/сек"}
]

var chapters := [
    {"need":0.0, "title":"Глава I — Первое отражение", "subtitle":"Архив оживает и показывает первое устойчивое отражение.", "symbol":"◇", "reward":"Судзунэ Хорикита", "art":"res://assets/gallery/01_horikita.png"},
    {"need":100.0, "title":"Глава II — Тёплый сигнал", "subtitle":"Осколки складываются в новое воспоминание.", "symbol":"✦", "reward":"Хонами Ичиносэ", "art":"res://assets/gallery/02_ichinose.png"},
    {"need":1000.0, "title":"Глава III — Лунный архив", "subtitle":"В памяти появляется мир, где всё решалось одним выбором.", "symbol":"☾", "reward":"Кагуя Синомия", "art":"res://assets/gallery/03_kaguya.png"},
    {"need":10000.0, "title":"Глава IV — Красная линия", "subtitle":"Стабилизатор впервые собирает полноценную сцену.", "symbol":"◈", "reward":"Асуна Юки", "art":"res://assets/gallery/04_asuna.png"},
    {"need":100000.0, "title":"Глава V — След чужого мира", "subtitle":"Архив начинает открывать образы из всё более далёких реальностей.", "symbol":"✧", "reward":"Элизабет Лайонес", "art":"res://assets/gallery/05_elizabeth.png"},
    {"need":1000000.0, "title":"Глава VI — Риск", "subtitle":"Система предлагает опасную ветку восстановления.", "symbol":"♠", "reward":"Юмэко Джабами", "art":"res://assets/gallery/06_yumeko.png"},
    {"need":10000000.0, "title":"Глава VII — Серебряный свет", "subtitle":"Отражение удерживается уже без ручной стабилизации.", "symbol":"❄", "reward":"Эмилия", "art":"res://assets/gallery/07_emilia.png"},
    {"need":100000000.0, "title":"Глава VIII — Долгая память", "subtitle":"Устройство начинает помнить то, что старше его самого.", "symbol":"✤", "reward":"Фрирен", "art":"res://assets/gallery/08_frieren.png"},
    {"need":1000000000.0, "title":"Глава IX — Тихий вечер", "subtitle":"Архив открывает спокойное отражение, за которым чувствуется скрытая опасность.", "symbol":"◆", "reward":"Йор Форджер", "art":"res://assets/gallery/09_yor.png"},
    {"need":10000000000.0, "title":"Глава X — Свет сцены", "subtitle":"Восстановленное отражение отвечает яркой вспышкой со сцены.", "symbol":"★", "reward":"Руби Хосино", "art":"res://assets/gallery/10_ruby.png"},
    {"need":100000000000.0, "title":"Глава XI — Звезда архива", "subtitle":"Система впервые удерживает образ даже во время перегрузки ядра.", "symbol":"✺", "reward":"Ай Хосино", "art":"res://assets/gallery/11_ai.png"},
    {"need":10000000000000.0, "title":"Глава XII — Последняя магия", "subtitle":"Почти все фрагменты заняли свои места.", "symbol":"✦", "reward":"Рокси Мигурдия", "art":"res://assets/gallery/12_roxy.png"},
    {"need":1000000000000000.0, "title":"Глава XIII — Совершенство", "subtitle":"Финальный архив открывается совсем не так, как ожидалось.", "symbol":"∞", "reward":"Аянокоджи", "art":"res://assets/gallery/13_ayanokoji.png"}
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
var fx_layer: Control
var bonus_clock: float = 18.0
var rare_bonus_button: Button
var last_click_fx_tier: int = 0
var sfx_bank
var gallery_button: Button
var gallery_overlay: ColorRect
var gallery_grid: GridContainer
var gallery_preview: TextureRect
var gallery_preview_text: Label
var reward_overlay: ColorRect
var reward_card: PanelContainer
var reward_art: TextureRect
var reward_name: Label
var reward_title: Label
var current_art: TextureRect
var current_art_frame: Panel

func _ready() -> void:
    rng.randomize()
    sfx_bank = SfxBank.new()
    add_child(sfx_bank)
    var music_bank := MusicBank.new()
    add_child(music_bank)
    _build_ui()
    _build_fx_layer()
    _build_gallery_overlay()
    _build_reward_overlay()
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
    bonus_clock -= delta
    if bonus_clock <= 0.0 and not is_instance_valid(rare_bonus_button):
        _spawn_rare_bonus()
        bonus_clock = rng.randf_range(22.0, 38.0)

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

    var ambient := AmbientFx.new()
    add_child(ambient)

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

    gallery_button = Button.new()
    gallery_button.text = "ГАЛЕРЕЯ"
    gallery_button.custom_minimum_size = Vector2(110, 38)
    gallery_button.add_theme_font_size_override("font_size", 14)
    gallery_button.pressed.connect(_toggle_gallery)
    header.add_child(gallery_button)

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
    stage_holder.custom_minimum_size = Vector2(660, 300)
    stage.add_child(stage_holder)

    current_art_frame = Panel.new()
    current_art_frame.position = Vector2(0, 4)
    current_art_frame.size = Vector2(286, 286)
    current_art_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
    current_art_frame.add_theme_stylebox_override("panel", _panel_style(Color("141a31"), 20))
    stage_holder.add_child(current_art_frame)

    current_art = TextureRect.new()
    current_art.position = Vector2(8, 8)
    current_art.size = Vector2(270, 270)
    current_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    current_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    current_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    current_art.modulate = Color(1.0, 1.0, 1.0, 0.96)
    current_art_frame.add_child(current_art)

    core_glow = ColorRect.new()
    core_glow.position = Vector2(355, 25)
    core_glow.size = Vector2(250, 250)
    core_glow.color = Color(0.24, 0.48, 1.0, 0.08)
    core_glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage_holder.add_child(core_glow)

    core_button = Button.new()
    core_button.text = "◇"
    core_button.position = Vector2(380, 50)
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
    chapter_symbol.position = Vector2(442, 258)
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

func _build_gallery_overlay() -> void:
    gallery_overlay = ColorRect.new()
    gallery_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    gallery_overlay.color = Color(0.025, 0.02, 0.07, 0.96)
    gallery_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    gallery_overlay.z_index = 200
    gallery_overlay.visible = false
    add_child(gallery_overlay)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    gallery_overlay.add_child(center)

    var panel := PanelContainer.new()
    panel.custom_minimum_size = Vector2(1040, 620)
    panel.add_theme_stylebox_override("panel", _panel_style(Color("101426"), 22))
    center.add_child(panel)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 22)
    margin.add_theme_constant_override("margin_right", 22)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    panel.add_child(margin)

    var layout := VBoxContainer.new()
    layout.add_theme_constant_override("separation", 14)
    margin.add_child(layout)

    var top := HBoxContainer.new()
    layout.add_child(top)

    var title := Label.new()
    title.text = "АРХИВ ОТРАЖЕНИЙ"
    title.add_theme_font_size_override("font_size", 26)
    title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    top.add_child(title)

    var close := Button.new()
    close.text = "Закрыть"
    close.pressed.connect(_toggle_gallery)
    top.add_child(close)

    var content := HBoxContainer.new()
    content.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_theme_constant_override("separation", 18)
    layout.add_child(content)

    var scroll := ScrollContainer.new()
    scroll.custom_minimum_size = Vector2(520, 0)
    scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
    content.add_child(scroll)

    gallery_grid = GridContainer.new()
    gallery_grid.columns = 2
    gallery_grid.add_theme_constant_override("h_separation", 10)
    gallery_grid.add_theme_constant_override("v_separation", 10)
    scroll.add_child(gallery_grid)

    var preview_box := VBoxContainer.new()
    preview_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    preview_box.add_theme_constant_override("separation", 12)
    content.add_child(preview_box)

    gallery_preview = TextureRect.new()
    gallery_preview.custom_minimum_size = Vector2(430, 430)
    gallery_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    gallery_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    preview_box.add_child(gallery_preview)

    gallery_preview_text = Label.new()
    gallery_preview_text.text = "Здесь появляются только уже восстановленные отражения."
    gallery_preview_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    gallery_preview_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    gallery_preview_text.add_theme_font_size_override("font_size", 18)
    gallery_preview_text.add_theme_color_override("font_color", Color("cbd7f7"))
    preview_box.add_child(gallery_preview_text)

    _rebuild_gallery_cards()

func _toggle_gallery() -> void:
    gallery_overlay.visible = not gallery_overlay.visible
    if gallery_overlay.visible:
        _rebuild_gallery_cards()
        sfx_bank.play("open")

func _rebuild_gallery_cards() -> void:
    if not is_instance_valid(gallery_grid):
        return
    for child in gallery_grid.get_children():
        child.queue_free()

    var unlocked_count: int = 0
    for i in range(chapters.size()):
        var ch = chapters[i]
        var unlocked: bool = total_shards >= float(ch["need"])
        if not unlocked:
            continue

        unlocked_count += 1
        var card := Button.new()
        card.custom_minimum_size = Vector2(245, 104)
        card.alignment = HORIZONTAL_ALIGNMENT_LEFT
        card.add_theme_font_size_override("font_size", 15)
        card.text = "%s\n%s" % [ch["reward"], ch["title"]]
        var art_path: String = String(ch["art"])
        if ResourceLoader.exists(art_path):
            var texture = load(art_path)
            if texture is Texture2D:
                card.icon = texture
                card.expand_icon = true
        card.pressed.connect(_show_gallery_entry.bind(i))
        gallery_grid.add_child(card)

    if unlocked_count == 0:
        var empty := Label.new()
        empty.text = "Архив пока пуст. Первое отражение ещё не восстановлено."
        empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        empty.add_theme_font_size_override("font_size", 18)
        empty.add_theme_color_override("font_color", Color("8795ba"))
        gallery_grid.add_child(empty)

func _show_gallery_entry(index: int) -> void:
    var ch = chapters[index]
    var art_path: String = String(ch["art"])
    gallery_preview.texture = null

    if ResourceLoader.exists(art_path):
        var texture = load(art_path)
        if texture is Texture2D:
            gallery_preview.texture = texture
            gallery_preview_text.text = "%s\n%s" % [ch["reward"], ch["subtitle"]]
        else:
            gallery_preview_text.text = "%s\nИллюстрация готовится." % ch["reward"]
    else:
        gallery_preview_text.text = "%s\nИллюстрация готовится." % ch["reward"]
    sfx_bank.play("open")

func _build_reward_overlay() -> void:
    reward_overlay = ColorRect.new()
    reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    reward_overlay.color = Color(0.015, 0.01, 0.04, 0.0)
    reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    reward_overlay.z_index = 300
    reward_overlay.visible = false
    add_child(reward_overlay)

    var center := CenterContainer.new()
    center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    reward_overlay.add_child(center)

    reward_card = PanelContainer.new()
    reward_card.custom_minimum_size = Vector2(520, 610)
    reward_card.add_theme_stylebox_override("panel", _panel_style(Color("171226"), 26))
    reward_card.pivot_offset = Vector2(260, 305)
    center.add_child(reward_card)

    var margin := MarginContainer.new()
    margin.add_theme_constant_override("margin_left", 20)
    margin.add_theme_constant_override("margin_right", 20)
    margin.add_theme_constant_override("margin_top", 18)
    margin.add_theme_constant_override("margin_bottom", 18)
    reward_card.add_child(margin)

    var box := VBoxContainer.new()
    box.alignment = BoxContainer.ALIGNMENT_CENTER
    box.add_theme_constant_override("separation", 12)
    margin.add_child(box)

    reward_title = Label.new()
    reward_title.text = "НОВОЕ ОТРАЖЕНИЕ"
    reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reward_title.add_theme_font_size_override("font_size", 24)
    reward_title.add_theme_color_override("font_color", Color("f7dfff"))
    box.add_child(reward_title)

    reward_art = TextureRect.new()
    reward_art.custom_minimum_size = Vector2(450, 450)
    reward_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    reward_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    box.add_child(reward_art)

    reward_name = Label.new()
    reward_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reward_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    reward_name.add_theme_font_size_override("font_size", 28)
    reward_name.add_theme_color_override("font_color", Color("ffffff"))
    box.add_child(reward_name)

    var close := Button.new()
    close.text = "В галерею"
    close.custom_minimum_size = Vector2(0, 46)
    close.pressed.connect(_close_reward_overlay)
    box.add_child(close)

func _show_reward_overlay(index: int) -> void:
    if index < 0 or index >= chapters.size():
        return
    var ch = chapters[index]
    var is_final: bool = index == chapters.size() - 1
    reward_title.text = "ТЫ ДОСТИГ СОВЕРШЕНСТВА" if is_final else "НОВОЕ ОТРАЖЕНИЕ"
    reward_title.add_theme_color_override("font_color", Color("ffd978") if is_final else Color("f7dfff"))
    reward_name.text = String(ch["reward"])
    reward_art.texture = null
    var art_path: String = String(ch["art"])
    if ResourceLoader.exists(art_path):
        var texture = load(art_path)
        if texture is Texture2D:
            reward_art.texture = texture

    reward_overlay.visible = true
    reward_overlay.color.a = 0.0
    reward_card.modulate.a = 0.0
    reward_card.scale = Vector2(0.72, 0.72)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(reward_overlay, "color:a", 0.97 if is_final else 0.94, 0.28)
    tween.tween_property(reward_card, "modulate:a", 1.0, 0.28)
    tween.tween_property(reward_card, "scale", Vector2.ONE, 0.58 if is_final else 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    var spark_count: int = 110 if is_final else 52
    for i in range(spark_count):
        _spawn_reveal_spark()

    if is_final:
        sfx_bank.play("crit")
        var base_pos: Vector2 = position
        var shake := create_tween()
        shake.tween_property(self, "position", base_pos + Vector2(-12, 4), 0.05)
        shake.tween_property(self, "position", base_pos + Vector2(11, -3), 0.05)
        shake.tween_property(self, "position", base_pos + Vector2(-8, 2), 0.05)
        shake.tween_property(self, "position", base_pos + Vector2(6, -1), 0.05)
        shake.tween_property(self, "position", base_pos, 0.08)

func _close_reward_overlay() -> void:
    if not is_instance_valid(reward_overlay) or not reward_overlay.visible:
        return
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(reward_overlay, "color:a", 0.0, 0.20)
    tween.tween_property(reward_card, "modulate:a", 0.0, 0.18)
    tween.tween_property(reward_card, "scale", Vector2(0.90, 0.90), 0.20)
    tween.finished.connect(_finish_close_reward)

func _finish_close_reward() -> void:
    reward_overlay.visible = false
    _toggle_gallery()

func _build_fx_layer() -> void:
    fx_layer = Control.new()
    fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fx_layer.z_index = 100
    add_child(fx_layer)

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
    sfx_bank.play("crit" if critical else "click")
    _spawn_float_text(amount, critical)
    _spawn_click_particles(critical)
    _animate_click(critical)
    _check_chapter_unlocks()
    _refresh_all()

func _spawn_click_particles(critical: bool) -> void:
    if not is_instance_valid(fx_layer):
        return

    var tier: int = mini(5, 1 + int(log(maxf(click_power, 1.0)) / log(10.0)))
    last_click_fx_tier = tier
    var particle_count: int = 6 + tier * 3 + (8 if critical else 0)
    var center: Vector2 = core_button.global_position + core_button.size / 2.0

    for i in range(particle_count):
        var spark := ColorRect.new()
        var size_px: float = rng.randf_range(3.0, 7.0 + float(tier))
        spark.size = Vector2(size_px, size_px)
        spark.position = center - spark.size / 2.0
        spark.color = Color.from_hsv(rng.randf_range(0.53, 0.72), 0.55, 1.0, 0.92)
        spark.rotation = rng.randf_range(-PI, PI)
        spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
        fx_layer.add_child(spark)

        var angle: float = rng.randf_range(0.0, TAU)
        var distance: float = rng.randf_range(35.0, 75.0 + 16.0 * float(tier))
        if critical:
            distance *= 1.35
        var target: Vector2 = spark.position + Vector2(cos(angle), sin(angle)) * distance
        var duration: float = rng.randf_range(0.28, 0.55)
        var tween := create_tween()
        tween.set_parallel(true)
        tween.tween_property(spark, "position", target, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(spark, "modulate:a", 0.0, duration)
        tween.tween_property(spark, "rotation", spark.rotation + rng.randf_range(-2.0, 2.0), duration)
        tween.finished.connect(spark.queue_free)

    if tier >= 3 or critical:
        _spawn_energy_ring(center, critical)

func _spawn_energy_ring(center: Vector2, critical: bool) -> void:
    var ring := Panel.new()
    var diameter: float = 56.0 if not critical else 78.0
    ring.size = Vector2(diameter, diameter)
    ring.position = center - ring.size / 2.0
    ring.pivot_offset = ring.size / 2.0
    ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0, 0, 0, 0)
    style.border_width_left = 3 if critical else 2
    style.border_width_top = 3 if critical else 2
    style.border_width_right = 3 if critical else 2
    style.border_width_bottom = 3 if critical else 2
    style.border_color = Color(0.62, 0.82, 1.0, 0.9) if not critical else Color(1.0, 0.84, 0.38, 0.95)
    style.corner_radius_top_left = int(diameter / 2.0)
    style.corner_radius_top_right = int(diameter / 2.0)
    style.corner_radius_bottom_left = int(diameter / 2.0)
    style.corner_radius_bottom_right = int(diameter / 2.0)
    ring.add_theme_stylebox_override("panel", style)
    fx_layer.add_child(ring)

    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(ring, "scale", Vector2(3.0, 3.0) if critical else Vector2(2.2, 2.2), 0.36)
    tween.tween_property(ring, "modulate:a", 0.0, 0.36)
    tween.finished.connect(ring.queue_free)

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

    if is_instance_valid(current_art):
        current_art.pivot_offset = current_art.size / 2.0
        var art_tween := create_tween().set_loops()
        art_tween.tween_property(current_art, "scale", Vector2(1.025, 1.025), 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
        art_tween.tween_property(current_art, "scale", Vector2.ONE, 2.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

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
    sfx_bank.play("buy")
    _spawn_level_up(upgrades[index]["name"])
    _refresh_all()
    _save_game()

func _spawn_level_up(upgrade_name: String) -> void:
    if not is_instance_valid(fx_layer):
        return
    var label := Label.new()
    label.text = "LEVEL UP  •  %s" % upgrade_name
    label.add_theme_font_size_override("font_size", 22)
    label.add_theme_color_override("font_color", Color("fff2a6"))
    label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.position = Vector2(size.x * 0.58, size.y * 0.24)
    label.modulate.a = 0.0
    fx_layer.add_child(label)
    var start_pos: Vector2 = label.position
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "modulate:a", 1.0, 0.12)
    tween.tween_property(label, "position", start_pos + Vector2(0, -24), 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween.chain().tween_property(label, "modulate:a", 0.0, 0.28)
    tween.finished.connect(label.queue_free)

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
    sfx_bank.play("unlock")
    _chapter_flash("%s  •  %s" % [ch["title"], ch["reward"]])
    _rebuild_gallery_cards()
    _show_reward_overlay(current_chapter)

    if is_instance_valid(current_art):
        current_art.modulate.a = 0.0
        current_art.scale = Vector2(0.94, 0.94)
        var art_reveal := create_tween()
        art_reveal.set_parallel(true)
        art_reveal.tween_property(current_art, "modulate:a", 0.96, 0.55)
        art_reveal.tween_property(current_art, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    var tween := create_tween()
    chapter_label.modulate.a = 0.0
    chapter_subtitle.modulate.a = 0.0
    chapter_label.scale = Vector2(0.92, 0.92)
    chapter_label.pivot_offset = chapter_label.size / 2.0
    tween.set_parallel(true)
    tween.tween_property(chapter_label, "modulate:a", 1.0, 0.7)
    tween.tween_property(chapter_subtitle, "modulate:a", 1.0, 1.0)
    tween.tween_property(chapter_label, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    _save_game()

func _chapter_flash(title_text: String) -> void:
    if not is_instance_valid(fx_layer):
        return

    var flash := ColorRect.new()
    flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    flash.color = Color(0.70, 0.83, 1.0, 0.0)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fx_layer.add_child(flash)

    var banner := Label.new()
    banner.text = "НОВАЯ ИЛЛЮСТРАЦИЯ\n%s" % title_text
    banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    banner.set_anchors_preset(Control.PRESET_CENTER)
    banner.position = Vector2(-330, -70)
    banner.size = Vector2(660, 140)
    banner.add_theme_font_size_override("font_size", 28)
    banner.add_theme_color_override("font_color", Color("f4f7ff"))
    banner.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
    banner.add_theme_constant_override("shadow_offset_x", 3)
    banner.add_theme_constant_override("shadow_offset_y", 3)
    banner.modulate.a = 0.0
    banner.scale = Vector2(0.88, 0.88)
    banner.pivot_offset = banner.size / 2.0
    fx_layer.add_child(banner)

    var flash_tween := create_tween()
    flash_tween.tween_property(flash, "color:a", 0.52, 0.10)
    flash_tween.tween_property(flash, "color:a", 0.0, 0.55)
    flash_tween.finished.connect(flash.queue_free)

    var banner_tween := create_tween()
    banner_tween.set_parallel(true)
    banner_tween.tween_property(banner, "modulate:a", 1.0, 0.22)
    banner_tween.tween_property(banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    banner_tween.chain().tween_interval(0.7)
    banner_tween.chain().tween_property(banner, "modulate:a", 0.0, 0.35)
    banner_tween.finished.connect(banner.queue_free)

    for i in range(34):
        _spawn_reveal_spark()

func _spawn_reveal_spark() -> void:
    if not is_instance_valid(fx_layer):
        return
    var spark := ColorRect.new()
    var px: float = rng.randf_range(3.0, 8.0)
    spark.size = Vector2(px, px)
    spark.position = Vector2(rng.randf_range(0.0, maxf(size.x, 1.0)), rng.randf_range(0.0, maxf(size.y, 1.0)))
    spark.color = Color.from_hsv(rng.randf_range(0.53, 0.70), 0.45, 1.0, 0.9)
    fx_layer.add_child(spark)
    var target: Vector2 = spark.position + Vector2(rng.randf_range(-70.0, 70.0), rng.randf_range(-120.0, -35.0))
    var duration: float = rng.randf_range(0.6, 1.2)
    var tween := create_tween()
    tween.set_parallel(true)
    tween.tween_property(spark, "position", target, duration)
    tween.tween_property(spark, "modulate:a", 0.0, duration)
    tween.finished.connect(spark.queue_free)

func _spawn_rare_bonus() -> void:
    if not is_instance_valid(fx_layer) or is_instance_valid(rare_bonus_button):
        return

    var bonus := Button.new()
    rare_bonus_button = bonus
    bonus.text = "✦"
    bonus.size = Vector2(64, 64)
    bonus.position = Vector2(-72, rng.randf_range(120.0, maxf(160.0, size.y - 160.0)))
    bonus.add_theme_font_size_override("font_size", 34)
    bonus.add_theme_color_override("font_color", Color("fff2a0"))
    bonus.add_theme_stylebox_override("normal", _round_button_style(Color("493a13"), Color("ffd85e"), 32))
    bonus.add_theme_stylebox_override("hover", _round_button_style(Color("675019"), Color("ffe889"), 32))
    bonus.add_theme_stylebox_override("pressed", _round_button_style(Color("2e260f"), Color("ffffff"), 32))
    bonus.mouse_filter = Control.MOUSE_FILTER_STOP
    bonus.pressed.connect(_collect_rare_bonus.bind(bonus))
    fx_layer.add_child(bonus)

    event_label.text = "Редкий осколок появился! Успей поймать его."
    var target_x: float = maxf(size.x + 20.0, 1300.0)
    var tween := create_tween()
    tween.tween_property(bonus, "position:x", target_x, 6.0).set_trans(Tween.TRANS_LINEAR)
    tween.finished.connect(_expire_rare_bonus.bind(bonus))

func _collect_rare_bonus(button: Button) -> void:
    if not is_instance_valid(button):
        return
    var reward: float = maxf(click_power * 20.0, maxf(25.0, auto_rate * 8.0))
    shards += reward
    total_shards += reward
    event_label.text = "РЕДКИЙ БОНУС! +%s осколков" % _compact(reward)
    sfx_bank.play("bonus")
    _spawn_float_text(reward, true)
    _spawn_click_particles(true)
    if rare_bonus_button == button:
        rare_bonus_button = null
    button.queue_free()
    _check_chapter_unlocks()
    _refresh_all()

func _expire_rare_bonus(button: Button) -> void:
    if not is_instance_valid(button):
        return
    if rare_bonus_button == button:
        rare_bonus_button = null
    button.queue_free()

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
    core_button.tooltip_text = "Текущее отражение: %s" % ch["reward"]

    if is_instance_valid(current_art):
        current_art.texture = null
        var art_path: String = String(ch["art"])
        if ResourceLoader.exists(art_path):
            var texture = load(art_path)
            if texture is Texture2D:
                current_art.texture = texture

    var hue: float = float(current_chapter) / maxf(1.0, float(chapters.size() - 1))
    core_glow.color = Color.from_hsv(0.58 + hue * 0.18, 0.55, 1.0, 0.10)

func _refresh_chapter_progress() -> void:
    if current_chapter >= chapters.size() - 1:
        chapter_progress.value = 100
        chapter_need_label.text = "Все 13 отражений открыты. Финальная награда доступна."
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
