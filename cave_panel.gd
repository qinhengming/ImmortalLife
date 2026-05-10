extends PanelContainer

var cave_level: int = 1
var cave_buildings: Dictionary = {}

# 由主脚本注入的数据引用
var _spiritual_energy: float = 0.0
var _realm_level: int = 1
var _learned_recipes: Array = []
var _pill_inventory: Dictionary = {}

signal upgrade_cave_requested()
signal building_action_requested(bid: String)
signal craft_pill_requested(recipe_name: String)
signal use_pill_requested(pill_name: String)

const BUILDING_DEFS = {
	'alchemy_furnace': {
		'name': '炼丹炉',
		'desc': '炼制各类丹药，等级越高炼制消耗越低',
		'max_level': 5,
		'base_cost': 1000,
		'cost_growth': 2.0,
		'unlock_realm': 1,
		'init_unlocked': true,
		'color': Color(1.0, 0.6, 0.2),
	},
	'spirit_array': {
		'name': '聚灵阵',
		'desc': '汇聚天地灵气，提升修炼效率',
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
		'unlock_realm': 5,
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

func set_state(level: int, buildings: Dictionary, energy: float, realm_lv: int, recipes: Array, pills: Dictionary):
	cave_level = level
	cave_buildings = buildings.duplicate()
	_spiritual_energy = energy
	_realm_level = realm_lv
	_learned_recipes = recipes
	_pill_inventory = pills.duplicate()

func _make_card_bg(color: Color, border: Color = Color(0,0,0,0)) -> StyleBoxFlat:
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

func _label(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

func refresh():
	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	# === 洞府信息卡 ===
	var info_card = PanelContainer.new()
	info_card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.12, 0.16, 0.12)))
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 4)
	info_card.add_child(info_vbox)

	info_vbox.add_child(_label("洞府等级：" + str(cave_level), Color(0.3, 1.0, 0.6), 16))

	var cave_cost = 5000 * int(pow(2, cave_level))
	var can_afford_cave = _spiritual_energy >= cave_cost

	var cave_row = HBoxContainer.new()
	cave_row.add_child(_label("升级消耗：" + str(cave_cost) + "灵气", Color(0.7, 0.7, 0.8), 11))
	var cave_btn = Button.new()
	cave_btn.text = "升级洞府"
	if not can_afford_cave:
		cave_btn.disabled = true
	cave_btn.pressed.connect(func(): upgrade_cave_requested.emit())
	cave_row.add_child(cave_btn)
	info_vbox.add_child(cave_row)

	list.add_child(info_card)
	list.add_child(HSeparator.new())

	# === 建筑物列表 ===
	var bh = _label("── 建筑物 ──", Color(0.3, 0.8, 1.0), 13)
	bh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bh.add_theme_constant_override("margin_bottom", 4)
	list.add_child(bh)

	for bid in BUILDING_DEFS:
		_build_building_card(list, bid)

	# === 炼丹区域（炼丹炉已解锁） ===
	if is_building_unlocked('alchemy_furnace') and get_building_level('alchemy_furnace') >= 1:
		_build_alchemy_section(list)

func _build_building_card(list: VBoxContainer, bid: String):
	var defs = BUILDING_DEFS[bid]
	var level = get_building_level(bid)
	var unlocked = is_building_unlocked(bid)
	var maxed = unlocked and level >= defs.max_level

	var card = PanelContainer.new()
	if unlocked:
		card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.12, 0.14, 0.18), defs.color * 0.4))
	else:
		card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.1, 0.1, 0.12)))

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	# 名称 + 等级
	var name_label = _label("", Color(0.7, 0.7, 0.9), 13)
	if unlocked:
		name_label.text = defs['name'] + "  Lv." + str(level) + "/" + str(defs.max_level)
		name_label.add_theme_color_override("font_color", defs.color)
	else:
		name_label.text = "??? " + defs['name'] + "（未解锁）"
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(name_label)

	# 描述
	vbox.add_child(_label(defs['desc'], Color(0.55, 0.55, 0.7), 11))

	# 按钮区域
	if maxed:
		var ml = _label("已满级", Color(0.5, 0.5, 0.5), 11)
		hbox.add_child(ml)
	elif unlocked:
		var cost = get_upgrade_cost(bid)
		var can_afford = _spiritual_energy >= cost
		var btn = Button.new()
		btn.text = "升级（" + str(cost) + "灵）"
		btn.disabled = not can_afford
		var b_id = bid
		btn.pressed.connect(func(): building_action_requested.emit(b_id))
		hbox.add_child(btn)
	else:
		# 未解锁 — 检查境界
		var need_realm = defs.unlock_realm
		var realm_ok = _realm_level >= need_realm
		var cost = defs.base_cost
		var can_afford_unlock = _spiritual_energy >= cost
		var btn = Button.new()
		if realm_ok:
			btn.text = "解锁（" + str(cost) + "灵）"
			btn.disabled = not can_afford_unlock
		else:
			btn.text = "境界不足"
			btn.disabled = true
		var b_id = bid
		btn.pressed.connect(func(): building_action_requested.emit(b_id))
		hbox.add_child(btn)

	list.add_child(card)

func _build_alchemy_section(list: VBoxContainer):
	list.add_child(HSeparator.new())

	var ah = _label("── 炼丹 ──", Color(0.3, 0.8, 1.0), 13)
	ah.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(ah)

	if _learned_recipes.is_empty():
		var e = _label("尚未学会任何丹方，请在商店购买", Color(0.5, 0.5, 0.6), 11)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(e)
	else:
		var furnace_level = get_building_level('alchemy_furnace')
		var cost_reduction = 1.0 - furnace_level * 0.05  # 每级减5%消耗

		for recipe in _learned_recipes:
			var row = HBoxContainer.new()
			var info = _label(recipe['name'] + "  " + recipe['desc'], Color(0.7, 0.7, 0.9), 12)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)

			var craft_cost = int(recipe['craft_cost'] * cost_reduction)
			var cost_label = _label(str(craft_cost) + "灵", Color(0.9, 0.7, 0.3), 11)
			row.add_child(cost_label)

			var can_craft = _spiritual_energy >= craft_cost
			var btn = Button.new()
			btn.text = "炼制"
			btn.disabled = not can_craft
			var r_name = recipe['name']
			btn.pressed.connect(func(): craft_pill_requested.emit(r_name))
			row.add_child(btn)
			list.add_child(row)

	list.add_child(HSeparator.new())

	# 丹药背包
	var pt = _label("── 丹药背包 ──", Color(0.9, 0.6, 0.3), 12)
	pt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(pt)

	if _pill_inventory.is_empty():
		var e = _label("暂无丹药", Color(0.5, 0.5, 0.6), 11)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(e)
	else:
		for pill_name in _pill_inventory:
			var count = _pill_inventory[pill_name]
			if count <= 0:
				continue
			var row = HBoxContainer.new()
			var info = _label(pill_name + " x" + str(count), Color(0.9, 0.7, 0.5), 12)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)
			var btn = Button.new()
			btn.text = "使用"
			var pn = pill_name
			btn.pressed.connect(func(): use_pill_requested.emit(pn))
			row.add_child(btn)
			list.add_child(row)
