## Contains [code]MaterialLayer[/code] resource and generates final material.
## [url=https://www.foyez.es/docs/material-layers]Learn more[/url]
@icon ("res://addons/materialLayers/icons/layerStack.svg")
@tool
class_name LayerStack
extends ShaderMaterial

func _init() -> void:
	resource_name = "layer_stack"
	call_deferred("_auto_compile_on_load")

var _base_layer_initialized := false
var _layers_initialized := false
var _compiled := false

## [img width=32]res://addons/materialLayers/icons/surfaceMaterial.svg[/img]
## Base layer
@export var base_layer: SurfaceMaterial:
	set(val):
		if val:
			val = val.duplicate()
		if base_layer and base_layer.changed.is_connected(_on_uniform_changed):
			base_layer.changed.disconnect(_on_uniform_changed)
		base_layer = val
		if base_layer and not base_layer.changed.is_connected(_on_uniform_changed):
			base_layer.changed.connect(_on_uniform_changed)
		_invalidate_assets()
		_base_layer_initialized = true
		emit_changed()


@export var layers: Array[MaterialLayer] = []:
	set(val):
		for layer in layers:
			if layer and layer.changed.is_connected(_on_layer_changed):
				layer.changed.disconnect(_on_layer_changed)
			if layer and layer.material_replaced.is_connected(_on_material_replaced):
				layer.material_replaced.disconnect(_on_material_replaced)
			if layer and layer.mask_updated.is_connected(_on_mask_updated):
				layer.mask_updated.disconnect(_on_mask_updated)
			if layer and layer.surface_material and layer.surface_material.changed.is_connected(_on_uniform_changed):
				layer.surface_material.changed.disconnect(_on_uniform_changed)
			if layer and layer.mask_material and layer.mask_material.changed.is_connected(_on_uniform_changed):
				layer.mask_material.changed.disconnect(_on_uniform_changed)
		var arr := val.duplicate()
		for i in arr.size():
			if arr[i] == null:
				arr[i] = MaterialLayer.new()
		layers = arr
		_reconnect_layer_signals()
		_invalidate_assets()
		emit_changed()

var layer_uniform_maps: Array = []
var _assets: Array = []

func _ensure_assets() -> Array:
	if _assets.is_empty():
		_assets = _collect_layer_assets()
	return _assets

func _invalidate_assets() -> void:
	_assets.clear()

const TYPES := ["float", "int", "bool", "bvec2", "bvec3", "bvec4", "ivec2", "ivec3", "ivec4", "uint", "uvec2", "uvec3","uvec4","vec2", "vec3", "vec4", "mat2", "mat3", "mat4", ]
const OUTPUTS := ["VERTEX", "ALBEDO", "NORMAL_MAP", "NORMAL_MAP_DEPTH", "ROUGHNESS", "AO", "AO_LIGHT_AFFECT", "EMISSION", "BENT_NORMAL", "METALLIC", "SPECULAR", "RIM", "RIM_TINT", "CLEARCOAT", "CLEARCOAT_GLOSS", "ANISOTROPY", "ANISOTROPY_FLOW", "SSS_STRENGTH", "SSS_TRANSMITTANCE_COLOR", "SSS_TRANSMITTANCE_DEPTH", "BACKLIGHT", "FOG", "RADIANCE", "IRRADIANCE"]
const DEFAULT_FRAGMENT_OUTPUT := "
	fragmentMaterial DEFAULT_FRAGMENT = fragmentMaterial(
	    vec3(0.75),               
	    vec3(0.5, 0.5, 1.0),      
	    1.0,                      
	    1.0,                      
	    0.5,                      
	    0.0,                      
	    vec3(0.0),                
	    vec3(0.5, 0.5, 1.0),    
	    vec3(0.5, 0.5, 1.0),      
	    1.0,                      
	    0.5,                      
	    0.0,                      
	    0.0                
	);
	"

const DEFAULT_VERTEX_OUTPUT := "
	vertexMaterial DEFAULT_VERTEX = vertexMaterial(
	    VERTEX,
		0.5
	);
	"
const FRAGMENT_OUTPUTS := "
	ALBEDO = finalFragment.layer_mat_albedo;
	NORMAL_MAP = l_normalCombine(finalFragment.layer_mat_normal_map, finalFragment.layer_mat_mesh_normal_map);
	BENT_NORMAL_MAP = finalFragment.layer_mat_bent_normal;
	ROUGHNESS = finalFragment.layer_mat_roughness;
	AO = finalFragment.layer_mat_ao * finalFragment.layer_mat_mesh_ao;
	METALLIC = finalFragment.layer_mat_metallic;
	EMISSION = finalFragment.layer_mat_emission;
	"

const FRAGMENT_LAYER_OUT_FIELDS := {
    "LAYER_OUT_ALBEDO":     "layer_mat_albedo",
    "LAYER_OUT_NORMAL_MAP": "layer_mat_normal_map",
    "LAYER_OUT_MESH_NORMAL_MAP": "layer_mat_mesh_normal_map",
    "LAYER_OUT_BENT_NORMAL": "layer_mat_bent_normal",
    "LAYER_OUT_ROUGHNESS":  "layer_mat_roughness",
    "LAYER_OUT_AO":         "layer_mat_ao",
    "LAYER_OUT_HEIGHT":     "layer_mat_height",
    "LAYER_OUT_METALLIC":   "layer_mat_metallic",
    "LAYER_OUT_EMISSION":   "layer_mat_emission",
    "LAYER_OUT_MESH_AO":    "layer_mat_mesh_ao",
    "LAYER_OUT_MESH_HEIGHT": "layer_mat_mesh_height",
    "LAYER_OUT_MESH_CURVATURE": "layer_mat_mesh_curvature",
    "LAYER_OUT_MESH_THICKNESS": "layer_mat_mesh_thickness",

}
const FRAGMENT_LAYER_BELOW_FIELDS := {
    "LAYER_BELOW_ALBEDO":     "layer_mat_albedo",
    "LAYER_BELOW_NORMAL_MAP": "layer_mat_normal_map",
	"LAYER_BELOW_MESH_NORMAL_MAP": "layer_mat_mesh_normal_map",
    "LAYER_BELOW_BENT_NORMALS": "layer_mat_bent_normal",
    "LAYER_BELOW_ROUGHNESS":  "layer_mat_roughness",
    "LAYER_BELOW_AO":         "layer_mat_ao",
    "LAYER_BELOW_HEIGHT":     "layer_mat_height",
    "LAYER_BELOW_METALLIC":   "layer_mat_metallic",
    "LAYER_BELOW_EMISSION":   "layer_mat_emission",
    "LAYER_BELOW_MESH_AO":    "layer_mat_mesh_ao",
    "LAYER_BELOW_MESH_HEIGHT": "layer_mat_mesh_height",
    "LAYER_BELOW_MESH_CURVATURE": "layer_mat_mesh_curvature",
    "LAYER_BELOW_MESH_THICKNESS": "layer_mat_mesh_thickness",

}
const FRAGMENT_LAYER_CURRENT_FIELDS := {
    "LAYER_CURRENT_ALBEDO":     "layer_mat_albedo",
    "LAYER_CURRENT_NORMAL_MAP": "layer_mat_normal_map",
	"LAYER_CURRENT_MESH_NORMAL_MAP": "layer_mat_mesh_normal_map",
    "LAYER_CURRENT_BENT_NORMALS": "layer_mat_bent_normal",
    "LAYER_CURRENT_ROUGHNESS":  "layer_mat_roughness",
    "LAYER_CURRENT_AO":         "layer_mat_ao",
    "LAYER_CURRENT_HEIGHT":     "layer_mat_height",
    "LAYER_CURRENT_METALLIC":   "layer_mat_metallic",
    "LAYER_CURRENT_EMISSION":   "layer_mat_emission",
    "LAYER_CURRENT_MESH_AO":    "layer_mat_mesh_ao",
    "LAYER_CURRENT_MESH_HEIGHT": "layer_mat_mesh_height",
    "LAYER_CURRENT_MESH_CURVATURE": "layer_mat_mesh_curvature",
    "LAYER_CURRENT_MESH_THICKNESS": "layer_mat_mesh_thickness",

}
const FRAGMENT_LAYER_RESULT_FIELDS := {
    "RESULT_ALBEDO":     "layer_mat_albedo",
    "RESULT_NORMAL_MAP": "layer_mat_normal_map",
	"RESULT_MESH_NORMAL_MAP": "layer_mat_mesh_normal_map",
    "RESULT_BENT_NORMALS": "layer_mat_bent_normal",
    "RESULT_ROUGHNESS":  "layer_mat_roughness",
    "RESULT_AO":         "layer_mat_ao",
    "RESULT_HEIGHT":     "layer_mat_height",
    "RESULT_METALLIC":   "layer_mat_metallic",
    "RESULT_EMISSION":   "layer_mat_emission",
    "RESULT_MESH_AO":    "layer_mat_mesh_ao",
    "RESULT_MESH_HEIGHT": "layer_mat_mesh_height",
    "RESULT_MESH_CURVATURE": "layer_mat_mesh_curvature",
    "RESULT_MESH_THICKNESS": "layer_mat_mesh_thickness",

}
const VERTEX_OUTPUTS := "
	VERTEX = finalVertex.layer_mat_vertex;
	"
const VERTEX_LAYER_OUT_FIELDS := {
    "LAYER_OUT_VERTEX":     "layer_mat_vertex",
    "LAYER_OUT_HEIGHT":     "layer_mat_height",
}
const VERTEX_LAYER_BELOW_FIELDS := {
    "LAYER_BELOW_VERTEX":     "layer_mat_vertex",
    "LAYER_BELOW_HEIGHT":     "layer_mat_height",
}
const VERTEX_LAYER_CURRENT_FIELDS := {
    "LAYER_CURRENT_VERTEX":     "layer_mat_vertex",
    "LAYER_CURRENT_HEIGHT":     "layer_mat_height",
}
const VERTEX_LAYER_RESULT_FIELDS := {
    "RESULT_VERTEX":     "layer_mat_vertex",
    "RESULT_HEIGHT":     "layer_mat_height",
}
const DEFAULT_LAYER_DATA_OUTPUT := "
	layerData DEFAULT_LAYER_DATA = layerData(
	    vec4(0.0),
    	vec4(0.0),
    	vec4(0.0),
    	vec4(0.0),
    	vec4(0.0),
    	vec4(0.0),
    	vec4(0.0),
    	vec4(0.0),
    	0.0,
    	0.0,
    	0.0,
    	0.0,
    	0.0,
    	0.0,
    	0.0,
    	0.0
	);
"
const LAYER_DATA_OUT_FIELDS := {
	"LAYER_OUT_TEX_0": "mat_layer_tex_0",
	"LAYER_OUT_TEX_1": "mat_layer_tex_1",
	"LAYER_OUT_TEX_2": "mat_layer_tex_2",
	"LAYER_OUT_TEX_3": "mat_layer_tex_3",
	"LAYER_OUT_TEX_4": "mat_layer_tex_4",
	"LAYER_OUT_TEX_5": "mat_layer_tex_5",
	"LAYER_OUT_TEX_6": "mat_layer_tex_6",
	"LAYER_OUT_TEX_7": "mat_layer_tex_7",

	"LAYER_OUT_MASK_0": "mat_layer_mask_0",
	"LAYER_OUT_MASK_1": "mat_layer_mask_1",
	"LAYER_OUT_MASK_2": "mat_layer_mask_2",
	"LAYER_OUT_MASK_3": "mat_layer_mask_3",
	"LAYER_OUT_MASK_4": "mat_layer_mask_4",
	"LAYER_OUT_MASK_5": "mat_layer_mask_5",
	"LAYER_OUT_MASK_6": "mat_layer_mask_6",
	"LAYER_OUT_MASK_7": "mat_layer_mask_7",
}
const LAYER_DATA_BELOW_FIELDS := {
	"LAYER_BELOW_TEX_0": "mat_layer_tex_0",
	"LAYER_BELOW_TEX_1": "mat_layer_tex_1",
	"LAYER_BELOW_TEX_2": "mat_layer_tex_2",
	"LAYER_BELOW_TEX_3": "mat_layer_tex_3",
	"LAYER_BELOW_TEX_4": "mat_layer_tex_4",
	"LAYER_BELOW_TEX_5": "mat_layer_tex_5",
	"LAYER_BELOW_TEX_6": "mat_layer_tex_6",
	"LAYER_BELOW_TEX_7": "mat_layer_tex_7",

	"LAYER_BELOW_MASK_0": "mat_layer_mask_0",
	"LAYER_BELOW_MASK_1": "mat_layer_mask_1",
	"LAYER_BELOW_MASK_2": "mat_layer_mask_2",
	"LAYER_BELOW_MASK_3": "mat_layer_mask_3",
	"LAYER_BELOW_MASK_4": "mat_layer_mask_4",
	"LAYER_BELOW_MASK_5": "mat_layer_mask_5",
	"LAYER_BELOW_MASK_6": "mat_layer_mask_6",
	"LAYER_BELOW_MASK_7": "mat_layer_mask_7",
}

var _fragment_layer_out_regex: Dictionary = {}
var _fragment_layer_below_regex: Dictionary = {}
var _fragment_layer_current_regex: Dictionary = {}
var _fragment_layer_result_regex: Dictionary = {}
var _vertex_layer_out_regex: Dictionary = {}
var _vertex_layer_below_regex: Dictionary = {}
var _vertex_layer_current_regex: Dictionary = {}
var _vertex_layer_result_regex: Dictionary = {}

var _layer_data_out_regex: Dictionary = {}
var _layer_data_below_regex: Dictionary = {}

func _get_fragment_layer_out_regex() -> Dictionary:
	if _fragment_layer_out_regex.is_empty():
		for out_name in FRAGMENT_LAYER_OUT_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + out_name + "\\b")
			_fragment_layer_out_regex[out_name] = rx
	
	return _fragment_layer_out_regex


func _get_fragment_layer_below_regex() -> Dictionary:
	if _fragment_layer_below_regex.is_empty():
		for in_name in FRAGMENT_LAYER_BELOW_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + in_name + "\\b")
			_fragment_layer_below_regex[in_name] = rx
	
	return _fragment_layer_below_regex


func _get_fragment_layer_current_regex() -> Dictionary:
	if _fragment_layer_current_regex.is_empty():
		for in_name in FRAGMENT_LAYER_CURRENT_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + in_name + "\\b")
			_fragment_layer_current_regex[in_name] = rx
	
	return _fragment_layer_current_regex


func _get_fragment_layer_result_regex() -> Dictionary:
	if _fragment_layer_result_regex.is_empty():
		for in_name in FRAGMENT_LAYER_RESULT_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + in_name + "\\b")
			_fragment_layer_result_regex[in_name] = rx
	
	return _fragment_layer_result_regex


func _get_vertex_layer_out_regex() -> Dictionary:
	if _vertex_layer_out_regex.is_empty():
		for out_name in VERTEX_LAYER_OUT_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + out_name + "\\b")
			_vertex_layer_out_regex[out_name] = rx
	
	return _vertex_layer_out_regex


func _get_vertex_layer_below_regex() -> Dictionary:
	if _vertex_layer_below_regex.is_empty():
		for in_name in VERTEX_LAYER_BELOW_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + in_name + "\\b")
			_vertex_layer_below_regex[in_name] = rx
	
	return _vertex_layer_below_regex


func _get_vertex_layer_current_regex() -> Dictionary:
	if _vertex_layer_current_regex.is_empty():
		for in_name in VERTEX_LAYER_CURRENT_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + in_name + "\\b")
			_vertex_layer_current_regex[in_name] = rx
	
	return _vertex_layer_current_regex


func _get_vertex_layer_result_regex() -> Dictionary:
	if _vertex_layer_result_regex.is_empty():
		for in_name in VERTEX_LAYER_RESULT_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + in_name + "\\b")
			_vertex_layer_result_regex[in_name] = rx
	
	return _vertex_layer_result_regex


func _get_layer_data_out_regex() -> Dictionary:
	if _layer_data_out_regex.is_empty():
		for in_name in LAYER_DATA_OUT_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + in_name + "\\b")
			_layer_data_out_regex[in_name] = rx
	
	return _layer_data_out_regex


func _get_layer_data_below_regex() -> Dictionary:
	if _layer_data_below_regex.is_empty():
		for in_name in LAYER_DATA_BELOW_FIELDS:
			var rx := RegEx.new()
			rx.compile("\\b" + in_name + "\\b")
			_layer_data_below_regex[in_name] = rx
	
	return _layer_data_below_regex


func _on_layer_changed() -> void:
	_invalidate_assets()
	_reconnect_layer_signals()


func _reconnect_layer_signals() -> void:
	for layer in layers:
		if not layer:
			continue
		if layer.changed.is_connected(_on_layer_changed):
			layer.changed.disconnect(_on_layer_changed)
		layer.changed.connect(_on_layer_changed)
		if layer.material_replaced.is_connected(_on_material_replaced):
			layer.material_replaced.disconnect(_on_material_replaced)
		layer.material_replaced.connect(_on_material_replaced)
		if layer.mask_updated.is_connected(_on_mask_updated):
			layer.mask_updated.disconnect(_on_mask_updated)
		layer.mask_updated.connect(_on_mask_updated)
		if layer.surface_material:
			if layer.surface_material.changed.is_connected(_on_uniform_changed):
				layer.surface_material.changed.disconnect(_on_uniform_changed)
			layer.surface_material.changed.connect(_on_uniform_changed)
		if layer.mask_material:
			if layer.mask_material.changed.is_connected(_on_uniform_changed):
				layer.mask_material.changed.disconnect(_on_uniform_changed)
			layer.mask_material.changed.connect(_on_uniform_changed)


func _on_material_replaced() -> void:
	_invalidate_assets()
	_reconnect_layer_signals()


func _on_mask_updated() -> void:
	_invalidate_assets()
	if layer_uniform_maps.size() > 0:
		update_uniforms(_ensure_assets())


func _on_uniform_changed() -> void:
	_invalidate_assets()
	update_uniforms(_ensure_assets())


func clear_uniforms() -> void:
	if not shader:
		return
	for prop in get_property_list():
		if prop.name.begins_with("shader_parameter/"):
			var param_name = prop.name.substr("shader_parameter/".length())
			set_shader_parameter(param_name, null)


func update_uniforms(assets: Array) -> void:
	if layer_uniform_maps.is_empty():
		return
	clear_uniforms()
	copy_uniform_values(self, layer_uniform_maps)
	set_mask_uniforms(assets)


func strip_comments(shader: String) -> String:
	var result := ""
	var i := 0
	var n := shader.length()
	var in_string := false

	while i < n:
		var c := shader[i]

		if in_string:
			if c == "\\" and i + 1 < n:
				result += c + shader[i + 1]
				i += 2
				continue
			result += c
			if c == "\"":
				in_string = false
			i += 1
			continue
		
		if c =="\"":
			in_string = true
			result += c
			i += 1
			continue
		
		if c == "/" and i + 1 < n and shader[i + 1] == "/":
			while i < n and shader[i] != "\n":
				i += 1
			continue
		
		if c == "/" and i + 1 < n and shader[i + 1] == "*":
			i += 2
			while i + 1 < n and not (shader[i] == "*" and shader[i + 1] == "/"):
				i += 1
			i += 2
			continue
		
		result += c
		i += 1

	return result
  

func get_includes(shader: String) -> Array:
	var directive_regex := RegEx.new()
	directive_regex.compile("#include[^\\n]*")

	var result : Array = []

	var matches := directive_regex.search_all(shader)
	for m in matches:
		result.append(m.get_string().strip_edges())

	return result


func get_global_macros(shader: String) -> Array:
	var global_macro_regex := RegEx.new()
	global_macro_regex.compile("SETUP_VARYINGS")

	var result : Array = []

	var matches := global_macro_regex.search_all(shader)
	for m in matches:
		result.append(m.get_string().strip_edges() + ";")

	return result


func get_fragment_macros(statements: Array) -> Array:
	var result := []
	var pattern := RegEx.new()
	pattern.compile("^[A-Z][A-Z0-9_]+$")

	for s in statements:
		if s.type != "statement":
			continue
		var line : String = s.text.strip_edges().trim_suffix(";")
		if pattern.search(line) != null:
			result.append(s.text)
	

	return result


func get_mask_out(statements: Array, index: int) -> String:
	var mask_out := ""
	for s in statements:
		var line = s.text.strip_edges()

		if line.begins_with("LAYER_OUT_MASK"):
			var tokens = line.split("=")

			mask_out = "layer_%d_" % index + tokens[1].strip_edges()

	return mask_out 


func parse_uniforms(shader: String, is_mask: bool, index: int) -> Dictionary:
	var prefix := "s_layer_%d_" % index
	if is_mask:
		prefix = "m_layer_%d_" % index
	var directive_regex := RegEx.new()
	directive_regex.compile("#[^\\n]*")
	var surface_c := directive_regex.sub(shader, "", true)
	
	var prefixed_samplers : Array = []
	var sampler_identifiers : Array = []
	var prefixed_uniforms : Array = []
	var uniform_identifiers : Array = []
	var uniforms : Array = []

	for word in surface_c.split(";"):
		var line = word.strip_edges()
		if not line.begins_with("uniform "):
			continue
		uniforms.append(line)

	for uniform in uniforms:
		var colon_parts: Array = uniform.split(":", false, 1)
		var head: String = colon_parts[0].strip_edges()
		var tail: String = ""
		if colon_parts.size() > 1:
			tail = " :" + colon_parts[1]

		var head_tokens: Array = head.split(" ", false)
		var type: String = head_tokens[1]

		if type == "sampler2D" or type == "sampler2DArray":
			var sampler_id: String = head_tokens[2]
			var prefixed_sampler_id := prefix + sampler_id

			head_tokens[2] = prefixed_sampler_id
			var new_sampler_head := " ".join(head_tokens)

			sampler_identifiers.append(sampler_id)
			prefixed_samplers.append(new_sampler_head + tail  + ";")
			
			continue
		
		var uniform_id: String = head_tokens[2]
		var prefixed_uniform_id := prefix + uniform_id

		head_tokens[2] = prefixed_uniform_id
		var new_uniform_head := " ".join(head_tokens)

		uniform_identifiers.append(uniform_id)
		prefixed_uniforms.append(new_uniform_head + tail  + ";")

		

	return {"uniforms": prefixed_uniforms, "samplers": prefixed_samplers, "uniform_identifiers": uniform_identifiers, "sampler_identifiers": sampler_identifiers}


func parse_global_uniforms(shader: String, index: int) -> Dictionary:
	var directive_regex := RegEx.new()
	directive_regex.compile("#[^\\n]*")
	var surface_c := directive_regex.sub(shader, "", true)
	
	var uniforms : Array = []

	for word in surface_c.split(";"):
		var line = word.strip_edges()
		if not line.begins_with("global uniform "):
			continue
		uniforms.append(line + ";")

	return {"uniforms": uniforms}


func copy_uniform_values(mega_material: ShaderMaterial, layer_uniform_maps: Array) -> void:
	for layer in layer_uniform_maps:
		var identifiers: Array = layer["identifiers"]
		var index: int = layer["index"]
		var is_mask : bool = layer.get("is_mask", false)
		var prefix := "s_layer_%d_" % index
		if is_mask:
			prefix = "m_layer_%d_" % index

		var source_material: ShaderMaterial
		if layer.has("surface_material"):
			source_material = layer["surface_material"]
		elif layer.has("mask_material"):
			source_material = layer["mask_material"]
		else:
			continue

		for old_name in identifiers:
			var new_name : String = prefix + old_name
			var value = source_material.get_shader_parameter(old_name)
			if value != null:
				mega_material.set_shader_parameter(new_name, value)

		var sampler_ids: Array = layer.get("sampler_identifiers", [])
		for old_name in sampler_ids:
			var new_name : String = prefix + old_name
			var value = source_material.get_shader_parameter(old_name)
			if value != null:
				mega_material.set_shader_parameter(new_name, value)


func parse_varyings(shader: String, index: int) -> Dictionary:
	var directive_regex := RegEx.new()
	directive_regex.compile("#[^\\n]*")
	var surface_c := directive_regex.sub(shader, "", true)
	
	var result : Array = []
	var varyings : Array = []

	for word in surface_c.split(";"):
		var line = word.strip_edges()
		if not line.begins_with("varying "):
			continue
		varyings.append(line)

	for varying in varyings:
		var tokens: Array = varying.split(" ", false)
		var final_varying := " ".join(tokens) + ";"
		result.append(final_varying)
	
	return {"varyings": result}


func vertex_layer_out(index: int) -> String:
	if index == 0:
		return "\tvertexMaterial vertex_%d_out = DEFAULT_VERTEX;\n" % index
	else:
		return "\tvertexMaterial vertex_%d_out = finalVertex;\n" % index


func fragment_layer_out(index: int) -> String:
	if index == 0:
		return "\tfragmentMaterial fragment_%d_out = DEFAULT_FRAGMENT;\n" % index
	else:
		return "\tfragmentMaterial fragment_%d_out = finalFragment;\n" % index


func layer_data_out(index: int) -> String:
	if index == 0:
		return "\tlayerData layer_%d_data = DEFAULT_LAYER_DATA;\n" % index
	else:
		return "\tlayerData layer_%d_data = finalLayerData;\n" % index


func mask_texture_uniforms(channel_select: int, index: int) -> Array:
	var result := []
	if index != 0:
		var mask_sampler := "uniform sampler2D m_layer_%d_mask_sampler;" % index
		var mask_channel := "uniform int m_layer_%d_mask_channel = %d;" % [index, channel_select]
		result.append(mask_sampler)
		result.append(mask_channel)

	return result


func mask_texture_sample(index: int) -> Dictionary:
	var u_v := "UV"
	var mask := ""
	var result := ""
	if index != 0:
		var layer_mask_sampler := "\nvec4 m_layer_%d_mask = texture(m_layer_%d_mask_sampler, UV);\n" % [index, index]
		mask = "l_getChannel(m_layer_%d_mask, " % index + u_v + " ,m_layer_%d_mask_channel)" % index
		result += "\n" + layer_mask_sampler.indent("\t")

	return {"fragment": result, "mask": mask}


func blend_fragment_block(fragment: String, mask: String, index: int, mask_type: int, mask_active: bool) -> String:
	var result := fragment
	var current_layer := "fragment_%d_out" % index

	if index == 0:
		result += "\n\n\t" + "fragmentMaterial finalFragment = fragment_0_out;\n"
	elif mask_active and mask_type == MaterialLayer.MaskType.TEXTURE:
		result += "\n\n\t" + "finalFragment = l_mixFragment(finalFragment, " + current_layer + ", " + mask + ");\n"

	return result


func blend_vertex_block(vertex: String, mask: String, index: int, mask_type: int, mask_active: bool) -> String:
	var result := vertex
	var current_layer := "vertex_%d_out" % index

	if index == 0:
		result += "\n\n\t" + "vertexMaterial finalVertex = vertex_0_out;\n"

	return result


func blend_layer_data_block(fragment: String, index: int) -> String:
	var result := fragment

	if index == 0:
		result += "\n\n\t" + "layerData finalLayerData = layer_0_data;\n"

	return result


func get_fragment(shader: String) -> String:
	var sig := RegEx.new()
	sig.compile("void\\s+fragment\\s*\\(\\s*\\)\\s*\\{")
	var m := sig.search(shader)
	if not m:
		return ""
	
	var i := m.get_end()
	var start := i
	var depth := 1
	var n := shader.length()

	while i < n and depth > 0:
		var c := shader[i]
		
		if c == "{":
			depth += 1
		elif c == "}":
			depth -= 1
		i += 1

	var end := i - 1
	return shader.substr(start, end - start)


func get_vertex(shader: String) -> String:
	var sig := RegEx.new()
	sig.compile("void\\s+vertex\\s*\\(\\s*\\)\\s*\\{")
	var m := sig.search(shader)
	if not m:
		return ""
	
	var i := m.get_end()
	var start := i
	var depth := 1
	var n := shader.length()

	while i < n and depth > 0:
		var c := shader[i]
		
		if c == "{":
			depth += 1
		elif c == "}":
			depth -= 1
		i += 1

	var end := i - 1
	return shader.substr(start, end - start)


func parse_fragment(body: String, index: int) -> Dictionary:
	var statements := []
	var identifiers := []
	var buffer := ""
	var paren_depth := 0
	var i := 0
	var n := body.length()

	# Get statements

	while i < n:
		var c := body[i]

		if c == "(":
			paren_depth += 1
		elif c == ")":
			paren_depth -= 1

		if c == "{" and paren_depth == 0:
			var head := buffer.strip_edges()
			statements.append({"type": "block_open", "text": head})
			buffer = ""
			i += 1
			continue
		
		if c == "}" and paren_depth == 0:
			var tail := buffer.strip_edges()
			if tail != "":
				statements.append({"type": "block_close", "text": ""})
			statements.append({"type": "block_close", "text": ""})
			buffer = ""
			i += 1
			continue
		
		if c == ";" and paren_depth == 0:
			var stmt := buffer.strip_edges()
			if stmt != "":
				statements.append({"type": "statement", "text": stmt})
			buffer = ""
			i += 1
			continue
		
		buffer += c
		i += 1
	
	var leftover := buffer.strip_edges()
	if leftover != "":
		statements.append({"type": "statement", "text": leftover})
	
	var indent_str: String = "\t"
	var fragment := ""
	var depth := 0
	
	######### MACROS

	var macros := []
	var pattern := RegEx.new()
	pattern.compile("^[A-Z][A-Z0-9_]+$")

	for s in statements:
		if s.type != "statement":
			continue
		var line : String = s.text.strip_edges().trim_suffix(";")
		if pattern.search(line) != null:
			macros.append("\t" + s.text + ";")
			s.text = ""
	

	var mask_out := get_mask_out(statements, index)
	statements = parse_fragment_in_out(statements, index)
	statements = parse_layer_data_in_out(statements, index)

	for s in statements:
		match s.type:
			"block_open":
				fragment += indent_str.repeat(depth) + s.text + " {\n"
				depth += 1
			"block_close":
				depth = max(depth - 1, 0)
				fragment += indent_str.repeat(depth) + "}\n"
			"statement":

				for output in OUTPUTS:
					if s.text.begins_with(output):
						s.text = s.text.replace(s.text, "")
				
				if s.text.strip_edges() != "":
					fragment += indent_str.repeat(depth) + s.text + ";\n"
				

	fragment = fragment.indent("\t")

	for s in statements:
		var line: String = s.text.strip_edges()
		if line == "":
			continue

		var tokens: Array = line.split(" ", false)
		if tokens.size() < 2:
			continue

		if not TYPES.has(tokens[0]):
			continue

		var identifier: String = tokens[1]
		identifiers.append(identifier)

	return {"fragment": fragment, "identifiers": identifiers, "macros": macros, "mask": mask_out}


func parse_vertex(body: String, index: int) -> Dictionary:
	var statements := []
	var identifiers := []
	var buffer := ""
	var paren_depth := 0
	var i := 0
	var n := body.length()

	while i < n:
		var c := body[i]

		if c == "(":
			paren_depth += 1
		elif c == ")":
			paren_depth -= 1

		if c == "{" and paren_depth == 0:
			var head := buffer.strip_edges()
			statements.append({"type": "block_open", "text": head})
			buffer = ""
			i += 1
			continue
		
		if c == "}" and paren_depth == 0:
			var tail := buffer.strip_edges()
			if tail != "":
				statements.append({"type": "block_close", "text": ""})
			statements.append({"type": "block_close", "text": ""})
			buffer = ""
			i += 1
			continue
		
		if c == ";" and paren_depth == 0:
			var stmt := buffer.strip_edges()
			if stmt != "":
				statements.append({"type": "statement", "text": stmt})
			buffer = ""
			i += 1
			continue
		
		buffer += c
		i += 1
	
	var leftover := buffer.strip_edges()
	if leftover != "":
		statements.append({"type": "statement", "text": leftover})
	
	
	var indent_str: String = "\t"
	var vertex := ""
	var depth := 0

	var has_setup := false
	for s in statements:
		if s.type == "statement" and "SETUP_LAYER_VERTEX" in s.text:
			has_setup = true
			break
	# if not has_setup:
	# 	push_error("Layer_%d ERROR ! Vertex Shader : missing SETUP_LAYER_VERTEX" % index)

	######### MACROS

	var macros := []
	var pattern := RegEx.new()
	pattern.compile("^[A-Z][A-Z0-9_]+$")

	for s in statements:
		if s.type != "statement":
			continue
		var line : String = s.text.strip_edges().trim_suffix(";")
		if pattern.search(line) != null:
			macros.append("\t" + s.text + ";")
			s.text = ""
	
	

	statements = parse_vertex_in_out(statements, index)
	statements = parse_layer_data_in_out(statements, index)

	for s in statements:
		match s.type:
			"block_open":
				vertex += indent_str.repeat(depth) + s.text + " {\n"
				depth += 1
			"block_close":
				depth = max(depth - 1, 0)
				vertex += indent_str.repeat(depth) + "}\n"
			"statement":

				for output in OUTPUTS:
					if s.text.begins_with(output):
						s.text = s.text.replace(s.text, "")
				
				if s.text.strip_edges() != "":
					vertex += indent_str.repeat(depth) + s.text + ";\n"
				

	vertex = vertex.indent("\t")


	for s in statements:
		var line: String = s.text.strip_edges()
		if line == "":
			continue

		var tokens: Array = line.split(" ", false)
		if tokens.size() < 2:
			continue

		if not TYPES.has(tokens[0]):
			continue

		var identifier: String = tokens[1]
		identifiers.append(identifier)

	return {"statements": statements, "vertex": vertex, "identifiers": identifiers, "macros": macros}


func parse_fragment_in_out(statements: Array, index: int):
	var result := []
	var out_struct_name := "fragment_%d_out" % index
	var below_struct_name := "finalFragment"
	var current_struct_name := "fragment_%d_out" % index
	var result_struct_name := "finalFragment"
	
	var out_regex_map := _get_fragment_layer_out_regex()
	var below_regex_map := _get_fragment_layer_below_regex()
	var current_regex_map := _get_fragment_layer_current_regex()
	var result_regex_map := _get_fragment_layer_result_regex()

	for s in statements:
		if s.type != "statement":
			result.append(s)
			continue
		
		var line = s.text.strip_edges()
		
		if line.begins_with("SETUP_LAYER_FRAGMENT"):
			s.text = ""
			
		for out_name in out_regex_map:
			s.text = out_regex_map[out_name].sub(s.text,"%s.%s" % [out_struct_name, FRAGMENT_LAYER_OUT_FIELDS[out_name]], true)
		
		for current_name in current_regex_map:
			s.text = current_regex_map[current_name].sub(s.text,"%s.%s" % [current_struct_name, FRAGMENT_LAYER_CURRENT_FIELDS[current_name]], true)
		
		for result_name in result_regex_map:
			s.text = result_regex_map[result_name].sub(s.text,"%s.%s" % [result_struct_name, FRAGMENT_LAYER_RESULT_FIELDS[result_name]], true)

		if index == 0:
			var default_struct := "DEFAULT_FRAGMENT"
			for in_name in below_regex_map:
				s.text = below_regex_map[in_name].sub(
					s.text,
					"%s.%s" % [default_struct, FRAGMENT_LAYER_BELOW_FIELDS[in_name]],
					true
				)
		
		if index == 1:
			for in_name in below_regex_map:
				s.text = below_regex_map[in_name].sub(
					s.text,
					"%s.%s" % ["fragment_%d_out" % (index - 1), FRAGMENT_LAYER_BELOW_FIELDS[in_name]],
					true
				)

		elif index > 1:
			for in_name in below_regex_map:
				s.text = below_regex_map[in_name].sub(
					s.text,
					"%s.%s" % [below_struct_name, FRAGMENT_LAYER_BELOW_FIELDS[in_name]],
					true
				)

		result.append(s)
	
	return result


func parse_vertex_in_out(statements: Array, index: int):
	var result := []
	var out_struct_name := "vertex_%d_out" % index
	var below_struct_name := "finalVertex"
	var current_struct_name := "vertex_%d_out" % index
	var result_struct_name := "finalVertex"
	
	var out_regex_map := _get_vertex_layer_out_regex()
	var below_regex_map := _get_vertex_layer_below_regex()
	var current_regex_map := _get_vertex_layer_current_regex()
	var result_regex_map := _get_vertex_layer_result_regex()

	for s in statements:
		if s.type != "statement":
			result.append(s)
			continue
		
		var line = s.text.strip_edges()
		
		if line.begins_with("SETUP_LAYER_VERTEX"):
			s.text = ""
			
		for out_name in out_regex_map:
			s.text = out_regex_map[out_name].sub(s.text,"%s.%s" % [out_struct_name, VERTEX_LAYER_OUT_FIELDS[out_name]], true)
		
		for current_name in current_regex_map:
			s.text = current_regex_map[current_name].sub(s.text,"%s.%s" % [current_struct_name, VERTEX_LAYER_CURRENT_FIELDS[current_name]], true)
		
		for result_name in result_regex_map:
			s.text = result_regex_map[result_name].sub(s.text,"%s.%s" % [result_struct_name, VERTEX_LAYER_RESULT_FIELDS[result_name]], true)

		if index == 0:
			var default_struct := "DEFAULT_VERTEX"
			for in_name in below_regex_map:
				s.text = below_regex_map[in_name].sub(
					s.text,
					"%s.%s" % [default_struct, VERTEX_LAYER_BELOW_FIELDS[in_name]],
					true
				)
		
		if index == 1:
			for in_name in below_regex_map:
				s.text = below_regex_map[in_name].sub(
					s.text,
					"%s.%s" % ["vertex_%d_out" % (index - 1), VERTEX_LAYER_BELOW_FIELDS[in_name]],
					true
				)

		elif index > 1:
			for in_name in below_regex_map:
				s.text = below_regex_map[in_name].sub(
					s.text,
					"%s.%s" % [below_struct_name, VERTEX_LAYER_BELOW_FIELDS[in_name]],
					true
				)

		result.append(s)
	
	return result


func parse_layer_data_in_out(statements: Array, index: int):
	var result := []
	var out_struct_name := "layer_%d_data" % index
	var below_struct_name := "finalLayerData"

	var out_regex_map := _get_layer_data_out_regex()
	var below_regex_map := _get_layer_data_below_regex()

	for s in statements:
		if s.type != "statement":
			result.append(s)
			continue

		for out_name in out_regex_map:
			s.text = out_regex_map[out_name].sub(s.text,"%s.%s" % [out_struct_name, LAYER_DATA_OUT_FIELDS[out_name]], true)

		for in_name in below_regex_map:
			s.text = below_regex_map[in_name].sub(
				s.text,
				"%s.%s" % [below_struct_name, LAYER_DATA_BELOW_FIELDS[in_name]],
				true
			)

		result.append(s)
	
	return result


func prefix_vertex_fragment(body: String, identifiers: Array, is_mask: bool, index: int) -> String:
	var prefix := "s_layer_%d_" % index
	if is_mask:
		prefix = "m_layer_%d_" % index
	var result := body
	for identifier in identifiers:
		var regex := RegEx.new()
		regex.compile("\\b" + identifier + "\\b(?!\\s*\\()")
		result = regex.sub(result, prefix + identifier, true)
	return result


func prefix_vertex_fragment_samplers(all_fragment_funcs: Array, originals: Array, renames: Array) -> Array:
	var result := []
	var body := ""
	for fragment in all_fragment_funcs:
		body = fragment
		for i in originals.size():
			var regex := RegEx.new()
			regex.compile("\\b" + originals[i] + "\\b")
			body = regex.sub(body, renames[i], true)
		result.append(body)
	
	return result


func prefix_vertex_samplers(all_vertex_funcs: Array, originals: Array, renames: Array) -> Array:
	var result := []
	var body := ""
	for vertex in all_vertex_funcs:
		body = vertex
		for i in originals.size():
			var regex := RegEx.new()
			regex.compile("\\b" + originals[i] + "\\b")
			body = regex.sub(body, renames[i], true)
		result.append(body)
	
	return result


func prefix_helper_funcs(functions: Array, identifiers: Array, is_mask: bool, index: int) -> Array:
	var prefix := "s_layer_%d_" % index
	if is_mask:
		prefix = "m_layer_%d_" % index
	var result := []
	var body := ""

	for fn in functions:
		body = fn

		for identifier in identifiers:
			var regex := RegEx.new()
			regex.compile("\\b" + identifier + "\\b")
			result.append(regex.sub(body, prefix + identifier, true))
	return result


func parse_helper_funcs(shader: String, is_mask: bool, index: int) -> Dictionary:
	var type_pattern := "(?:" + "|".join(TYPES) + ")"
	var sig := RegEx.new()
	sig.compile(type_pattern + "\\s+(\\w+)\\s*\\(([^)]*)\\)\\s*\\{")

	var skip_names := ["vertex", "fragment", "light", "start", "process", "sky", "fog"]
	var raw_functions := []
	var identifiers := []
	var n := shader.length()

	for m in sig.search_all(shader):
		var func_name := m.get_string(1)
		if func_name in skip_names:
			continue

		var i := m.get_end()
		var start := i
		var depth := 1
		while i < n and depth > 0:
			var c := shader[i]
			if c == "{":
				depth += 1
			elif c == "}":
				depth -= 1
			i += 1
		var end := i - 1

		var params := m.get_string(2).strip_edges()
		var body := shader.substr(start, end - start)
		var return_type := m.get_string(0).split(func_name)[0].strip_edges()

		raw_functions.append(return_type + " " + func_name + "(" + params + ") {" + body + "}")
		identifiers.append(func_name)

	var prefix := "s_layer_%d_" % index
	if is_mask:
		prefix = "m_layer_%d_" % index
	var result := []

	for fn in raw_functions:
		var text : String = fn
		for identifier in identifiers:
			var regex := RegEx.new()
			regex.compile("\\b" + identifier + "\\b")
			text = regex.sub(text, prefix + identifier, true)
		result.append(text)

	return {"functions": result, "identifiers": identifiers}


func dedup(array: Array) -> Array:
	var seen := {}
	var result := []
	for item in array:
		if not seen.has(item):
			seen[item] = true
			result.append(item)
	return result


func dedup_statements(statements: Array) -> Array:
	var seen := {}
	var result := []

	for s in statements:
		var key : String = s["type"] + "|" + s["text"].strip_edges()
		if not seen.has(key):
			seen[key] = true
			result.append(s)

	return result


func flatten_statements(statements: Array) -> String:
	var result := ""
	var indent_str: String = "\t"
	var depth := 0

	for s in statements:
		match s.type:
			"block_open":
				result += indent_str.repeat(depth) + s.text + " {\n"
				depth += 1
			"block_close":
				depth = max(depth - 1, 0)
				result += indent_str.repeat(depth) + "}\n"
			"statement":

				for output in OUTPUTS:
					if s.text.begins_with(output):
						s.text = s.text.replace(s.text, "")
				
				if s.text.strip_edges() != "":
					result += indent_str.repeat(depth) + s.text + ";\n"
				

	result = result.indent("\t")
	return result


func dedup_samplers(layer_uniform_maps: Array):
	var sampler_rid_map := {}
	var originals := []
	var renames := []
	var uniforms := []
	var _to_remove := []

	for layer in layer_uniform_maps:
		var original: ShaderMaterial
		if layer.has("surface_material"):
			original = layer["surface_material"]
		elif layer.has("mask_material"):
			original = layer["mask_material"]
		else:
			continue
		var identifiers: Array = layer["sampler_identifiers"]
		var prefix := "s_layer_%d_" % layer["index"]
		if layer.get("is_mask", false):
			prefix = "m_layer_%d_" % layer["index"]
		uniforms.append_array(layer["sampler_uniforms"])

		for old_name in identifiers:
			var new_name : String = prefix + old_name
			var value = original.get_shader_parameter(old_name)

			if value != null:
				sampler_rid_map[new_name] = {"rid": value.get_rid(), "identifier": old_name}
	
	var first_seen := {}
	
	for uniform_name in sampler_rid_map:
		var rid: RID = sampler_rid_map[uniform_name]["rid"]
		var identifier: String = sampler_rid_map[uniform_name]["identifier"]
		if first_seen.has(rid):
			originals.append(uniform_name)
			renames.append(first_seen[rid])
			for uniform in uniforms:
				if uniform.contains(uniform_name):
					_to_remove.append(uniform)
					break
		else:
			first_seen[rid] = uniform_name
	
	for uniform in _to_remove:
		uniforms.erase(uniform)

	return {"sampler_uniforms": uniforms, "originals": originals, "renames": renames}
			

func set_mask_uniforms(assets: Array):
	for asset in assets:
		var slot : int = asset["slot"]
		if asset and asset["mask_texture"]:
			var sampler_param = "m_layer_%d_mask_sampler" % slot
			var channel_param = "m_layer_%d_mask_channel" % slot
			self.set_shader_parameter(sampler_param, asset["mask_texture"])
			self.set_shader_parameter(channel_param, asset["mask_texture_channel"])





func _collect_layer_assets() -> Array:
	var assets: Array = []

	var base_mat: ShaderMaterial = base_layer
	var base_shader: Shader = base_mat.shader if base_mat and base_mat.shader else null
	assets.append({
		"slot": 0,
		"layer": null,
		"surface_mat": base_mat,
		"surface_shader": base_shader,
		"mask_mat": null,
		"mask_shader": null,
		"mask_type": MaterialLayer.MaskType.TEXTURE,
		"mask_active": false,
		"mask_texture": null,
		"mask_texture_channel": MaterialLayer.TextureChannel.RED,
	})

	for i in layers.size():
		var layer: MaterialLayer = layers[i]
		var active := layer != null and layer.active
		var mask_active := layer != null and layer.mask_active
		var surface_mat: ShaderMaterial = layer.surface_material if active else null
		var surface_shader: Shader = surface_mat.shader if surface_mat and surface_mat.shader else null
		var mask_type = layer.mask_type if active else MaterialLayer.MaskType.TEXTURE
		var mask_texture = layer.mask_texture if active or mask_active else null
		var mask_texture_channel = layer.mask_texture_channel if active or mask_active else MaterialLayer.TextureChannel.RED
		var mask_mat: ShaderMaterial = layer.mask_material if active or mask_active else null
		var mask_shader: Shader = mask_mat.shader if mask_mat and mask_mat.shader else null
		assets.append({
			"slot": i + 1,
			"layer": layer,
			"surface_mat": surface_mat,
			"surface_shader": surface_shader,
			"mask_type": mask_type,
			"mask_active": mask_active,
			"mask_texture": mask_texture,
			"mask_texture_channel": mask_texture_channel,
			"mask_mat": mask_mat,
			"mask_shader": mask_shader,
		})

	return assets


func _generate_code(assets: Array) -> String:

	var mega_shader := PackedStringArray()

	var all_includes := []
	var all_global_macros := []
	var all_varyings := []
	var all_uniforms := []
	var all_global_uniforms := []
	var all_helper_funcs := []
	var all_layer_outs := []
	var all_fragment_macros := []
	var all_fragment_funcs := []
	var all_vertex_macros := []
	var all_vertex_funcs := []
	var all_identifiers := []
	var vertex_identifiers := []

	layer_uniform_maps.clear()
	
	for asset in assets:
		var slot: int = asset["slot"]
		var mask_type: int = asset["mask_type"]
		var mask_active: bool = asset["mask_active"]
		var mask_expr = "1.0"

		var surface_shader: Shader = asset["surface_shader"]
		if surface_shader == null:
			continue
		
		
		var mask_shader: Shader = asset["mask_shader"]
		var mask_c := ""

		if mask_type == MaterialLayer.MaskType.MATERIAL and mask_shader:
			mask_c = strip_comments(mask_shader.code)

		var surface_c := strip_comments(surface_shader.code)

		var mask_fragment_body := ""
		var mask_vertex_body := ""

		if mask_type == MaterialLayer.MaskType.TEXTURE and mask_active:
			var mask_texture_channel : int = asset["mask_texture_channel"]
			var mask_fragment = mask_texture_sample(slot)
			mask_expr = mask_fragment["mask"]
			
			all_uniforms.append_array(mask_texture_uniforms(mask_texture_channel, slot))
			all_fragment_funcs.append(mask_fragment["fragment"])

		elif mask_type == MaterialLayer.MaskType.MATERIAL and mask_active:
			var mask_includes = get_includes(mask_c)
			var mask_global_macros := get_global_macros(mask_c)
			var mask_uniforms = parse_uniforms(mask_c, true, slot)
			var mask_global_uniforms = parse_global_uniforms(mask_c, slot)
			var mask_varyings = parse_varyings(mask_c, slot)
			var mask_helper_funcs := parse_helper_funcs(mask_c, true, slot)
			var mask_fragment := get_fragment(mask_c)
			var mask_parsed_fragment := parse_fragment(mask_fragment, slot)
			mask_fragment_body = mask_parsed_fragment["fragment"]
			var mask_vertex := get_vertex(mask_c)
			var mask_parsed_vertex := parse_vertex(mask_vertex, slot)
			mask_vertex_body = mask_parsed_vertex["vertex"]

		
			all_includes.append_array(mask_includes)
			all_global_macros.append_array(mask_global_macros)
			all_uniforms.append_array(mask_uniforms["uniforms"])
			all_global_uniforms.append_array(mask_global_uniforms["uniforms"])
			all_varyings.append_array(mask_varyings["varyings"])
			all_helper_funcs.append_array(mask_helper_funcs["functions"])

			all_identifiers.append_array(mask_uniforms["uniform_identifiers"])
			all_identifiers.append_array(mask_uniforms["sampler_identifiers"])
			all_identifiers.append_array(mask_helper_funcs["identifiers"])
			all_identifiers.append_array(mask_parsed_fragment["identifiers"])

			vertex_identifiers.append_array(mask_uniforms["uniform_identifiers"])
			vertex_identifiers.append_array(mask_uniforms["sampler_identifiers"])
			vertex_identifiers.append_array(mask_helper_funcs["identifiers"])
			vertex_identifiers.append_array(mask_parsed_vertex["identifiers"])

			layer_uniform_maps.append({
				"mask_material": asset["mask_mat"],
				"identifiers": mask_uniforms["uniform_identifiers"],
				"sampler_identifiers": mask_uniforms["sampler_identifiers"],
				"sampler_uniforms": mask_uniforms["samplers"],
				"index": slot,
				"is_mask": true,
			})

			mask_fragment_body = prefix_vertex_fragment(mask_fragment_body, all_identifiers, true, slot)
			mask_vertex_body = prefix_vertex_fragment(mask_vertex_body, vertex_identifiers, true, slot)

		
		var surface_global_macros := get_global_macros(surface_c)
		
		var surface_includes := get_includes(surface_c)

		var surface_uniforms := parse_uniforms(surface_c, false, slot)
		var surface_global_uniforms := parse_global_uniforms(surface_c, slot)

		var parsed_varyings := parse_varyings(surface_c, slot)

		var surface_helper_funcs := parse_helper_funcs(surface_c, true, slot)
		
		var surface_fragment := get_fragment(surface_c)
		var surface_parsed_fragment := parse_fragment(surface_fragment, slot)
		var surface_fragment_body: String = surface_parsed_fragment["fragment"]
		
		var surface_vertex := get_vertex(surface_c)
		var surface_parsed_vertex := parse_vertex(surface_vertex, slot)
		var surface_vertex_body: String = surface_parsed_vertex["vertex"]

		layer_uniform_maps.append({
			"surface_material": asset["surface_mat"],
			"identifiers": surface_uniforms["uniform_identifiers"],
			"sampler_identifiers": surface_uniforms["sampler_identifiers"],
			"sampler_uniforms": surface_uniforms["samplers"],
			"index": slot,
			"is_mask": false,
		})

		all_global_macros.append_array(surface_global_macros)
		all_global_macros = dedup(all_global_macros)

		all_varyings.append_array(parsed_varyings["varyings"])
		all_varyings = dedup(all_varyings)
		all_helper_funcs.append_array(surface_helper_funcs["functions"])
		all_helper_funcs.append("\n")

		
		all_includes.append_array(surface_includes)
		all_includes = dedup(all_includes)

		all_vertex_macros.append_array(surface_parsed_vertex["macros"])
		all_vertex_macros.append("\n")
		all_vertex_macros = dedup(all_vertex_macros)
		
		all_fragment_macros.append_array(surface_parsed_fragment["macros"])
		all_fragment_macros.append("\n")
		all_fragment_macros = dedup(all_fragment_macros)
		
		all_uniforms.append_array(surface_uniforms["uniforms"])
		all_uniforms.append("\n")
		all_global_uniforms.append_array(surface_global_uniforms["uniforms"])
		all_global_uniforms = dedup(all_global_uniforms)
		all_uniforms.append("\n")

		all_identifiers.append_array(surface_uniforms["uniform_identifiers"])
		all_identifiers.append_array(surface_uniforms["sampler_identifiers"])
		all_identifiers.append_array(surface_helper_funcs["identifiers"])
		all_identifiers.append_array(surface_parsed_fragment["identifiers"])

		vertex_identifiers.append_array(surface_uniforms["uniform_identifiers"])
		vertex_identifiers.append_array(surface_uniforms["sampler_identifiers"])
		vertex_identifiers.append_array(surface_helper_funcs["identifiers"])
		vertex_identifiers.append_array(surface_parsed_vertex["identifiers"])

		surface_fragment_body = prefix_vertex_fragment(surface_fragment_body, all_identifiers, false, slot)
		surface_fragment_body = blend_layer_data_block(surface_fragment_body,slot)
		surface_fragment_body = blend_fragment_block(surface_fragment_body, mask_expr, slot, mask_type, mask_active)

		all_fragment_funcs.append(layer_data_out(slot))
		all_fragment_funcs.append(fragment_layer_out(slot))
		all_fragment_funcs.append(surface_fragment_body)
		all_fragment_funcs.append("\n")
		all_fragment_funcs.append(mask_fragment_body)
		all_fragment_funcs.append("\tfinalLayerData = layer_%d_data;" % slot)
		all_fragment_funcs.append("\n\n")

		if not mask_active:
			all_fragment_funcs.append("\tfinalFragment = fragment_%d_out;" % slot)
		all_fragment_funcs.append("\n")

		surface_vertex_body = prefix_vertex_fragment(surface_vertex_body, vertex_identifiers, false, slot)
		surface_vertex_body = blend_vertex_block(surface_vertex_body, mask_expr, slot, mask_type, mask_active)

		all_vertex_funcs.append(vertex_layer_out(slot))
		all_vertex_funcs.append(surface_vertex_body)
		all_vertex_funcs.append("\n")
		all_vertex_funcs.append(mask_vertex_body)
		if not mask_active:
			all_vertex_funcs.append("\tfinalVertex = vertex_%d_out;" % slot)
		all_vertex_funcs.append("\n")
	

	var deduped_samplers = dedup_samplers(layer_uniform_maps)
	
	all_uniforms.append_array(deduped_samplers["sampler_uniforms"])

	all_fragment_funcs = prefix_vertex_fragment_samplers(all_fragment_funcs, deduped_samplers["originals"], deduped_samplers["renames"])
	all_vertex_funcs = prefix_vertex_fragment_samplers(all_vertex_funcs, deduped_samplers["originals"], deduped_samplers["renames"])
	all_helper_funcs = prefix_vertex_fragment_samplers(all_helper_funcs, deduped_samplers["originals"], deduped_samplers["renames"])
	mega_shader.append("shader_type spatial;")
	mega_shader.append("\n\n")
	mega_shader.append("\n".join(all_includes))
	mega_shader.append("\n".join(all_global_macros) + "\n")
	mega_shader.append("\n")
	mega_shader.append("\n".join(all_varyings))
	mega_shader.append("\n\n")
	mega_shader.append("\n".join(all_uniforms))
	mega_shader.append("\n\n")
	mega_shader.append("\n".join(all_global_uniforms))
	mega_shader.append("\n\n")
	mega_shader.append("\n".join(all_helper_funcs))

	mega_shader.append("void vertex() {\n")
	mega_shader.append(DEFAULT_VERTEX_OUTPUT)
	mega_shader.append("\n".join(all_vertex_macros))
	mega_shader.append("".join(all_vertex_funcs))
	mega_shader.append("\t" + VERTEX_OUTPUTS)
	mega_shader.append("}")

	mega_shader.append("\nvoid fragment() {")
	mega_shader.append("\n\n")
	mega_shader.append(DEFAULT_LAYER_DATA_OUTPUT)
	mega_shader.append(DEFAULT_FRAGMENT_OUTPUT)
	mega_shader.append("\n".join(all_fragment_macros))
	mega_shader.append("".join(all_fragment_funcs))
	mega_shader.append("\t" + FRAGMENT_OUTPUTS)
	mega_shader.append("}")

	return "".join(mega_shader)




func _auto_compile_on_load() -> void:
	if shader and not layers.is_empty():
		_rebuild_uniform_maps()
		ensure_assets_and_update()


func _rebuild_uniform_maps() -> void:
	var assets := _ensure_assets()
	layer_uniform_maps.clear()

	for asset in assets:
		var slot: int = asset["slot"]
		var mask_type: int = asset["mask_type"]
		var mask_active: bool = asset["mask_active"]

		var mask_shader: Shader = asset["mask_shader"]

		if mask_type == MaterialLayer.MaskType.MATERIAL and mask_active and mask_shader:
			var mask_c := strip_comments(mask_shader.code)
			var mask_uniforms = parse_uniforms(mask_c, true, slot)

			layer_uniform_maps.append({
				"mask_material": asset["mask_mat"],
				"identifiers": mask_uniforms["uniform_identifiers"],
				"sampler_identifiers": mask_uniforms["sampler_identifiers"],
				"sampler_uniforms": mask_uniforms["samplers"],
				"index": slot,
				"is_mask": true,
			})

		var surface_shader: Shader = asset["surface_shader"]
		if surface_shader == null:
			continue

		var surface_c := strip_comments(surface_shader.code)
		var surface_uniforms := parse_uniforms(surface_c, false, slot)

		layer_uniform_maps.append({
			"surface_material": asset["surface_mat"],
			"identifiers": surface_uniforms["uniform_identifiers"],
			"sampler_identifiers": surface_uniforms["sampler_identifiers"],
			"sampler_uniforms": surface_uniforms["samplers"],
			"index": slot,
			"is_mask": false,
		})


func ensure_assets_and_update() -> void:
	update_uniforms(_ensure_assets())


func compile() -> void:
	for layer in layers:
		if layer:
			layer.resource_name = layer.label

	_fragment_layer_out_regex.clear()
	_fragment_layer_below_regex.clear()
	_fragment_layer_current_regex.clear()
	_fragment_layer_result_regex.clear()
	_vertex_layer_out_regex.clear()
	_vertex_layer_below_regex.clear()
	_vertex_layer_current_regex.clear()
	_vertex_layer_result_regex.clear()
	_layer_data_out_regex.clear()
	_layer_data_below_regex.clear()
	layer_uniform_maps.clear()
	var assets := _ensure_assets()
	var code := _generate_code(assets)
	print_rich("Generated " + "[color=#75ff13]LayerStack")

	var sh: Shader
	if self.shader != null and self.shader is Shader:
		sh = self.shader
	else:
		sh = Shader.new()
	sh.code = code
	sh.emit_changed()

	if sh.resource_path != "":
		ResourceSaver.save(sh, sh.resource_path)
	elif self.shader == null:
		self.shader = sh

	for prop in get_property_list():
		if prop.name.begins_with("shader_parameter/"):
			var param_name = prop.name.substr("shader_parameter/".length())
			set_shader_parameter(param_name, null)

	copy_uniform_values(self, layer_uniform_maps)
	set_mask_uniforms(assets)


func update() -> void:
	update_uniforms(_ensure_assets())


