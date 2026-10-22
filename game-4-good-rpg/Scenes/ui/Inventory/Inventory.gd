extends CanvasLayer

@onready var item_list: ItemList = $Control/CenterContainer/PanelContainer/VBoxContainer/ItemList

func _ready() -> void:
	visible = false
	update_inventory()
	
func toggle_inventory() -> void:
	visible = not visible
	
	if visible:
		update_inventory()

func update_inventory() -> void:
	item_list.clear()
	
	for item in InventoryManager.get_items():
		item_list.add_item(item)
