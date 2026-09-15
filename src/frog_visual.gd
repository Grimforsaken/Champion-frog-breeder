class_name FrogVisual
extends TextureRect

const TINT_SHADER := preload("res://src/frog_tint.gdshader")

var species := "regular_frog"
var view_mode := "side"
var hue := 120
var fluorescent := false

func configure(frog: Dictionary, requested_view: String = "side") -> void:
	species = str(frog.get("species", "regular_frog"))
	view_mode = requested_view
	hue = int(frog.get("hue", 120))
	fluorescent = bool(frog.get("fluorescent", false))
	_update_visual()

func _update_visual() -> void:
	var path := _asset_path()
	if ResourceLoader.exists(path):
		texture = load(path)
	else:
		texture = null

	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	var mat := ShaderMaterial.new()
	mat.shader = TINT_SHADER
	mat.set_shader_parameter("hue_degrees", float(hue))
	mat.set_shader_parameter("fluorescent", fluorescent)
	material = mat

func _asset_path() -> String:
	var prefix := "bullfrog" if species == "bullfrog" else "regular"
	var suffix := "top" if view_mode == "top" else "side"
	return "res://assets/frogs/%s_%s_mask.webp" % [prefix, suffix]
