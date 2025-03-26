class_name Card extends Control

@onready var _textureRect = $TextureRect

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

const CARD_WIDTH = 42
const CARD_HEIGHT = 60
const CARD_OFFSET_X = 11
const CARD_OFFSET_Y = 2
const SUIT_INCREMENT_Y = 64
const VALUE_INCREMENT_X = 64

var is_dragging : bool = false
var dragging_offset : Vector2 = Vector2(0,0)
var is_face_up = true

func is_red():
	return suit == Suit.Heart or suit == Suit.Diamond
	
func is_black():
	return suit == Suit.Club or suit == Suit.Spade

func _ready():
	var atlasTexture : AtlasTexture = AtlasTexture.new()
	atlasTexture.atlas = cardAtlas
	_textureRect.texture = atlasTexture
	
	update_texture()
	
func update_texture():
	var atlasTexture : AtlasTexture = _textureRect.texture
	if is_face_up:
		atlasTexture.region.position.x = (value - 1) * VALUE_INCREMENT_X + CARD_OFFSET_X
		atlasTexture.region.position.y = suit * SUIT_INCREMENT_Y + CARD_OFFSET_Y
	else:
		atlasTexture.region.position.x = (14 - 1) * VALUE_INCREMENT_X + CARD_OFFSET_X
		atlasTexture.region.position.y = 1 * SUIT_INCREMENT_Y + CARD_OFFSET_Y
	atlasTexture.region.size.x = CARD_WIDTH
	atlasTexture.region.size.y = CARD_HEIGHT

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed == true:
			z_index = RenderingServer.CANVAS_ITEM_Z_MAX
			is_dragging = true
			dragging_offset = event.position
			
		elif event.pressed == false and is_dragging:
			
			z_index = 0
			position += event.position - dragging_offset
			is_dragging = false
	elif event is InputEventMouseMotion:
		if is_dragging:
			position += event.position - dragging_offset
