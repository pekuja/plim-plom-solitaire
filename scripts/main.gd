extends Node2D

@export var _card_scene : PackedScene

@onready var _deck_locator : CardPile = $Deck
@onready var _tableaus = [
	$"Tableau 1",
	$"Tableau 2",
	$"Tableau 3",
	$"Tableau 4",
	$"Tableau 5",
	]
	
@onready var _cells = [
	$"Cell 1",
	$"Cell 2",
	]

@onready var _foundations = [
	$"Foundation 1",
	$"Foundation 2",
	$"Foundation 3",
	$"Foundation 4",
	]

var _card_deck : Array[Card] = []
var _deck_top_card : Card = null
var _previous_move : Node2D = null
var _previous_move_timestamp : int = -1

const CARDS_PER_TABLEAU = 5
const MOVE_REPEAT_THRESHOLD = 1000

func get_tableau_or_top_card(tableau : Node2D) -> Node2D:	
	var card : Card = tableau.get_node_or_null("Card")
	if card:
		while true:
			var child = card.get_node_or_null("Card")
			if child:
				card = child
			else:
				return card
	
	return tableau

func _ready():
	game_setup()

func game_setup():
	generate_card_deck()
	
	_card_deck.shuffle()
	
	_deck_top_card = null
		
	for card in _card_deck:
		card.location = Card.Location.Deck
		if _deck_top_card:
			_deck_top_card.add_child(card)
		else:
			_deck_locator.add_child(card)
		_deck_top_card = card
		
	for tableau_index in range(0, _tableaus.size()):
		var next_card : Card
		var tableau = _tableaus[tableau_index]
		var top_card = tableau
		for index in range(0, CARDS_PER_TABLEAU):
			next_card = _deck_top_card
			var parent : Card = next_card.get_parent()
			next_card.move_to(top_card, tableau_index)
			
			top_card = next_card
			
			_deck_top_card = parent
			
		next_card.is_face_up = true
		next_card.update_texture()
	
	for cell_index in range(0, _cells.size()):
		var next_card : Card = _deck_top_card
		var parent : Card = next_card.get_parent()
		next_card.move_to(_cells[cell_index], cell_index)
		next_card.is_face_up = true
		next_card.update_texture()
		
		_deck_top_card = parent
	
	_deck_locator.pile_clicked.connect(deck_clicked)
	
func deck_clicked():
	if _deck_top_card:
		var index = 0
		for tableau in _tableaus:
			var parent = _deck_top_card.get_parent()
			var tableau_or_top_card = get_tableau_or_top_card(tableau)
			
			_deck_top_card.move_to(tableau_or_top_card, index)
			index += 1
			
			_deck_top_card.is_face_up = true
			_deck_top_card.update_texture()
			
			if parent is Card:
				_deck_top_card = parent
			else:
				_deck_top_card = null
				break
	
func generate_card_deck():
	_card_deck.clear()
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

func free_child_cards(parent):
	var card = parent.get_node_or_null("Card")
	if card:
		card.queue_free()
		parent.remove_child(card)

func _on_restart_button_pressed() -> void:
	free_child_cards(_deck_locator)
	for cell in _cells:
		free_child_cards(cell)
	for foundation in _foundations:
		free_child_cards(foundation)
	for tableau in _tableaus:
		free_child_cards(tableau)
		
	game_setup()

func _is_better_move(new_move : Node2D, old_move : Node2D, card_to_move : Card):
	if old_move == null:
		return true
	
	if _previous_move:
		if _previous_move_timestamp + MOVE_REPEAT_THRESHOLD > Time.get_ticks_msec():
			if new_move == _previous_move:
				return true
			if old_move == _previous_move:
				return false
	if new_move.location == Card.Location.Foundation:
		return true
	if old_move.location == Card.Location.Foundation:
		return false
	if new_move is Card and card_to_move.suit == new_move.suit:
		return true
	if not old_move is Card:
		return true
	return false

func _on_card_clicked(card: Card) -> void:
	var best_move : Node2D = null
	
	for foundation in _foundations:
		var top_card_or_pile = foundation.get_top_card_or_pile()
		if top_card_or_pile.is_legal_drop(card) and _is_better_move(top_card_or_pile, best_move, card):
			best_move = top_card_or_pile
			
	for tableau in _tableaus:
		var top_card_or_pile = tableau.get_top_card_or_pile()
		if top_card_or_pile.is_legal_drop(card) and _is_better_move(top_card_or_pile, best_move, card):
			best_move = top_card_or_pile
	
	if best_move:
		_previous_move = card
		_previous_move_timestamp = Time.get_ticks_msec()
		card.move_to(best_move)
	else:
		_previous_move = null

func _on_card_drag_start(card: Card) -> void:
	_previous_move = null

func _on_card_drag_end(card: Card, drop_point: Node2D) -> void:
	_previous_move = null
