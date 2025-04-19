extends Node2D

var _dragging_touch_index = -1
var dragging_offset : Vector2 = Vector2(0,0)
var is_a_card_being_dragged = false
var dragged_card : Card = null

signal card_clicked(card : Card)
signal card_drag_start(card : Card)
signal card_drag_end(card : Card, drop_point : Node2D)
signal card_moved(move : Card.Move)

const DRAG_THRESHOLD = 25

func _input(event : InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			# only one drag allowed at once
			if dragged_card:
				return
			
			var view_to_world = get_canvas_transform().affine_inverse()
			var touch_position = view_to_world * event.position
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = touch_position
			query.collide_with_areas = true
			var results = space_state.intersect_point(query)
			
			var top_card : Card = null
			var top_card_z_index = -1
			
			for result in results:
				var area2D = result.collider
				var card = area2D.get_parent()
				if card is Card:
					var card_z_index = card.get_absolute_z_index()
					if card_z_index > top_card_z_index:
						top_card = card
						top_card_z_index = card_z_index
			
			if top_card == null:
				return
			
			if not top_card.is_draggable():
				return
				
			dragged_card = top_card
			
			_dragging_touch_index = event.index
			dragging_offset = touch_position - dragged_card.global_position
		if event.index == _dragging_touch_index and event.pressed == false and dragged_card:
			if is_a_card_being_dragged:
				dragged_card.z_index = 1
				var closest_distance = 0.0
				var card_to_drop_on = null
				for other_area2D : Area2D in dragged_card.area2D.get_overlapping_areas():
					var other_card_or_pile = other_area2D.get_parent()
					if (other_card_or_pile is Card or other_card_or_pile is CardPile) and other_card_or_pile != dragged_card:
						if other_card_or_pile.is_legal_drop(dragged_card):
							var distance = other_card_or_pile.global_position.distance_squared_to(dragged_card.global_position)
							if card_to_drop_on == null or distance < closest_distance:
								card_to_drop_on = other_card_or_pile
								closest_distance = distance
								
				
				var parent = dragged_card.get_parent()
				if card_to_drop_on:
					var move = dragged_card.move_to(card_to_drop_on)
					card_moved.emit(move)
					card_drag_end.emit(dragged_card, card_to_drop_on)
				else:
					if parent is Card:
						dragged_card.position.x = 0
						if parent.location == Card.Location.Tableau:
							dragged_card.position.y = Card.PILE_OFFSET
						else:
							dragged_card.position.y = 0
					else:
						dragged_card.position.x = 0
						dragged_card.position.y = 0
					card_drag_end.emit(dragged_card, null)
				dragged_card.set_dragging(false)
				is_a_card_being_dragged = false
			else:
				card_clicked.emit(dragged_card)
			dragged_card = null
	elif event is InputEventScreenDrag and dragged_card:
		var view_to_world = get_canvas_transform().affine_inverse()
		var touch_position = view_to_world * event.position
			
		if not is_a_card_being_dragged:
			if (touch_position - (dragged_card.global_position + dragging_offset)).length() > DRAG_THRESHOLD:
				is_a_card_being_dragged = true
				dragged_card.z_index = RenderingServer.CANVAS_ITEM_Z_MAX
				dragged_card.set_dragging(true)
				card_drag_start.emit(dragged_card)
			
		if is_a_card_being_dragged:
			dragged_card.global_position = touch_position - dragging_offset
