extends RefCounted

const ATLAS_PATH := "res://assets/gallery_b64/gallery_atlas.jpg.b64"
const ATLAS_CELL := 72
const ATLAS_COLUMNS := 5

static var _atlas_cache: Texture2D = null

static func load_texture(art_path: String) -> Texture2D:
    if ResourceLoader.exists(art_path):
        var resource = load(art_path)
        if resource is Texture2D:
            return resource

    var individual_path: String = art_path.replace(
        "res://assets/gallery/",
        "res://assets/gallery_b64/"
    ).replace(".png", ".jpg.b64")

    var individual: Texture2D = _load_b64_jpg(individual_path)
    if individual != null:
        return individual

    return _load_from_atlas(art_path)

static func _load_b64_jpg(path: String) -> Texture2D:
    if not FileAccess.file_exists(path):
        return null

    var encoded: String = FileAccess.get_file_as_string(path).strip_edges()
    if encoded.is_empty():
        return null

    var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
    var image := Image.new()
    var error: Error = image.load_jpg_from_buffer(bytes)
    if error != OK:
        return null

    return ImageTexture.create_from_image(image)

static func _load_atlas_texture() -> Texture2D:
    if _atlas_cache != null:
        return _atlas_cache

    _atlas_cache = _load_b64_jpg(ATLAS_PATH)
    return _atlas_cache

static func _load_from_atlas(art_path: String) -> Texture2D:
    var filename: String = art_path.get_file()
    if filename.length() < 2:
        return null

    var prefix: String = filename.substr(0, 2)
    if not prefix.is_valid_int():
        return null

    var index: int = int(prefix) - 1
    if index < 0 or index >= 13:
        return null

    var atlas: Texture2D = _load_atlas_texture()
    if atlas == null:
        return null

    var col: int = index % ATLAS_COLUMNS
    var row: int = int(index / ATLAS_COLUMNS)

    var region := AtlasTexture.new()
    region.atlas = atlas
    region.region = Rect2(
        col * ATLAS_CELL,
        row * ATLAS_CELL,
        ATLAS_CELL,
        ATLAS_CELL
    )
    return region
