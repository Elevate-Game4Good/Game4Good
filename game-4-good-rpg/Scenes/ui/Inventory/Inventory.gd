extends CanvasLayer

@onready var item_list: ItemList = $Control/CenterContainer/PanelContainer/VBoxContainer/ItemList

func ready() -> void:
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

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
