extends PanelContainer

signal back_requested()
signal buy_skill_requested(skill: Dictionary)
signal buy_recipe_requested(recipe: Dictionary)
signal buy_equipment_requested(item: Dictionary)
signal buy_array_requested(array_data: Dictionary)
signal buy_furnace_requested(furnace: Dictionary)

var _spiritual_energy: float = 0.0
var _realm_level: int = 1
var _shop_skills: Array = []
var _shop_recipes: Array = []
var _shop_equipment: Array = []
var _shop_arrays: Array = []
var _shop_furnaces: Array = []
var _learned_techniques: Dictionary = {}
var _learned_recipes: Array = []
var _recipe_inventory: Array = []
var _learned_arrays: Array = []
var _array_inventory: Array = []
var _furnace_inventory: Array = []

const TECHNIQUE_ID_MAP = {
	"吐纳术": "breathing_art",
	"聚灵诀": "spirit_gathering",
	"御风诀": "wind_control",
	"焚天决": "burning_heaven",
	"冰心诀": "ice_heart",
	"天罡功": "celestial_art",
}

const TECHNIQUE_GRADES = ["黄级", "玄级", "地级", "天级", "圣级"]
const TECHNIQUE_GRADE_COLORS = [
	Color(0.9, 0.85, 0.4),
	Color(0.35, 0.75, 0.9),
	Color(0.9, 0.55, 0.3),
	Color(0.65, 0.35, 0.95),
	Color(1.0, 0.25, 0.2),
]
const TECHNIQUE_GRADE_MAX_LEVELS = [3, 5, 7, 9, 12]
var _equipped_items: Dictionary = {}
var _equipment_inventory: Array = []
var _realms: Array = []
var _equipment_slots: Array = []
var _equipment_slot_names: Dictionary = {}
var _current_cat: String = "all"


func set_state(data: Dictionary):
	_spiritual_energy = data.get('spiritual_energy', 0.0)
	_realm_level = data.get('realm_level', 1)
	_shop_skills = data.get('shop_skills', [])
	_shop_recipes = data.get('shop_recipes', [])
	_shop_equipment = data.get('shop_equipment', [])
	_shop_arrays = data.get('shop_arrays', [])
	_shop_furnaces = data.get('shop_furnaces', [])
	_learned_techniques = data.get('learned_techniques', {})
	_learned_recipes = data.get('learned_recipes', [])
	_recipe_inventory = data.get('recipe_inventory', [])
	_learned_arrays = data.get('learned_arrays', [])
	_array_inventory = data.get('array_inventory', [])
	_equipped_items = data.get('equipped_items', {})
	_equipment_inventory = data.get('equipment_inventory', [])
	_furnace_inventory = data.get('furnace_inventory', [])
	_realms = data.get('realms', [])
	_equipment_slots = data.get('equipment_slots', [])
	_equipment_slot_names = data.get('equipment_slot_names', {})


func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
	$VBox/HBox/LeftMenu/BtnAll.pressed.connect(func(): _set_category("all"))
	$VBox/HBox/LeftMenu/BtnSkills.pressed.connect(func(): _set_category("skills"))
	$VBox/HBox/LeftMenu/BtnPills.pressed.connect(func(): _set_category("pills"))
	$VBox/HBox/LeftMenu/BtnEquip.pressed.connect(func(): _set_category("equip"))
	$VBox/HBox/LeftMenu/BtnArrays.pressed.connect(func(): _set_category("arrays"))

	var btn_misc = Button.new()
	btn_misc.name = "BtnMisc"
	btn_misc.text = "杂项"
	btn_misc.toggle_mode = true
	btn_misc.add_theme_font_size_override("font_size", 12)
	btn_misc.pressed.connect(func(): _set_category("misc"))
	$VBox/HBox/LeftMenu.add_child(btn_misc)


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


func _make_card_bg(owned: bool, affordable: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	if owned:
		style.bg_color = Color(0.12, 0.16, 0.12)
	elif affordable:
		style.bg_color = Color(0.14, 0.18, 0.16)
	else:
		style.bg_color = Color(0.19, 0.13, 0.13)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style


func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label


func is_skill_learned(name: String) -> bool:
	var tid = TECHNIQUE_ID_MAP.get(name, "")
	if tid != "" and _learned_techniques.has(tid):
		return _learned_techniques[tid].get("level", 0) > 0
	return false


func is_recipe_learned(name: String) -> bool:
	for r in _learned_recipes:
		if r['name'] == name:
			return true
	return false

func _recipe_inventory_has(name: String) -> bool:
	for r in _recipe_inventory:
		if r['name'] == name:
			return true
	return false


func _is_equipment_owned(name: String) -> bool:
	for slot in _equipment_slots:
		var item = _equipped_items.get(slot)
		if item != null and item['name'] == name:
			return true
	for item in _equipment_inventory:
		if item['name'] == name:
			return true
	return false

func _is_furnace_owned(name: String) -> bool:
	for f in _furnace_inventory:
		if f.get('name', '') == name:
			return true
	return false


func _set_category(cat: String):
	_current_cat = cat
	var menu = $VBox/HBox/LeftMenu
	for btn in menu.get_children():
		btn.button_pressed = false
	match cat:
		"all":
			menu.get_node("BtnAll").button_pressed = true
		"skills":
			menu.get_node("BtnSkills").button_pressed = true
		"pills":
			menu.get_node("BtnPills").button_pressed = true
		"equip":
			menu.get_node("BtnEquip").button_pressed = true
		"arrays":
			menu.get_node("BtnArrays").button_pressed = true
		"misc":
			menu.get_node("BtnMisc").button_pressed = true
	refresh()

func refresh():
	var list = $VBox/HBox/ScrollList/ItemList
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	# 当前灵气栏
	var header = HBoxContainer.new()
	var hl = _pl("当前灵气：")
	var hv = _pl(_format_num(_spiritual_energy), Color(1.0, 0.84, 0.0), 15)
	header.add_child(hl)
	header.add_child(hv)
	list.add_child(header)
	list.add_child(HSeparator.new())

	# 功法区
	if _current_cat == "all" or _current_cat == "skills":
		var st = _pl("── 功法秘笈 ──", Color(0.3, 0.8, 1.0), 13)
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st.add_theme_constant_override("margin_top", 6)
		st.add_theme_constant_override("margin_bottom", 4)
		list.add_child(st)

		for skill in _shop_skills:
			list.add_child(_make_item_card(skill, "skill"))

	# 丹方区
	if _current_cat == "all" or _current_cat == "pills":
		var rt = _pl("── 丹方大全 ──", Color(0.3, 0.8, 1.0), 13)
		rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rt.add_theme_constant_override("margin_top", 8)
		rt.add_theme_constant_override("margin_bottom", 4)
		list.add_child(rt)

		for recipe in _shop_recipes:
			list.add_child(_make_item_card(recipe, "recipe"))

	# 装备区
	if _current_cat == "all" or _current_cat == "equip":
		var et = _pl("── 装备 ──", Color(0.3, 0.8, 1.0), 13)
		et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		et.add_theme_constant_override("margin_top", 8)
		et.add_theme_constant_override("margin_bottom", 4)
		list.add_child(et)

		for equip in _shop_equipment:
			list.add_child(_make_equip_card(equip))

	# 杂项区
	if _current_cat == "all" or _current_cat == "misc":
		var ft = _pl("── 杂项 ──", Color(0.6, 0.6, 0.7), 13)
		ft.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ft.add_theme_constant_override("margin_top", 8)
		ft.add_theme_constant_override("margin_bottom", 4)
		list.add_child(ft)

		for furnace in _shop_furnaces:
			list.add_child(_make_furnace_card(furnace))

	# 阵法区
	if _current_cat == "all" or _current_cat == "arrays":
		var at = _pl("── 阵法秘笈 ──", Color(0.3, 0.8, 1.0), 13)
		at.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		at.add_theme_constant_override("margin_top", 8)
		at.add_theme_constant_override("margin_bottom", 4)
		list.add_child(at)

		for arr in _shop_arrays:
			list.add_child(_make_array_card(arr))


func _make_item_card(data: Dictionary, type: String) -> PanelContainer:
	var owned = is_skill_learned(data['name']) if type == "skill" else (is_recipe_learned(data['name']) or _recipe_inventory_has(data['name']))
	var affordable = _spiritual_energy >= data['price']

	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_bg(owned, affordable))

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	# 名称+描述
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = data['name']
	name_label.add_theme_font_size_override("font_size", 13)
	if owned:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	elif type == "skill":
		name_label.add_theme_color_override("font_color", data.get('color', Color(0.95, 0.95, 1.0)))
	else:
		name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	if type == "skill":
		var tid = TECHNIQUE_ID_MAP.get(data.name, "")
		var grade_name = ""
		var max_lv = 0
		if tid != "":
			var grade_idx = 0
			match tid:
				"breathing_art": grade_idx = 0
				"spirit_gathering": grade_idx = 1
				"wind_control": grade_idx = 2
				"burning_heaven": grade_idx = 3
				"ice_heart": grade_idx = 3
				"celestial_art": grade_idx = 4
			grade_name = TECHNIQUE_GRADES[grade_idx]
			max_lv = TECHNIQUE_GRADE_MAX_LEVELS[grade_idx]
		desc_label.text = data['desc'] + " | " + grade_name + "·" + str(max_lv) + "重 | 修炼速度x" + str(1.0 + data['mana_bonus_pct'])
	else:
		desc_label.text = data['desc'] + " | 炼制消耗：" + _format_num(data['craft_cost'])
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
	desc_label.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(desc_label)

	# 境界需求（仅功法）
	if type == "skill":
		var min_r = data.get('min_realm', 1)
		var realm_name = _realms[min_r - 1]['name'] if min_r >= 1 and min_r <= _realms.size() else "未知"
		var req_label = Label.new()
		req_label.text = "所需境界：" + realm_name
		req_label.add_theme_color_override("font_color", data.get('color', Color(0.6, 0.6, 0.8)))
		req_label.add_theme_font_size_override("font_size", 10)
		info_vbox.add_child(req_label)

	# 价格
	var price_box = HBoxContainer.new()
	hbox.add_child(price_box)

	var price_label = Label.new()
	price_label.text = _format_num(data['price'])
	price_label.add_theme_font_size_override("font_size", 13)
	if owned:
		price_label.add_theme_color_override("font_color", Color(0.3, 0.5, 0.3))
	elif affordable:
		price_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		price_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	price_box.add_child(price_label)

	var unit = Label.new()
	unit.text = "灵"
	unit.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	unit.add_theme_font_size_override("font_size", 11)
	unit.add_theme_constant_override("margin_right", 4)
	price_box.add_child(unit)

	# 按钮
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(52, 28)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 11)
	if owned:
		btn.text = "已习得"
		btn.disabled = true
	else:
		var realm_ok = true
		if type == "skill":
			realm_ok = _realm_level >= data.get('min_realm', 1)
		if not realm_ok:
			btn.text = "境界不足"
			btn.disabled = true
		else:
			btn.text = "购买"
			var d = data
			if type == "skill":
				btn.pressed.connect(func(): buy_skill_requested.emit(d))
			else:
				btn.pressed.connect(func(): buy_recipe_requested.emit(d))
	hbox.add_child(btn)

	return card


func _make_equip_card(data: Dictionary) -> PanelContainer:
	var owned = _is_equipment_owned(data['name'])
	var affordable = _spiritual_energy >= data['price']

	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_bg(owned, affordable))

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	# 名称+描述+属性
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(vbox)

	var name_label = Label.new()
	name_label.text = data['name']
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	vbox.add_child(name_label)

	var slot_name = _equipment_slot_names.get(data['slot'], data['slot'])
	var stat_parts = []
	stat_parts.append(slot_name)
	if data['atk_bonus'] > 0:
		stat_parts.append("攻击+" + str(data['atk_bonus']))
	if data['def_bonus'] > 0:
		stat_parts.append("防御+" + str(data['def_bonus']))
	if data['mana_bonus'] > 0:
		stat_parts.append("灵气+" + str(data['mana_bonus']))

	var dl = Label.new()
	dl.text = data['desc'] + " | " + " ".join(stat_parts)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
	dl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(dl)

	# 价格
	var price_box = HBoxContainer.new()
	hbox.add_child(price_box)

	var pl = Label.new()
	pl.text = _format_num(data['price'])
	pl.add_theme_font_size_override("font_size", 13)
	pl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3) if affordable else Color(1.0, 0.35, 0.35))
	price_box.add_child(pl)

	var ul = Label.new()
	ul.text = "灵"
	ul.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	ul.add_theme_font_size_override("font_size", 11)
	ul.add_theme_constant_override("margin_right", 4)
	price_box.add_child(ul)

	# 按钮
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(52, 28)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 11)
	if owned:
		btn.text = "已拥有"
		btn.disabled = true
	else:
		btn.text = "购买"
		var d = data
		btn.pressed.connect(func(): buy_equipment_requested.emit(d))
	hbox.add_child(btn)

	return card


func _make_furnace_card(data: Dictionary) -> PanelContainer:
	var owned = _is_furnace_owned(data['name'])
	var affordable = _spiritual_energy >= data['price']

	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_bg(owned, affordable))

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = data['name']
	name_label.add_theme_font_size_override("font_size", 13)
	if owned:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		name_label.add_theme_color_override("font_color", data.get('color', Color(0.95, 0.95, 1.0)))
	info_vbox.add_child(name_label)

	var stat_parts = []
	if data.get('speed_bonus', 0) > 0:
		stat_parts.append("炼制速度+" + str(int(data['speed_bonus'] * 100)) + "%")
	if data.get('success_bonus', 0) > 0:
		stat_parts.append("成功率+" + str(int(data['success_bonus'] * 100)) + "%")

	var dl = Label.new()
	dl.text = data['desc'] + " | " + " ".join(stat_parts)
	dl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
	dl.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(dl)

	var min_r = data.get('min_realm', 1)
	var realm_name = _realms[min_r - 1]['name'] if min_r >= 1 and min_r <= _realms.size() else "未知"
	var req_label = Label.new()
	req_label.text = "所需境界：" + realm_name
	req_label.add_theme_color_override("font_color", data.get('color', Color(0.6, 0.6, 0.8)))
	req_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(req_label)

	var price_box = HBoxContainer.new()
	hbox.add_child(price_box)

	var pl = Label.new()
	pl.text = _format_num(data['price'])
	pl.add_theme_font_size_override("font_size", 13)
	if owned:
		pl.add_theme_color_override("font_color", Color(0.3, 0.5, 0.3))
	elif affordable:
		pl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		pl.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	price_box.add_child(pl)

	var ul = Label.new()
	ul.text = "灵"
	ul.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	ul.add_theme_font_size_override("font_size", 11)
	ul.add_theme_constant_override("margin_right", 4)
	price_box.add_child(ul)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(52, 28)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 11)
	if owned:
		btn.text = "已拥有"
		btn.disabled = true
	else:
		var realm_ok = _realm_level >= data.get('min_realm', 1)
		if not realm_ok:
			btn.text = "境界不足"
			btn.disabled = true
		else:
			btn.text = "购买"
			var d = data
			btn.pressed.connect(func(): buy_furnace_requested.emit(d))
	hbox.add_child(btn)

	return card


func _make_array_card(data: Dictionary) -> PanelContainer:
	var owned = _learned_arrays.has(data['name']) or _array_inventory.has(data['name'])
	var affordable = _spiritual_energy >= data['price']

	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_bg(owned, affordable))

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = data.get('trigram', '') + " " + data['name']
	name_label.add_theme_font_size_override("font_size", 13)
	if owned:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		name_label.add_theme_color_override("font_color", data.get('color', Color(0.95, 0.95, 1.0)))
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = data['desc']
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
	desc_label.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(desc_label)

	var min_r = data.get('min_realm', 1)
	var realm_name = _realms[min_r - 1]['name'] if min_r >= 1 and min_r <= _realms.size() else "未知"
	var req_label = Label.new()
	req_label.text = "所需境界：" + realm_name
	req_label.add_theme_color_override("font_color", data.get('color', Color(0.6, 0.6, 0.8)))
	req_label.add_theme_font_size_override("font_size", 10)
	info_vbox.add_child(req_label)

	var price_box = HBoxContainer.new()
	hbox.add_child(price_box)

	var price_label = Label.new()
	price_label.text = _format_num(data['price'])
	price_label.add_theme_font_size_override("font_size", 13)
	if owned:
		price_label.add_theme_color_override("font_color", Color(0.3, 0.5, 0.3))
	elif affordable:
		price_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		price_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	price_box.add_child(price_label)

	var unit = Label.new()
	unit.text = "灵"
	unit.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	unit.add_theme_font_size_override("font_size", 11)
	unit.add_theme_constant_override("margin_right", 4)
	price_box.add_child(unit)

	var btn = Button.new()
	btn.custom_minimum_size = Vector2(52, 28)
	btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 11)
	if owned:
		btn.text = "已习得"
		btn.disabled = true
	else:
		var realm_ok = _realm_level >= data.get('min_realm', 1)
		if not realm_ok:
			btn.text = "境界不足"
			btn.disabled = true
		else:
			btn.text = "购买"
			var d = data
			btn.pressed.connect(func(): buy_array_requested.emit(d))
	hbox.add_child(btn)

	return card
