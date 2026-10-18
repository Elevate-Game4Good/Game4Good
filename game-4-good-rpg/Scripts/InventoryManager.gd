extends Node

var items: Array[String] = []

func add_item(item_name: String) -> void:
	items.append(item_name)
	
func remove_items(item_name: String) -> void:
	items.erase(item_name)

func has_item(item_name: String) -> bool:
	return item_name in items

func get_items() -> Array[String]:
	return items
	
	
	
	
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
