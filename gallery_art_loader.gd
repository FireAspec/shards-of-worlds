extends RefCounted

static func load_texture(art_path: String) -> Texture2D:
    if ResourceLoader.exists(art_path):
        var resource = load(art_path)
        if resource is Texture2D:
            return resource

    var fallback_path: String = art_path.replace(
        "res://assets/gallery/",
        "res://assets/gallery_b64/"
    ).replace(".png", ".jpg.b64")

    if not FileAccess.file_exists(fallback_path):
        return null

    var encoded: String = FileAccess.get_file_as_string(fallback_path).strip_edges()
    if encoded.is_empty():
        return null

    var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
    var image := Image.new()
    var error: Error = image.load_jpg_from_buffer(bytes)
    if error != OK:
        return null

    return ImageTexture.create_from_image(image)
