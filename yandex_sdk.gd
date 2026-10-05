extends Node

const LEADERBOARD_NAME := "shards_total"

var enabled: bool = false
var ready: bool = false
var player_ready: bool = false
var cloud_requested: bool = false
var cloud_consumed: bool = false
var leaderboard_requested: bool = false

func _ready() -> void:
    enabled = OS.has_feature("web")
    if enabled:
        _inject_sdk()

func _process(_delta: float) -> void:
    if not enabled:
        return
    ready = bool(JavaScriptBridge.eval("Boolean(window.__yg_ready)", true))
    player_ready = bool(JavaScriptBridge.eval("Boolean(window.__yg_player_ready)", true))

func _inject_sdk() -> void:
    JavaScriptBridge.eval("""
(() => {
    if (window.__yg_booting || window.__yg_ready) return;
    window.__yg_booting = true;
    window.__yg_ready = false;
    window.__yg_player_ready = false;
    window.__yg_cloud_payload = "";
    window.__yg_lb_payload = "";
    window.__yg_error = "";

    const boot = async () => {
        try {
            window.__ysdk = await YaGames.init();
            window.__yg_ready = true;
            try {
                window.__yg_player = await window.__ysdk.getPlayer();
                window.__yg_player_ready = true;
            } catch (playerError) {
                window.__yg_error = String(playerError);
            }
        } catch (e) {
            window.__yg_error = String(e);
        }
    };

    if (window.YaGames) {
        boot();
        return;
    }

    const existing = document.querySelector('script[data-shards-ysdk]');
    if (existing) {
        existing.addEventListener('load', boot, { once: true });
        return;
    }

    const script = document.createElement('script');
    script.src = '/sdk.js';
    script.async = true;
    script.dataset.shardsYsdk = '1';
    script.onload = boot;
    script.onerror = () => window.__yg_error = 'Yandex Games SDK failed to load';
    document.head.appendChild(script);
})();
""", true)

func request_cloud_data() -> void:
    if not player_ready or cloud_requested:
        return
    cloud_requested = true
    JavaScriptBridge.eval("""
(async () => {
    try {
        const data = await window.__yg_player.getData();
        window.__yg_cloud_payload = JSON.stringify(data || {});
    } catch (e) {
        window.__yg_error = String(e);
        window.__yg_cloud_payload = "{}";
    }
})();
""", true)

func consume_cloud_data() -> Dictionary:
    if not enabled or cloud_consumed:
        return {}
    var payload = JavaScriptBridge.eval("window.__yg_cloud_payload || ''", true)
    if typeof(payload) != TYPE_STRING or String(payload).is_empty():
        return {}
    cloud_consumed = true
    var parsed = JSON.parse_string(String(payload))
    if typeof(parsed) == TYPE_DICTIONARY:
        return parsed
    return {}

func save_cloud(data: Dictionary) -> void:
    if not player_ready:
        return
    var payload: String = JSON.stringify(data)
    var js_payload: String = JSON.stringify(payload)
    JavaScriptBridge.eval("""
(async () => {
    try {
        const payload = JSON.parse(%s);
        await window.__yg_player.setData(JSON.parse(payload), true);
    } catch (e) {
        window.__yg_error = String(e);
    }
})();
""" % js_payload, true)

func submit_score(score: float) -> void:
    if not ready or not player_ready:
        return
    var safe_score: int = int(clampf(floor(score), 0.0, 9000000000000000.0))
    JavaScriptBridge.eval("""
(async () => {
    try {
        const available = await window.__ysdk.isAvailableMethod('leaderboards.setScore');
        if (!available) return;
        await window.__ysdk.leaderboards.setScore('%s', %d);
    } catch (e) {
        window.__yg_error = String(e);
    }
})();
""" % [LEADERBOARD_NAME, safe_score], true)

func request_leaderboard() -> void:
    if not ready:
        return
    leaderboard_requested = true
    JavaScriptBridge.eval("""
(async () => {
    try {
        const result = await window.__ysdk.leaderboards.getEntries('%s', {
            quantityTop: 10,
            includeUser: true,
            quantityAround: 3
        });
        const compact = (result.entries || []).map(e => ({
            rank: e.rank,
            score: e.score,
            formatted_score: e.formattedScore || String(e.score),
            name: (e.player && e.player.publicName) || e.publicName || 'Игрок'
        }));
        window.__yg_lb_payload = JSON.stringify(compact);
    } catch (e) {
        window.__yg_error = String(e);
        window.__yg_lb_payload = "[]";
    }
})();
""" % LEADERBOARD_NAME, true)

func consume_leaderboard() -> Array:
    if not enabled:
        return []
    var payload = JavaScriptBridge.eval("window.__yg_lb_payload || ''", true)
    if typeof(payload) != TYPE_STRING or String(payload).is_empty():
        return []
    JavaScriptBridge.eval("window.__yg_lb_payload = ''", true)
    var parsed = JSON.parse_string(String(payload))
    if typeof(parsed) == TYPE_ARRAY:
        return parsed
    return []

func show_rewarded_ad() -> void:
    if not ready:
        return
    JavaScriptBridge.eval("""
try {
    window.__ysdk.adv.showRewardedVideo({
        callbacks: {
            onOpen: () => window.__yg_rewarded = false,
            onRewarded: () => window.__yg_rewarded = true,
            onClose: () => window.__yg_rewarded_closed = true,
            onError: e => window.__yg_error = String(e)
        }
    });
} catch (e) {
    window.__yg_error = String(e);
}
""", true)

func consume_rewarded() -> bool:
    if not enabled:
        return false
    var rewarded: bool = bool(JavaScriptBridge.eval("Boolean(window.__yg_rewarded)", true))
    if rewarded:
        JavaScriptBridge.eval("window.__yg_rewarded = false", true)
    return rewarded

func get_error() -> String:
    if not enabled:
        return ""
    var err = JavaScriptBridge.eval("window.__yg_error || ''", true)
    return String(err)
