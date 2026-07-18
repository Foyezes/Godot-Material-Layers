## Material used to blend [code]SurfaceMaterials[/code].
## [url=https://www.foyez.es/docs/layerforge]Learn more[/url]
@icon ("res://addons/materialLayers/icons/maskMaterial.svg")
@tool
class_name MaskMaterial
extends ShaderMaterial

const DEFAULT_SHADER_PATH := "res://addons/materialLayers/shaders/mask_material.gdshader"

func _init() -> void:
	if not shader:
		shader = Shader.new()
		shader.resource_name = "maskMaterial"
		var template := load(DEFAULT_SHADER_PATH) as Shader
		if template:
			shader.code = template.code

func _validate_property(property: Dictionary) -> void:
	if property.name in ["render_priority", "next_pass"]:
		property.usage &= ~PROPERTY_USAGE_EDITOR

func _set(property: StringName, value: Variant) -> bool:
	if str(property).begins_with("shader_parameter/"):
		call_deferred("emit_changed")
	return false