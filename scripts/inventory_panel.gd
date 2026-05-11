extends PanelContainer

signal back_requested()
signal use_skill_requested(index: int)
signal sell_skill_requested(index: int)
signal use_pill_requested(name: String)
signal sell_pill_requested(name: String)
signal equip_item_requested(index: int)
signal sell_equipment_requested(index: int)

var _inventory: Array = []
var _pill_inventory: Dictionary = {}
var _equipment_inventory: Array = []
var _shop_skills: Array = []
var _shop_recipes: Array = []
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
	_shop_skills = data.get("shop_skills", [])
	_shop_recipes = data.get("shop_recipes", [])
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

func _format_num(n) -> String:
	if n is float:
		n = int(n)
	if n >= 100000000:
		return str(n / 100000000.0).pad_decimals(1) + "亿"
	elif n >= 10000:
		return str(n / 10000.0).pad_decimals(1) + "万"
	return str(n)

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

	var has_content = false
	if _current_cat == "all":
		has_content = not (_inventory.is_empty() and _pill_inventory.is_empty() and _equipment_inventory.is_empty())
	elif _current_cat == "skills":
		has_content = not _inventory.is_empty()
	elif _current_cat == "pills":
		for pill_name in _pill_inventory:
			if _pill_inventory[pill_name] > 0:
				has_content = true
				break
	elif _current_cat == "equip":
		has_content = not _equipment_inventory.is_empty()

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
	refresh()

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
	$VBox/HBox/LeftMenu/BtnAll.pressed.connect(func(): _set_category("all"))
	$VBox/HBox/LeftMenu/BtnSkills.pressed.connect(func(): _set_category("skills"))
	$VBox/HBox/LeftMenu/BtnPills.pressed.connect(func(): _set_category("pills"))
	$VBox/HBox/LeftMenu/BtnEquip.pressed.connect(func(): _set_category("equip"))
