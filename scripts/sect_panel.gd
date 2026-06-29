extends PanelContainer

signal back_requested()
signal building_action_requested(building_id: String)
signal recruit_disciple_requested()
signal dismiss_disciple_requested(index: int)

const BIG_UNITS = ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']

const SECT_BUILDING_DEFS = {
	"sect_main_hall": {
		"name": "宗门大殿",
		"desc": "宗门核心建筑，提升宗门等级，解锁更多建筑",
		"max_level": 5,
		"base_cost": 2000,
		"cost_growth": 2.5,
		"unlock_realm": 37,
		"init_unlocked": true,
		"color": Color(1.0, 0.84, 0.0),
		"material": "灵木",
		"material_base": 5,
	},
	"spirit_residence": {
		"name": "灵居",
		"desc": "弟子居所，每级提供5名弟子的居住空间",
		"max_level": 10,
		"base_cost": 1000,
		"cost_growth": 2.0,
		"unlock_realm": 37,
		"init_unlocked": false,
		"require_building": "sect_main_hall",
		"require_level": 2,
		"color": Color(0.3, 0.8, 0.5),
		"material": "灵木",
		"material_base": 3,
	},
	"recruitment_platform": {
		"name": "接引台",
		"desc": "招收弟子的场所，等级影响弟子品级概率",
		"max_level": 5,
		"base_cost": 3000,
		"cost_growth": 3.0,
		"unlock_realm": 37,
		"init_unlocked": false,
		"require_building": "sect_main_hall",
		"require_level": 3,
		"color": Color(0.3, 0.6, 1.0),
		"material": "玄铁",
		"material_base": 5,
	},
	"enlightenment_hall": {
		"name": "悟道堂",
		"desc": "弟子修炼之地，每级+15%弟子修炼速度",
		"max_level": 5,
		"base_cost": 5000,
		"cost_growth": 3.5,
		"unlock_realm": 37,
		"init_unlocked": false,
		"require_building": "sect_main_hall",
		"require_level": 4,
		"color": Color(0.7, 0.3, 1.0),
		"material": "魂晶",
		"material_base": 3,
	},
}

const DISCIPLE_GRADES = [
	{"name": "凡质", "color": Color(0.6, 0.6, 0.6), "mana": 0.15, "hp": 25, "atk": 2, "def": 1},
	{"name": "良质", "color": Color(0.2, 0.8, 0.3), "mana": 0.4, "hp": 55, "atk": 6, "def": 4},
	{"name": "精英", "color": Color(0.2, 0.5, 1.0), "mana": 1.0, "hp": 100, "atk": 14, "def": 10},
	{"name": "绝世", "color": Color(0.9, 0.3, 0.9), "mana": 3.0, "hp": 220, "atk": 35, "def": 22},
	{"name": "传说", "color": Color(1.0, 0.7, 0.0), "mana": 8.0, "hp": 450, "atk": 70, "def": 45},
	{"name": "神话", "color": Color(1.0, 0.2, 0.2), "mana": 20.0, "hp": 900, "atk": 140, "def": 85},
]

const GRADE_WEIGHTS = [0.40, 0.28, 0.17, 0.09, 0.04, 0.02]

var _spiritual_energy: float = 0.0
var _realm_level: int = 1
var _sect_level: int = 1
var _sect_buildings: Dictionary = {}
var _sect_materials: Dictionary = {}
var _disciples: Array = []
var _disciple_capacity: int = 3
var _current_view: String = "overview"
var _current_tab: String = "buildings"
var _disciple_detail_index: int = -1
var _building_panels: Dictionary = {}
var _overview_container: VBoxContainer = null
var _main_vbox: VBoxContainer = null
var _top_bar_container: HBoxContainer = null
var _tab_btn_buildings: Button = null
var _tab_btn_disciples: Button = null

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

func set_state(data: Dictionary):
	_spiritual_energy = data.get('spiritual_energy', 0.0)
	_realm_level = data.get('realm_level', 1)
	_sect_level = data.get('sect_level', 1)
	_sect_buildings = data.get('sect_buildings', {})
	_sect_materials = data.get('sect_materials', {})
	_disciples = data.get('disciples', [])
	_disciple_capacity = data.get('disciple_capacity', 3)

func _ready():
	_build_ui()
	_init_building_panels()

func _build_ui():
	_main_vbox = VBoxContainer.new()
	_main_vbox.name = "MainVBox"
	_main_vbox.anchors_preset = Control.PRESET_FULL_RECT
	_main_vbox.offset_left = 0
	_main_vbox.offset_top = 0
	_main_vbox.offset_right = 0
	_main_vbox.offset_bottom = 0
	_main_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_main_vbox)

	_top_bar_container = HBoxContainer.new()
	_top_bar_container.name = "TopBar"

	var btn_back = Button.new()
	btn_back.text = "← 返回"
	btn_back.add_theme_font_size_override("font_size", 12)
	btn_back.pressed.connect(func():
		if _disciple_detail_index >= 0:
			_disciple_detail_index = -1
			refresh()
		else:
			back_requested.emit()
	)
	_top_bar_container.add_child(btn_back)

	var tab_bar = HBoxContainer.new()
	tab_bar.name = "TabBar"
	tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.add_theme_constant_override("separation", 4)

	_tab_btn_buildings = Button.new()
	_tab_btn_buildings.name = "BtnBuildings"
	_tab_btn_buildings.text = "建筑"
	_tab_btn_buildings.add_theme_font_size_override("font_size", 12)
	_tab_btn_buildings.pressed.connect(func(): _switch_tab("buildings"))
	tab_bar.add_child(_tab_btn_buildings)

	_tab_btn_disciples = Button.new()
	_tab_btn_disciples.name = "BtnDisciples"
	_tab_btn_disciples.text = "弟子"
	_tab_btn_disciples.add_theme_font_size_override("font_size", 12)
	_tab_btn_disciples.pressed.connect(func(): _switch_tab("disciples"))
	tab_bar.add_child(_tab_btn_disciples)

	_top_bar_container.add_child(tab_bar)

	var title = _pl("── 宗门 ──", Color(1.0, 0.84, 0.0), 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_bar_container.add_child(title)

	_main_vbox.add_child(_top_bar_container)
	_main_vbox.add_child(HSeparator.new())

	_overview_container = VBoxContainer.new()
	_overview_container.name = "OverviewVBox"
	_overview_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_overview_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_main_vbox.add_child(_overview_container)

func _init_building_panels():
	var panel_scripts = {
		"sect_main_hall": preload("res://scripts/buildings_sect/sect_main_hall_panel.gd"),
		"spirit_residence": preload("res://scripts/buildings_sect/spirit_residence_panel.gd"),
		"recruitment_platform": preload("res://scripts/buildings_sect/recruitment_platform_panel.gd"),
		"enlightenment_hall": preload("res://scripts/buildings_sect/enlightenment_hall_panel.gd"),
	}
	for bid in panel_scripts:
		var script = panel_scripts[bid]
		var panel = script.new()
		panel.name = bid
		panel.visible = false
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_main_vbox.add_child(panel)
		_building_panels[bid] = panel

		if bid == "sect_main_hall":
			panel.upgrade_requested.connect(func(): building_action_requested.emit("sect_main_hall"))
		elif bid == "spirit_residence":
			panel.upgrade_requested.connect(func(): building_action_requested.emit("spirit_residence"))
		elif bid == "recruitment_platform":
			panel.recruit_requested.connect(func(): recruit_disciple_requested.emit())
			panel.dismiss_requested.connect(func(idx): dismiss_disciple_requested.emit(idx))
		elif bid == "enlightenment_hall":
			panel.upgrade_requested.connect(func(): building_action_requested.emit("enlightenment_hall"))

		panel.back_requested.connect(_on_building_back)

func _switch_tab(tab: String):
	_current_tab = tab
	_disciple_detail_index = -1
	_update_tab_buttons()
	refresh()

func _update_tab_buttons():
	var active_color = Color(1.0, 0.84, 0.0)
	var inactive_color = Color(0.5, 0.5, 0.5)
	_tab_btn_buildings.add_theme_color_override("font_color", active_color if _current_tab == "buildings" else inactive_color)
	_tab_btn_disciples.add_theme_color_override("font_color", active_color if _current_tab == "disciples" else inactive_color)

func refresh():
	if _current_view == "overview":
		_update_visibility()
		_build_overview()
	else:
		_update_visibility()
		_refresh_current_building()

func _update_visibility():
	var is_overview = _current_view == "overview"
	_top_bar_container.visible = is_overview
	_overview_container.visible = is_overview
	for bid in _building_panels:
		_building_panels[bid].visible = (_current_view == bid)

func _build_overview():
	for child in _overview_container.get_children():
		_overview_container.remove_child(child)
		child.queue_free()

	_update_tab_buttons()

	_overview_container.add_child(_pl("宗门等级：" + str(_sect_level) + "  |  弟子：" + str(_disciples.size()) + "/" + str(_disciple_capacity), Color(1.0, 0.84, 0.0), 14))

	if _current_tab == "buildings":
		_build_buildings_tab()
	else:
		_build_disciples_tab()

func _build_buildings_tab():
	var mat_hbox = HBoxContainer.new()
	mat_hbox.add_theme_constant_override("separation", 15)
	for mat_name in ["灵木", "玄铁", "魂晶"]:
		var count = _sect_materials.get(mat_name, 0)
		var mat_color = Color(0.3, 0.8, 0.3)
		if mat_name == "玄铁":
			mat_color = Color(0.4, 0.5, 0.7)
		elif mat_name == "魂晶":
			mat_color = Color(0.9, 0.4, 1.0)
		mat_hbox.add_child(_pl(mat_name + ": " + str(count), mat_color, 12))
	_overview_container.add_child(mat_hbox)
	_overview_container.add_child(HSeparator.new())

	_overview_container.add_child(_pl("── 宗门建筑 ──", Color(0.3, 0.8, 1.0), 13))

	for bid in SECT_BUILDING_DEFS:
		_overview_container.add_child(_make_building_card(bid))

func _build_disciples_tab():
	if _disciple_detail_index >= _disciples.size():
		_disciple_detail_index = -1
	if _disciple_detail_index >= 0:
		_build_disciple_detail()
	else:
		_overview_container.add_child(HSeparator.new())

		if _disciples.size() > 0:
			_overview_container.add_child(_pl("── 弟子一览 ──", Color(0.3, 0.6, 1.0), 13))
			for i in range(_disciples.size()):
				_overview_container.add_child(_make_disciple_card(i))
		else:
			_overview_container.add_child(_pl("暂无弟子，升级宗门等级以解锁接引台招收弟子", Color(0.5, 0.5, 0.5)))

func _make_building_card(bid: String) -> PanelContainer:
	var def = SECT_BUILDING_DEFS[bid]
	var b_data = _sect_buildings.get(bid, {'level': 0, 'unlocked': false})
	var unlocked = b_data.get('unlocked', false)
	var level = b_data.get('level', 0)
	var maxed = level >= def['max_level']
	var can_unlock = not unlocked and _sect_level >= def.get('require_level', 1) and _can_unlock_requirement(def)

	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	if maxed:
		style.bg_color = Color(0.12, 0.16, 0.12)
	elif unlocked:
		style.bg_color = Color(0.14, 0.16, 0.18)
	else:
		style.bg_color = Color(0.16, 0.13, 0.14)
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
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var status = ""
	var name_color = def['color']
	if maxed:
		status = "（满级）"
		name_color = Color(0.3, 0.5, 0.3)
	elif unlocked:
		status = "（Lv." + str(level) + "）"
	else:
		status = "（未解锁）"
		name_color = Color(0.5, 0.5, 0.5)
	info_vbox.add_child(_pl(def['name'] + status, name_color, 13))

	var desc = def['desc']
	if not unlocked and def.has('require_building'):
		desc += " | 需要宗门" + str(def.get('require_level', 1)) + "级"
	info_vbox.add_child(_pl(desc, Color(0.5, 0.5, 0.6), 11))

	var btn_box = HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 4)
	hbox.add_child(btn_box)

	if maxed:
		var btn = Button.new()
		btn.text = "已满级"
		btn.disabled = true
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(60, 26)
		btn_box.add_child(btn)
	elif unlocked:
		if not maxed:
			var btid = bid
			var btn_up = Button.new()
			btn_up.text = "升级"
			btn_up.add_theme_font_size_override("font_size", 11)
			btn_up.custom_minimum_size = Vector2(52, 26)
			btn_up.pressed.connect(func(): building_action_requested.emit(btid))
			btn_box.add_child(btn_up)
		var btid2 = bid
		var btn_enter = Button.new()
		btn_enter.text = "进入"
		btn_enter.add_theme_font_size_override("font_size", 11)
		btn_enter.custom_minimum_size = Vector2(52, 26)
		btn_enter.pressed.connect(func(): _enter_building(btid2))
		btn_box.add_child(btn_enter)
	else:
		var btid3 = bid
		var btn_unlock = Button.new()
		if can_unlock:
			btn_unlock.text = "解锁"
			btn_unlock.pressed.connect(func(): building_action_requested.emit(btid3))
		else:
			btn_unlock.text = "条件不足"
			btn_unlock.disabled = true
		btn_unlock.add_theme_font_size_override("font_size", 11)
		btn_unlock.custom_minimum_size = Vector2(64, 26)
		btn_box.add_child(btn_unlock)

	return card

func _can_unlock_requirement(def: Dictionary) -> bool:
	if not def.has('require_building'):
		return true
	var req_bid = def['require_building']
	var req_data = _sect_buildings.get(req_bid, {})
	if not req_data.get('unlocked', false):
		return false
	return _sect_level >= def.get('require_level', 1)

func _make_disciple_card(index: int) -> PanelContainer:
	var d = _disciples[index]
	var grade_idx = d.get('grade', 0)
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

	var name_label = _pl(d.get('name', '弟子') + "  " + grade_data['name'], grade_data['color'], 13)
	info_vbox.add_child(name_label)

	var lv = d.get('level', 1)
	var stats = "Lv." + str(lv) + " | HP:" + str(int(d.get('hp', 0))) + "  ATK:" + str(int(d.get('atk', 0))) + "  DEF:" + str(int(d.get('def', 0))) + "  灵气:" + _format_num(d.get('mana', 0)) + "/秒"
	info_vbox.add_child(_pl(stats, Color(0.55, 0.55, 0.7), 11))

	var btn_box = HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 4)
	hbox.add_child(btn_box)

	var btn_detail = Button.new()
	btn_detail.text = "详情"
	btn_detail.add_theme_font_size_override("font_size", 11)
	btn_detail.custom_minimum_size = Vector2(48, 26)
	var idx = index
	btn_detail.pressed.connect(func():
		_disciple_detail_index = idx
		refresh()
	)
	btn_box.add_child(btn_detail)

	var btn_dismiss = Button.new()
	btn_dismiss.text = "逐出"
	btn_dismiss.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	btn_dismiss.add_theme_font_size_override("font_size", 11)
	btn_dismiss.custom_minimum_size = Vector2(48, 26)
	btn_dismiss.pressed.connect(func(): dismiss_disciple_requested.emit(idx))
	btn_box.add_child(btn_dismiss)

	return card

func _build_disciple_detail():
	var d = _disciples[_disciple_detail_index]
	var grade_idx = d.get('grade', 0)
	var grade_data = DISCIPLE_GRADES[grade_idx] if grade_idx < DISCIPLE_GRADES.size() else DISCIPLE_GRADES[0]

	var detail_card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.12, 0.18)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	detail_card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	detail_card.add_child(vbox)

	vbox.add_child(_pl("── 弟子详情 ──", grade_data['color'], 16))

	var name_line = HBoxContainer.new()
	name_line.add_child(_pl(d.get('name', '弟子'), Color(1.0, 1.0, 1.0), 18))
	name_line.add_child(_pl("  " + grade_data['name'], grade_data['color'], 16))
	name_line.add_child(_pl("  Lv." + str(d.get('level', 1)), Color(0.8, 0.8, 0.8), 14))
	vbox.add_child(name_line)

	vbox.add_child(HSeparator.new())

	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 20)
	stats_grid.add_theme_constant_override("v_separation", 6)

	var hp_val = d.get('hp', 0)
	var atk_val = d.get('atk', 0)
	var def_val = d.get('def', 0)
	var mana_val = d.get('mana', 0)

	stats_grid.add_child(_pl("生命 HP", Color(0.6, 0.6, 0.6), 12))
	stats_grid.add_child(_pl(str(int(hp_val)), Color(0.3, 1.0, 0.3), 12))
	stats_grid.add_child(_pl("攻击 ATK", Color(0.6, 0.6, 0.6), 12))
	stats_grid.add_child(_pl(str(int(atk_val)), Color(1.0, 0.5, 0.3), 12))
	stats_grid.add_child(_pl("防御 DEF", Color(0.6, 0.6, 0.6), 12))
	stats_grid.add_child(_pl(str(int(def_val)), Color(0.3, 0.6, 1.0), 12))
	stats_grid.add_child(_pl("灵气产出", Color(0.6, 0.6, 0.6), 12))
	stats_grid.add_child(_pl(_format_num(mana_val) + "/秒", Color(1.0, 0.84, 0.0), 12))
	vbox.add_child(stats_grid)

	vbox.add_child(HSeparator.new())

	var progress = d.get('cultivation_progress', 0.0)
	var time_needed = d.get('cultivation_time', 30.0)
	var pct = min(progress / time_needed * 100.0, 100.0)
	vbox.add_child(_pl("修炼进度：%.1f%%" % pct, Color(0.7, 0.5, 1.0), 12))

	var progress_bar = ProgressBar.new()
	progress_bar.custom_minimum_size = Vector2(0, 16)
	progress_bar.max_value = time_needed
	progress_bar.value = progress
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(progress_bar)

	vbox.add_child(_pl("升级还需：" + _format_num(max(time_needed - progress, 0)) + " 秒", Color(0.5, 0.5, 0.6), 11))

	vbox.add_child(HSeparator.new())

	var btn_box = HBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 8)

	var btn_back_list = Button.new()
	btn_back_list.text = "← 返回列表"
	btn_back_list.add_theme_font_size_override("font_size", 12)
	btn_back_list.custom_minimum_size = Vector2(100, 30)
	btn_back_list.pressed.connect(func():
		_disciple_detail_index = -1
		refresh()
	)
	btn_box.add_child(btn_back_list)

	var btn_dismiss = Button.new()
	btn_dismiss.text = "逐出弟子"
	btn_dismiss.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	btn_dismiss.add_theme_font_size_override("font_size", 12)
	btn_dismiss.custom_minimum_size = Vector2(90, 30)
	var dismiss_idx = _disciple_detail_index
	btn_dismiss.pressed.connect(func():
		_disciple_detail_index = -1
		dismiss_disciple_requested.emit(dismiss_idx)
	)
	btn_box.add_child(btn_dismiss)

	vbox.add_child(btn_box)

	_overview_container.add_child(detail_card)

func _enter_building(bid: String):
	_disciple_detail_index = -1
	_current_view = bid
	_update_visibility()
	_refresh_current_building()

func _on_building_back():
	_current_view = "overview"
	refresh()

func _refresh_current_building():
	var panel = _building_panels.get(_current_view)
	if not panel:
		return
	var b_data = _sect_buildings.get(_current_view, {'level': 0, 'unlocked': false})

	if _current_view == "sect_main_hall":
		panel.set_state(b_data, _sect_level, _spiritual_energy, _sect_materials, _sect_buildings, _realm_level)
	elif _current_view == "spirit_residence":
		panel.set_state(b_data, _spiritual_energy, _sect_materials, _disciples.size(), _disciple_capacity)
	elif _current_view == "recruitment_platform":
		panel.set_state(b_data, _spiritual_energy, _disciples, _disciple_capacity)
	elif _current_view == "enlightenment_hall":
		panel.set_state(b_data, _spiritual_energy, _sect_materials, _disciples)

	panel.refresh()
