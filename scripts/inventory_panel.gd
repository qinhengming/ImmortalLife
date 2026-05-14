extends PanelContainer

signal back_requested()
signal use_skill_requested(index: int)
signal sell_skill_requested(index: int)
signal use_pill_requested(name: String)
signal sell_pill_requested(name: String)
signal equip_item_requested(index: int)
signal sell_equipment_requested(index: int)
signal use_array_requested(index: int)
signal sell_array_requested(index: int)
signal use_recipe_requested(index: int)
signal sell_recipe_requested(index: int)
signal sell_furnace_requested(index: int)

var _inventory: Array = []
var _pill_inventory: Dictionary = {}
var _equipment_inventory: Array = []
var _array_inventory: Array = []
var _recipe_inventory: Array = []
var _furnace_inventory: Array = []
var _shop_skills: Array = []
var _shop_recipes: Array = []
var _shop_arrays: Array = []
var _realms: Array = []
var _sell_ratio: float = 0.5
var _realm_level: int = 1
var _current_cat: String = "all"

const TECHNIQUE_ID_MAP = {
	"breathing_art": "吐纳术",
	"spirit_gathering": "聚灵诀",
	"wind_control": "御风诀",
	"burning_heaven": "焚天决",
	"ice_heart": "冰心诀",
	"celestial_art": "天罡功",
}

func _get_tech_name(tid: String) -> String:
	return TECHNIQUE_ID_MAP.get(tid, tid)

func set_state(data: Dictionary):
	_inventory = data.get("inventory", []).duplicate()
	_pill_inventory = data.get("pill_inventory", {}).duplicate()
	_equipment_inventory = data.get("equipment_inventory", []).duplicate()
	_array_inventory = data.get("array_inventory", []).duplicate()
	_recipe_inventory = data.get("recipe_inventory", []).duplicate()
	_furnace_inventory = data.get("furnace_inventory", []).duplicate()
	_shop_skills = data.get("shop_skills", [])
	_shop_recipes = data.get("shop_recipes", [])
	_shop_arrays = data.get("shop_arrays", [])
	_realms = data.get("realms", [])
	_sell_ratio = data.get("sell_ratio", 0.5)
	_realm_level = data.get("realm_level", 1)

func _make_card_bg(color: Color, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
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

const BIG_UNITS = ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']

func _format_num(n) -> String:
	if n is float:
		n = int(n)
	if n < 10000:
		return str(n)
	var val = float(n)
	var unit_idx = 0
	while val >= 10000 and unit_idx < BIG_UNITS.size() - 1:
		val /= 10000.0
		unit_idx += 1
	return str(val).pad_decimals(1) + BIG_UNITS[unit_idx]

func refresh():
	var list = $VBox/HBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	if _current_cat == "all" or _current_cat == "skills":
		_render_skills(list)
	if _current_cat == "all" or _current_cat == "pills":
		_render_pills(list)
	if _current_cat == "all" or _current_cat == "equip":
		_render_equipment(list)
	if _current_cat == "all" or _current_cat == "misc":
		_render_furnaces(list)
	if _current_cat == "all" or _current_cat == "arrays":
		_render_arrays(list)
	if _current_cat == "all" or _current_cat == "recipes":
		_render_recipes(list)

	var has_content = false
	if _current_cat == "all":
		has_content = not (_inventory.is_empty() and _pill_inventory.is_empty() and _equipment_inventory.is_empty() and _array_inventory.is_empty() and _recipe_inventory.is_empty() and _furnace_inventory.is_empty())
	elif _current_cat == "skills":
		has_content = not _inventory.is_empty()
	elif _current_cat == "pills":
		for pill_name in _pill_inventory:
			if _pill_inventory[pill_name] > 0:
				has_content = true
				break
	elif _current_cat == "equip":
		has_content = not _equipment_inventory.is_empty()
	elif _current_cat == "misc":
		has_content = not _furnace_inventory.is_empty()
	elif _current_cat == "arrays":
		has_content = not _array_inventory.is_empty()
	elif _current_cat == "recipes":
		has_content = not _recipe_inventory.is_empty()

	if not has_content:
		var empty = Label.new()
		empty.text = "空空如也"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		list.add_child(empty)

func _render_skills(list: VBoxContainer):
	if _inventory.is_empty():
		return
	var title = Label.new()
	title.text = "── 功法 ──"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.8))
	list.add_child(title)

	for i in range(_inventory.size()):
		var tid = _inventory[i]
		var skill_name = _get_tech_name(tid)
		var skill_data = null
		for s in _shop_skills:
			if s.get("name", "") == skill_name:
				skill_data = s
				break

		var row = HBoxContainer.new()
		var info = Label.new()
		info.text = skill_name
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 13)
		if skill_data:
			info.add_theme_color_override("font_color", skill_data.get("color", Color(0.95, 0.95, 1.0)))
		row.add_child(info)

		var realm_ok = skill_data != null and _realm_level >= skill_data.get("min_realm", 1)
		if skill_data and not realm_ok:
			var req_label = Label.new()
			var min_realm_idx = skill_data.get("min_realm", 1) - 1
			if min_realm_idx >= 0 and min_realm_idx < _realms.size():
				req_label.text = "(" + _realms[min_realm_idx].get("name", "未知") + ")"
			else:
				req_label.text = "(境界不足)"
			req_label.add_theme_color_override("font_color", skill_data.get("color", Color(0.6, 0.6, 0.8)))
			req_label.add_theme_font_size_override("font_size", 10)
			row.add_child(req_label)

		var use_btn = Button.new()
		use_btn.text = "使用"
		if not realm_ok:
			use_btn.disabled = true
		var idx = i
		use_btn.pressed.connect(func(): use_skill_requested.emit(idx))
		row.add_child(use_btn)

		if skill_data != null:
			var sell_btn = Button.new()
			var sell_price = int(skill_data.get("price", 0) * _sell_ratio)
			sell_btn.text = "出售 +" + _format_num(sell_price) + "灵"
			sell_btn.pressed.connect(func(): sell_skill_requested.emit(idx))
			row.add_child(sell_btn)

		list.add_child(row)

func _render_pills(list: VBoxContainer):
	var has_pills = false
	for pill_name in _pill_inventory:
		if _pill_inventory[pill_name] > 0:
			has_pills = true
			break
	if not has_pills:
		return

	var title = Label.new()
	title.text = "── 丹药 ──"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.4))
	list.add_child(title)

	for pill_name in _pill_inventory:
		var count = _pill_inventory[pill_name]
		if count <= 0:
			continue

		var row = HBoxContainer.new()

		var recipe_data = null
		for r in _shop_recipes:
			if r.get("name", "") == pill_name:
				recipe_data = r
				break

		var info = Label.new()
		info.text = pill_name + " x" + str(count)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 13)
		row.add_child(info)

		var use_btn = Button.new()
		use_btn.text = "使用"
		var pn = pill_name
		use_btn.pressed.connect(func(): use_pill_requested.emit(pn))
		row.add_child(use_btn)

		if recipe_data != null:
			var sell_btn = Button.new()
			var sell_price = int(recipe_data.get("price", 0) * _sell_ratio)
			sell_btn.text = "出售 +" + _format_num(sell_price) + "灵"
			sell_btn.pressed.connect(func(): sell_pill_requested.emit(pn))
			row.add_child(sell_btn)

		list.add_child(row)

func _render_equipment(list: VBoxContainer):
	if _equipment_inventory.is_empty():
		return

	var title = Label.new()
	title.text = "── 装备 ──"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.5, 0.8, 0.9))
	list.add_child(title)

	for ei in range(_equipment_inventory.size()):
		var item = _equipment_inventory[ei]
		var row = HBoxContainer.new()

		var info = Label.new()
		info.text = item.get("name", "未知装备")
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 13)

		var slot_color = Color(0.95, 0.95, 1.0)
		match item.get("slot", ""):
			"weapon":
				slot_color = Color(1, 0.6, 0.4)
			"armor":
				slot_color = Color(0.4, 0.8, 1)
			"accessory":
				slot_color = Color(0.9, 0.7, 1)
			"artifact":
				slot_color = Color(1, 0.84, 0)
		info.add_theme_color_override("font_color", slot_color)
		row.add_child(info)

		var stat_parts = []
		if item.get("atk_bonus", 0) > 0:
			stat_parts.append("攻击+" + str(item["atk_bonus"]))
		if item.get("def_bonus", 0) > 0:
			stat_parts.append("防御+" + str(item["def_bonus"]))
		if item.get("mana_bonus", 0) > 0:
			stat_parts.append("灵+" + str(item["mana_bonus"]))
		var stat_label = Label.new()
		stat_label.text = " ".join(stat_parts)
		stat_label.add_theme_font_size_override("font_size", 11)
		stat_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
		row.add_child(stat_label)

		var equip_btn = Button.new()
		equip_btn.text = "装备"
		var eidx = ei
		equip_btn.pressed.connect(func(): equip_item_requested.emit(eidx))
		row.add_child(equip_btn)

		var sell_btn = Button.new()
		var sell_price = int(item.get("price", 0) * _sell_ratio)
		sell_btn.text = "出售 +" + _format_num(sell_price) + "灵"
		sell_btn.pressed.connect(func(): sell_equipment_requested.emit(eidx))
		row.add_child(sell_btn)
		list.add_child(row)


func _render_furnaces(list: VBoxContainer):
	if _furnace_inventory.is_empty():
		return

	var title = Label.new()
	title.text = "── 丹炉 ──"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	list.add_child(title)

	for fi in range(_furnace_inventory.size()):
		var furnace = _furnace_inventory[fi]
		var row = HBoxContainer.new()

		var info = Label.new()
		info.text = furnace.get("name", "未知丹炉")
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 13)
		var col = furnace.get('color', null)
		var name_color = Color(0.8, 0.5, 0.2)
		if col is Color:
			name_color = col
		elif typeof(col) == TYPE_STRING:
			var parts = col.split(",")
			if parts.size() >= 3:
				name_color = Color(float(parts[0]), float(parts[1]), float(parts[2]))
		info.add_theme_color_override("font_color", name_color)
		row.add_child(info)

		var stat_parts = []
		if furnace.get("speed_bonus", 0) > 0:
			stat_parts.append("速度+" + str(int(furnace["speed_bonus"] * 100)) + "%")
		if furnace.get("success_bonus", 0) > 0:
			stat_parts.append("成功率+" + str(int(furnace["success_bonus"] * 100)) + "%")
		var stat_label = Label.new()
		stat_label.text = " ".join(stat_parts)
		stat_label.add_theme_font_size_override("font_size", 11)
		stat_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
		row.add_child(stat_label)

		var sell_btn = Button.new()
		var sell_price = int(furnace.get("price", 0) * _sell_ratio)
		sell_btn.text = "出售 +" + _format_num(sell_price) + "灵"
		var f_idx = fi
		sell_btn.pressed.connect(func(): sell_furnace_requested.emit(f_idx))
		row.add_child(sell_btn)
		list.add_child(row)


func _render_arrays(list: VBoxContainer):
	if _array_inventory.is_empty():
		return

	var title = Label.new()
	title.text = "── 阵法 ──"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	list.add_child(title)

	for i in range(_array_inventory.size()):
		var array_name = _array_inventory[i]
		var arr_data = null
		for a in _shop_arrays:
			if a.get("name", "") == array_name:
				arr_data = a
				break

		var row = HBoxContainer.new()

		var info = Label.new()
		var trigram = arr_data.get("trigram", "") if arr_data else ""
		info.text = trigram + " " + array_name
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 13)
		if arr_data:
			info.add_theme_color_override("font_color", arr_data.get("color", Color(0.95, 0.95, 1.0)))
		row.add_child(info)

		var realm_ok = arr_data != null and _realm_level >= arr_data.get("min_realm", 1)
		if arr_data and not realm_ok:
			var req_label = Label.new()
			var min_realm_idx = arr_data.get("min_realm", 1) - 1
			if min_realm_idx >= 0 and min_realm_idx < _realms.size():
				req_label.text = "(" + _realms[min_realm_idx].get("name", "未知") + ")"
			else:
				req_label.text = "(境界不足)"
			req_label.add_theme_color_override("font_color", arr_data.get("color", Color(0.6, 0.6, 0.8)))
			req_label.add_theme_font_size_override("font_size", 10)
			row.add_child(req_label)

		var use_btn = Button.new()
		use_btn.text = "使用"
		if not realm_ok:
			use_btn.disabled = true
		var idx = i
		use_btn.pressed.connect(func(): use_array_requested.emit(idx))
		row.add_child(use_btn)

		if arr_data != null:
			var sell_btn = Button.new()
			var sell_price = int(arr_data.get("price", 0) * _sell_ratio)
			sell_btn.text = "出售 +" + _format_num(sell_price) + "灵"
			sell_btn.pressed.connect(func(): sell_array_requested.emit(idx))
			row.add_child(sell_btn)

		list.add_child(row)


func _render_recipes(list: VBoxContainer):
	if _recipe_inventory.is_empty():
		return

	var title = Label.new()
	title.text = "── 丹方 ──"
	title.add_theme_font_size_override("font_size", 12)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	list.add_child(title)

	for i in range(_recipe_inventory.size()):
		var recipe = _recipe_inventory[i]
		var recipe_name = recipe.get("name", "未知丹方")

		var row = HBoxContainer.new()

		var info = Label.new()
		info.text = recipe_name
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_font_size_override("font_size", 13)
		info.add_theme_color_override("font_color", Color(0.95, 0.85, 0.3))
		row.add_child(info)

		var desc_label = Label.new()
		desc_label.text = recipe.get("desc", "")
		desc_label.add_theme_font_size_override("font_size", 10)
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
		row.add_child(desc_label)

		var use_btn = Button.new()
		use_btn.text = "使用"
		var idx = i
		use_btn.pressed.connect(func(): use_recipe_requested.emit(idx))
		row.add_child(use_btn)

		var sell_btn = Button.new()
		var sell_price = int(recipe.get("price", 0) * _sell_ratio)
		sell_btn.text = "出售 +" + _format_num(sell_price) + "灵"
		sell_btn.pressed.connect(func(): sell_recipe_requested.emit(idx))
		row.add_child(sell_btn)

		list.add_child(row)


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
		"recipes":
			menu.get_node("BtnRecipes").button_pressed = true
		"misc":
			menu.get_node("BtnMisc").button_pressed = true
	refresh()

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
	$VBox/HBox/LeftMenu/BtnAll.pressed.connect(func(): _set_category("all"))
	$VBox/HBox/LeftMenu/BtnSkills.pressed.connect(func(): _set_category("skills"))
	$VBox/HBox/LeftMenu/BtnPills.pressed.connect(func(): _set_category("pills"))
	$VBox/HBox/LeftMenu/BtnEquip.pressed.connect(func(): _set_category("equip"))
	$VBox/HBox/LeftMenu/BtnArrays.pressed.connect(func(): _set_category("arrays"))
	$VBox/HBox/LeftMenu/BtnRecipes.pressed.connect(func(): _set_category("recipes"))

	var btn_misc = Button.new()
	btn_misc.name = "BtnMisc"
	btn_misc.text = "杂项"
	btn_misc.toggle_mode = true
	btn_misc.add_theme_font_size_override("font_size", 12)
	btn_misc.pressed.connect(func(): _set_category("misc"))
	$VBox/HBox/LeftMenu.add_child(btn_misc)
