extends Node2D

@export var _card_scene : PackedScene

func _ready():
	generate_card_deck()
	
func generate_card_deck():
	generate_card_suit(Card.Suit.Heart, Vector2(-400, -400))
	generate_card_suit(Card.Suit.Diamond, Vector2(-400, 256-400))
	generate_card_suit(Card.Suit.Club, Vector2(-400, 512-400))
	generate_card_suit(Card.Suit.Spade, Vector2(-400, 768-400))
	
func generate_card_suit(suit : Card.Suit, offset : Vector2):
	for value in range(0, 13):
		var card : Card = _card_scene.instantiate()
		card.suit = suit
		card.value = value + 1
		card.is_face_up = (value % 2 == 0)
		card.z_index = value
		
		card.global_position = offset + Vector2(value * 64, 0)
		
		add_child(card)
