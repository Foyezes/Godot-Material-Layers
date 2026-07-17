## Contains [code]SurfaceMaterial[/code] & mask texture or [code]MaskMaterial[/code].
## [url=https://www.foyez.es/docs/layerforge]Learn more[/url]
@icon ("res://addons/materialLayers/icons/materialLayer.svg")
@tool
class_name MaterialLayer
extends Resource

signal material_replaced
signal mask_updated

var _setting_surface := false
var _setting_mask := false

@export var label: String = "Layer":
	set(val):
		label = val

@export var active: bool = true:
	set(val):
		active = val
		emit_changed()
    
@export var surface_material: ShaderMaterial:
	set(val):
		if _setting_surface:
			surface_material = val
			return
		_setting_surface = true
		surface_material = val.duplicate(false) if val else null
		if surface_material:
			surface_material.resource_path = ""
		if surface_material and surface_material.use_as_overlay:
			mask_active = false
		_setting_surface = false
		material_replaced.emit()
		emit_changed()

enum MaskType { TEXTURE, MATERIAL }


@export var mask_active: bool = true:
	set(val):
		mask_active = val
		emit_changed()
		notify_property_list_changed()

@export var mask_type: MaskType = MaskType.TEXTURE:
	set(val):
		mask_type = val
		emit_changed()
		notify_property_list_changed()

@export var mask_texture: Texture2D:
	set(val):
		mask_texture = val
		mask_updated.emit()
		emit_changed()

enum TextureChannel { RED, GREEN, BLUE, ALPHA }

@export var mask_texture_channel: TextureChannel = TextureChannel.RED:
	set(val):
		mask_texture_channel = val
		mask_updated.emit()
		emit_changed()

@export var mask_material: ShaderMaterial:
	set(val):
		if _setting_mask:
			mask_material = val
			return
		_setting_mask = true
		mask_material = val.duplicate(false) if val else null
		if mask_material:
			mask_material.resource_path = ""
		_setting_mask = false
		material_replaced.emit()
		emit_changed()


func _validate_property(property: Dictionary) -> void:
	if property.name == "mask_type" or property.name == "mask_material" or property.name == "mask_texture" or property.name == "mask_texture_channel":
		if !mask_active:
			property.usage &= ~PROPERTY_USAGE_EDITOR

	if property.name == "mask_texture" or property.name == "mask_texture_channel":
		if mask_type != MaskType.TEXTURE:
			property.usage &= ~PROPERTY_USAGE_EDITOR

	if property.name == "mask_material":
		if mask_type != MaskType.MATERIAL:
			property.usage &= ~PROPERTY_USAGE_EDITOR
	
	if property.name == "surface_material":
		property.hint = PROPERTY_HINT_RESOURCE_TYPE
		property.hint_string = "SurfaceMaterial"
	
	if property.name == "mask_material":
		property.hint = PROPERTY_HINT_RESOURCE_TYPE
		property.hint_string = "MaskMaterial"