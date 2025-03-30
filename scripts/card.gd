class_name Card extends Node2D

@onready var _sprite2D = $Sprite2D
@onready var _area2D = $Area2D

enum Suit
{
	Heart = 0,
	Diamond = 1,
	Club = 2,
	Spade = 3
}

@export var value = 1
@export var suit : Suit = Suit.Heart
@export var cardAtlas : Texture2D
@export var is_face_up = true

signal card_clicked

const CARD_WIDTH = 42
const CARD_HEIGHT = 60
const CARD_OFFSET_X = 11
const CARD_OFFSET_Y = 2
const SUIT_INCREMENT_Y = 64
const VALUE_INCREMENT_X = 64
const PILE_OFFSET = 32

var is_dragging : bool = false
var dragging_offset : Vector2 = Vector2(0,0)
var drag_start_position : Vector2 = Vector2(0,0)

static var hovered_cards : Array[Card] = []

func is_red():
	return suit == Suit.Heart or suit == Suit.Diamond
	
func is_black():
	return suit == Suit.Club or suit == Suit.Spade
	
func is_legal_drop(other_card : Card):
	if not is_face_up:
		return false
	if not is_top_card():
		return false
	if is_black() and other_card.is_black() or is_red() and other_card.is_red():
		return false
	if other_card.value != value - 1:
		return false
	
	return true

func _ready():
	var atlasTexture : AtlasTexture = AtlasTexture.new()
	atlasTexture.atlas = cardAtlas
	_sprite2D.texture = atlasTexture
	
	update_texture()
	
func is_draggable():
	# TODO: Support dragging piles of cards
	if not is_top_card():
		return false
	if not is_face_up:
		return false
	return true
	
func is_top_card():
	var child_cards = find_children("*", "Card")
	return child_cards.is_empty()
	
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed == false and is_dragging:
			var closest_distance = 0.0
			var card_to_drop_on : Card = null
			for other_area2D : Area2D in _area2D.get_overlapping_areas():
				var other_card : Card = other_area2D.get_parent()
				if other_card and other_card != self:
					if other_card.is_legal_drop(self):
						var distance = other_card.global_position.distance_squared_to(global_position)
						if card_to_drop_on == null or distance < closest_distance:
							card_to_drop_on = other_card
							closest_distance = closest_distance
			
			
			var parent = get_parent()
			if card_to_drop_on:
				z_index = card_to_drop_on.z_index + 1
				if parent is Card:
					parent.is_face_up = true
					parent.update_texture()
				parent.remove_child(self)
				card_to_drop_on.add_child(self)
				
				position.x = 0
				position.y = PILE_OFFSET
			elif parent is Card:
				position.x = 0
				position.y = PILE_OFFSET
			else:
				position.x = 0
				position.y = 0
			is_dragging = false
	if event is InputEventMouseMotion:
		if is_dragging:
			global_position = event.position - dragging_offset

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed == true:
			card_clicked.emit()
			if is_draggable():
				for card in hovered_cards:
					if card.z_index > z_index:
						return
				z_index = RenderingServer.CANVAS_ITEM_Z_MAX
				is_dragging = true
				is_face_up = true
				drag_start_position = global_position
				update_texture()
				dragging_offset = event.position - global_position

func _on_area_2d_mouse_entered() -> void:
	hovered_cards.append(self)

func _on_area_2d_mouse_exited() -> void:
	hovered_cards.erase(self)
