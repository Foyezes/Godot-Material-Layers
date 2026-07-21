@tool
class_name LayerStackInspectorPlugin
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	return object is LayerStack

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if not (object is LayerStack):
		return false
	if name.begins_with("shader_parameter/"):
		return true
	return false

func _parse_begin(object: Object) -> void:
	if not object is LayerStack:
		return

	var stack: LayerStack = object

	var compile_btn := Button.new()
	compile_btn.text = "Generate"
	compile_btn.pressed.connect(func() -> void:
		stack.compile()
		stack.update()
	)
	add_custom_control(compile_btn)
