extends PanelContainer

signal back_requested()

var _current_cat: String = "realms"
var _realms: Array = []

func set_state(data: Dictionary):
	_realms = data.get('realms', [])

func _card_bg(color: Color = Color(0.1, 0.12, 0.18)) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 5
	s.corner_radius_top_right = 5
	s.corner_radius_bottom_left = 5
	s.corner_radius_bottom_right = 5
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func _lbl(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

func _fmt(n: float) -> String:
	var s = str(int(n))
	var r = ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			r += ","
		r += s[i]
	return r

const BIG_UNITS = ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']

func _format_big(n: float) -> String:
	if n < 10000:
		return _fmt(n)
	var val = n
	var unit_idx = 0
	while val >= 10000 and unit_idx < BIG_UNITS.size() - 1:
		val /= 10000.0
		unit_idx += 1
	var s = str(val)
	var dot = s.find(".")
	if dot > 0:
		s = s.substr(0, min(s.length(), dot + 2))
	else:
		if s.length() > 4:
			s = s.substr(0, 4)
	return s + BIG_UNITS[unit_idx]

func _set_category(cat: String):
	_current_cat = cat
	var menu = $VBox/HBox/LeftMenu
	for btn in menu.get_children():
		if btn is Button and btn.toggle_mode:
			btn.button_pressed = false
	match cat:
		"realms":
			if menu.has_node("BtnRealms"):
				menu.get_node("BtnRealms").button_pressed = true
	refresh()

func refresh():
	var list = $VBox/HBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	if _current_cat == "realms":
		_build_realms_view(list)

func _build_realms_view(list: VBoxContainer):
	var title = _lbl("── 修真境界 ──", Color(0.3, 0.8, 1.0), 15)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)

	if _realms.is_empty():
		list.add_child(_lbl("暂无数据", Color(0.5, 0.5, 0.6), 12))
		return

	var current_macro_name = ""
	for r in _realms:
		var name = r.get('name', '')
		var macro_name = ""
		for mn in ["练气", "筑基", "金丹", "元婴", "化神", "合体", "大乘", "渡劫", "真仙", "金仙", "太乙", "大罗", "混元"]:
			if name.begins_with(mn):
				macro_name = mn
				break

		if macro_name != current_macro_name:
			current_macro_name = macro_name
			list.add_child(HSeparator.new())
			var col = r.get('color', Color(0.6, 0.6, 0.8))
			var header = PanelContainer.new()
			header.add_theme_stylebox_override("panel", _card_bg(Color(col.r * 0.2, col.g * 0.2, col.b * 0.2)))
			var hv = VBoxContainer.new()
			hv.add_theme_constant_override("separation", 2)
			hv.add_child(_lbl(macro_name, col, 16))
			hv.add_child(_lbl("修炼阶段", Color(0.5, 0.5, 0.6), 10))
			header.add_child(hv)
			list.add_child(header)

		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_bg())
		var cv = VBoxContainer.new()
		cv.add_theme_constant_override("separation", 2)
		card.add_child(cv)

		var name_lbl = _lbl(name, r.get('color', Color(0.9, 0.9, 1.0)), 12)
		cv.add_child(name_lbl)

		var atk = r.get('atk_bonus', 0)
		var def = r.get('def_bonus', 0)
		var hp = r.get('hp_bonus', 0)
		var cost = r.get('cost', 0)

		var stats = "攻" + _format_big(atk) + "  防" + _format_big(def) + "  血" + _format_big(hp) + "  突破" + _format_big(cost) + "灵"
		var stats_lbl = Label.new()
		stats_lbl.text = stats
		stats_lbl.add_theme_color_override("font_color", Color(0.7, 0.8, 0.7))
		stats_lbl.add_theme_font_size_override("font_size", 11)
		stats_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		cv.add_child(stats_lbl)

		list.add_child(card)

func _ready():
	anchor_left = 0
	anchor_right = 1
	anchor_top = 0
	anchor_bottom = 1

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var top_bar = HBoxContainer.new()
	top_bar.name = "TopBar"
	top_bar.add_theme_constant_override("separation", 10)
	vbox.add_child(top_bar)

	var btn_back = Button.new()
	btn_back.name = "BtnBack"
	btn_back.text = "< 返回"
	btn_back.add_theme_font_size_override("font_size", 14)
	btn_back.pressed.connect(func(): back_requested.emit())
	top_bar.add_child(btn_back)

	var hbox = HBoxContainer.new()
	hbox.name = "HBox"
	hbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 0)
	vbox.add_child(hbox)

	var left_menu = VBoxContainer.new()
	left_menu.name = "LeftMenu"
	left_menu.custom_minimum_size = Vector2(60, 0)
	left_menu.add_theme_constant_override("separation", 4)
	hbox.add_child(left_menu)

	var make_cat_btn = func(text: String, cat: String) -> Button:
		var b = Button.new()
		b.name = "Btn" + cat.capitalize()
		b.text = text
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 12)
		b.pressed.connect(func(): _set_category(cat))
		return b

	var btn_realms = make_cat_btn.call("境界", "realms")
	btn_realms.button_pressed = true
	left_menu.add_child(btn_realms)

	var scroll = ScrollContainer.new()
	scroll.name = "ScrollList"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = 0
	scroll.follow_focus = true
	hbox.add_child(scroll)

	var item_list = VBoxContainer.new()
	item_list.name = "ItemList"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 4)
	scroll.add_child(item_list)
