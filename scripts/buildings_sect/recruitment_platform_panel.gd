extends PanelContainer

signal back_requested()
signal recruit_requested()
signal dismiss_requested(index: int)

var _building_data: Dictionary = {}
var _spiritual_energy: float = 0.0
var _disciples: Array = []
var _disciple_capacity: int = 3

const BIG_UNITS = ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']

const DISCIPLE_GRADES = [
	{"name": "凡质", "color": Color(0.6, 0.6, 0.6), "mana": 0.15, "hp": 25, "atk": 2, "def": 1},
	{"name": "良质", "color": Color(0.2, 0.8, 0.3), "mana": 0.4, "hp": 55, "atk": 6, "def": 4},
	{"name": "精英", "color": Color(0.2, 0.5, 1.0), "mana": 1.0, "hp": 100, "atk": 14, "def": 10},
	{"name": "绝世", "color": Color(0.9, 0.3, 0.9), "mana": 3.0, "hp": 220, "atk": 35, "def": 22},
	{"name": "传说", "color": Color(1.0, 0.7, 0.0), "mana": 8.0, "hp": 450, "atk": 70, "def": 45},
	{"name": "神话", "color": Color(1.0, 0.2, 0.2), "mana": 20.0, "hp": 900, "atk": 140, "def": 85},
]

const DISCIPLE_SURNAMES = ["云", "风", "清", "玄", "灵", "玉", "元", "道", "真", "明", "虚", "静", "太", "紫", "青"]

func _format_num(n: float) -> String:
	if n < 10000:
		return str(int(n))
	var val = n
	var unit_idx = 0
	while val >= 10000 and unit_idx < BIG_UNITS.size() - 1:
		val /= 10000.0
		unit_idx += 1
	return str(val).pad_decimals(1) + BIG_UNITS[unit_idx]

func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func set_state(building: Dictionary, energy: float, disciples: Array, capacity: int):
	_building_data = building
	_spiritual_energy = energy
	_disciples = disciples
	_disciple_capacity = capacity

func refresh():
	clear_children()
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	add_child(vbox)

	var top_bar = HBoxContainer.new()
	var btn_back = Button.new()
	btn_back.text = "← 返回"
	btn_back.add_theme_font_size_override("font_size", 12)
	btn_back.pressed.connect(func(): back_requested.emit())
	top_bar.add_child(btn_back)
	var title = _pl("── 接引台 ──", Color(0.3, 0.6, 1.0), 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	vbox.add_child(top_bar)
	vbox.add_child(HSeparator.new())

	var lv = _building_data.get('level', 0)
	vbox.add_child(_pl("接引台等级：" + str(lv) + " / 5", Color(0.3, 0.6, 1.0)))
	vbox.add_child(_pl("招收弟子的场所，等级影响招收高品质弟子的概率。"))

	var recruit_cost = 500 * (lv + 1)
	var cap_color = Color(1.0, 0.35, 0.35) if _disciples.size() >= _disciple_capacity else Color(0.3, 1.0, 0.3)
	vbox.add_child(_pl("弟子数量：" + str(_disciples.size()) + " / " + str(_disciple_capacity), cap_color))
	vbox.add_child(_pl("招收消耗：" + _format_num(recruit_cost) + " 灵气", Color(1.0, 0.84, 0.0)))

	var can_recruit = _spiritual_energy >= recruit_cost and _disciples.size() < _disciple_capacity
	var btn_recruit = Button.new()
	btn_recruit.text = "招收弟子"
	btn_recruit.add_theme_font_size_override("font_size", 13)
	btn_recruit.custom_minimum_size = Vector2(120, 32)
	btn_recruit.disabled = not can_recruit
	if _disciples.size() >= _disciple_capacity:
		btn_recruit.text = "弟子已满"
	elif _spiritual_energy < recruit_cost:
		btn_recruit.text = "灵气不足"
	btn_recruit.pressed.connect(func(): recruit_requested.emit())
	vbox.add_child(btn_recruit)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_pl("── 已招收弟子 ──", Color(0.3, 0.6, 1.0), 14))

	if _disciples.is_empty():
		vbox.add_child(_pl("暂无弟子，点击上方按钮招收", Color(0.5, 0.5, 0.5)))
	else:
		for i in range(_disciples.size()):
			var d = _disciples[i]
			vbox.add_child(_make_disciple_card(d, i))

func _make_disciple_card(disciple: Dictionary, index: int) -> PanelContainer:
	var grade_idx = disciple.get('grade', 0)
	var grade_data = DISCIPLE_GRADES[grade_idx] if grade_idx < DISCIPLE_GRADES.size() else DISCIPLE_GRADES[0]

	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.14, 0.18)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label = _pl(disciple.get('name', '弟子') + "  " + grade_data['name'], grade_data['color'], 13)
	info_vbox.add_child(name_label)

	var lv = disciple.get('level', 1)
	var stats = "Lv." + str(lv) + " | HP:" + str(int(disciple.get('hp', 0))) + "  ATK:" + str(int(disciple.get('atk', 0))) + "  DEF:" + str(int(disciple.get('def', 0))) + "  灵气:" + _format_num(disciple.get('mana', 0)) + "/秒"
	info_vbox.add_child(_pl(stats, Color(0.55, 0.55, 0.7), 11))

	var btn_dismiss = Button.new()
	btn_dismiss.text = "逐出"
	btn_dismiss.add_theme_font_size_override("font_size", 11)
	btn_dismiss.custom_minimum_size = Vector2(48, 26)
	var idx = index
	btn_dismiss.pressed.connect(func(): dismiss_requested.emit(idx))
	hbox.add_child(btn_dismiss)

	return card

func clear_children():
	for child in get_children():
		remove_child(child)
		child.queue_free()
