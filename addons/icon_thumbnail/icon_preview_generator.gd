@tool
extends EditorResourcePreviewGenerator

func _handles(type: String) -> bool:
	return type == "Resource"

func _generate(resource: Resource, size: Vector2i, metadata: Dictionary) -> Texture2D:
	if resource == null or size.x <= 0 or size.y <= 0:
		return null
	var icon_value: Variant = resource.get("icon")
	if not (icon_value is Texture2D):
		return null
	var img: Image = (icon_value as Texture2D).get_image()
	if img == null or img.get_width() <= 0 or img.get_height() <= 0:
		return null
	if img.is_compressed():
		img.decompress()
	img.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	return ImageTexture.create_from_image(img)
