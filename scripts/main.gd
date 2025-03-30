extends Node2D

@export var _card_scene : PackedScene

@onready var _deck_locator = $Deck
@onready var _draw_pile_locator = $"Draw Pile"
@onready var _piles = [
	$"Pile 1",
	$"Pile 2",
	$"Pile 3",
	$"Pile 4",
	$"Pile 5",
	$"Pile 6",
	$"Pile 7"
	]
@onready var _stacks = [
	$"Stack 1",
	$"Stack 2",
	$"Stack 3",
	$"Stack 4"
	]

var _card_deck : Array[Card] = []
var _deck_top_card : Card = null

func _ready():
	generate_card_deck()
	
	_card_deck.shuffle()
	
	var index = 0
	var pile_index = 0
	_deck_top_card = null
	for card in _card_deck:
		card.z_index = index
		if pile_index < 7:
			var pile = _piles[pile_index]
			if _deck_top_card:
				card.position.y = Card.PILE_OFFSET
				_deck_top_card.add_child(card)
			else:
				pile.add_child(card)
			_deck_top_card = card
			
			index += 1
			
			if index > pile_index:
				card.is_face_up = true
				card.update_texture()
				_deck_top_card = null
				index = 0
				pile_index += 1
			
		else:
			if _deck_top_card:
				_deck_top_card.add_child(card)
			else:
				_deck_locator.add_child(card)
			_deck_top_card = card
			index += 1
		
	_deck_top_card.card_clicked.connect(deck_clicked)
	
func deck_clicked():
	_deck_top_card.card_clicked.disconnect(deck_clicked)
		
	var parent = _deck_top_card.get_parent()
	parent.remove_child(_deck_top_card)
	_draw_pile_locator.add_child(_deck_top_card)
	_deck_top_card.is_face_up = true
	_deck_top_card.update_texture()
	
	if parent is Card:
		print("parent is card")
		_deck_top_card = parent
		_deck_top_card.card_clicked.connect(deck_clicked)
	else:
		print("parent is ", parent)
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
