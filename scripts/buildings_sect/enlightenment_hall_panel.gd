extends PanelContainer

signal back_requested()
signal upgrade_requested()

var _building_data: Dictionary = {}
var _spiritual_energy: float = 0.0
var _sect_materials: Dictionary = {}
var _disciples: Array = []

const BIG_UNITS = ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']

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

func set_state(building: Dictionary, energy: float, materials: Dictionary, disciples: Array):
	_building_data = building
	_spiritual_energy = energy
	_sect_materials = materials
	_disciples = disciples

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
	var title = _pl("── 悟道堂 ──", Color(0.7, 0.3, 1.0), 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	vbox.add_child(top_bar)
	vbox.add_child(HSeparator.new())

	var lv = _building_data.get('level', 0)
	var speed_bonus = lv * 0.15
	vbox.add_child(_pl("悟道堂等级：" + str(lv) + " / 5", Color(0.7, 0.3, 1.0)))
	vbox.add_child(_pl("弟子修炼之地，当前弟子修炼速度+" + str(int(speed_bonus * 100)) + "%"))
	vbox.add_child(HSeparator.new())

	var next_lv = lv + 1
	if next_lv <= 5:
		var cost = int(5000 * pow(3.5, lv))
		var mat_name = "魂晶"
		var mat_cost = 3 + lv * 2
		var has_mat = _sect_materials.get(mat_name, 0) >= mat_cost
		var can_afford = _spiritual_energy >= cost and has_mat

		vbox.add_child(_pl("升级至" + str(next_lv) + "级需求："))
		vbox.add_child(_pl("  灵气：" + _format_num(cost), Color(0.3, 1.0, 0.3) if _spiritual_energy >= cost else Color(1.0, 0.35, 0.35)))
		vbox.add_child(_pl("  " + mat_name + "：" + str(mat_cost) + "（拥有：" + str(_sect_materials.get(mat_name, 0)) + "）", Color(0.3, 1.0, 0.3) if has_mat else Color(1.0, 0.35, 0.35)))

		var next_bonus = next_lv * 0.15
		vbox.add_child(_pl("升级后修炼速度：" + str(int(speed_bonus * 100)) + "% → " + str(int(next_bonus * 100)) + "%", Color(0.9, 0.5, 1.0)))

		var btn = Button.new()
		btn.text = "升级悟道堂"
		btn.add_theme_font_size_override("font_size", 13)
		btn.custom_minimum_size = Vector2(120, 32)
		btn.disabled = not can_afford
		if not can_afford:
			btn.text = "资源不足"
		btn.pressed.connect(func(): upgrade_requested.emit())
		vbox.add_child(btn)
	else:
		vbox.add_child(_pl("悟道堂已达最高等级！", Color(0.9, 0.5, 1.0)))

	vbox.add_child(HSeparator.new())
	vbox.add_child(_pl("── 弟子修炼进度 ──", Color(0.7, 0.3, 1.0), 13))

	if _disciples.is_empty():
		vbox.add_child(_pl("暂无弟子", Color(0.5, 0.5, 0.5)))
	else:
		for d in _disciples:
			var progress = d.get('cultivation_progress', 0.0)
			var time_needed = d.get('cultivation_time', 60.0)
			var pct = min(progress / time_needed * 100.0, 100.0)
			var info = d.get('name', '弟子') + " Lv." + str(d.get('level', 1)) + "  修炼进度：" + str(int(pct)) + "%"
			vbox.add_child(_pl(info, Color(0.7, 0.7, 0.9)))

func clear_children():
	for child in get_children():
		remove_child(child)
		child.queue_free()
