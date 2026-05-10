extends PanelContainer

signal back_requested()

var _learned_skills: Array = []
var _shop_skills: Array = []

func set_state(data: Dictionary):
	_learned_skills = data.get("learned_skills", []).duplicate()
	_shop_skills = data.get("shop_skills", []).duplicate()

func _make_card_bg(color: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	if border.a > 0:
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.border_color = border
	s.corner_radius_top_left = 5
	s.corner_radius_top_right = 5
	s.corner_radius_bottom_left = 5
	s.corner_radius_bottom_right = 5
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func refresh():
	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	if _learned_skills.is_empty():
		var empty = Label.new()
		empty.text = "尚未学会任何功法"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		list.add_child(empty)
		return

	for skill in _learned_skills:
		var skill_color = Color(0.7, 0.7, 0.9)
		for s in _shop_skills:
			if s.get('name', '') == skill.get('name', ''):
				skill_color = s.get('color', skill_color)
				break

		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.12, 0.14, 0.18), skill_color * 0.3))

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		card.add_child(vbox)

		var name_label = Label.new()
		name_label.text = skill.get('name', '未知功法')
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", skill_color)
		vbox.add_child(name_label)

		var pct = skill.get('mana_bonus_pct', 0.0)
		if pct == 0.0 and skill.has('mana_bonus'):
			pct = skill['mana_bonus'] / 10.0

		var info_label = Label.new()
		info_label.text = skill.get('desc', '') + "  修炼速度x" + str(1.0 + pct)
		info_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
		info_label.add_theme_font_size_override("font_size", 11)
		vbox.add_child(info_label)

		list.add_child(card)

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
