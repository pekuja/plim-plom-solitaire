class_name CardPile extends Node2D

@export var location : Card.Location = Card.Location.None

signal pile_clicked

func is_top_card():
	var child_card = get_node_or_null("Card")
	return child_card == null
	
func get_top_card_or_pile() -> Node2D:
	var top_card_or_pile : Node2D = self
	var child_card : Node2D = get_node_or_null("Card")
	while child_card != null:
		top_card_or_pile = child_card
		child_card = top_card_or_pile.get_node_or_null("Card")
	
	return top_card_or_pile

func is_legal_drop(card : Card):
	if location == Card.Location.None or location == Card.Location.Deck or \
		location == Card.Location.Cell or location == Card.Location.Draw:
		return false
	if not is_top_card():
		return false
	if location == Card.Location.Foundation and not card.is_top_card():
		return false
	if location == Card.Location.Foundation and card.value != 1:
		return false
	
	return true

func _input(event : InputEvent) -> void:
	if event is InputEventScreenTouch and event.is_pressed():
		var view_to_world = get_canvas_transform().affine_inverse()
		var touch_position = view_to_world * event.position
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = touch_position
		query.collide_with_areas = true
		var results = space_state.intersect_point(query)
		
		for result in results:
			var area2D = result.collider
			if area2D.get_parent() == self:
				pile_clicked.emit()
				return

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	pass
	#if event is InputEventScreenTouch and event.is_pressed():
	#	pile_clicked.emit()
