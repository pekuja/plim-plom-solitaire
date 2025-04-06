extends Node2D

@export var _card_scene : PackedScene

@onready var _deck_locator : CardPile = $Deck
@onready var _draw_pile_locator : CardPile = $"Draw Pile"
@onready var _tableaus = [
	$"Tableau 1",
	$"Tableau 2",
	$"Tableau 3",
	$"Tableau 4",
	$"Tableau 5",
	$"Tableau 6",
	$"Tableau 7"
	]

var _card_deck : Array[Card] = []
var _deck_top_card : Card = null
var _draw_pile_top_card : Card = null

func get_draw_pile_top_card() -> Card:
	var card : Card = _draw_pile_locator.get_node("Card")
	if card == null:
		return card
	
	while true:
		var child = card.get_node_or_null("Card")
		if child:
			card = child
		else:
			return card
	
	return null

func _ready():
	generate_card_deck()
	
	_card_deck.shuffle()
	
	var index = 0
	var tableau_index = 0
	_deck_top_card = null
	for card in _card_deck:
		if tableau_index < 7:
			card.location = Card.Location.Tableau
			var tableau = _tableaus[tableau_index]
			if _deck_top_card:
				card.position.y = Card.PILE_OFFSET
				_deck_top_card.add_child(card)
			else:
				tableau.add_child(card)
			_deck_top_card = card
			
			index += 1
			
			if index > tableau_index:
				card.is_face_up = true
				card.update_texture()
				_deck_top_card = null
				index = 0
				tableau_index += 1
			
		else:
			card.location = Card.Location.Deck
			if _deck_top_card:
				_deck_top_card.add_child(card)
			else:
				_deck_locator.add_child(card)
			_deck_top_card = card
			index += 1
	
	_deck_locator.pile_clicked.connect(deck_clicked)
	
func deck_clicked():
	if _deck_top_card == null:
		var draw_pile_top_card : Card = null
		var next_card : Card = _draw_pile_locator.get_node_or_null("Card")
		
		while next_card != null:
			draw_pile_top_card = next_card
			next_card = next_card.get_node_or_null("Card")
		
		next_card = draw_pile_top_card
		while next_card != null:
			next_card.is_face_up = false
			next_card.update_texture()
			
			var parent = next_card.get_parent()
			parent.remove_child(next_card)
			if _deck_top_card:
				_deck_top_card.add_child(next_card)
			else:
				_deck_locator.add_child(next_card)
			_deck_top_card = next_card
			if parent is Card:
				next_card = parent
			else:
				next_card = null	
	else:
		var parent = _deck_top_card.get_parent()
		parent.remove_child(_deck_top_card)
		
		var draw_pile_top_card = get_draw_pile_top_card()
		
		if draw_pile_top_card:
			draw_pile_top_card.add_child(_deck_top_card)
		else:
			_draw_pile_locator.add_child(_deck_top_card)
		_deck_top_card.is_face_up = true
		_deck_top_card.update_texture()
		_deck_top_card.location = Card.Location.Draw
		
		if parent is Card:
			_deck_top_card = parent
		else:
			_deck_top_card = null
	
func generate_card_deck():
	generate_card_suit(Card.Suit.Heart)
	generate_card_suit(Card.Suit.Diamond)
	generate_card_suit(Card.Suit.Club)
	generate_card_suit(Card.Suit.Spade)
	
func generate_card_suit(suit : Card.Suit):
	for value in range(0, 13):
		var card : Card = _card_scene.instantiate()
		card.suit = suit
		card.value = value + 1
		card.is_face_up = false
		
		_card_deck.append(card)
