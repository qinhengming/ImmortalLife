extends PanelContainer

const UI := preload("res://scripts/ui_common.gd")

var cave_level: int = 1
var cave_buildings: Dictionary = {}

var _spiritual_energy: float = 0.0
var _ore: float = 0.0
var _wood: float = 0.0
var _ore_rate: float = 0.0
var _wood_rate: float = 0.0
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
var _upgrade_queue: Array = []
var _upgrade_limit: int = 1
var _queue_progress_bars: Dictionary = {}
var _ore_wood_label: Label = null
var _cave_upgrade_btn: Button = null

signal upgrade_cave_requested()
signal building_action_requested(bid: String)
signal cancel_upgrade_requested(bid: String)
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
		'max_level': -1,
		'base_cost': 1000,
		'cost_growth': 2.0,
		'currency': 'both',
		'base_time': 20,
		'time_growth': 1.25,
		'unlock_realm': 1,
		'init_unlocked': true,
		'color': Color(1.0, 0.6, 0.2),
	},
	'spirit_array': {
		'name': '聚灵阵',
		'desc': '汇聚天地灵气，布置阵法提升修炼效率',
		'max_level': -1,
		'base_cost': 500,
		'cost_growth': 1.5,
		'currency': 'both',
		'base_time': 15,
		'time_growth': 1.2,
		'unlock_realm': 1,
		'init_unlocked': true,
		'color': Color(0.3, 0.8, 1.0),
	},
	'cultivation_room': {
		'name': '修炼室',
		'desc': '加速修炼速度',
		'max_level': -1,
		'base_cost': 800,
		'cost_growth': 1.5,
		'currency': 'both',
		'base_time': 15,
		'time_growth': 1.2,
		'unlock_realm': 2,
		'init_unlocked': true,
		'color': Color(0.3, 1.0, 0.5),
	},
	'herb_garden': {
		'name': '灵药圃',
		'desc': '培育灵药，随时间产出灵气',
		'max_level': -1,
		'base_cost': 2000,
		'cost_growth': 2.0,
		'currency': 'both',
		'base_time': 20,
		'time_growth': 1.2,
		'unlock_realm': 3,
		'init_unlocked': false,
		'color': Color(0.2, 0.8, 0.3),
	},
	'library': {
		'name': '藏经阁',
		'desc': '参悟功法奥秘，提升修炼速度',
		'max_level': -1,
		'base_cost': 5000,
		'cost_growth': 2.5,
		'currency': 'both',
		'base_time': 30,
		'time_growth': 1.3,
		'unlock_realm': 14,
		'init_unlocked': false,
		'color': Color(0.7, 0.3, 0.95),
	},
	'spirit_mine': {
		'name': '灵矿场',
		'desc': '开采灵脉，随时间产出灵矿',
		'max_level': -1,
		'base_cost': 30,
		'cost_growth': 1.5,
		'currency': 'ore',
		'base_time': 10,
		'time_growth': 1.15,
		'unlock_realm': 1,
		'init_unlocked': true,
		'init_level': 1,
		'rate_per_level': 1.0,
		'color': Color(0.55, 0.7, 0.95),
	},
	'spirit_wood': {
		'name': '灵木林',
		'desc': '种植灵木，随时间产出灵木',
		'max_level': -1,
		'base_cost': 30,
		'cost_growth': 1.5,
		'currency': 'wood',
		'base_time': 10,
		'time_growth': 1.15,
		'unlock_realm': 1,
		'init_unlocked': true,
		'init_level': 1,
		'rate_per_level': 1.0,
		'color': Color(0.7, 0.55, 0.35),
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

## 建筑升级货币：'energy'(灵气) / 'ore'(灵矿) / 'wood'(灵木) / 'both'(灵矿+灵木)，默认灵气
func get_upgrade_currency(bid: String) -> String:
	return BUILDING_DEFS.get(bid, {}).get('currency', 'energy')

func set_state(level: int, buildings: Dictionary, energy: float, realm_lv: int, recipes: Array, pills: Dictionary, learned_arrs: Array = [], active_arr: String = "", shop_arrs: Array = [], furnace_inv: Array = [], equipped_furns: Array = [], ore: float = 0.0, wood: float = 0.0, ore_rate: float = 0.0, wood_rate: float = 0.0, upgrade_queue: Array = [], upgrade_limit: int = 1):
	cave_level = level
	cave_buildings = buildings.duplicate()
	_spiritual_energy = energy
	_ore = ore
	_wood = wood
	_ore_rate = ore_rate
	_wood_rate = wood_rate
	_realm_level = realm_lv
	_learned_recipes = recipes
	_pill_inventory = pills.duplicate()
	_learned_arrays = learned_arrs
	_active_array = active_arr
	_shop_arrays = shop_arrs
	_furnace_inventory = furnace_inv.duplicate()
	_equipped_furnaces = equipped_furns.duplicate()
	_upgrade_queue = upgrade_queue.duplicate()
	_upgrade_limit = upgrade_limit

func _make_card_bg(color: Color, border: Color = Color(0,0,0,0)) -> StyleBoxFlat:
	# 统一到 UI 规范：圆角6、内边距10/6
	return UI.card_bg(color, 6, border)

func _label(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	return UI.lbl(text, color, size)

func _format_num(n: float) -> String:
	return UI.format_big(n)

func _format_big(n: float) -> String:
	return UI.format_big(n)

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
			panel.set_state(building, _spiritual_energy, _learned_recipes, _pill_inventory, _furnace_inventory, _equipped_furnaces, _ore, _wood)
		"spirit_array":
			panel.set_state(building, _spiritual_energy, _learned_arrays, _active_array, _shop_arrays, _ore, _wood)
		"spirit_mine", "spirit_wood":
			panel.set_state(building, _ore, _wood, _ore_rate, _wood_rate)
		_:
			panel.set_state(building, _spiritual_energy, _ore, _wood)

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
				panel.set_state(building, _spiritual_energy, _learned_recipes, _pill_inventory, _furnace_inventory, _equipped_furnaces, _ore, _wood)
			"spirit_array":
				panel.set_state(building, _spiritual_energy, _learned_arrays, _active_array, _shop_arrays, _ore, _wood)
			"spirit_mine", "spirit_wood":
				panel.set_state(building, _ore, _wood, _ore_rate, _wood_rate)
			_:
				panel.set_state(building, _spiritual_energy, _ore, _wood)
		panel.refresh()

func _build_overview():
	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()
	_queue_progress_bars.clear()

	# === 洞府信息卡 ===
	var info_card = PanelContainer.new()
	info_card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.08, 0.12, 0.18), Color(0.15, 0.35, 0.35)))
	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 6)
	info_card.add_child(info_vbox)

	info_vbox.add_child(_label("洞府等级：" + str(cave_level), Color(0.3, 1.0, 0.6), 18))

	var cave_ore_cost = int(100 * pow(2, cave_level))
	var cave_wood_cost = int(100 * pow(2, cave_level))
	var can_afford_cave = _ore >= cave_ore_cost and _wood >= cave_wood_cost

	_ore_wood_label = _label("灵矿：" + _format_num(int(_ore)) + "（+" + _format_num(int(_ore_rate)) + "/秒）   灵木：" + _format_num(int(_wood)) + "（+" + _format_num(int(_wood_rate)) + "/秒）", Color(0.9, 0.75, 0.3), 12)
	_ore_wood_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ore_wood_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_child(_ore_wood_label)

	var cost_row = HBoxContainer.new()
	cost_row.add_theme_constant_override("separation", 8)
	cost_row.add_child(_label("升级消耗：" + _format_num(cave_ore_cost) + " 灵矿 + " + _format_num(cave_wood_cost) + " 灵木", Color(0.7, 0.7, 0.8), 12))

	var cave_btn = Button.new()
	cave_btn.text = "升级洞府"
	cave_btn.add_theme_font_size_override("font_size", 13)
	if not can_afford_cave:
		cave_btn.disabled = true
	cave_btn.pressed.connect(func(): upgrade_cave_requested.emit())
	_cave_upgrade_btn = cave_btn
	cost_row.add_child(cave_btn)
	info_vbox.add_child(cost_row)
	info_vbox.add_child(_label("洞府等级影响所有建筑效果", Color(0.4, 0.5, 0.6), 10))

	list.add_child(info_card)

	_build_upgrade_queue_section(list)

	# === 建筑物列表 ===
	var building_header = HBoxContainer.new()
	var bh = _label("── 建筑物 ──", Color(0.35, 0.85, 1.0), 14)
	bh.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bh.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	building_header.add_child(bh)
	list.add_child(building_header)

	for bid in BUILDING_DEFS:
		_build_building_card(list, bid)

func _build_upgrade_queue_section(list: VBoxContainer):
	var header = HBoxContainer.new()
	var hl = _label("── 建筑升级队列 ──", Color(0.9, 0.6, 0.3), 14)
	hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(hl)
	list.add_child(header)

	var active_n = 0
	for bid in cave_buildings:
		if cave_buildings[bid].get('upgrading', false):
			active_n += 1
	list.add_child(_label("同时升级上限：" + str(_upgrade_limit) + "（升级中 " + str(active_n) + " / 排队 " + str(_upgrade_queue.size()) + "）", Color(0.6, 0.6, 0.75), 11))

	if active_n == 0 and _upgrade_queue.is_empty():
		list.add_child(_label("暂无升级任务", Color(0.4, 0.45, 0.55), 11))
		return

	# 活跃升级：进度条 + 剩余时间
	for bid in cave_buildings:
		var b = cave_buildings[bid]
		if not b.get('upgrading', false):
			continue
		var defs = BUILDING_DEFS.get(bid, {})
		var lv = b.get('level', 0)
		var row = PanelContainer.new()
		row.add_theme_stylebox_override("panel", _make_card_bg(Color(0.1, 0.16, 0.12)))
		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 2)
		row.add_child(vbox)
		vbox.add_child(_label(defs.get('name', bid) + "  Lv." + str(lv) + "→" + str(lv + 1) + "  升级中", defs.get('color', Color(0.8, 0.6, 0.3)), 12))
		var bar = ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 10)
		var fill = StyleBoxFlat.new()
		fill.bg_color = defs.get('color', Color(0.8, 0.6, 0.3))
		fill.corner_radius_top_left = 5
		fill.corner_radius_top_right = 5
		fill.corner_radius_bottom_left = 5
		fill.corner_radius_bottom_right = 5
		bar.add_theme_stylebox_override("fill", fill)
		vbox.add_child(bar)
		var rem_label = _label("", Color(0.6, 0.7, 0.6), 10)
		vbox.add_child(rem_label)
		list.add_child(row)
		_queue_progress_bars[bid] = {'bar': bar, 'label': rem_label}

	# 排队：顺序 + 取消按钮
	for i in range(_upgrade_queue.size()):
		var bid = _upgrade_queue[i]
		var defs = BUILDING_DEFS.get(bid, {})
		var b = cave_buildings.get(bid, {})
		var lv = b.get('level', 0)
		var row = PanelContainer.new()
		row.add_theme_stylebox_override("panel", _make_card_bg(Color(0.12, 0.12, 0.16)))
		var hbox = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 8)
		row.add_child(hbox)
		var lbl = _label(defs.get('name', bid) + "  Lv." + str(lv) + "→" + str(lv + 1) + "  排队第 " + str(i + 1) + " 位", Color(0.6, 0.6, 0.75), 12)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(lbl)
		var btn = Button.new()
		btn.text = "取消排队"
		btn.add_theme_font_size_override("font_size", 11)
		var b_id = bid
		btn.pressed.connect(func(): cancel_upgrade_requested.emit(b_id))
		hbox.add_child(btn)
		list.add_child(row)

func _build_building_card(list: VBoxContainer, bid: String):
	var defs = BUILDING_DEFS[bid]
	var level = get_building_level(bid)
	var unlocked = is_building_unlocked(bid)
	var upgrading = unlocked and cave_buildings.get(bid, {}).get('upgrading', false)
	var queued = unlocked and cave_buildings.get(bid, {}).get('queued', false)
	var maxed = unlocked and defs.max_level >= 0 and level >= defs.max_level

	var card = PanelContainer.new()
	if unlocked:
		card.add_theme_stylebox_override("panel", _make_card_bg(UI.COLOR_CARD, defs.color))
	else:
		card.add_theme_stylebox_override("panel", _make_card_bg(UI.COLOR_CARD_DARK))

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
		var lv_text = "Lv." + str(level) + ("" if defs.max_level < 0 else "/" + str(defs.max_level))
		name_label.text = defs['name'] + "  " + lv_text
		name_label.add_theme_color_override("font_color", defs.color)
	else:
		name_label.text = "??? " + defs['name'] + "（未解锁）"
		name_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	name_vbox.add_child(name_label)
	var desc_label = _label(defs['desc'], Color(0.55, 0.55, 0.7), 11)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_vbox.add_child(desc_label)
	if unlocked and defs.get('currency') == 'ore':
		name_vbox.add_child(_label("产出：" + _format_num(int(_ore_rate)) + " 灵矿/秒", Color(0.5, 0.75, 1.0), 11))
	elif unlocked and defs.get('currency') == 'wood':
		name_vbox.add_child(_label("产出：" + _format_num(int(_wood_rate)) + " 灵木/秒", Color(0.75, 0.6, 0.4), 11))
	top_row.add_child(name_vbox)

	if maxed:
		var ml = _label("已满级", Color(0.4, 0.8, 0.4), 12)
		ml.add_theme_constant_override("margin_top", 4)
		top_row.add_child(ml)
	elif upgrading:
		var ul = _label("升级中", Color(0.8, 0.6, 0.3), 12)
		ul.add_theme_constant_override("margin_top", 4)
		top_row.add_child(ul)
	elif queued:
		var ql = _label("排队中", Color(0.5, 0.55, 0.7), 12)
		ql.add_theme_constant_override("margin_top", 4)
		top_row.add_child(ql)
	elif unlocked:
		var cost = get_upgrade_cost(bid)
		var currency = get_upgrade_currency(bid)
		var can_afford = false
		var currency_text = ""
		match currency:
			'energy':
				can_afford = _spiritual_energy >= cost
				currency_text = "灵"
			'ore':
				can_afford = _ore >= cost
				currency_text = "灵矿"
			'wood':
				can_afford = _wood >= cost
				currency_text = "灵木"
			_:
				can_afford = _ore >= cost and _wood >= cost
				currency_text = "灵矿 + " + _format_num(cost) + " 灵木"
		var btn = Button.new()
		btn.text = "升级（" + _format_num(cost) + currency_text + "）"
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

## 每帧刷新资源数值与升级进度条（由 main_ui 在洞府可见时调用）
func tick_upgrade_bars(ore: float = 0.0, wood: float = 0.0, ore_rate: float = 0.0, wood_rate: float = 0.0):
	_ore = ore
	_wood = wood
	_ore_rate = ore_rate
	_wood_rate = wood_rate

	if _ore_wood_label:
		_ore_wood_label.text = "灵矿：" + _format_num(int(_ore)) + "（+" + _format_num(int(_ore_rate)) + "/秒）   灵木：" + _format_num(int(_wood)) + "（+" + _format_num(int(_wood_rate)) + "/秒）"
	if _cave_upgrade_btn:
		var ore_cost = int(100 * pow(2, cave_level))
		var wood_cost = int(100 * pow(2, cave_level))
		_cave_upgrade_btn.disabled = not (_ore >= ore_cost and _wood >= wood_cost)

	# 升级队列：顶部列表进度条实时刷新
	for bid in _queue_progress_bars:
		var b = cave_buildings.get(bid, {})
		if not b.get('upgrading', false):
			continue
		var dur = b.get('upgrade_duration', 1.0)
		var rem = b.get('upgrade_remaining', 0.0)
		var pct = clampf(1.0 - rem / dur, 0.0, 1.0)
		_queue_progress_bars[bid].bar.value = pct * 100.0
		_queue_progress_bars[bid].label.text = "升级中 " + str(int(pct * 100)) + "%（剩余" + str(int(rem)) + "秒）"
	# 子建筑面板实时刷新
	var p = _building_panels.get(_current_view)
	if p and p.has_method("tick_upgrade"):
		p.tick_upgrade(cave_buildings.get(_current_view, {}), _ore, _wood, _ore_rate, _wood_rate)

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
		"spirit_mine": "res://scenes/buildings/spirit_mine_panel.tscn",
		"spirit_wood": "res://scenes/buildings/spirit_wood_panel.tscn",
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
			panel.set_array_requested.connect(func(arr_name: String): set_array_requested.emit(arr_name))
