extends PanelContainer

const UI := preload("res://scripts/ui_common.gd")

signal back_requested()
signal upgrade_requested()

var _building_data: Dictionary = {}
var _sect_level: int = 1
var _spiritual_energy: float = 0.0
var _sect_materials: Dictionary = {}
var _sect_buildings: Dictionary = {}
var _realm_level: int = 1

func _format_num(n: float) -> String:
	return UI.format_big(n)

func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	return UI.lbl(text, color, font_size)

func set_state(building: Dictionary, sect_level: int, energy: float, materials: Dictionary, sect_buildings: Dictionary, realm_level: int):
	_building_data = building
	_sect_level = sect_level
	_spiritual_energy = energy
	_sect_materials = materials
	_sect_buildings = sect_buildings
	_realm_level = realm_level

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
	var title = _pl("── 宗门大殿 ──", Color(1.0, 0.84, 0.0), 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(title)
	vbox.add_child(top_bar)
	vbox.add_child(HSeparator.new())

	vbox.add_child(_pl("宗门等级：" + str(_sect_level), Color(1.0, 0.84, 0.0), 15))
	vbox.add_child(_pl("宗门大殿是宗门的核心建筑，提升其等级可解锁更多宗门建筑。"))

	var lv = _building_data.get('level', 0)
	vbox.add_child(_pl("当前大殿等级：" + str(lv) + " / 5"))

	if lv >= 2:
		vbox.add_child(_pl("已解锁：灵居", Color(0.3, 0.8, 0.5)))
	else:
		vbox.add_child(_pl("宗门2级解锁：灵居（提高弟子上限）", Color(0.5, 0.5, 0.5)))
	if lv >= 3:
		vbox.add_child(_pl("已解锁：接引台", Color(0.3, 0.6, 1.0)))
	else:
		vbox.add_child(_pl("宗门3级解锁：接引台（招收弟子）", Color(0.5, 0.5, 0.5)))
	if lv >= 4:
		vbox.add_child(_pl("已解锁：悟道堂", Color(0.7, 0.3, 1.0)))
	else:
		vbox.add_child(_pl("宗门4级解锁：悟道堂（加速弟子修炼）", Color(0.5, 0.5, 0.5)))

	vbox.add_child(HSeparator.new())

	var next_lv = lv + 1
	if next_lv <= 5:
		var cost = int(2000 * pow(2.5, lv))
		var mat_name = "灵木"
		var mat_cost = 5 + lv * 2
		var has_mat = _sect_materials.get(mat_name, 0) >= mat_cost
		var can_afford = _spiritual_energy >= cost and has_mat

		vbox.add_child(_pl("晋升至宗门" + str(next_lv) + "级需求："))
		var cost_label = _pl("  灵气：" + _format_num(cost), Color(0.3, 1.0, 0.3) if _spiritual_energy >= cost else Color(1.0, 0.35, 0.35))
		vbox.add_child(cost_label)
		var mat_label = _pl("  " + mat_name + "：" + str(mat_cost) + "（拥有：" + str(_sect_materials.get(mat_name, 0)) + "）", Color(0.3, 1.0, 0.3) if has_mat else Color(1.0, 0.35, 0.35))
		vbox.add_child(mat_label)

		var btn_upgrade = Button.new()
		btn_upgrade.text = "晋升宗门"
		btn_upgrade.add_theme_font_size_override("font_size", 13)
		btn_upgrade.custom_minimum_size = Vector2(120, 32)
		btn_upgrade.disabled = not can_afford
		if not can_afford:
			btn_upgrade.text = "资源不足"
		btn_upgrade.pressed.connect(func(): upgrade_requested.emit())
		vbox.add_child(btn_upgrade)
	else:
		vbox.add_child(_pl("宗门已达最高等级！", Color(1.0, 0.84, 0.0)))

func clear_children():
	for child in get_children():
		remove_child(child)
		child.queue_free()
