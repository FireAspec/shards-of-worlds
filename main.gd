extends Control

const SAVE_PATH: String = "user://shards_worlds_save_v3.json"
const AUTOSAVE_INTERVAL: float = 5.0
const CLOUD_SYNC_INTERVAL: float = 20.0
const BONUS_MIN_TIME: float = 20.0
const BONUS_MAX_TIME: float = 34.0
const SfxBank = preload("res://sfx_bank.gd")
const MusicBank = preload("res://music_bank.gd")
const BackgroundLoader = preload("res://background_loader.gd")
const YandexSdk = preload("res://yandex_sdk.gd")

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
var yandex_sdk: Node
var cloud_merge_done: bool = false
var cloud_sync_clock: float = 0.0
var app_has_focus: bool = true
var audio_is_muted: bool = false
var user_sound_enabled: bool = true
var overlay_mode: String = ""

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
var click_panel: Panel
var offline_label: Label
var character_transition_tween: Tween

var overlay_root: ColorRect
var overlay_title: Label
var overlay_content: VBoxContainer
var overlay_close: Button
var leaderboard_status: Label

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
    yandex_sdk = YandexSdk.new()
    add_child(yandex_sdk)
    _build_screen()
    _build_generic_overlay()
    _build_reward_overlay()
    _load_game()
    _recalculate_stats()
    _apply_offline_progress()
    _update_audio_mute()
    music_bank = MusicBank.new()
    add_child(music_bank)
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

    cloud_sync_clock += delta
    if cloud_sync_clock >= CLOUD_SYNC_INTERVAL:
        cloud_sync_clock = 0.0
        _sync_cloud()

    _process_yandex()
    _refresh_live_labels()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        _save_game()
        _sync_cloud()
        get_tree().quit()
    elif what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        app_has_focus = false
        _update_audio_mute()
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        app_has_focus = true
        _update_audio_mute()

func _process_yandex() -> void:
    if not is_instance_valid(yandex_sdk):
        return

    if yandex_sdk.ready and not yandex_sdk.game_ready_sent:
        yandex_sdk.mark_game_ready()

    if yandex_sdk.player_ready and not yandex_sdk.cloud_requested:
        yandex_sdk.request_cloud_data()

    if not cloud_merge_done:
        var cloud_data: Dictionary = yandex_sdk.consume_cloud_data()
        if not cloud_data.is_empty():
            _merge_cloud_data(cloud_data)
        if yandex_sdk.cloud_consumed:
            cloud_merge_done = true

    if yandex_sdk.consume_rewarded():
        boost_multiplier = 2.0
        boost_time_left = maxf(boost_time_left, 60.0)
        sfx_bank.play("bonus")
        _spawn_status_text("НАГРАДА ЗА РЕКЛАМУ • РЕЗОНАНС ×2 НА 60 СЕКУНД", Color("ffd7ff"))

    if overlay_mode == "leaderboard" and yandex_sdk.has_leaderboard_payload():
        _render_leaderboard(yandex_sdk.consume_leaderboard())

    _update_audio_mute()

func _update_audio_mute() -> void:
    var ad_open: bool = false
    if is_instance_valid(yandex_sdk):
        ad_open = yandex_sdk.is_ad_open()

    var should_mute: bool = not user_sound_enabled or not app_has_focus or ad_open
    if should_mute == audio_is_muted:
        return

    audio_is_muted = should_mute
    var master_index: int = AudioServer.get_bus_index("Master")
    if master_index >= 0:
        AudioServer.set_bus_mute(master_index, should_mute)

func _sync_cloud() -> void:
    if not is_instance_valid(yandex_sdk) or not yandex_sdk.player_ready:
        return
    _save_game()
    var data: Dictionary = _build_save_data()
    yandex_sdk.save_cloud(data)
    if yandex_sdk.is_authorized():
        yandex_sdk.submit_score(total_shards)

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
    background_layer.pivot_offset = Vector2(1024, 682.5)
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

    click_panel = Panel.new()
    click_panel.position = Vector2(785, 790)
    click_panel.size = Vector2(390, 135)
    click_panel.pivot_offset = click_panel.size / 2.0
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

func _refresh_character(apply_background: bool = true) -> void:
    active_character = clampi(active_character, 0, current_chapter)
    var chapter: Dictionary = chapters[active_character]
    character_portrait.texture = load(String(chapter["art"]))
    character_name_label.text = String(chapter["name"])
    character_rarity_label.text = "✧  %s" % String(chapter["rarity"])
    character_bonus_label.text = String(chapter["bonus_text"])
    character_quote_label.text = String(chapter["quote"])
    collection_title.text = "✧  Моя коллекция  (%d/13)" % (current_chapter + 1)
    if apply_background:
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
    buy.add_theme_stylebox_override("pressed", _button_style(Color(0.34,0.11,0.48,1.0), Color(1.0,0.78,1.0,1.0), 8))
    buy.add_theme_stylebox_override("disabled", _button_style(Color(0.055,0.065,0.095,0.95), Color(0.20,0.22,0.31,0.7), 8))
    buy.pivot_offset = buy.size / 2.0
    buy.mouse_entered.connect(_interactive_hover.bind(buy, true, 1.045))
    buy.mouse_exited.connect(_interactive_hover.bind(buy, false, 1.045))
    buy.button_down.connect(_interactive_press.bind(buy, true, 0.93, 1.045))
    buy.button_up.connect(_interactive_press.bind(buy, false, 0.93, 1.045))
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
    card.pivot_offset = Vector2(72.5, 107.5)
    var border_color: Color = Color("ffd36f") if index == active_character else Color(0.66,0.28,0.74,0.86)
    card.add_theme_stylebox_override("panel", _glass_style(Color(0.025,0.035,0.07,0.98), border_color, 10, 8 if index == active_character else 6))

    var art: TextureRect = TextureRect.new()
    art.position = Vector2(7, 7)
    art.size = Vector2(131, 158)
    art.texture = load(String(chapter["art"]))
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    art.pivot_offset = art.size / 2.0
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
    click.mouse_entered.connect(_collection_card_hover.bind(card, art, true))
    click.mouse_exited.connect(_collection_card_hover.bind(card, art, false))
    click.button_down.connect(_collection_card_press.bind(card, art, true))
    click.button_up.connect(_collection_card_press.bind(card, art, false))
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
    sfx_bank.play("select")
    _animate_character_transition()
    _rebuild_automation()
    _refresh_live_labels()
    _save_game()

func _animate_character_transition() -> void:
    if character_transition_tween != null and character_transition_tween.is_valid():
        character_transition_tween.kill()

    character_transition_tween = create_tween()
    character_transition_tween.set_trans(Tween.TRANS_QUAD)
    character_transition_tween.set_ease(Tween.EASE_OUT)

    character_transition_tween.tween_property(background_layer, "modulate:a", 0.08, 0.16)
    character_transition_tween.parallel().tween_property(character_portrait, "modulate:a", 0.0, 0.14)
    character_transition_tween.parallel().tween_property(character_name_label, "modulate:a", 0.0, 0.14)
    character_transition_tween.parallel().tween_property(character_rarity_label, "modulate:a", 0.0, 0.14)
    character_transition_tween.parallel().tween_property(character_bonus_label, "modulate:a", 0.0, 0.14)
    character_transition_tween.parallel().tween_property(character_quote_label, "modulate:a", 0.0, 0.14)

    character_transition_tween.tween_callback(_commit_character_transition)

    character_transition_tween.tween_property(background_layer, "modulate:a", 1.0, 0.34)
    character_transition_tween.parallel().tween_property(background_layer, "scale", Vector2.ONE, 0.42).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
    character_transition_tween.parallel().tween_property(character_portrait, "modulate:a", 1.0, 0.26)
    character_transition_tween.parallel().tween_property(character_portrait, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    character_transition_tween.parallel().tween_property(character_name_label, "modulate:a", 1.0, 0.24)
    character_transition_tween.parallel().tween_property(character_rarity_label, "modulate:a", 1.0, 0.26)
    character_transition_tween.parallel().tween_property(character_bonus_label, "modulate:a", 1.0, 0.28)
    character_transition_tween.parallel().tween_property(character_quote_label, "modulate:a", 1.0, 0.30)
    character_transition_tween.tween_callback(_finish_character_transition)

func _commit_character_transition() -> void:
    _refresh_character(false)
    _apply_character_background(false)
    _rebuild_collection()

    background_layer.modulate.a = 0.08
    background_layer.scale = Vector2(1.025, 1.025)
    character_portrait.pivot_offset = character_portrait.size / 2.0
    character_portrait.modulate.a = 0.0
    character_portrait.scale = Vector2(1.075, 1.075)
    character_name_label.modulate.a = 0.0
    character_rarity_label.modulate.a = 0.0
    character_bonus_label.modulate.a = 0.0
    character_quote_label.modulate.a = 0.0

func _finish_character_transition() -> void:
    background_layer.modulate.a = 1.0
    background_layer.scale = Vector2.ONE
    character_portrait.modulate.a = 1.0
    character_portrait.scale = Vector2.ONE
    character_name_label.modulate.a = 1.0
    character_rarity_label.modulate.a = 1.0
    character_bonus_label.modulate.a = 1.0
    character_quote_label.modulate.a = 1.0
    _spawn_status_text("АКТИВНЫЙ ПЕРСОНАЖ • %s" % String(chapters[active_character]["name"]), Color("ffe2ff"))

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
    var target: Vector2 = Vector2(1.14, 1.14) if critical else Vector2(1.075, 1.075)

    var tween_a: Tween = create_tween()
    tween_a.tween_property(crystal_ring_a, "scale", target, 0.055)
    tween_a.parallel().tween_property(crystal_ring_a, "modulate:a", 0.72 if critical else 0.50, 0.055)
    tween_a.tween_property(crystal_ring_a, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween_a.parallel().tween_property(crystal_ring_a, "modulate:a", 0.25, 0.24)

    var tween_b: Tween = create_tween()
    tween_b.tween_property(crystal_ring_b, "scale", target * 1.05, 0.055)
    tween_b.parallel().tween_property(crystal_ring_b, "modulate:a", 0.80 if critical else 0.58, 0.055)
    tween_b.tween_property(crystal_ring_b, "scale", Vector2.ONE, 0.27).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
    tween_b.parallel().tween_property(crystal_ring_b, "modulate:a", 0.18, 0.27)

    if is_instance_valid(click_panel):
        var panel_tween: Tween = create_tween()
        panel_tween.tween_property(click_panel, "scale", Vector2(0.955, 0.955), 0.045)
        panel_tween.tween_property(click_panel, "scale", Vector2(1.035, 1.035) if critical else Vector2(1.018, 1.018), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
        panel_tween.tween_property(click_panel, "scale", Vector2.ONE, 0.13)

        if critical:
            var base_position: Vector2 = click_panel.position
            var shake: Tween = create_tween()
            shake.tween_property(click_panel, "position", base_position + Vector2(-7, 1), 0.035)
            shake.tween_property(click_panel, "position", base_position + Vector2(6, -1), 0.035)
            shake.tween_property(click_panel, "position", base_position, 0.05)

    _spawn_core_ripple(critical)

func _spawn_core_ripple(critical: bool) -> void:
    if not is_instance_valid(fx_layer):
        return

    var diameter: float = 150.0 if critical else 112.0
    var ring: Panel = Panel.new()
    ring.size = Vector2(diameter, diameter)
    ring.position = Vector2(1000, 650) - ring.size / 2.0
    ring.pivot_offset = ring.size / 2.0
    ring.scale = Vector2(0.72, 0.72)
    ring.modulate.a = 0.92 if critical else 0.62
    ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
    ring.add_theme_stylebox_override("panel", _ring_style(Color("ffe39a") if critical else Color("cc8cff"), 4 if critical else 3))
    fx_layer.add_child(ring)

    var ripple: Tween = create_tween()
    ripple.set_parallel(true)
    ripple.tween_property(ring, "scale", Vector2(3.0, 3.0) if critical else Vector2(2.35, 2.35), 0.34 if critical else 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    ripple.tween_property(ring, "modulate:a", 0.0, 0.34 if critical else 0.28)
    ripple.finished.connect(ring.queue_free)

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
        var target: Vector2 = center + Vector2(cos(angle), sin(angle)) * dist
        var lifetime: float = rng.randf_range(0.32, 0.58 if critical else 0.46)
        var end_scale: float = rng.randf_range(0.25, 0.65)

        var tween: Tween = create_tween()
        tween.set_parallel(true)
        tween.tween_property(spark, "position", target, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
        tween.tween_property(spark, "rotation", spark.rotation + rng.randf_range(-2.8, 2.8), lifetime)
        tween.tween_property(spark, "modulate:a", 0.0, lifetime)
        tween.tween_property(spark, "scale", Vector2.ONE * end_scale, lifetime)
        tween.finished.connect(spark.queue_free)

# -----------------------------------------------------------------------------
# Runtime helpers and gameplay systems
# -----------------------------------------------------------------------------

func _collection_card_hover(card: Control, art: Control, hovered: bool) -> void:
    if not is_instance_valid(card) or not is_instance_valid(art):
        return
    card.set_meta("hovered", hovered)
    card.z_index = 12 if hovered else 0
    _animate_control_scale(card, Vector2(1.028, 1.028) if hovered else Vector2.ONE, 0.16)
    _animate_control_scale(art, Vector2(1.065, 1.065) if hovered else Vector2.ONE, 0.18)

func _collection_card_press(card: Control, art: Control, pressed: bool) -> void:
    if not is_instance_valid(card) or not is_instance_valid(art):
        return
    if pressed:
        _animate_control_scale(card, Vector2(0.975, 0.975), 0.055)
        _animate_control_scale(art, Vector2(1.025, 1.025), 0.055)
    else:
        var hovered: bool = bool(card.get_meta("hovered", false))
        _animate_control_scale(card, Vector2(1.028, 1.028) if hovered else Vector2.ONE, 0.12)
        _animate_control_scale(art, Vector2(1.065, 1.065) if hovered else Vector2.ONE, 0.14)

func _interactive_hover(control: Control, hovered: bool, hover_scale: float) -> void:
    if not is_instance_valid(control):
        return
    control.set_meta("hovered", hovered)
    if bool(control.get_meta("pressed", false)):
        return
    _animate_control_scale(control, Vector2.ONE * (hover_scale if hovered else 1.0), 0.12)

func _interactive_press(control: Control, pressed: bool, press_scale: float, hover_scale: float) -> void:
    if not is_instance_valid(control):
        return
    control.set_meta("pressed", pressed)
    if pressed:
        _animate_control_scale(control, Vector2.ONE * press_scale, 0.045)
    else:
        var hovered: bool = bool(control.get_meta("hovered", false))
        _animate_control_scale(control, Vector2.ONE * (hover_scale if hovered else 1.0), 0.11)

func _animate_control_scale(control: Control, target_scale: Vector2, duration: float) -> void:
    if not is_instance_valid(control):
        return

    var previous: Variant = control.get_meta("motion_tween", null)
    if previous is Tween:
        var old_tween: Tween = previous
        if old_tween.is_valid():
            old_tween.kill()

    var tween: Tween = create_tween()
    control.set_meta("motion_tween", tween)
    tween.tween_property(control, "scale", target_scale, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _active_bonus_kind() -> String:
    return String(chapters[clampi(active_character, 0, chapters.size() - 1)]["bonus_kind"])

func _active_bonus_value() -> float:
    return float(chapters[clampi(active_character, 0, chapters.size() - 1)]["bonus_value"])

func _all_income_multiplier() -> float:
    var kind: String = _active_bonus_kind()
    if kind == "all_income":
        return 1.0 + _active_bonus_value()
    if kind == "perfection":
        return 2.0
    return 1.0

func _auto_income_multiplier() -> float:
    var kind: String = _active_bonus_kind()
    if kind == "auto_income" or kind == "auto_efficiency":
        return 1.0 + _active_bonus_value()
    return 1.0

func _display_auto_multiplier() -> float:
    return _auto_income_multiplier()

func _click_multiplier() -> float:
    var kind: String = _active_bonus_kind()
    if kind == "click_power":
        return 1.0 + _active_bonus_value()
    if kind == "perfection":
        return 2.0
    return 1.0

func _crit_multiplier_bonus() -> float:
    if _active_bonus_kind() == "crit_power":
        return 1.0 + _active_bonus_value()
    return 1.0

func _upgrade_cost_multiplier() -> float:
    if _active_bonus_kind() == "upgrade_discount":
        return maxf(0.05, 1.0 - _active_bonus_value())
    return 1.0

func _offline_income_multiplier() -> float:
    var kind: String = _active_bonus_kind()
    if kind == "offline_income":
        return 1.0 + _active_bonus_value()
    if kind == "perfection":
        return 2.0
    return 1.0

func _task_reward_multiplier() -> float:
    if _active_bonus_kind() == "task_reward":
        return 1.0 + _active_bonus_value()
    return 1.0

func _resonance_duration_multiplier() -> float:
    if _active_bonus_kind() == "resonance_duration":
        return 1.0 + _active_bonus_value()
    return 1.0

func _next_bonus_delay() -> float:
    var delay: float = rng.randf_range(BONUS_MIN_TIME, BONUS_MAX_TIME)
    if _active_bonus_kind() == "resonance_frequency":
        delay /= 1.0 + _active_bonus_value()
    return delay

func _recalculate_stats() -> void:
    click_power = 1.0
    auto_rate = 0.0
    for up in upgrades:
        var contribution: float = float(up["value"]) * float(int(up["count"]))
        if String(up["kind"]) == "click":
            click_power += contribution
        elif String(up["kind"]) == "auto":
            auto_rate += contribution

func _upgrade_cost(index: int) -> float:
    if index < 0 or index >= upgrades.size():
        return INF
    var up: Dictionary = upgrades[index]
    return float(up["base"]) * pow(float(up["growth"]), int(up["count"])) * _upgrade_cost_multiplier()

func _buy_upgrade(index: int) -> void:
    if index < 0 or index >= upgrades.size():
        return
    var cost: float = _upgrade_cost(index)
    if shards < cost:
        _spawn_status_text("НЕ ХВАТАЕТ ОСКОЛКОВ • нужно %s" % _compact(cost), Color("ff9eb9"))
        return
    shards -= cost
    upgrades[index]["count"] = int(upgrades[index]["count"]) + 1
    _recalculate_stats()
    sfx_bank.play("buy")
    _spawn_status_text("%s • уровень %d" % [String(upgrades[index]["name"]), int(upgrades[index]["count"])], Color("dcb8ff"))
    _rebuild_automation()
    _refresh_live_labels()
    _save_game()

func _check_chapter_unlock() -> void:
    var unlocked: int = current_chapter
    for i in range(chapters.size()):
        if total_shards >= float(chapters[i]["need"]):
            unlocked = i
    if unlocked <= current_chapter:
        return

    var old_chapter: int = current_chapter
    var task_reward: float = 0.0
    for i in range(old_chapter + 1, unlocked + 1):
        task_reward += maxf(50.0, float(chapters[i]["need"]) * 0.05) * _task_reward_multiplier()

    current_chapter = unlocked
    active_character = unlocked
    shards += task_reward

    sfx_bank.play("unlock")
    _refresh_character()
    _rebuild_collection()
    _rebuild_automation()
    _refresh_live_labels()
    _show_reward(unlocked)
    _spawn_status_text("НОВЫЙ ПЕРСОНАЖ • %s" % String(chapters[unlocked]["name"]), Color("ffe39a"))
    _save_game()

func _debug_unlock_next() -> void:
    if current_chapter >= chapters.size() - 1:
        _spawn_status_text("Все 13 персонажей уже открыты.", Color("ffe39a"))
        return
    var need: float = float(chapters[current_chapter + 1]["need"])
    var delta: float = maxf(0.0, need - total_shards)
    total_shards += delta
    shards += delta
    _check_chapter_unlock()

func _show_reward(index: int) -> void:
    if index < 0 or index >= chapters.size() or not is_instance_valid(reward_overlay):
        return
    var chapter: Dictionary = chapters[index]
    var is_final: bool = index == chapters.size() - 1
    reward_title.text = "ТЫ ДОСТИГ СОВЕРШЕНСТВА" if is_final else "НОВЫЙ ПЕРСОНАЖ"
    reward_title.add_theme_color_override("font_color", Color("ffd978") if is_final else Color("fff5ff"))
    reward_name.text = String(chapter["name"])
    reward_story.text = String(chapter["story"])
    reward_art.texture = load(String(chapter["art"]))

    reward_overlay.visible = true
    reward_overlay.color.a = 0.0
    reward_card.modulate.a = 0.0
    reward_card.scale = Vector2(0.84, 0.84)

    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(reward_overlay, "color:a", 0.95, 0.25)
    tween.tween_property(reward_card, "modulate:a", 1.0, 0.28)
    tween.tween_property(reward_card, "scale", Vector2.ONE, 0.42 if not is_final else 0.62).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

    if is_final:
        sfx_bank.play("crit")
        _spawn_status_text("ТЫ ДОСТИГ СОВЕРШЕНСТВА", Color("ffd978"))

func _close_reward() -> void:
    if not is_instance_valid(reward_overlay) or not reward_overlay.visible:
        return
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(reward_overlay, "color:a", 0.0, 0.18)
    tween.tween_property(reward_card, "modulate:a", 0.0, 0.18)
    tween.tween_property(reward_card, "scale", Vector2(0.94, 0.94), 0.18)
    tween.finished.connect(func() -> void:
        reward_overlay.visible = false
        reward_card.scale = Vector2.ONE
    )

func _spawn_rare_bonus() -> void:
    if not is_instance_valid(fx_layer) or is_instance_valid(rare_bonus_button):
        return

    var bonus: Button = Button.new()
    rare_bonus_button = bonus
    bonus.text = "✦"
    bonus.size = Vector2(76, 76)
    bonus.position = Vector2(310, rng.randf_range(190.0, 760.0))
    bonus.focus_mode = Control.FOCUS_NONE
    bonus.mouse_filter = Control.MOUSE_FILTER_STOP
    bonus.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    bonus.add_theme_font_override("font", title_font)
    bonus.add_theme_font_size_override("font_size", 42)
    bonus.add_theme_color_override("font_color", Color("fff0a8"))
    bonus.add_theme_stylebox_override("normal", _button_style(Color(0.20,0.08,0.31,0.96), Color("ffc85f"), 38))
    bonus.add_theme_stylebox_override("hover", _button_style(Color(0.39,0.10,0.50,0.99), Color("fff0a8"), 38))
    bonus.pressed.connect(_collect_rare_bonus.bind(bonus))
    fx_layer.add_child(bonus)

    var target: Vector2 = Vector2(1480, rng.randf_range(220.0, 770.0))
    var tween: Tween = create_tween()
    tween.tween_property(bonus, "position", target, 7.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.finished.connect(_expire_rare_bonus.bind(bonus))

func _collect_rare_bonus(button: Button) -> void:
    if not is_instance_valid(button):
        return
    var reward: float = maxf(25.0, maxf(click_power * 25.0, auto_rate * 10.0)) * _all_income_multiplier()
    var duration: float = 15.0 * _resonance_duration_multiplier()
    shards += reward
    total_shards += reward
    caught_bonuses += 1
    boost_multiplier = 2.0
    boost_time_left = maxf(boost_time_left, duration)
    sfx_bank.play("bonus")
    _spawn_status_text("РЕЗОНАНС ×2 • %.0f сек • +%s" % [duration, _compact(reward)], Color("ffd7ff"))
    if rare_bonus_button == button:
        rare_bonus_button = null
    button.queue_free()
    _check_chapter_unlock()
    _refresh_live_labels()
    _save_game()

func _expire_rare_bonus(button: Button) -> void:
    if not is_instance_valid(button):
        return
    if rare_bonus_button == button:
        rare_bonus_button = null
    button.queue_free()

func _spawn_status_text(message: String, color: Color) -> void:
    if not is_instance_valid(fx_layer):
        return
    var label: Label = Label.new()
    label.text = message
    label.position = Vector2(560, 175)
    label.size = Vector2(900, 58)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.add_theme_font_override("font", title_font)
    label.add_theme_font_size_override("font_size", 24)
    label.add_theme_color_override("font_color", color)
    label.add_theme_color_override("font_shadow_color", Color(0,0,0,0.95))
    label.add_theme_constant_override("shadow_offset_x", 2)
    label.add_theme_constant_override("shadow_offset_y", 2)
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fx_layer.add_child(label)

    var start: Vector2 = label.position
    var tween: Tween = create_tween()
    tween.set_parallel(true)
    tween.tween_property(label, "position", start + Vector2(0, -70), 1.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
    tween.tween_property(label, "modulate:a", 0.0, 1.15)
    tween.finished.connect(label.queue_free)

func _focus_click_area() -> void:
    _spawn_status_text("КЛИКНИ ПО КРИСТАЛЛУ", Color("e8c8ff"))
    var tween_a: Tween = create_tween()
    tween_a.tween_property(crystal_ring_a, "scale", Vector2(1.12,1.12), 0.14)
    tween_a.tween_property(crystal_ring_a, "scale", Vector2.ONE, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_ambient_animation() -> void:
    if is_instance_valid(crystal_ring_a):
        var tween_a: Tween = create_tween().set_loops()
        tween_a.tween_property(crystal_ring_a, "rotation", TAU, 18.0).from(0.0).set_trans(Tween.TRANS_LINEAR)
    if is_instance_valid(crystal_ring_b):
        var tween_b: Tween = create_tween().set_loops()
        tween_b.tween_property(crystal_ring_b, "rotation", -TAU, 13.0).from(0.0).set_trans(Tween.TRANS_LINEAR)

func _clear_overlay_content() -> void:
    overlay_mode = ""
    leaderboard_status = null
    if not is_instance_valid(overlay_content):
        return
    for child in overlay_content.get_children():
        child.queue_free()

func _close_overlay() -> void:
    overlay_mode = ""
    leaderboard_status = null
    if is_instance_valid(overlay_root):
        overlay_root.visible = false

func _show_home() -> void:
    _close_overlay()

func _open_gallery() -> void:
    _clear_overlay_content()
    overlay_title.text = "Галерея отражений"
    var info: Label = _small_text("Выбери любого уже открытого персонажа. Будущие награды скрыты до момента открытия.")
    overlay_content.add_child(info)

    var grid: GridContainer = GridContainer.new()
    grid.columns = 5
    grid.add_theme_constant_override("h_separation", 18)
    grid.add_theme_constant_override("v_separation", 18)
    overlay_content.add_child(grid)

    for i in range(current_chapter + 1):
        grid.add_child(_make_collection_card(i))

    overlay_root.visible = true

func _open_current_story() -> void:
    _clear_overlay_content()
    var chapter: Dictionary = chapters[active_character]
    overlay_title.text = String(chapter["name"])
    overlay_content.add_child(_small_text(String(chapter["story"])))
    overlay_content.add_child(_small_text("Особенность: %s" % String(chapter["bonus_text"])))
    overlay_content.add_child(_small_text(String(chapter["quote"])))
    overlay_root.visible = true

func _open_tasks() -> void:
    _clear_overlay_content()
    overlay_title.text = "Задания"
    if current_chapter >= chapters.size() - 1:
        overlay_content.add_child(_small_text("Главная цель выполнена: все 13 отражений восстановлены."))
    else:
        var need: float = float(chapters[current_chapter + 1]["need"])
        var remaining: float = maxf(0.0, need - total_shards)
        var reward: float = maxf(50.0, need * 0.05) * _task_reward_multiplier()
        overlay_content.add_child(_small_text("Текущая цель: собрать %s осколков." % _compact(need)))
        overlay_content.add_child(_small_text("Осталось: %s." % _compact(remaining)))
        overlay_content.add_child(_small_text("Награда за этап: примерно %s осколков." % _compact(reward)))
    overlay_root.visible = true

func _open_achievements() -> void:
    _clear_overlay_content()
    overlay_title.text = "Достижения"
    var achievements: Array = [
        ["Первое отражение", current_chapter >= 0],
        ["Коллекционер I — 5 персонажей", current_chapter >= 4],
        ["Коллекционер II — 10 персонажей", current_chapter >= 9],
        ["Охотник за резонансом — 10 бонусов", caught_bonuses >= 10],
        ["Тысяча импульсов — 1000 кликов", total_clicks >= 1000],
        ["Совершенство — 13/13", current_chapter >= 12]
    ]
    for item in achievements:
        var mark: String = "✓" if bool(item[1]) else "◇"
        overlay_content.add_child(_small_text("%s  %s" % [mark, String(item[0])]))
    overlay_root.visible = true

func _open_stats() -> void:
    _clear_overlay_content()
    overlay_title.text = "Статистика"
    overlay_content.add_child(_small_text("Всего собрано: %s осколков" % _compact(total_shards)))
    overlay_content.add_child(_small_text("Осколков сейчас: %s" % _compact(shards)))
    overlay_content.add_child(_small_text("Кликов: %d" % total_clicks))
    overlay_content.add_child(_small_text("Критических кликов: %d" % critical_clicks))
    overlay_content.add_child(_small_text("Поймано резонансов: %d" % caught_bonuses))
    overlay_content.add_child(_small_text("Открыто персонажей: %d / 13" % (current_chapter + 1)))
    overlay_content.add_child(_small_text("Время текущей сессии: %d мин." % int(session_time / 60.0)))
    if OS.has_feature("web"):
        overlay_content.add_child(_make_overlay_button("Рейтинг Яндекс.Игр", _open_leaderboard))
    overlay_root.visible = true

func _open_leaderboard() -> void:
    _clear_overlay_content()
    overlay_mode = "leaderboard"
    overlay_title.text = "Рейтинг восстановителей"
    leaderboard_status = _small_text("Подключаемся к Яндекс.Играм...")
    leaderboard_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    overlay_content.add_child(leaderboard_status)
    overlay_root.visible = true

    if not is_instance_valid(yandex_sdk) or not yandex_sdk.enabled:
        leaderboard_status.text = "Таблица лидеров доступна в Web-сборке на Яндекс.Играх."
        return
    if not yandex_sdk.ready:
        leaderboard_status.text = "SDK Яндекс.Игр ещё загружается. Попробуй открыть рейтинг через несколько секунд."
        return

    leaderboard_status.text = "Загружаем лучшие результаты..."
    yandex_sdk.request_leaderboard()

func _render_leaderboard(entries: Array) -> void:
    if overlay_mode != "leaderboard" or not is_instance_valid(overlay_content):
        return

    for child in overlay_content.get_children():
        child.queue_free()
    leaderboard_status = null

    if entries.is_empty():
        overlay_content.add_child(_small_text("В таблице лидеров пока нет результатов."))
        return

    overlay_content.add_child(_small_text("Лучшие восстановители по общему числу собранных осколков."))
    for raw_entry in entries:
        if typeof(raw_entry) != TYPE_DICTIONARY:
            continue

        var row: HBoxContainer = HBoxContainer.new()
        row.custom_minimum_size = Vector2(0, 48)
        row.add_theme_constant_override("separation", 18)

        var rank: Label = Label.new()
        rank.text = "#%d" % (int(raw_entry.get("rank", 0)) + 1)
        rank.custom_minimum_size = Vector2(90, 0)
        rank.add_theme_font_override("font", ui_font)
        rank.add_theme_font_size_override("font_size", 20)
        rank.add_theme_color_override("font_color", Color("d8c9ff"))
        row.add_child(rank)

        var player_name: Label = Label.new()
        player_name.text = String(raw_entry.get("name", "Игрок"))
        player_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        player_name.add_theme_font_override("font", ui_font)
        player_name.add_theme_font_size_override("font_size", 20)
        player_name.add_theme_color_override("font_color", Color("f5efff"))
        row.add_child(player_name)

        var score: Label = Label.new()
        score.text = _compact(float(raw_entry.get("score", 0)))
        score.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
        score.custom_minimum_size = Vector2(220, 0)
        score.add_theme_font_override("font", title_font)
        score.add_theme_font_size_override("font_size", 21)
        score.add_theme_color_override("font_color", Color("ffd978"))
        row.add_child(score)

        overlay_content.add_child(row)

func _on_yandex_auth_pressed() -> void:
    if not is_instance_valid(yandex_sdk) or not yandex_sdk.ready:
        _spawn_status_text("ЯНДЕКС.ИГРЫ ЕЩЁ ПОДКЛЮЧАЮТСЯ", Color("e8c8ff"))
        return
    cloud_merge_done = false
    _spawn_status_text("ОТКРЫВАЕМ ВХОД В ЯНДЕКС", Color("e8c8ff"))
    yandex_sdk.open_auth_dialog()

func _on_rewarded_ad_pressed() -> void:
    if not is_instance_valid(yandex_sdk) or not yandex_sdk.ready:
        _spawn_status_text("РЕКЛАМА ПОКА НЕДОСТУПНА", Color("ffb6c8"))
        return
    _close_overlay()
    _spawn_status_text("ОТКРЫВАЕМ НАГРАДНУЮ РЕКЛАМУ", Color("e8c8ff"))
    yandex_sdk.show_rewarded_ad()

func _open_settings() -> void:
    _clear_overlay_content()
    overlay_title.text = "Настройки"
    var sound_toggle: CheckButton = CheckButton.new()
    sound_toggle.text = "Звук"
    sound_toggle.button_pressed = user_sound_enabled
    sound_toggle.add_theme_font_override("font", ui_font)
    sound_toggle.add_theme_font_size_override("font_size", 24)
    sound_toggle.toggled.connect(_set_sound_enabled)
    overlay_content.add_child(sound_toggle)
    overlay_content.add_child(_small_text("Прогресс сохраняется автоматически каждые 5 секунд."))
    overlay_content.add_child(_small_text("Выбранный персонаж сохраняется отдельно от прогресса открытия."))

    if OS.has_feature("web"):
        overlay_content.add_child(_small_text("Яндекс.Игры"))
        var platform_status: String = "Подключение к SDK..."
        if is_instance_valid(yandex_sdk) and yandex_sdk.ready:
            platform_status = "Подключено. Облачное сохранение активно."
            if yandex_sdk.is_authorized():
                platform_status += " Вход выполнен."
            else:
                platform_status += " Вход нужен для таблицы лидеров и переноса прогресса между устройствами."
        overlay_content.add_child(_small_text(platform_status))

        if not is_instance_valid(yandex_sdk) or not yandex_sdk.is_authorized():
            overlay_content.add_child(_make_overlay_button("Войти в Яндекс", _on_yandex_auth_pressed))
        overlay_content.add_child(_make_overlay_button("Рейтинг Яндекс.Игр", _open_leaderboard))
        overlay_content.add_child(_make_overlay_button("Резонанс ×2 за рекламу", _on_rewarded_ad_pressed))

    overlay_root.visible = true

func _set_sound_enabled(enabled: bool) -> void:
    user_sound_enabled = enabled
    _update_audio_mute()
    _save_game()

func _make_overlay_button(text_value: String, callback: Callable) -> Button:
    var button: Button = Button.new()
    button.text = text_value
    button.custom_minimum_size = Vector2(0, 58)
    button.add_theme_font_override("font", ui_font)
    button.add_theme_font_size_override("font_size", 20)
    button.add_theme_stylebox_override("normal", _button_style(Color(0.08,0.05,0.16,0.96), Color(0.65,0.46,0.85,0.85), 16))
    button.add_theme_stylebox_override("hover", _button_style(Color(0.17,0.06,0.26,0.98), Color(0.94,0.59,1.0,1.0), 16))
    button.pressed.connect(callback)
    return button

func _small_text(value: String) -> Label:
    var label: Label = Label.new()
    label.text = value
    label.custom_minimum_size = Vector2(0, 52)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.add_theme_font_override("font", ui_font)
    label.add_theme_font_size_override("font_size", 22)
    label.add_theme_color_override("font_color", Color("eee8ff"))
    return label

func _glass_style(bg_color: Color, border_color: Color, radius: int, shadow_size_value: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.set_border_width_all(2)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.shadow_color = Color(0.30, 0.08, 0.50, 0.38)
    style.shadow_size = shadow_size_value
    return style

func _button_style(bg_color: Color, border_color: Color, radius: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = bg_color
    style.border_color = border_color
    style.set_border_width_all(2)
    style.corner_radius_top_left = radius
    style.corner_radius_top_right = radius
    style.corner_radius_bottom_left = radius
    style.corner_radius_bottom_right = radius
    style.shadow_color = Color(0.45,0.10,0.62,0.25)
    style.shadow_size = 8
    return style

func _ring_style(border_color: Color, width: int) -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.08,0.02,0.16,0.08)
    style.border_color = border_color
    style.set_border_width_all(width)
    style.corner_radius_top_left = 200
    style.corner_radius_top_right = 200
    style.corner_radius_bottom_left = 200
    style.corner_radius_bottom_right = 200
    return style

func _click_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = _glass_style(Color(0.16,0.035,0.30,0.96), Color("d36cff"), 28, 18)
    style.border_width_left = 3
    style.border_width_top = 3
    style.border_width_right = 3
    style.border_width_bottom = 3
    return style

func _progress_bg_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color(0.015,0.025,0.06,0.96)
    style.border_color = Color(0.32,0.28,0.55,0.80)
    style.set_border_width_all(1)
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    return style

func _progress_fill_style() -> StyleBoxFlat:
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = Color("c85cff")
    style.corner_radius_top_left = 10
    style.corner_radius_top_right = 10
    style.corner_radius_bottom_left = 10
    style.corner_radius_bottom_right = 10
    style.shadow_color = Color(0.75,0.27,1.0,0.55)
    style.shadow_size = 8
    return style

func _resonance_style(active: bool) -> StyleBoxFlat:
    if active:
        return _glass_style(Color(0.22,0.055,0.16,0.97), Color("ffb36b"), 18, 14)
    return _glass_style(Color(0.045,0.035,0.10,0.94), Color(0.48,0.31,0.72,0.70), 18, 10)

func _compact(value: float) -> String:
    var suffixes: Array[String] = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No"]
    var idx: int = 0
    var n: float = value
    while absf(n) >= 1000.0 and idx < suffixes.size() - 1:
        n /= 1000.0
        idx += 1
    if idx == 0:
        return str(int(round(value)))
    if absf(n) >= 100.0:
        return "%.0f%s" % [n, suffixes[idx]]
    if absf(n) >= 10.0:
        return "%.1f%s" % [n, suffixes[idx]]
    return "%.2f%s" % [n, suffixes[idx]]

func _build_save_data() -> Dictionary:
    var counts: Array[int] = []
    for up in upgrades:
        counts.append(int(up["count"]))
    return {
        "shards": shards,
        "total_shards": total_shards,
        "current_chapter": current_chapter,
        "active_character": active_character,
        "upgrade_counts": counts,
        "last_unix": last_unix,
        "total_clicks": total_clicks,
        "critical_clicks": critical_clicks,
        "caught_bonuses": caught_bonuses,
        "sound_enabled": user_sound_enabled
    }

func _save_game() -> void:
    last_unix = int(Time.get_unix_time_from_system())
    var data: Dictionary = _build_save_data()
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file != null:
        file.store_string(JSON.stringify(data))
        file.flush()

func _load_game() -> void:
    last_unix = int(Time.get_unix_time_from_system())
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        return
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if typeof(parsed) != TYPE_DICTIONARY:
        return
    var data: Dictionary = parsed
    shards = float(data.get("shards", 0.0))
    total_shards = float(data.get("total_shards", 0.0))
    current_chapter = clampi(int(data.get("current_chapter", 0)), 0, chapters.size() - 1)
    active_character = clampi(int(data.get("active_character", current_chapter)), 0, current_chapter)
    last_unix = int(data.get("last_unix", last_unix))
    total_clicks = int(data.get("total_clicks", 0))
    critical_clicks = int(data.get("critical_clicks", 0))
    caught_bonuses = int(data.get("caught_bonuses", 0))
    user_sound_enabled = bool(data.get("sound_enabled", true))

    var counts: Variant = data.get("upgrade_counts", [])
    if counts is Array:
        var count_array: Array = counts
        for i in range(mini(count_array.size(), upgrades.size())):
            upgrades[i]["count"] = int(count_array[i])

func _merge_cloud_data(data: Dictionary) -> void:
    var cloud_time: int = int(data.get("last_unix", 0))
    if cloud_time <= last_unix:
        return

    shards = float(data.get("shards", shards))
    total_shards = float(data.get("total_shards", total_shards))
    current_chapter = clampi(int(data.get("current_chapter", current_chapter)), 0, chapters.size() - 1)
    active_character = clampi(int(data.get("active_character", current_chapter)), 0, current_chapter)
    last_unix = cloud_time
    total_clicks = int(data.get("total_clicks", total_clicks))
    critical_clicks = int(data.get("critical_clicks", critical_clicks))
    caught_bonuses = int(data.get("caught_bonuses", caught_bonuses))
    user_sound_enabled = bool(data.get("sound_enabled", user_sound_enabled))

    var counts: Variant = data.get("upgrade_counts", [])
    if counts is Array:
        var count_array: Array = counts
        for i in range(mini(count_array.size(), upgrades.size())):
            upgrades[i]["count"] = int(count_array[i])

    _recalculate_stats()
    _apply_offline_progress()
    _update_audio_mute()
    _refresh_all()
    _save_game()
    offline_label.text = "Облачное сохранение Яндекс.Игр загружено."

func _apply_offline_progress() -> void:
    var now: int = int(Time.get_unix_time_from_system())
    if last_unix <= 0 or auto_rate <= 0.0:
        last_unix = now
        return
    var seconds: int = clampi(now - last_unix, 0, 8 * 60 * 60)
    last_unix = now
    if seconds <= 0:
        return
    var gain: float = auto_rate * float(seconds) * _auto_income_multiplier() * _all_income_multiplier() * _offline_income_multiplier()
    shards += gain
    total_shards += gain
    offline_label.text = "Пока тебя не было: +%s за %d мин." % [_compact(gain), int(seconds / 60)]
    _check_chapter_unlock()
