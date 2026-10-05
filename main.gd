extends Control

const SAVE_PATH: String = "user://shards_worlds_save_v3.json"
const AUTOSAVE_INTERVAL: float = 5.0
const BONUS_MIN_TIME: float = 20.0
const BONUS_MAX_TIME: float = 34.0
const SfxBank = preload("res://sfx_bank.gd")
const MusicBank = preload("res://music_bank.gd")
const BackgroundLoader = preload("res://background_loader.gd")

var shards: float = 0.0
var total_shards: float = 0.0
var click_power: float = 1.0
var auto_rate: float = 0.0
var current_chapter: int = 0
var active_character: int = 0
var auto_tick_clock: float = 0.0
var crit_chance: float = 0.06
var crit_multiplier: float = 5.0
var boost_multiplier: float = 1.0
var boost_time_left: float = 0.0
var bonus_clock: float = 12.0
var autosave_clock: float = 0.0
var automation_refresh_clock: float = 0.0
var upgrade_buy_buttons: Dictionary = {}
var last_visible_upgrade_count: int = -1
var last_unix: int = 0
var total_clicks: int = 0
var critical_clicks: int = 0
var caught_bonuses: int = 0
var session_time: float = 0.0
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var sfx_bank: Node
var music_bank: Node
var rare_bonus_button: Button

var ui_font: SystemFont
var title_font: SystemFont

var shard_value_label: Label
var shard_rate_label: Label
var chapter_counter_label: Label
var task_label: Label
var task_progress: ProgressBar
var task_value_label: Label
var click_gain_label: Label
var resonance_panel: Panel
var resonance_title: Label
var resonance_time_label: Label
var background_layer: TextureRect
var main_ui_root: Control
var character_portrait: TextureRect
var character_rarity_label: Label
var character_name_label: Label
var character_bonus_label: Label
var character_quote_label: Label
var automation_header: Label
var automation_box: VBoxContainer
var collection_title: Label
var collection_box: HBoxContainer
var fx_layer: Control
var crystal_ring_a: Panel
var crystal_ring_b: Panel
var click_hotspot: Button
var offline_label: Label

var overlay_root: ColorRect
var overlay_title: Label
var overlay_content: VBoxContainer
var overlay_close: Button

var reward_overlay: ColorRect
var reward_card: Panel
var reward_title: Label
var reward_art: TextureRect
var reward_name: Label
var reward_story: Label

var upgrades: Array = [
    {"name":"Усилитель импульса", "base":20.0, "growth":1.55, "kind":"click", "value":1.0, "unlock":0.0, "count":0, "icon":"✦", "desc":"+1 к силе клика"},
    {"name":"Кристаллический рудник", "base":60.0, "growth":1.68, "kind":"auto", "value":5.0, "unlock":25.0, "count":0, "icon":"◆", "desc":"+5 / сек"},
    {"name":"Портал осколков", "base":520.0, "growth":1.72, "kind":"auto", "value":40.0, "unlock":300.0, "count":0, "icon":"◉", "desc":"+40 / сек"},
    {"name":"Хранилище миров", "base":6200.0, "growth":1.76, "kind":"auto", "value":450.0, "unlock":3500.0, "count":0, "icon":"◇", "desc":"+450 / сек"},
    {"name":"Сингулярный экстрактор", "base":78000.0, "growth":1.79, "kind":"auto", "value":6500.0, "unlock":42000.0, "count":0, "icon":"◎", "desc":"+6.5K / сек"},
    {"name":"Орбитальный сборщик", "base":1100000.0, "growth":1.82, "kind":"auto", "value":95000.0, "unlock":650000.0, "count":0, "icon":"✧", "desc":"+95K / сек"},
    {"name":"Межмировой комплекс", "base":18000000.0, "growth":1.84, "kind":"auto", "value":1600000.0, "unlock":9000000.0, "count":0, "icon":"✺", "desc":"+1.6M / сек"},
    {"name":"Контур вероятностей", "base":310000000.0, "growth":1.86, "kind":"auto", "value":30000000.0, "unlock":140000000.0, "count":0, "icon":"∞", "desc":"+30M / сек"},
    {"name":"Лунный кластер", "base":6500000000.0, "growth":1.88, "kind":"auto", "value":720000000.0, "unlock":2500000000.0, "count":0, "icon":"☾", "desc":"+720M / сек"},
    {"name":"Ткацкий станок времени", "base":145000000000.0, "growth":1.90, "kind":"auto", "value":18000000000.0, "unlock":55000000000.0, "count":0, "icon":"⌛", "desc":"+18B / сек"},
    {"name":"Архив синхронизации", "base":4200000000000.0, "growth":1.92, "kind":"auto", "value":650000000000.0, "unlock":1300000000000.0, "count":0, "icon":"✣", "desc":"+650B / сек"},
    {"name":"Реконструктор миров", "base":120000000000000.0, "growth":1.94, "kind":"auto", "value":22000000000000.0, "unlock":35000000000000.0, "count":0, "icon":"✹", "desc":"+22T / сек"}
]

var chapters: Array = [
    {"need":0.0, "name":"Судзунэ Хорикита", "art":"res://assets/gallery/01_horikita.png", "background":"res://assets/backgrounds/01_horikita.webp", "wide_layout":false, "rarity":"Обычный", "bonus_kind":"all_income", "bonus_value":0.08, "bonus_text":"Бонус коллекции: +8% ко всему доходу", "quote":"«Слишком много шума. Но твой прогресс... не такой уж и плохой.»", "story":"Повреждённый Архив впервые отвечает на твой импульс. Первое отражение стабилизируется, и система начинает поиск остальных фрагментов."},
    {"need":100.0, "name":"Хонами Ичиносэ", "art":"res://assets/gallery/02_ichinose.png", "background":"res://assets/backgrounds/02_ichinose.webp", "wide_layout":false, "rarity":"Редкий", "bonus_kind":"auto_income", "bonus_value":0.12, "bonus_text":"+12% к пассивному доходу", "quote":"«Я всегда рядом. Спасибо, что проводишь это время со мной...»", "story":"Второе отражение приносит тёплый сигнал. Вместе с ним появляется предупреждение: Архив хранит больше, чем показывает."},
    {"need":1000.0, "name":"Кагуя Синомия", "art":"res://assets/gallery/03_kaguya.png", "background":"res://assets/backgrounds/03_kaguya.webp", "wide_layout":false, "rarity":"Эпический", "bonus_kind":"auto_double_chance", "bonus_value":0.18, "bonus_text":"18% шанс удвоить доход автофарма", "quote":"«Побеждает не тот, кто спешит, а тот, кто всё просчитывает.»", "story":"Система начинает оценивать восстановленные данные. В журнале появляется загадочная строка: «Поиск совершенства начат»."},
    {"need":10000.0, "name":"Асуна Юки", "art":"res://assets/gallery/04_asuna.png", "background":"res://assets/backgrounds/04_asuna.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"click_power", "bonus_value":0.35, "bonus_text":"+35% к силе клика", "quote":"«Я буду рядом. Мы обязательно дойдём до конца.»", "story":"Стабилизатор удерживает целую сцену без сбоев. Теперь Архив способен автоматически собирать часть осколков."},
    {"need":100000.0, "name":"Элизабет Лайонес", "art":"res://assets/gallery/05_elizabeth.png", "background":"res://assets/backgrounds/05_elizabeth.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"upgrade_discount", "bonus_value":0.12, "bonus_text":"−12% к стоимости улучшений", "quote":"«Я всегда буду рядом. Пока есть надежда, мы можем идти дальше.»", "story":"За отражением обнаруживается след ещё десятков миров. Архив явно выбирал изображения не случайно."},
    {"need":1000000.0, "name":"Юмэко Джабами", "art":"res://assets/gallery/06_yumeko.png", "background":"res://assets/backgrounds/06_yumeko.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"resonance_frequency", "bonus_value":0.25, "bonus_text":"+25% к шансу редкого Резонанса", "quote":"«Риск — это не угроза. Это то, что делает жизнь по-настоящему интересной.»", "story":"Ядро становится нестабильным и время от времени выбрасывает редкие осколки. Пойманный осколок кратко удваивает всю добычу."},
    {"need":10000000.0, "name":"Эмилия", "art":"res://assets/gallery/07_emilia.png", "background":"res://assets/backgrounds/07_emilia.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"resonance_duration", "bonus_value":0.40, "bonus_text":"+40% к длительности Резонанса", "quote":"«Я хочу быть рядом. Всегда. В этом мире и в любом другом.»", "story":"Автоматизация работает почти сама. Архив впервые спрашивает напрямую: «Ты действительно хочешь увидеть финал?»"},
    {"need":100000000.0, "name":"Фрирен", "art":"res://assets/gallery/08_frieren.png", "background":"res://assets/backgrounds/08_frieren.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"offline_income", "bonus_value":1.0, "bonus_text":"+100% к офлайн-доходу", "quote":"«Время течёт. Но хорошие воспоминания всегда остаются рядом.»", "story":"Среди старых данных находится запись создателя: самое ценное отражение он намеренно оставил последним."},
    {"need":1000000000.0, "name":"Йор Форджер", "art":"res://assets/gallery/09_yor.png", "background":"res://assets/backgrounds/09_yor.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"crit_power", "bonus_value":0.60, "bonus_text":"+60% к силе критического клика", "quote":"«Я просто обычная жена. Но ради тех, кого я люблю, я могу стать кем угодно.»", "story":"Имена будущих отражений полностью стёрты. Архив явно не желает портить сюрприз."},
    {"need":10000000000.0, "name":"Руби Хосино", "art":"res://assets/gallery/10_ruby.png", "background":"res://assets/backgrounds/10_ruby.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"task_reward", "bonus_value":0.50, "bonus_text":"+50% к наградам за задания", "quote":"«Я хочу, чтобы ещё больше людей увидели мир, который я люблю! Ведь сиять вместе — это так здорово!»", "story":"В ядре появляется скрытая шкала «Совершенство», но без процентов. Чем больше осколков, тем ярче она сияет."},
    {"need":100000000000.0, "name":"Ай Хосино", "art":"res://assets/gallery/11_ai.png", "background":"res://assets/backgrounds/11_ai.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"all_income", "bonus_value":0.25, "bonus_text":"+25% ко всему доходу", "quote":"«Я хочу, чтобы как можно больше людей полюбили меня! Ведь я — айдол!»", "story":"Последние данные зашифрованы одной фразой: «Идеал нельзя описать. Его можно только увидеть»."},
    {"need":10000000000000.0, "name":"Рокси Мигурдия", "art":"res://assets/gallery/12_roxy.png", "background":"res://assets/backgrounds/12_roxy.webp", "wide_layout":true, "rarity":"Эпический", "bonus_kind":"auto_efficiency", "bonus_value":0.35, "bonus_text":"+35% к эффективности автоматизаций", "quote":"«Магия — это не только сила. Это путь, который делает мир чуть шире.»", "story":"Архив подтверждает финальный этап. Ни имени, ни силуэта, ни подсказки — только абсурдно высокая цена восстановления."},
    {"need":1000000000000000.0, "name":"Аянокоджи", "art":"res://assets/gallery/13_ayanokoji.png", "background":"res://assets/backgrounds/13_ayanokoji.webp", "wide_layout":true, "rarity":"Легендарный", "bonus_kind":"perfection", "bonus_value":1.0, "bonus_text":"+100% ко всему доходу, +100% к клику, +100% к офлайн-доходу", "quote":"«Иногда самый сильный просто наблюдает.»", "story":"После миллиардов, триллионов и квадриллиона осколков Архив без единой доли сомнения сообщает: «Совершенное отражение найдено». Спорить с системой уже поздно."}
]

func _ready() -> void:
    rng.randomize()
    _make_fonts()
    sfx_bank = SfxBank.new()
    add_child(sfx_bank)
    music_bank = MusicBank.new()
    add_child(music_bank)
    _build_screen()
    _build_generic_overlay()
    _build_reward_overlay()
    _load_game()
    _recalculate_stats()
    _apply_offline_progress()
    _refresh_all()
    _start_ambient_animation()

func _process(delta: float) -> void:
    session_time += delta
    if auto_rate > 0.0:
        auto_tick_clock += delta
        while auto_tick_clock >= 1.0:
            auto_tick_clock -= 1.0
            var gain: float = auto_rate * _auto_income_multiplier() * _all_income_multiplier() * boost_multiplier
            if _active_bonus_kind() == "auto_double_chance" and rng.randf() < _active_bonus_value():
                gain *= 2.0
                _spawn_status_text("КАГУЯ • АВТОФАРМ ×2", Color("ffd8ff"))
            shards += gain
            total_shards += gain
            _check_chapter_unlock()

    if boost_time_left > 0.0:
        boost_time_left = maxf(0.0, boost_time_left - delta)
        if boost_time_left <= 0.0:
            boost_multiplier = 1.0

    bonus_clock -= delta
    if bonus_clock <= 0.0 and not is_instance_valid(rare_bonus_button):
        _spawn_rare_bonus()
        bonus_clock = _next_bonus_delay()

    automation_refresh_clock += delta
    if automation_refresh_clock >= 0.25:
        automation_refresh_clock = 0.0
        _refresh_upgrade_button_states()
        var visible_now: int = _visible_upgrade_count()
        if visible_now != last_visible_upgrade_count:
            _rebuild_automation()

    autosave_clock += delta
    if autosave_clock >= AUTOSAVE_INTERVAL:
        autosave_clock = 0.0
        _save_game()

    _refresh_live_labels()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_game()
        get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
    if not OS.is_debug_build():
        return
    if event is InputEventKey:
        var key_event: InputEventKey = event
        if key_event.pressed and not key_event.echo and key_event.keycode == KEY_F9:
            _debug_unlock_next()

func _make_fonts() -> void:
    ui_font = SystemFont.new()
    ui_font.font_names = PackedStringArray(["Georgia", "Times New Roman", "DejaVu Serif"])
    title_font = SystemFont.new()
    title_font.font_names = PackedStringArray(["Georgia", "Times New Roman", "DejaVu Serif"])

func _build_screen() -> void:
    background_layer = TextureRect.new()
    background_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background_layer.texture = BackgroundLoader.load_texture("res://assets/backgrounds/01_horikita.webp")
    background_layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background_layer.stretch_mode = TextureRect.STRETCH_SCALE
    background_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background_layer)

    main_ui_root = Control.new()
    main_ui_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(main_ui_root)

    fx_layer = Control.new()
    fx_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fx_layer.z_index = 50
    main_ui_root.add_child(fx_layer)

    _build_top_counter()
    _build_secondary_counter()
    _build_character_panel()
    _build_automation_panel()
    _build_task_panel()
    _build_click_area()
    _build_resonance_panel()
    _build_collection_panel()
    _build_menu_hotspots()
    _build_top_hotspots()

    offline_label = Label.new()
    offline_label.position = Vector2(720, 128)
    offline_label.size = Vector2(620, 40)
    offline_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    offline_label.add_theme_font_override("font", ui_font)
    offline_label.add_theme_font_size_override("font_size", 20)
    offline_label.add_theme_color_override("font_color", Color("e5c5ff"))
    offline_label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
    offline_label.add_theme_constant_override("shadow_offset_x", 2)
    offline_label.add_theme_constant_override("shadow_offset_y", 2)
    main_ui_root.add_child(offline_label)

func _build_top_counter() -> void:
    var cover: Panel = Panel.new()
    cover.position = Vector2(844, 24)
    cover.size = Vector2(376, 92)
    cover.add_theme_stylebox_override("panel", _glass_style(Color(0.018,0.035,0.09,0.94), Color(0.36,0.33,0.72,0.72), 10, 8))
    main_ui_root.add_child(cover)

    shard_value_label = Label.new()
    shard_value_label.position = Vector2(8, 0)
    shard_value_label.size = Vector2(360, 58)
    shard_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    shard_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    shard_value_label.add_theme_font_override("font", title_font)
    shard_value_label.add_theme_font_size_override("font_size", 42)
    shard_value_label.add_theme_color_override("font_color", Color("f9f3ff"))
    cover.add_child(shard_value_label)

    shard_rate_label = Label.new()
    shard_rate_label.position = Vector2(8, 53)
    shard_rate_label.size = Vector2(360, 32)
    shard_rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    shard_rate_label.add_theme_font_override("font", ui_font)
    shard_rate_label.add_theme_font_size_override("font_size", 21)
    shard_rate_label.add_theme_color_override("font_color", Color("e7e0ff"))
    cover.add_child(shard_rate_label)

func _build_secondary_counter() -> void:
    var cover: Panel = Panel.new()
    cover.position = Vector2(1300, 23)
    cover.size = Vector2(165, 76)
    cover.add_theme_stylebox_override("panel", _glass_style(Color(0.04,0.025,0.10,0.94), Color(0.63,0.32,0.92,0.70), 8, 7))
    main_ui_root.add_child(cover)

    chapter_counter_label = Label.new()
    chapter_counter_label.position = Vector2(5, 5)
    chapter_counter_label.size = Vector2(100, 66)
    chapter_counter_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    chapter_counter_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    chapter_counter_label.add_theme_font_override("font", title_font)
    chapter_counter_label.add_theme_font_size_override("font_size", 28)
    chapter_counter_label.add_theme_color_override("font_color", Color("fff4ff"))
    cover.add_child(chapter_counter_label)

    var plus: Button = Button.new()
    plus.text = "+"
    plus.position = Vector2(108, 8)
    plus.size = Vector2(50, 58)
    plus.add_theme_font_override("font", title_font)
    plus.add_theme_font_size_override("font_size", 30)
    plus.add_theme_stylebox_override("normal", _button_style(Color(0.12,0.07,0.22,0.9), Color(0.74,0.45,1.0,0.8), 8))
    plus.add_theme_stylebox_override("hover", _button_style(Color(0.22,0.08,0.35,0.95), Color(0.95,0.67,1.0,1.0), 8))
    plus.pressed.connect(_open_gallery)
    cover.add_child(plus)

func _build_character_panel() -> void:
    var panel: Panel = Panel.new()
    panel.position = Vector2(1538, 136)
    panel.size = Vector2(478, 435)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.015,0.026,0.066,0.97), Color(0.36,0.37,0.71,0.82), 16, 10))
    main_ui_root.add_child(panel)

    var header: Label = Label.new()
    header.text = "Текущий персонаж"
    header.position = Vector2(28, 12)
    header.size = Vector2(360, 45)
    header.add_theme_font_override("font", title_font)
    header.add_theme_font_size_override("font_size", 28)
    header.add_theme_color_override("font_color", Color("f6f0ff"))
    panel.add_child(header)

    var gallery_btn: Button = Button.new()
    gallery_btn.text = "↻"
    gallery_btn.position = Vector2(418, 9)
    gallery_btn.size = Vector2(44, 42)
    gallery_btn.flat = true
    gallery_btn.add_theme_font_size_override("font_size", 28)
    gallery_btn.add_theme_color_override("font_color", Color("f7f2ff"))
    gallery_btn.pressed.connect(_open_gallery)
    panel.add_child(gallery_btn)

    character_portrait = TextureRect.new()
    character_portrait.position = Vector2(24, 72)
    character_portrait.size = Vector2(190, 245)
    character_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    character_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    panel.add_child(character_portrait)

    character_name_label = Label.new()
    character_name_label.position = Vector2(230, 76)
    character_name_label.size = Vector2(230, 42)
    character_name_label.add_theme_font_override("font", title_font)
    character_name_label.add_theme_font_size_override("font_size", 25)
    character_name_label.add_theme_color_override("font_color", Color("fff7ff"))
    character_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(character_name_label)

    character_rarity_label = Label.new()
    character_rarity_label.position = Vector2(230, 127)
    character_rarity_label.size = Vector2(220, 32)
    character_rarity_label.add_theme_font_override("font", ui_font)
    character_rarity_label.add_theme_font_size_override("font_size", 18)
    character_rarity_label.add_theme_color_override("font_color", Color("ded4ff"))
    panel.add_child(character_rarity_label)

    character_bonus_label = Label.new()
    character_bonus_label.position = Vector2(230, 166)
    character_bonus_label.size = Vector2(225, 78)
    character_bonus_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    character_bonus_label.add_theme_font_override("font", ui_font)
    character_bonus_label.add_theme_font_size_override("font_size", 18)
    character_bonus_label.add_theme_color_override("font_color", Color("f7e6ff"))
    panel.add_child(character_bonus_label)

    character_quote_label = Label.new()
    character_quote_label.position = Vector2(230, 247)
    character_quote_label.size = Vector2(225, 92)
    character_quote_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    character_quote_label.add_theme_font_override("font", ui_font)
    character_quote_label.add_theme_font_size_override("font_size", 17)
    character_quote_label.add_theme_color_override("font_color", Color("d8d1e9"))
    panel.add_child(character_quote_label)

    var story_btn: Button = Button.new()
    story_btn.text = "История"
    story_btn.position = Vector2(258, 354)
    story_btn.size = Vector2(185, 52)
    story_btn.add_theme_font_override("font", ui_font)
    story_btn.add_theme_font_size_override("font_size", 18)
    story_btn.add_theme_stylebox_override("normal", _button_style(Color(0.07,0.04,0.12,0.94), Color(0.59,0.36,0.75,0.72), 18))
    story_btn.add_theme_stylebox_override("hover", _button_style(Color(0.16,0.06,0.24,0.97), Color(0.92,0.58,1.0,1.0), 18))
    story_btn.pressed.connect(_open_current_story)
    panel.add_child(story_btn)

func _build_automation_panel() -> void:
    var panel: Panel = Panel.new()
    panel.position = Vector2(1544, 598)
    panel.size = Vector2(474, 380)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.012,0.025,0.063,0.97), Color(0.36,0.38,0.72,0.82), 16, 10))
    main_ui_root.add_child(panel)

    automation_header = Label.new()
    automation_header.position = Vector2(26, 10)
    automation_header.size = Vector2(400, 46)
    automation_header.add_theme_font_override("font", title_font)
    automation_header.add_theme_font_size_override("font_size", 27)
    automation_header.add_theme_color_override("font_color", Color("f5efff"))
    panel.add_child(automation_header)

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.position = Vector2(20, 62)
    scroll.size = Vector2(436, 300)
    panel.add_child(scroll)

    automation_box = VBoxContainer.new()
    automation_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    automation_box.add_theme_constant_override("separation", 8)
    scroll.add_child(automation_box)

func _build_task_panel() -> void:
    var panel: Panel = Panel.new()
    panel.position = Vector2(38, 770)
    panel.size = Vector2(663, 190)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.012,0.024,0.064,0.97), Color(0.41,0.42,0.76,0.80), 16, 10))
    main_ui_root.add_child(panel)

    var title: Label = Label.new()
    title.text = "✣  Текущее задание"
    title.position = Vector2(20, 12)
    title.size = Vector2(420, 44)
    title.add_theme_font_override("font", title_font)
    title.add_theme_font_size_override("font_size", 27)
    title.add_theme_color_override("font_color", Color("f9f4ff"))
    panel.add_child(title)

    var crystal_icon: Label = Label.new()
    crystal_icon.text = "♦"
    crystal_icon.position = Vector2(25, 70)
    crystal_icon.size = Vector2(70, 80)
    crystal_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    crystal_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    crystal_icon.add_theme_font_size_override("font_size", 54)
    crystal_icon.add_theme_color_override("font_color", Color("a978ff"))
    crystal_icon.add_theme_color_override("font_shadow_color", Color(0.55,0.1,1.0,0.8))
    crystal_icon.add_theme_constant_override("shadow_offset_x", 3)
    crystal_icon.add_theme_constant_override("shadow_offset_y", 3)
    panel.add_child(crystal_icon)

    task_label = Label.new()
    task_label.position = Vector2(112, 70)
    task_label.size = Vector2(430, 34)
    task_label.add_theme_font_override("font", ui_font)
    task_label.add_theme_font_size_override("font_size", 21)
    task_label.add_theme_color_override("font_color", Color("fff8ff"))
    panel.add_child(task_label)

    task_progress = ProgressBar.new()
    task_progress.position = Vector2(112, 112)
    task_progress.size = Vector2(415, 22)
    task_progress.show_percentage = false
    task_progress.add_theme_stylebox_override("background", _progress_bg_style())
    task_progress.add_theme_stylebox_override("fill", _progress_fill_style())
    panel.add_child(task_progress)

    task_value_label = Label.new()
    task_value_label.position = Vector2(112, 139)
    task_value_label.size = Vector2(415, 32)
    task_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    task_value_label.add_theme_font_override("font", ui_font)
    task_value_label.add_theme_font_size_override("font_size", 18)
    task_value_label.add_theme_color_override("font_color", Color("ebe6ff"))
    panel.add_child(task_value_label)

    var go_btn: Button = Button.new()
    go_btn.text = "→"
    go_btn.position = Vector2(575, 77)
    go_btn.size = Vector2(62, 76)
    go_btn.add_theme_font_size_override("font_size", 34)
    go_btn.add_theme_stylebox_override("normal", _button_style(Color(0.08,0.05,0.16,0.96), Color(0.54,0.39,0.79,0.85), 10))
    go_btn.add_theme_stylebox_override("hover", _button_style(Color(0.17,0.06,0.26,0.98), Color(0.94,0.59,1.0,1.0), 10))
    go_btn.pressed.connect(_focus_click_area)
    panel.add_child(go_btn)

func _build_click_area() -> void:
    click_hotspot = Button.new()
    click_hotspot.text = ""
    click_hotspot.position = Vector2(650, 510)
    click_hotspot.size = Vector2(630, 420)
    click_hotspot.flat = true
    click_hotspot.focus_mode = Control.FOCUS_NONE
    click_hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    click_hotspot.pressed.connect(_on_core_pressed)
    click_hotspot.mouse_entered.connect(_core_hover_on)
    click_hotspot.mouse_exited.connect(_core_hover_off)
    main_ui_root.add_child(click_hotspot)

    crystal_ring_a = Panel.new()
    crystal_ring_a.position = Vector2(825, 520)
    crystal_ring_a.size = Vector2(350, 350)
    crystal_ring_a.mouse_filter = Control.MOUSE_FILTER_IGNORE
    crystal_ring_a.pivot_offset = crystal_ring_a.size / 2.0
    crystal_ring_a.modulate.a = 0.25
    crystal_ring_a.add_theme_stylebox_override("panel", _ring_style(Color(0.66,0.31,1.0,0.65), 4))
    main_ui_root.add_child(crystal_ring_a)

    crystal_ring_b = Panel.new()
    crystal_ring_b.position = Vector2(865, 560)
    crystal_ring_b.size = Vector2(270, 270)
    crystal_ring_b.mouse_filter = Control.MOUSE_FILTER_IGNORE
    crystal_ring_b.pivot_offset = crystal_ring_b.size / 2.0
    crystal_ring_b.modulate.a = 0.18
    crystal_ring_b.add_theme_stylebox_override("panel", _ring_style(Color(0.92,0.55,1.0,0.75), 3))
    main_ui_root.add_child(crystal_ring_b)

    var click_panel: Panel = Panel.new()
    click_panel.position = Vector2(785, 790)
    click_panel.size = Vector2(390, 135)
    click_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    click_panel.add_theme_stylebox_override("panel", _click_style())
    main_ui_root.add_child(click_panel)

    var click_title: Label = Label.new()
    click_title.text = "Клик"
    click_title.position = Vector2(10, 14)
    click_title.size = Vector2(370, 55)
    click_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    click_title.add_theme_font_override("font", title_font)
    click_title.add_theme_font_size_override("font_size", 42)
    click_title.add_theme_color_override("font_color", Color("fff8ff"))
    click_panel.add_child(click_title)

    click_gain_label = Label.new()
    click_gain_label.position = Vector2(10, 70)
    click_gain_label.size = Vector2(370, 45)
    click_gain_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    click_gain_label.add_theme_font_override("font", title_font)
    click_gain_label.add_theme_font_size_override("font_size", 29)
    click_gain_label.add_theme_color_override("font_color", Color("f0d9ff"))
    click_panel.add_child(click_gain_label)

func _build_resonance_panel() -> void:
    resonance_panel = Panel.new()
    resonance_panel.position = Vector2(1250, 798)
    resonance_panel.size = Vector2(218, 142)
    resonance_panel.add_theme_stylebox_override("panel", _resonance_style(false))
    main_ui_root.add_child(resonance_panel)

    resonance_title = Label.new()
    resonance_title.position = Vector2(8, 25)
    resonance_title.size = Vector2(202, 45)
    resonance_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    resonance_title.add_theme_font_override("font", title_font)
    resonance_title.add_theme_font_size_override("font_size", 27)
    resonance_title.add_theme_color_override("font_color", Color("ffd9ae"))
    resonance_panel.add_child(resonance_title)

    resonance_time_label = Label.new()
    resonance_time_label.position = Vector2(8, 76)
    resonance_time_label.size = Vector2(202, 40)
    resonance_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    resonance_time_label.add_theme_font_override("font", ui_font)
    resonance_time_label.add_theme_font_size_override("font_size", 17)
    resonance_time_label.add_theme_color_override("font_color", Color("fff1df"))
    resonance_panel.add_child(resonance_time_label)

func _build_collection_panel() -> void:
    var panel: Panel = Panel.new()
    panel.position = Vector2(20, 1000)
    panel.size = Vector2(2005, 320)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.009,0.023,0.055,0.975), Color(0.50,0.35,0.79,0.80), 18, 12))
    main_ui_root.add_child(panel)

    collection_title = Label.new()
    collection_title.position = Vector2(30, 10)
    collection_title.size = Vector2(620, 48)
    collection_title.add_theme_font_override("font", title_font)
    collection_title.add_theme_font_size_override("font_size", 28)
    collection_title.add_theme_color_override("font_color", Color("f8f2ff"))
    panel.add_child(collection_title)

    var open_btn: Button = Button.new()
    open_btn.text = "Открыть галерею"
    open_btn.position = Vector2(1710, 13)
    open_btn.size = Vector2(250, 45)
    open_btn.add_theme_font_override("font", ui_font)
    open_btn.add_theme_font_size_override("font_size", 16)
    open_btn.add_theme_stylebox_override("normal", _button_style(Color(0.08,0.05,0.16,0.96), Color(0.65,0.46,0.85,0.85), 16))
    open_btn.add_theme_stylebox_override("hover", _button_style(Color(0.17,0.06,0.26,0.98), Color(0.94,0.59,1.0,1.0), 16))
    open_btn.pressed.connect(_open_gallery)
    panel.add_child(open_btn)

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.position = Vector2(22, 70)
    scroll.size = Vector2(1955, 225)
    panel.add_child(scroll)

    collection_box = HBoxContainer.new()
    collection_box.add_theme_constant_override("separation", 14)
    scroll.add_child(collection_box)

func _build_menu_hotspots() -> void:
    _menu_hotspot(Rect2(18, 250, 270, 72), _show_home)
    _menu_hotspot(Rect2(18, 335, 270, 72), _open_gallery)
    _menu_hotspot(Rect2(18, 420, 270, 72), _open_tasks)
    _menu_hotspot(Rect2(18, 505, 270, 72), _open_achievements)
    _menu_hotspot(Rect2(18, 590, 270, 72), _open_settings)

func _build_top_hotspots() -> void:
    _menu_hotspot(Rect2(1568, 17, 78, 78), _open_achievements)
    _menu_hotspot(Rect2(1660, 17, 78, 78), _open_stats)
    _menu_hotspot(Rect2(1752, 17, 78, 78), _open_settings)

func _menu_hotspot(rect: Rect2, callback: Callable) -> void:
    var button: Button = Button.new()
    button.position = rect.position
    button.size = rect.size
    button.text = ""
    button.flat = true
    button.focus_mode = Control.FOCUS_NONE
    button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    button.pressed.connect(callback)
    main_ui_root.add_child(button)

func _build_generic_overlay() -> void:
    overlay_root = ColorRect.new()
    overlay_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    overlay_root.color = Color(0.015,0.008,0.04,0.93)
    overlay_root.mouse_filter = Control.MOUSE_FILTER_STOP
    overlay_root.z_index = 200
    overlay_root.visible = false
    add_child(overlay_root)

    var panel: Panel = Panel.new()
    panel.position = Vector2(240, 120)
    panel.size = Vector2(1568, 1110)
    panel.add_theme_stylebox_override("panel", _glass_style(Color(0.014,0.025,0.064,0.98), Color(0.53,0.38,0.83,0.90), 28, 18))
    overlay_root.add_child(panel)

    overlay_title = Label.new()
    overlay_title.position = Vector2(44, 30)
    overlay_title.size = Vector2(1200, 60)
    overlay_title.add_theme_font_override("font", title_font)
    overlay_title.add_theme_font_size_override("font_size", 42)
    overlay_title.add_theme_color_override("font_color", Color("fff6ff"))
    panel.add_child(overlay_title)

    overlay_close = Button.new()
    overlay_close.text = "Закрыть"
    overlay_close.position = Vector2(1320, 28)
    overlay_close.size = Vector2(190, 56)
    overlay_close.add_theme_font_override("font", ui_font)
    overlay_close.add_theme_font_size_override("font_size", 18)
    overlay_close.add_theme_stylebox_override("normal", _button_style(Color(0.08,0.05,0.16,0.96), Color(0.65,0.46,0.85,0.85), 16))
    overlay_close.add_theme_stylebox_override("hover", _button_style(Color(0.17,0.06,0.26,0.98), Color(0.94,0.59,1.0,1.0), 16))
    overlay_close.pressed.connect(_close_overlay)
    panel.add_child(overlay_close)

    var scroll: ScrollContainer = ScrollContainer.new()
    scroll.position = Vector2(42, 110)
    scroll.size = Vector2(1484, 950)
    panel.add_child(scroll)

    overlay_content = VBoxContainer.new()
    overlay_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    overlay_content.add_theme_constant_override("separation", 18)
    scroll.add_child(overlay_content)

func _build_reward_overlay() -> void:
    reward_overlay = ColorRect.new()
    reward_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    reward_overlay.color = Color(0.012,0.005,0.03,0.95)
    reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
    reward_overlay.z_index = 300
    reward_overlay.visible = false
    add_child(reward_overlay)

    reward_card = Panel.new()
    reward_card.position = Vector2(574, 92)
    reward_card.size = Vector2(900, 1180)
    reward_card.pivot_offset = reward_card.size / 2.0
    reward_card.add_theme_stylebox_override("panel", _glass_style(Color(0.018,0.024,0.063,0.99), Color(0.66,0.39,0.98,0.94), 30, 24))
    reward_overlay.add_child(reward_card)

    reward_title = Label.new()
    reward_title.position = Vector2(30, 28)
    reward_title.size = Vector2(840, 75)
    reward_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reward_title.add_theme_font_override("font", title_font)
    reward_title.add_theme_font_size_override("font_size", 44)
    reward_title.add_theme_color_override("font_color", Color("fff5ff"))
    reward_card.add_child(reward_title)

    reward_art = TextureRect.new()
    reward_art.position = Vector2(145, 120)
    reward_art.size = Vector2(610, 610)
    reward_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    reward_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    reward_card.add_child(reward_art)

    reward_name = Label.new()
    reward_name.position = Vector2(40, 755)
    reward_name.size = Vector2(820, 70)
    reward_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reward_name.add_theme_font_override("font", title_font)
    reward_name.add_theme_font_size_override("font_size", 38)
    reward_name.add_theme_color_override("font_color", Color("fff6ff"))
    reward_card.add_child(reward_name)

    reward_story = Label.new()
    reward_story.position = Vector2(95, 845)
    reward_story.size = Vector2(710, 170)
    reward_story.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    reward_story.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    reward_story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    reward_story.add_theme_font_override("font", ui_font)
    reward_story.add_theme_font_size_override("font_size", 21)
    reward_story.add_theme_color_override("font_color", Color("ded8ef"))
    reward_card.add_child(reward_story)

    var close: Button = Button.new()
    close.text = "Продолжить"
    close.position = Vector2(300, 1050)
    close.size = Vector2(300, 74)
    close.add_theme_font_override("font", title_font)
    close.add_theme_font_size_override("font_size", 24)
    close.add_theme_stylebox_override("normal", _button_style(Color(0.15,0.05,0.24,0.98), Color(0.76,0.42,1.0,0.95), 20))
    close.add_theme_stylebox_override("hover", _button_style(Color(0.28,0.07,0.40,0.99), Color(1.0,0.68,1.0,1.0), 20))
    close.pressed.connect(_close_reward)
    reward_card.add_child(close)

func _refresh_all() -> void:
    _refresh_live_labels()
    _refresh_character()
    _rebuild_automation()
    _rebuild_collection()

func _refresh_live_labels() -> void:
    if not is_instance_valid(shard_value_label):
        return
    shard_value_label.text = _compact(shards)
    shard_rate_label.text = "+%s / сек" % _compact(auto_rate * _display_auto_multiplier() * _all_income_multiplier() * boost_multiplier)
    chapter_counter_label.text = "✧  %d/13" % (current_chapter + 1)
    click_gain_label.text = "♦  +%s" % _compact(click_power * _click_multiplier() * _all_income_multiplier() * boost_multiplier)

    if current_chapter >= chapters.size() - 1:
        task_label.text = "Совершенство достигнуто"
        task_progress.value = 100.0
        task_value_label.text = "%s осколков собрано" % _compact(total_shards)
    else:
        var next_need: float = float(chapters[current_chapter + 1]["need"])
        var from_need: float = float(chapters[current_chapter]["need"])
        var span: float = maxf(1.0, next_need - from_need)
        var pct: float = clampf((total_shards - from_need) / span * 100.0, 0.0, 100.0)
        task_label.text = "Собрать %s осколков" % _compact(next_need)
        task_progress.value = pct
        task_value_label.text = "%s / %s" % [_compact(total_shards), _compact(next_need)]

    if boost_time_left > 0.0:
        resonance_panel.add_theme_stylebox_override("panel", _resonance_style(true))
        resonance_title.text = "Резонанс ×2"
        resonance_time_label.text = "Осталось: %02d:%02d" % [int(int(boost_time_left) / 60), int(boost_time_left) % 60]
    else:
        resonance_panel.add_theme_stylebox_override("panel", _resonance_style(false))
        resonance_title.text = "Резонанс"
        resonance_time_label.text = "Поймай редкий осколок"

func _refresh_character() -> void:
    active_character = clampi(active_character, 0, current_chapter)
    var chapter: Dictionary = chapters[active_character]
    character_portrait.texture = load(String(chapter["art"]))
    character_name_label.text = String(chapter["name"])
    character_rarity_label.text = "✧  %s" % String(chapter["rarity"])
    character_bonus_label.text = String(chapter["bonus_text"])
    character_quote_label.text = String(chapter["quote"])
    collection_title.text = "✧  Моя коллекция  (%d/13)" % (current_chapter + 1)
    _apply_character_background(false)

func _rebuild_automation() -> void:
    if not is_instance_valid(automation_box):
        return
    for child in automation_box.get_children():
        automation_box.remove_child(child)
        child.queue_free()
    upgrade_buy_buttons.clear()

    var visible_count: int = _visible_upgrade_count()
    last_visible_upgrade_count = visible_count
    automation_header.text = "Автоматизации  (%d/12)" % visible_count

    for i in range(upgrades.size()):
        var up: Dictionary = upgrades[i]
        if total_shards < float(up["unlock"]):
            continue
        automation_box.add_child(_make_upgrade_row(i))

    if visible_count == 0:
        var hint: Label = _small_text("Первая технология откроется очень скоро.")
        automation_box.add_child(hint)


func _visible_upgrade_count() -> int:
    var count: int = 0
    for up in upgrades:
        if total_shards >= float(up["unlock"]):
            count += 1
    return count

func _refresh_upgrade_button_states() -> void:
    for key in upgrade_buy_buttons.keys():
        var index: int = int(key)
        var button: Button = upgrade_buy_buttons[key]
        if is_instance_valid(button):
            var cost: float = _upgrade_cost(index)
            button.disabled = shards < cost
            button.text = "♦  %s" % _compact(cost)

func _make_upgrade_row(index: int) -> Control:
    var up: Dictionary = upgrades[index]
    var row: Panel = Panel.new()
    row.custom_minimum_size = Vector2(420, 78)
    row.add_theme_stylebox_override("panel", _glass_style(Color(0.02,0.045,0.09,0.93), Color(0.18,0.29,0.52,0.78), 10, 4))

    var icon: Label = Label.new()
    icon.text = String(up["icon"])
    icon.position = Vector2(8, 8)
    icon.size = Vector2(58, 58)
    icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    icon.add_theme_font_size_override("font_size", 34)
    icon.add_theme_color_override("font_color", Color("78c9ff"))
    row.add_child(icon)

    var name_label: Label = Label.new()
    name_label.text = "%s  Lv.%d" % [String(up["name"]), int(up["count"])]
    name_label.position = Vector2(72, 8)
    name_label.size = Vector2(230, 30)
    name_label.add_theme_font_override("font", ui_font)
    name_label.add_theme_font_size_override("font_size", 16)
    name_label.add_theme_color_override("font_color", Color("f3eeff"))
    row.add_child(name_label)

    var desc: Label = Label.new()
    desc.text = String(up["desc"])
    desc.position = Vector2(72, 40)
    desc.size = Vector2(220, 28)
    desc.add_theme_font_override("font", ui_font)
    desc.add_theme_font_size_override("font_size", 15)
    desc.add_theme_color_override("font_color", Color("cfd9ef"))
    row.add_child(desc)

    var cost: float = _upgrade_cost(index)
    var buy: Button = Button.new()
    buy.text = "♦  %s" % _compact(cost)
    buy.position = Vector2(302, 13)
    buy.size = Vector2(110, 52)
    buy.disabled = shards < cost
    buy.add_theme_font_override("font", ui_font)
    buy.add_theme_font_size_override("font_size", 15)
    buy.add_theme_color_override("font_color", Color("fff3ff"))
    buy.add_theme_stylebox_override("normal", _button_style(Color(0.14,0.07,0.24,0.98), Color(0.67,0.42,0.92,0.84), 8))
    buy.add_theme_stylebox_override("hover", _button_style(Color(0.24,0.08,0.36,0.99), Color(0.96,0.64,1.0,1.0), 8))
    buy.add_theme_stylebox_override("disabled", _button_style(Color(0.055,0.065,0.095,0.95), Color(0.20,0.22,0.31,0.7), 8))
    buy.pressed.connect(_buy_upgrade.bind(index))
    row.add_child(buy)
    upgrade_buy_buttons[index] = buy
    return row

func _rebuild_collection() -> void:
    if not is_instance_valid(collection_box):
        return
    for child in collection_box.get_children():
        child.queue_free()

    for i in range(current_chapter + 1):
        collection_box.add_child(_make_collection_card(i))

func _make_collection_card(index: int) -> Control:
    var chapter: Dictionary = chapters[index]
    var card: Panel = Panel.new()
    card.custom_minimum_size = Vector2(145, 215)
    var border_color: Color = Color("ffd36f") if index == active_character else Color(0.66,0.28,0.74,0.86)
    card.add_theme_stylebox_override("panel", _glass_style(Color(0.025,0.035,0.07,0.98), border_color, 10, 8 if index == active_character else 6))

    var art: TextureRect = TextureRect.new()
    art.position = Vector2(7, 7)
    art.size = Vector2(131, 158)
    art.texture = load(String(chapter["art"]))
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    card.add_child(art)

    var name_label: Label = Label.new()
    name_label.text = String(chapter["name"])
    name_label.position = Vector2(5, 169)
    name_label.size = Vector2(135, 40)
    name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    name_label.add_theme_font_override("font", ui_font)
    name_label.add_theme_font_size_override("font_size", 12)
    name_label.add_theme_color_override("font_color", Color("f9f3ff"))
    card.add_child(name_label)

    var click: Button = Button.new()
    click.position = Vector2.ZERO
    click.size = Vector2(145, 215)
    click.text = ""
    click.flat = true
    click.focus_mode = Control.FOCUS_NONE
    click.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    click.pressed.connect(_select_character.bind(index))
    card.add_child(click)

    if index == active_character:
        var active_label: Label = Label.new()
        active_label.text = "АКТИВЕН"
        active_label.position = Vector2(28, 8)
        active_label.size = Vector2(90, 24)
        active_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        active_label.add_theme_font_size_override("font_size", 11)
        active_label.add_theme_color_override("font_color", Color("ffe39a"))
        active_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
        card.add_child(active_label)
    return card

func _select_character(index: int) -> void:
    if index < 0 or index > current_chapter:
        return
    if index == active_character:
        return
    active_character = index
    bonus_clock = minf(bonus_clock, _next_bonus_delay())
    sfx_bank.play("open")
    _refresh_character()
    _rebuild_collection()
    _rebuild_automation()
    _refresh_live_labels()
    _spawn_status_text("АКТИВНЫЙ ПЕРСОНАЖ • %s" % String(chapters[index]["name"]), Color("ffe2ff"))
    _save_game()

func _apply_character_background(animate: bool = true) -> void:
    if not is_instance_valid(background_layer):
        return
    var chapter: Dictionary = chapters[active_character]
    background_layer.texture = BackgroundLoader.load_texture(String(chapter["background"]))
    var wide: bool = bool(chapter.get("wide_layout", false))
    if is_instance_valid(main_ui_root):
        if wide:
            main_ui_root.position = Vector2(0.0, 106.0)
            main_ui_root.scale = Vector2(1.0, 1152.0 / 1365.0)
        else:
            main_ui_root.position = Vector2.ZERO
            main_ui_root.scale = Vector2.ONE
    if animate:
        background_layer.modulate.a = 0.35
        var tween: Tween = create_tween()
        tween.tween_property(background_layer, "modulate:a", 1.0, 0.45)
    else:
        background_layer.modulate.a = 1.0

func _on_core_pressed() -> void:
    var amount: float = click_power * _click_multiplier() * _all_income_multiplier() * boost_multiplier
    var critical: bool = rng.randf() < crit_chance
    if critical:
        amount *= crit_multiplier * _crit_multiplier_bonus()
        critical_clicks += 1
        sfx_bank.play("crit")
    else:
        sfx_bank.play("click")
    total_clicks += 1
    shards += amount
    total_shards += amount
    _spawn_click_text(amount, critical)
    _spawn_click_particles(critical)
    _animate_core_press(critical)
    _check_chapter_unlock()
    _rebuild_automation()
    _refresh_live_labels()

func _animate_core_press(critical: bool) -> void:
    var target: Vector2 = Vector2(1.10, 1.10) if critical else Vector2(1.055, 1.055)
    var tween_a: Tween = create_tween()
    tween_a.tween_property(crystal_ring_a, "scale", target, 0.07)
    tween_a.tween_property(crystal_ring_a, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    var tween_b: Tween = create_tween()
    tween_b.tween_property(crystal_ring_b, "scale", target * 1.04, 0.07)
    tween_b.tween_property(crystal_ring_b, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _core_hover_on() -> void:
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(crystal_ring_a, "modulate:a", 0.55, 0.18)
    tween.tween_property(crystal_ring_b, "modulate:a", 0.42, 0.18)

func _core_hover_off() -> void:
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(crystal_ring_a, "modulate:a", 0.25, 0.18)
    tween.tween_property(crystal_ring_b, "modulate:a", 0.18, 0.18)

func _spawn_click_text(amount: float, critical: bool) -> void:
    var label: Label = Label.new()
    label.text = ("КРИТ +%s" if critical else "+%s") % _compact(amount)
    label.position = Vector2(910 + rng.randf_range(-70.0, 70.0), 570)
    label.size = Vector2(300, 55)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_override("font", title_font)
    label.add_theme_font_size_override("font_size", 31 if critical else 25)
    label.add_theme_color_override("font_color", Color("ffe9a8") if critical else Color("f0d8ff"))
    label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.9))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    fx_layer.add_child(label)

    var start_pos: Vector2 = label.position
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "position", start_pos + Vector2(0, -100), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(label, "modulate:a", 0.0, 0.8)
    tween.finished.connect(label.queue_free)

func _spawn_click_particles(critical: bool) -> void:
    var center: Vector2 = Vector2(1000, 650)
    var count: int = 30 if critical else 15
    for i in range(count):
        var spark: ColorRect = ColorRect.new()
        var px: float = rng.randf_range(3.0, 9.0)
        spark.size = Vector2(px, px)
        spark.position = center
        spark.pivot_offset = spark.size / 2.0
        spark.rotation = rng.randf_range(-PI, PI)
        spark.color = Color.from_hsv(rng.randf_range(0.72, 0.88), 0.42, 1.0, 0.95)
        spark.mouse_filter = Control.MOUSE_FILTER_IGNORE
        fx_layer.add_child(spark)
        var angle: float = rng.randf_range(0.0, TAU)
        var dist: float = rng.randf_range(80.0, 210.0 if critical else 145.0)