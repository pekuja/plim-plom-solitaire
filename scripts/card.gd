class_name Card extends Node2D

@onready var _sprite2D = $Sprite2D
@onready var _area2D = $Area2D
@onready var _label = $Label

enum Suit
{
	Heart = 0,
	Diamond = 1,
	Club = 2,
	Spade = 3
}

enum Location
{
	None,
	Deck,
	Draw,
	Tableau,
	Foundation,
	Cell
}

@export var value = 1
@export var suit : Suit = Suit.Heart
@export var cardAtlas : Texture2D
@export var is_face_up = true
@export var location : Location = Location.None

const CARD_WIDTH = 42
const CARD_HEIGHT = 60
const CARD_OFFSET_X = 11
const CARD_OFFSET_Y = 2
const SUIT_INCREMENT_Y = 64
const VALUE_INCREMENT_X = 64
const PILE_OFFSET = 56

var _is_dragging : bool = false
var _dragging_touch_index = -1
var dragging_offset : Vector2 = Vector2(0,0)

static var is_a_card_being_dragged = false

func is_red():
	return suit == Suit.Heart or suit == Suit.Diamond
	
func is_black():
	return suit == Suit.Club or suit == Suit.Spade
	
func is_legal_drop(other_card : Card):
	if location == Location.None or location == Location.Deck or \
		location == Location.Cell or location == Location.Draw:
		return false
	if is_dragging():
		return false
	if not is_top_card():
		return false
	if location == Location.Tableau and get_pile_size() >= 20:
		return false
	return is_sequential(other_card)
	
func is_sequential(other_card : Card):
	if location == Location.Foundation:
		if suit != other_card.suit:
			return false
		if other_card.value != value + 1:
			return false
		if not other_card.is_top_card():
			return false
	if location == Location.Tableau:
		if other_card.value != value - 1 and other_card.value != value + 1:
			return false
	
	return true
	
func get_pile_size():
	var parent = get_parent()
	var pile_size = 1
	while parent is Card:
		pile_size += 1
		parent = parent.get_parent()
	
	return pile_size

func _ready():
	var atlasTexture : AtlasTexture = AtlasTexture.new()
	atlasTexture.atlas = cardAtlas
	_sprite2D.texture = atlasTexture
	
	update_texture()
	
func _process(_delta):
	_label.text = "%s\n%s" % [get_absolute_z_index(), location]
	
func is_draggable():
	if location == Location.None or location == Location.Foundation:
		return false
	if not is_top_card():
		if location != Location.Tableau:
			return false
		var next_card : Card = get_node("Card")
		if next_card.suit != suit:
			return false
		if not is_sequential(next_card):
			return false
		if not next_card.is_draggable():
			return false
	if not is_face_up:
		return false
	return true
	
func is_top_card():
	var child_card = get_node_or_null("Card")
	return child_card == null
	
func is_dragging():
	if _is_dragging:
		return true
	
	var parent = get_parent()
	if parent is Card:
		return parent.is_dragging()
		
	return false
	
func update_texture():
	var atlasTexture : AtlasTexture = _sprite2D.texture
	if is_face_up:
		atlasTexture.region.position.x = (value - 1) * VALUE_INCREMENT_X + CARD_OFFSET_X
		atlasTexture.region.position.y = suit * SUIT_INCREMENT_Y + CARD_OFFSET_Y
	else:
		atlasTexture.region.position.x = (14 - 1) * VALUE_INCREMENT_X + CARD_OFFSET_X
		atlasTexture.region.position.y = 1 * SUIT_INCREMENT_Y + CARD_OFFSET_Y
	atlasTexture.region.size.x = CARD_WIDTH
	atlasTexture.region.size.y = CARD_HEIGHT

func _input(event : InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.is_pressed():
			# only one drag allowed at once
			if is_a_card_being_dragged:
				return
				
			if not is_draggable():
				return
			
			var view_to_world = get_canvas_transform().affine_inverse()
			var touch_position = view_to_world * event.position
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = touch_position
			query.collide_with_areas = true
			var results = space_state.intersect_point(query)
			var absolute_z_index = get_absolute_z_index()
			
			var self_intersected = false
			
			for result in results:
				var area2D = result.collider
				var card = area2D.get_parent()
				if card is Card:
					if card == self:
						self_intersected = true
					elif card.get_absolute_z_index() > absolute_z_index:
						return
			
			if not self_intersected:
				return
			
			z_index = RenderingServer.CANVAS_ITEM_Z_MAX
			_is_dragging = true
			_dragging_touch_index = event.index
			is_a_card_being_dragged = true
			is_face_up = true
			update_texture()
			dragging_offset = touch_position - global_position
		if event.index == _dragging_touch_index and event.pressed == false and _is_dragging:
			z_index = 1
			var closest_distance = 0.0
			var card_to_drop_on = null
			for other_area2D : Area2D in _area2D.get_overlapping_areas():
				var other_card_or_pile = other_area2D.get_parent()
				if (other_card_or_pile is Card or other_card_or_pile is CardPile) and other_card_or_pile != self:
					if other_card_or_pile.is_legal_drop(self):
						var distance = other_card_or_pile.global_position.distance_squared_to(global_position)
						if card_to_drop_on == null or distance < closest_distance:
							card_to_drop_on = other_card_or_pile
							closest_distance = distance
							
			
			var parent = get_parent()
			if card_to_drop_on:
				if parent is Card:
					parent.is_face_up = true
					parent.update_texture()
				parent.remove_child(self)
				card_to_drop_on.add_child(self)
				location = card_to_drop_on.location
				
				position.x = 0
				if card_to_drop_on.location == Location.Tableau and card_to_drop_on is Card:
					position.y = PILE_OFFSET
				else:
					position.y = 0
					
			elif parent is Card:
				position.x = 0
				if parent.location == Location.Tableau:
					position.y = PILE_OFFSET
				else:
					position.y = 0
			else:
				position.x = 0
				position.y = 0
			_is_dragging = false
			is_a_card_being_dragged = false
	elif event is InputEventScreenDrag:
		if _is_dragging:
			var view_to_world = get_canvas_transform().affine_inverse()
			var touch_position = view_to_world * event.position
			global_position = touch_position - dragging_offset

func get_absolute_z_index() -> int:
	var parent = get_parent()
	if parent is Card:
		return parent.get_absolute_z_index() + z_index
	return z_index
