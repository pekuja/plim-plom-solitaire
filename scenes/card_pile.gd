class_name CardPile extends Node2D

@export var location : Card.Location = Card.Location.None

signal pile_clicked

func is_top_card():
	var child_card = get_node_or_null("Card")
	return child_card == null

func is_legal_drop(card : Card):
	if location == Card.Location.None or location == Card.Location.Deck or location == Card.Location.Draw:
		return false
	if not is_top_card():
		return false
	if location == Card.Location.Foundation and not card.is_top_card():
		return false
	if location == Card.Location.Foundation and card.value != 1:
		return false
	if location == Card.Location.Tableau and card.value != 13:
		return false
	
	return true


func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT:
		pile_clicked.emit()
