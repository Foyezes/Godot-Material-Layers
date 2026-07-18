## Material that's blended using mask texture or [code]MaskMaterial[/code].
## [url=https://www.foyez.es/docs/layerforge]Learn more[/url]
@icon ("res://addons/materialLayers/icons/surfaceMaterial.svg")
@tool
class_name SurfaceMaterial
extends ShaderMaterial

@export var use_as_overlay: bool = false:
	set(val):
		use_as_overlay = val

const DEFAULT_SHADER_PATH := "res://addons/materialLayers/shaders/surface_material.gdshader"

func _init() -> void:
	if not shader:
		shader = Shader.new()
		shader.resource_name = "surfaceMaterial"
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