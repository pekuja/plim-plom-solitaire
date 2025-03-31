class_name CardPile extends Node2D

@export var location : Card.Location = Card.Location.None

func is_top_card():
	var child_card = get_node_or_null("Card")
	return child_card == null

func is_legal_drop(card : Card):
	if location == Card.Location.None or location == Card.Location.Deck or location == Card.Location.Draw:
		return false
	if not is_top_card():
		return false
	if location == Card.Location.Stack and card.value != 1:
		return false
	if location == Card.Location.Pile and card.value != 13:
		return false
	
	return true
