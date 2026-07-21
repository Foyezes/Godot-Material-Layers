@tool
extends EditorPlugin

var _inspector_plugin: LayerStackInspectorPlugin

func _enter_tree() -> void:
    _inspector_plugin = LayerStackInspectorPlugin.new()
    add_inspector_plugin(_inspector_plugin)

func _exit_tree() -> void:
    remove_inspector_plugin(_inspector_plugin)
    _inspector_plugin = null
