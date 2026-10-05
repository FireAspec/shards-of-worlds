extends RefCounted

static func load_texture(path: String) -> Texture2D:
    if ResourceLoader.exists(path):
        var resource: Resource = load(path)
        if resource is Texture2D:
            return resource as Texture2D

    var fallback: String = path + ".b64"
    if not FileAccess.file_exists(fallback):
        return null

    var encoded: String = FileAccess.get_file_as_string(fallback).strip_edges()
    if encoded.is_empty():
        return null

    var bytes: PackedByteArray = Marshalls.base64_to_raw(encoded)
    var image: Image = Image.new()
    var error: Error = image.load_webp_from_buffer(bytes)
    if error != OK:
        return null

    return ImageTexture.create_from_image(image)
