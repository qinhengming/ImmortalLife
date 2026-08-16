extends PanelContainer

const UI := preload("res://scripts/ui_common.gd")

signal back_requested()
signal upgrade_requested()

var _building_data: Dictionary = {}
var _spiritual_energy: float = 0.0
var _sect_materials: Dictionary = {}
var _disciple_count: int = 0
var _disciple_capacity: int = 3

func _format_num(n: float) -> String:
	return UI.format_big(n)

func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	return UI.lbl(text, color, font_size)

func set_state(building: Dictionary, energy: float, materials: Dictionary, disciple_count: int, disciple_capacity: int):
	_building_data = building
	_spiritual_energy = energy
	_sect_materials = materials
	_disciple_count = disciple_count
	_disciple_capacity = disciple_capacity

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
	var title = _pl("── 灵居 ──", Color(0.3, 0.8, 0.5), 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	vbox.add_child(top_bar)
	vbox.add_child(HSeparator.new())

	var lv = _building_data.get('level', 0)
	vbox.add_child(_pl("灵居等级：" + str(lv) + " / 10", Color(0.3, 0.8, 0.5)))
	vbox.add_child(_pl("弟子居所，每级提供5名弟子的居住空间。"))

	var cap_color = Color(1.0, 0.35, 0.35) if _disciple_count >= _disciple_capacity else Color(0.3, 1.0, 0.3)
	vbox.add_child(_pl("弟子数量：" + str(_disciple_count) + " / " + str(_disciple_capacity), cap_color, 15))
	vbox.add_child(HSeparator.new())

	var next_lv = lv + 1
	if next_lv <= 10:
		var cost = int(1000 * pow(2.0, lv))
		var mat_name = "灵木"
		var mat_cost = 3 + lv * 2
		var has_mat = _sect_materials.get(mat_name, 0) >= mat_cost
		var can_afford = _spiritual_energy >= cost and has_mat

		vbox.add_child(_pl("升级至" + str(next_lv) + "级需求："))
		vbox.add_child(_pl("  灵气：" + _format_num(cost), Color(0.3, 1.0, 0.3) if _spiritual_energy >= cost else Color(1.0, 0.35, 0.35)))
		vbox.add_child(_pl("  " + mat_name + "：" + str(mat_cost) + "（拥有：" + str(_sect_materials.get(mat_name, 0)) + "）", Color(0.3, 1.0, 0.3) if has_mat else Color(1.0, 0.35, 0.35)))

		var next_cap = 3 + next_lv * 5
		vbox.add_child(_pl("升级后弟子上限：" + str(_disciple_capacity) + " → " + str(next_cap), Color(0.3, 0.8, 0.5)))

		var btn = Button.new()
		btn.text = "升级灵居"
		btn.add_theme_font_size_override("font_size", 13)
		btn.custom_minimum_size = Vector2(120, 32)
		btn.disabled = not can_afford
		if not can_afford:
			btn.text = "资源不足"
		btn.pressed.connect(func(): upgrade_requested.emit())
		vbox.add_child(btn)
	else:
		vbox.add_child(_pl("灵居已达最高等级！", Color(0.3, 1.0, 0.3)))

func clear_children():
	for child in get_children():
		remove_child(child)
		child.queue_free()
