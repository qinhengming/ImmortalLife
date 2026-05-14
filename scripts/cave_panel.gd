extends PanelContainer

var cave_level: int = 1
var cave_buildings: Dictionary = {}

var _spiritual_energy: float = 0.0
var _realm_level: int = 1
var _learned_recipes: Array = []
var _pill_inventory: Dictionary = {}
var _learned_arrays: Array = []
var _active_array: String = ""
var _shop_arrays: Array = []
var _furnace_inventory: Array = []
var _equipped_furnaces: Array = []

var _current_view: String = "overview"
var _building_panels: Dictionary = {}
var _overview_nodes: Array = []

signal upgrade_cave_requested()
signal building_action_requested(bid: String)
signal craft_pill_requested(recipe_name: String)
signal use_pill_requested(pill_name: String)
signal back_requested()
signal set_array_requested(array_name: String)
signal equip_furnace_requested(slot_index: int, inventory_index: int)
signal unequip_furnace_requested(slot_index: int)

const BUILDING_DEFS = {
	'alchemy_furnace': {
		'name': '炼丹房',
		'desc': '炼制丹药，安装丹炉提升炼制速度与成功率',
		'max_level': 5,
		'base_cost': 1000,
		'cost_growth': 2.0,
		'unlock_realm': 1,
		'init_unlocked': true,
		'color': Color(1.0, 0.6, 0.2),
	},
	'spirit_array': {
		'name': '聚灵阵',
		'desc': '汇聚天地灵气，布置阵法提升修炼效率',
		'max_level': 10,
		'base_cost': 500,
		'cost_growth': 1.5,
		'unlock_realm': 1,
		'init_unlocked': true,
		'color': Color(0.3, 0.8, 1.0),
	},
	'cultivation_room': {
		'name': '修炼室',
		'desc': '加速修炼速度',
		'max_level': 10,
		'base_cost': 800,
		'cost_growth': 1.5,
		'unlock_realm': 2,
		'init_unlocked': true,
		'color': Color(0.3, 1.0, 0.5),
	},
	'herb_garden': {
		'name': '灵药圃',
		'desc': '培育灵药，随时间产出灵气',
		'max_level': 10,
		'base_cost': 2000,
		'cost_growth': 2.0,
		'unlock_realm': 3,
		'init_unlocked': false,
		'color': Color(0.2, 0.8, 0.3),
	},
	'library': {
		'name': '藏经阁',
		'desc': '参悟功法奥秘，提升修炼速度',
		'max_level': 5,
		'base_cost': 5000,
		'cost_growth': 2.5,
		'unlock_realm': 14,
		'init_unlocked': false,
		'color': Color(0.7, 0.3, 0.95),
	},
}

func get_building_level(bid: String) -> int:
	if cave_buildings.has(bid):
		return cave_buildings[bid].get('level', 0)
	return 0

func is_building_unlocked(bid: String) -> bool:
	if cave_buildings.has(bid):
		return cave_buildings[bid].get('unlocked', false)
	return BUILDING_DEFS.get(bid, {}).get('init_unlocked', false)

func get_upgrade_cost(bid: String) -> int:
	var defs = BUILDING_DEFS[bid]
	var level = get_building_level(bid)
	return int(defs.base_cost * pow(defs.cost_growth, level))

func set_state(level: int, buildings: Dictionary, energy: float, realm_lv: int, recipes: Array, pills: Dictionary, learned_arrs: Array = [], active_arr: String = "", shop_arrs: Array = [], furnace_inv: Array = [], equipped_furns: Array = []):
	cave_level = level
	cave_buildings = buildings.duplicate()
	_spiritual_energy = energy
	_realm_level = realm_lv
	_learned_recipes = recipes
	_pill_inventory = pills.duplicate()
	_learned_arrays = learned_arrs
	_active_array = active_arr
	_shop_arrays = shop_arrs
	_furnace_inventory = furnace_inv.duplicate()
	_equipped_furnaces = equipped_furns.duplicate()

func _make_card_bg(color: Color, border: Color = Color(0,0,0,0)) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	if border.a > 0:
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_width_bottom = 2
		s.border_color = border
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _label(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

func _format_num(n: float) -> String:
	return _format_big(n)

const BIG_UNITS = ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']

func _format_big(n: float) -> String:
	if n < 10000:
		return str(int(n))
	var val = n
	var unit_idx = 0
	while val >= 10000 and unit_idx < BIG_UNITS.size() - 1:
		val /= 10000.0
		unit_idx += 1
	return str(val).pad_decimals(1) + BIG_UNITS[unit_idx]

func _update_visibility():
	var show_overview = (_current_view == "overview")
	for node in _overview_nodes:
		node.visible = show_overview
	for bid in _building_panels:
		_building_panels[bid].visible = (_current_view == bid)

func _enter_building(bid: String):
	_current_view = bid
	_update_visibility()

	var panel = _building_panels[bid]
	var building = cave_buildings.get(bid, {'level': 0, 'unlocked': false})

	match bid:
		"alchemy_furnace":
			panel.set_state(building, _spiritual_energy, _learned_recipes, _pill_inventory, _furnace_inventory, _equipped_furnaces)
		"spirit_array":
			panel.set_state(building, _spiritual_energy, _learned_arrays, _active_array, _shop_arrays)
		_:
			panel.set_state(building, _spiritual_energy)

	panel.refresh()

func _on_building_back():
	_current_view = "overview"
	_update_visibility()
	refresh()

func refresh():
	if _current_view == "overview":
		_build_overview()
	else:
		var bid = _current_view
		var panel = _building_panels[bid]
		var building = cave_buildings.get(bid, {'level': 0, 'unlocked': false})
		match bid:
			"alchemy_furnace":
				panel.set_state(building, _spiritual_energy, _learned_recipes, _pill_inventory, _furnace_inventory, _equipped_furnaces)
			"spirit_array":
				panel.set_state(building, _spiritual_energy, _learned_arrays, _active_array, _shop_arrays)
			_:
				panel.set_state(building, _spiritual_energy)
		panel.refresh()

func _build_overview():
	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	# === 洞府信息卡 ===
	var info_card = PanelContainer.new()
	info_card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.08, 0.12, 0.18), Color(0.15, 0.35, 0.35)))
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 6)
	info_card.add_child(info_vbox)

	info_vbox.add_child(_label("洞府等级：" + str(cave_level), Color(0.3, 1.0, 0.6), 18))

	var cave_cost = 5000 * int(pow(2, cave_level))
	var can_afford_cave = _spiritual_energy >= cave_cost

	var cost_row = HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 8)
	cost_row.add_child(_label("升级消耗：" + _format_num(cave_cost) + " 灵气", Color(0.7, 0.7, 0.8), 12))

	var cave_btn = Button.new()
	cave_btn.text = "升级洞府"
	cave_btn.add_theme_font_size_override("font_size", 13)
	if not can_afford_cave:
		cave_btn.disabled = true
	cave_btn.pressed.connect(func(): upgrade_cave_requested.emit())
	cost_row.add_child(cave_btn)
	info_vbox.add_child(cost_row)
	info_vbox.add_child(_label("洞府等级影响所有建筑效果", Color(0.4, 0.5, 0.6), 10))

	list.add_child(info_card)

	# === 建筑物列表 ===
	var building_header = HBoxContainer.new()
	var bh = _label("── 建筑物 ──", Color(0.35, 0.85, 1.0), 14)
	bh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_header.add_child(bh)
	list.add_child(building_header)

	for bid in BUILDING_DEFS:
		_build_building_card(list, bid)

func _build_building_card(list: VBoxContainer, bid: String):
	var defs = BUILDING_DEFS[bid]
	var level = get_building_level(bid)
	var unlocked = is_building_unlocked(bid)
	var maxed = unlocked and level >= defs.max_level

	var card = PanelContainer.new()
	if unlocked:
		card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.1, 0.13, 0.2), defs.color))
	else:
		card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.08, 0.08, 0.1)))

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 4)
	card.add_child(main_vbox)

	var top_row = HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 8)

	var name_vbox = VBoxContainer.new()
	name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_theme_constant_override("separation", 2)

	var name_label = _label("", Color(0.7, 0.7, 0.9), 14)
	if unlocked:
		name_label.text = defs['name'] + "  Lv." + str(level) + "/" + str(defs.max_level)
		name_label.add_theme_color_override("font_color", defs.color)
	else:
		name_label.text = "??? " + defs['name'] + "（未解锁）"
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	name_vbox.add_child(name_label)
	name_vbox.add_child(_label(defs['desc'], Color(0.55, 0.55, 0.7), 11))
	top_row.add_child(name_vbox)

	if maxed:
		var ml = _label("已满级", Color(0.4, 0.8, 0.4), 12)
		ml.add_theme_constant_override("margin_top", 4)
		top_row.add_child(ml)
	elif unlocked:
		var cost = get_upgrade_cost(bid)
		var can_afford = _spiritual_energy >= cost
		var btn = Button.new()
		btn.text = "升级（" + _format_num(cost) + "灵）"
		btn.add_theme_font_size_override("font_size", 11)
		btn.disabled = not can_afford
		var b_id = bid
		btn.pressed.connect(func(): building_action_requested.emit(b_id))
		top_row.add_child(btn)
	else:
		var need_realm = defs.unlock_realm
		var realm_ok = _realm_level >= need_realm
		var cost = defs.base_cost
		var can_afford_unlock = _spiritual_energy >= cost
		var btn = Button.new()
		btn.add_theme_font_size_override("font_size", 11)
		if realm_ok:
			btn.text = "解锁（" + _format_num(cost) + "灵）"
			btn.disabled = not can_afford_unlock
		else:
			btn.text = "境界不足"
			btn.disabled = true
		var b_id = bid
		btn.pressed.connect(func(): building_action_requested.emit(b_id))
		top_row.add_child(btn)

	main_vbox.add_child(top_row)

	if unlocked:
		var enter_btn = Button.new()
		enter_btn.text = "▸ 进入 " + defs['name']
		enter_btn.add_theme_font_size_override("font_size", 13)
		enter_btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
		enter_btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
		var enter_style = StyleBoxFlat.new()
		enter_style.bg_color = defs.color * 0.25
		enter_style.corner_radius_top_left = 4
		enter_style.corner_radius_top_right = 4
		enter_style.corner_radius_bottom_left = 4
		enter_style.corner_radius_bottom_right = 4
		enter_style.content_margin_left = 8
		enter_style.content_margin_right = 8
		enter_style.content_margin_top = 4
		enter_style.content_margin_bottom = 4
		enter_btn.add_theme_stylebox_override("normal", enter_style)
		var enter_hover = enter_style.duplicate()
		enter_hover.bg_color = defs.color * 0.4
		enter_btn.add_theme_stylebox_override("hover", enter_hover)
		var b_id = bid
		enter_btn.pressed.connect(func(): _enter_building(b_id))
		main_vbox.add_child(enter_btn)

	list.add_child(card)

func _ready():
	# 收集总览节点引用
	_overview_nodes = [$VBox/TopBar, $VBox/Separator, $VBox/ScrollList]

	# 回主界面
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())

	# 动态加载建筑面板
	var panel_scenes = {
		"alchemy_furnace": "res://scenes/buildings/alchemy_furnace_panel.tscn",
		"spirit_array": "res://scenes/buildings/spirit_array_panel.tscn",
		"cultivation_room": "res://scenes/buildings/cultivation_room_panel.tscn",
		"herb_garden": "res://scenes/buildings/herb_garden_panel.tscn",
		"library": "res://scenes/buildings/library_panel.tscn",
	}

	for bid in panel_scenes:
		var scene = load(panel_scenes[bid])
		var panel = scene.instantiate()
		panel.visible = false
		$VBox.add_child(panel)
		_building_panels[bid] = panel

		# 连接信号
		panel.back_requested.connect(_on_building_back)
		panel.building_action_requested.connect(func(b_id: String): building_action_requested.emit(b_id))

		if bid == "alchemy_furnace":
			panel.craft_pill_requested.connect(func(rn: String): craft_pill_requested.emit(rn))
			panel.use_pill_requested.connect(func(pn: String): use_pill_requested.emit(pn))
			panel.equip_furnace_requested.connect(func(slot_idx: int, inv_idx: int): equip_furnace_requested.emit(slot_idx, inv_idx))
			panel.unequip_furnace_requested.connect(func(slot_idx: int): unequip_furnace_requested.emit(slot_idx))

		if bid == "spirit_array":
			panel.set_array_requested.connect(func(arr_name: String): set_array_requested.emit(arr_name))
