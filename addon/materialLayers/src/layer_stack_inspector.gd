@tool
class_name LayerStackInspectorPlugin
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
    return object is LayerStack

func _parse_begin(object: Object) -> void:
    if not object is LayerStack:
        return
    
    var stack: LayerStack = object

    var compile_btn := Button.new()
    var update_uniforms_btn := Button.new()
    compile_btn.text = "Generate"
    update_uniforms_btn.text = "Update Uniforms"
    compile_btn.pressed.connect(func() -> void:
        stack.compile()
        stack.update()
    )
    add_custom_control(compile_btn)
    add_custom_control(update_uniforms_btn)
