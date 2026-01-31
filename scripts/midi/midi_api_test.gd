extends Node

## Test script to discover MidiResource API methods.
## Run this scene to inspect the godot_midi plugin's API.

func _ready() -> void:
	print("=== MIDI API Discovery ===")
	
	var midi_resource = preload("res://assets/testing_track/Testing_Track.mid")
	
	if midi_resource == null:
		push_error("Failed to load MIDI file")
		return
	
	print("\n--- MidiResource Type ---")
	print("Class: ", midi_resource.get_class())
	print("Script: ", midi_resource.get_script())
	
	print("\n--- Available Methods ---")
	var methods: Array = midi_resource.get_method_list()
	for method in methods:
		var method_name: String = method.get("name", "")
		var return_type = method.get("return", {})
		var return_type_name: String = return_type.get("class_name", "")
		if return_type_name.is_empty():
			var type_id: int = return_type.get("type", -1)
			return_type_name = type_string(type_id)
		
		var args: Array = method.get("args", [])
		var arg_strings: Array[String] = []
		for arg in args:
			var arg_name: String = arg.get("name", "")
			var arg_type_id: int = arg.get("type", -1)
			var arg_type: String = type_string(arg_type_id)
			arg_strings.append("%s: %s" % [arg_name, arg_type])
		
		print("  %s(%s) -> %s" % [method_name, ", ".join(arg_strings), return_type_name])
	
	print("\n--- Available Properties ---")
	var properties: Array = midi_resource.get_property_list()
	for prop in properties:
		var prop_name: String = prop.get("name", "")
		var prop_type_id: int = prop.get("type", -1)
		var prop_type: String = type_string(prop_type_id)
		var usage: int = prop.get("usage", 0)
		if usage & PROPERTY_USAGE_SCRIPT_VARIABLE or usage & PROPERTY_USAGE_STORAGE:
			print("  %s: %s" % [prop_name, prop_type])
	
	print("\n--- Testing Property Access ---")
	_test_property_access(midi_resource)
	
	print("\n=== Discovery Complete ===")

func _test_property_access(midi_resource: Resource) -> void:
	var props_to_test: Array[String] = [
		"tempo_map",
		"tracks",
		"track_count",
		"tempo_track",
		"ppq",
		"ticks_per_beat",
		"time_signature",
		"notes",
		"events"
	]
	
	for prop_name in props_to_test:
		if prop_name in midi_resource:
			var value = midi_resource.get(prop_name)
			print("  %s = %s (type: %s)" % [prop_name, str(value).substr(0, 100), type_string(typeof(value))])

func type_string(type_id: int) -> String:
	match type_id:
		TYPE_NIL: return "null"
		TYPE_BOOL: return "bool"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_STRING: return "String"
		TYPE_VECTOR2: return "Vector2"
		TYPE_VECTOR3: return "Vector3"
		TYPE_COLOR: return "Color"
		TYPE_ARRAY: return "Array"
		TYPE_DICTIONARY: return "Dictionary"
		TYPE_OBJECT: return "Object"
		_: return "Unknown(%d)" % type_id
