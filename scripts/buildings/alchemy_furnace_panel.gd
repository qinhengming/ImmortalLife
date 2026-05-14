extends PanelContainer

const BID = "alchemy_furnace"

var _building: Dictionary = {}
var _energy: float = 0.0
var _recipes: Array = []
var _pills: Dictionary = {}
var _current_tab: String = "craft"
var _furnace_inventory: Array = []
var _equipped_furnaces: Array = []
var _crafting_states: Array = []

var _toast_panel: PanelContainer = null
var _toast_label: Label = null
var _toast_style: StyleBoxFlat = null
var _toast_active: bool = false
var _toast_timer: float = 0.0

var _select_slot: int = -1
var _select_popup: PopupPanel = null
var _craft_popup: PopupPanel = null
var _qty_popup: PopupPanel = null
var _qty_input: LineEdit = null
var _qty_recipe: Dictionary = {}
var _qty_slot: int = -1

var _needs_process: bool = false

signal back_requested()
signal craft_pill_requested(recipe_name: String)
signal use_pill_requested(pill_name: String)
signal building_action_requested(bid: String)
signal equip_furnace_requested(slot_index: int, inventory_index: int)
signal unequip_furnace_requested(slot_index: int)

func set_state(building: Dictionary, energy: float, recipes: Array, pills: Dictionary, furnace_inv: Array = [], equipped_furns: Array = []):
	_building = building.duplicate()
	_energy = energy
	_recipes = recipes
	_pills = pills.duplicate()
	_furnace_inventory = furnace_inv.duplicate()
	_equipped_furnaces = equipped_furns.duplicate()

func _card_bg(color: Color = Color(0.1, 0.12, 0.18)) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.corner_radius_top_left = 6
	s.corner_radius_top_right = 6
	s.corner_radius_bottom_left = 6
	s.corner_radius_bottom_right = 6
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _lbl(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

func _wlbl(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	var l = _lbl(text, color, size)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _fmt(n: float) -> String:
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

func _get_max_slots() -> int:
	var level = _building.get('level', 0)
	if level <= 0:
		return 0
	elif level <= 2:
		return 1
	elif level <= 4:
		return 2
	else:
		return 3

func _get_bonuses() -> Dictionary:
	var level = _building.get('level', 0)
	var speed_bonus = 0.1 * level
	var success_bonus = 0.0
	var cost_reduction = 0.05 * level
	for furnace in _equipped_furnaces:
		if furnace != null and furnace.has('speed_bonus'):
			speed_bonus += furnace['speed_bonus']
			success_bonus += furnace.get('success_bonus', 0.0)
	return {"speed": speed_bonus, "success": success_bonus, "cost_reduction": cost_reduction}

func _is_slot_crafting(slot_idx: int) -> bool:
	if slot_idx >= _crafting_states.size():
		return false
	return _crafting_states[slot_idx] != null

func _any_crafting() -> bool:
	for cs in _crafting_states:
		if cs != null:
			return true
	return false

func _update_tabs():
	$VBox/SubMenuBar/BtnTab1.button_pressed = (_current_tab == "craft")
	$VBox/SubMenuBar/BtnTab2.button_pressed = (_current_tab == "pills")

func _init_toast():
	var layer = CanvasLayer.new()
	layer.layer = 10

	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.layout_mode = 1

	_toast_panel.anchor_left = 0.08
	_toast_panel.anchor_right = 0.92
	_toast_panel.anchor_top = 0.0
	_toast_panel.anchor_bottom = 0.0
	_toast_panel.offset_top = 56
	_toast_panel.offset_bottom = 102

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.06, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.55, 0.25, 0.8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_toast_style = style
	_toast_panel.add_theme_stylebox_override("panel", style)

	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 14)
	_toast_panel.add_child(_toast_label)

	layer.add_child(_toast_panel)
	add_child(layer)

func _show_toast(msg: String, color: Color = Color(0.3, 1.0, 0.5)):
	_toast_label.text = msg
	_toast_label.add_theme_color_override("font_color", color)
	_toast_style.border_color = Color(color.r, color.g, color.b, 0.6)
	_toast_panel.modulate.a = 0.0
	_toast_panel.offset_top = 56
	_toast_panel.offset_bottom = 102
	_toast_panel.visible = true
	_toast_timer = 0.0
	_toast_active = true
	_needs_process = true
	set_process(true)

func _process_toast(delta: float):
	_toast_timer += delta
	if _toast_timer < 0.15:
		_toast_panel.modulate.a = _toast_timer / 0.15
		_toast_panel.offset_top = 56 + (1.0 - _toast_timer / 0.15) * 10
		_toast_panel.offset_bottom = 102 + (1.0 - _toast_timer / 0.15) * 10
	elif _toast_timer < 1.5:
		_toast_panel.modulate.a = 1.0
		_toast_panel.offset_top = 56
		_toast_panel.offset_bottom = 102
	elif _toast_timer < 1.9:
		var p = (_toast_timer - 1.5) / 0.4
		_toast_panel.modulate.a = 1.0 - p
		_toast_panel.offset_top = 56 - p * 40
		_toast_panel.offset_bottom = 102 - p * 40
	else:
		_toast_active = false
		_toast_panel.visible = false
		if not _needs_process:
			set_process(false)

func _start_batch_crafting(slot_idx: int, recipe: Dictionary, count: int):
	var bonuses = _get_bonuses()
	var cost_per = int(recipe['craft_cost'] * (1.0 - bonuses['cost_reduction']))
	var total_cost = cost_per * count
	if _energy < total_cost:
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	var time_per = max(0.3, 2.0 / (1.0 + bonuses['speed']))
	while _crafting_states.size() <= slot_idx:
		_crafting_states.append(null)
	_crafting_states[slot_idx] = {
		'recipe': recipe,
		'time_per': time_per,
		'elapsed': 0.0,
		'remaining': count,
		'total': count,
	}
	_needs_process = true
	set_process(true)
	refresh()

func _complete_crafting(slot_idx: int):
	var cs = _crafting_states[slot_idx]
	if cs == null:
		return
	var rname = cs['recipe'].get('name', '')
	craft_pill_requested.emit(rname)

	cs['remaining'] -= 1
	if cs['remaining'] <= 0:
		_crafting_states[slot_idx] = null
		_show_toast("炼制完成！" + rname + " x" + str(cs['total']), Color(0.9, 0.7, 0.3))
		refresh()
	else:
		cs['elapsed'] = 0.0
		refresh()

# ===== 选择丹炉弹窗 =====

func _open_furnace_select(slot_idx: int):
	_select_slot = slot_idx
	_select_popup = PopupPanel.new()
	_select_popup.name = "FurnaceSelectPopup"

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.1, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_select_popup.add_child(bg)

	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 20)
	mc.add_theme_constant_override("margin_right", 20)
	mc.add_theme_constant_override("margin_top", 80)
	mc.add_theme_constant_override("margin_bottom", 80)
	_select_popup.add_child(mc)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mc.add_child(vbox)

	vbox.add_child(_lbl("选择丹炉安装到槽位" + str(slot_idx + 1), Color(1.0, 0.6, 0.2), 16))

	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var svbox = VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 6)
	scroll.add_child(svbox)
	vbox.add_child(scroll)

	if _furnace_inventory.is_empty():
		svbox.add_child(_lbl("背包中没有丹炉", Color(0.5, 0.5, 0.6), 12))
	else:
		for fi in range(_furnace_inventory.size()):
			var furnace = _furnace_inventory[fi]
			var card = PanelContainer.new()
			card.add_theme_stylebox_override("panel", _card_bg(Color(0.12, 0.16, 0.14)))
			var row = HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			card.add_child(row)

			var info = VBoxContainer.new()
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info.add_theme_constant_override("separation", 2)
			var fc = furnace.get('color', Color(0.8, 0.5, 0.2))
			info.add_child(_lbl(furnace['name'], fc, 14))
			var desc = furnace.get('desc', '')
			var stats = ""
			if furnace.get('speed_bonus', 0) > 0:
				stats += "速度+" + str(int(furnace['speed_bonus'] * 100)) + "% "
			if furnace.get('success_bonus', 0) > 0:
				stats += "成功率+" + str(int(furnace['success_bonus'] * 100)) + "% "
			var dl = _wlbl(desc + "  " + stats, Color(0.55, 0.55, 0.7), 11)
			info.add_child(dl)
			row.add_child(info)

			var btn = Button.new()
			btn.text = "安装"
			btn.add_theme_font_size_override("font_size", 12)
			var fi_idx = fi
			var si = slot_idx
			btn.pressed.connect(func():
				_clear_popup()
				equip_furnace_requested.emit(si, fi_idx)
			)
			row.add_child(btn)
			svbox.add_child(card)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(func(): _clear_popup())
	vbox.add_child(close_btn)

	add_child(_select_popup)
	_select_popup.popup_centered(Vector2(340, 500))

func _clear_popup():
	if _select_popup:
		_select_popup.queue_free()
		_select_popup = null
	_select_slot = -1
	if _craft_popup:
		_craft_popup.queue_free()
		_craft_popup = null
	if _qty_popup:
		_qty_popup.queue_free()
		_qty_popup = null
	_qty_input = null
	_qty_recipe = {}
	_qty_slot = -1

# ===== 炼制弹窗（选择丹方） =====

func _open_craft_popup(slot_idx: int):
	_qty_slot = slot_idx

	_craft_popup = PopupPanel.new()
	_craft_popup.name = "CraftPopup"

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.1, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_craft_popup.add_child(bg)

	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 16)
	mc.add_theme_constant_override("margin_right", 16)
	mc.add_theme_constant_override("margin_top", 80)
	mc.add_theme_constant_override("margin_bottom", 40)
	_craft_popup.add_child(mc)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	mc.add_child(vbox)

	var furnace = _equipped_furnaces[slot_idx] if slot_idx < _equipped_furnaces.size() else null
	var furnace_name = furnace['name'] if furnace else "炼丹炉"
	vbox.add_child(_lbl(furnace_name + " - 选择丹方", Color(1.0, 0.6, 0.2), 16))

	var bonuses = _get_bonuses()
	var info_line = "消耗-" + str(int(bonuses['cost_reduction'] * 100)) + "%  速度+" + str(int(bonuses['speed'] * 100)) + "%  成功率" + str(int((0.8 + bonuses['success']) * 100)) + "%"
	vbox.add_child(_lbl(info_line, Color(0.5, 0.7, 0.5), 11))

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var svbox = VBoxContainer.new()
	svbox.add_theme_constant_override("separation", 4)
	svbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(svbox)
	vbox.add_child(scroll)

	if _recipes.is_empty():
		svbox.add_child(_lbl("尚未学会任何丹方", Color(0.5, 0.5, 0.6), 12))
	else:
		for recipe in _recipes:
			var card = PanelContainer.new()
			card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var normal_style = StyleBoxFlat.new()
			normal_style.bg_color = Color(0.1, 0.13, 0.2)
			normal_style.corner_radius_top_left = 5
			normal_style.corner_radius_top_right = 5
			normal_style.corner_radius_bottom_left = 5
			normal_style.corner_radius_bottom_right = 5
			normal_style.content_margin_left = 12
			normal_style.content_margin_right = 12
			normal_style.content_margin_top = 10
			normal_style.content_margin_bottom = 10
			card.add_theme_stylebox_override("panel", normal_style)

			var hover_style = normal_style.duplicate()
			hover_style.bg_color = Color(0.18, 0.22, 0.32)

			card.mouse_entered.connect(func():
				card.add_theme_stylebox_override("panel", hover_style)
			)
			card.mouse_exited.connect(func():
				card.add_theme_stylebox_override("panel", normal_style)
			)

			var hbox = HBoxContainer.new()
			hbox.add_theme_constant_override("separation", 8)
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			card.add_child(hbox)

			var name_lbl = _lbl(recipe['name'], Color(1.0, 0.8, 0.5), 15)
			name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_child(name_lbl)

			var cost = int(recipe['craft_cost'] * (1.0 - bonuses['cost_reduction']))
			var craft_time = max(0.3, 2.0 / (1.0 + bonuses['speed']))
			var cost_lbl = _lbl(_fmt(cost) + "灵  " + str(craft_time).pad_decimals(1) + "秒", Color(0.7, 0.7, 0.8), 12)
			hbox.add_child(cost_lbl)

			var r = recipe
			card.gui_input.connect(func(event):
				if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
					_craft_popup.queue_free()
					_craft_popup = null
					_open_qty_popup(r)
			)
			card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			svbox.add_child(card)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(func(): _clear_popup())
	vbox.add_child(close_btn)

	add_child(_craft_popup)
	_craft_popup.popup_centered(Vector2(340, 480))

# ===== 数量弹窗 =====

func _open_qty_popup(recipe: Dictionary):
	_qty_recipe = recipe

	_qty_popup = PopupPanel.new()
	_qty_popup.name = "QtyPopup"

	var bg = ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.1, 0.97)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_qty_popup.add_child(bg)

	var mc = MarginContainer.new()
	mc.add_theme_constant_override("margin_left", 30)
	mc.add_theme_constant_override("margin_right", 30)
	mc.add_theme_constant_override("margin_top", 120)
	mc.add_theme_constant_override("margin_bottom", 120)
	_qty_popup.add_child(mc)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	mc.add_child(vbox)

	vbox.add_child(_lbl("炼制 " + recipe['name'], Color(1.0, 0.6, 0.2), 18))

	var bonuses = _get_bonuses()
	var cost_per = int(recipe['craft_cost'] * (1.0 - bonuses['cost_reduction']))
	var time_per = max(0.3, 2.0 / (1.0 + bonuses['speed']))

	var info_hbox = HBoxContainer.new()
	info_hbox.add_theme_constant_override("separation", 4)
	info_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var count_row = HBoxContainer.new()
	count_row.add_theme_constant_override("separation", 8)
	count_row.alignment = BoxContainer.ALIGNMENT_CENTER

	var lbl = _lbl("数量", Color(0.9, 0.9, 1.0), 14)
	count_row.add_child(lbl)

	var minus_btn = Button.new()
	minus_btn.text = "-"
	minus_btn.add_theme_font_size_override("font_size", 16)
	count_row.add_child(minus_btn)

	var input = LineEdit.new()
	input.text = "1"
	input.custom_minimum_size = Vector2(80, 0)
	input.add_theme_font_size_override("font_size", 16)
	input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_qty_input = input
	count_row.add_child(input)

	var plus_btn = Button.new()
	plus_btn.text = "+"
	plus_btn.add_theme_font_size_override("font_size", 16)
	count_row.add_child(plus_btn)

	var unit = _lbl("颗", Color(0.9, 0.9, 1.0), 14)
	count_row.add_child(unit)

	vbox.add_child(count_row)

	var info_label = _lbl("共" + _fmt(cost_per) + "灵  " + str(time_per).pad_decimals(1) + "秒", Color(0.9, 0.7, 0.3), 14)
	vbox.add_child(info_label)

	input.text_changed.connect(func(txt: String):
		var filtered = ""
		for ch in txt:
			if ch >= '0' and ch <= '9':
				filtered += ch
		if filtered == "":
			filtered = "1"
		var n = int(filtered)
		if n < 1:
			n = 1
		if n > 999:
			n = 999
		if str(n) != input.text:
			input.text = str(n)
			input.caret_column = input.text.length()
		_show_qty_summary(info_label, n)
	)

	minus_btn.pressed.connect(func():
		var n = int(input.text) - 1
		if n < 1:
			n = 1
		input.text = str(n)
	)
	plus_btn.pressed.connect(func():
		var n = int(input.text) + 1
		if n > 999:
			n = 999
		input.text = str(n)
	)

	var start_btn = Button.new()
	start_btn.text = "开始炼制"
	start_btn.add_theme_font_size_override("font_size", 15)
	var recip = recipe
	var si = _qty_slot
	start_btn.pressed.connect(func():
		var n = int(input.text)
		if n < 1:
			n = 1
		_clear_popup()
		_start_batch_crafting(si, recip, n)
	)
	vbox.add_child(start_btn)

	var close_btn = Button.new()
	close_btn.text = "取消"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(func(): _clear_popup())
	vbox.add_child(close_btn)

	add_child(_qty_popup)
	_qty_popup.popup_centered(Vector2(300, 340))

func _show_qty_summary(label: Label, count: int):
	var bonuses = _get_bonuses()
	var cost_per = int(_qty_recipe['craft_cost'] * (1.0 - bonuses['cost_reduction']))
	var time_per = max(0.3, 2.0 / (1.0 + bonuses['speed']))
	label.text = "共" + _fmt(cost_per * count) + "灵  " + str(time_per * count).pad_decimals(1) + "秒"

# ===== 槽位渲染 =====

func _build_furnace_slots(list: VBoxContainer):
	var level = _building.get('level', 0)
	var max_lv = 5
	var max_slots = _get_max_slots()
	var bonuses = _get_bonuses()

	var info = PanelContainer.new()
	info.add_theme_stylebox_override("panel", _card_bg(Color(0.08, 0.12, 0.18)))
	var iv = VBoxContainer.new()
	iv.add_theme_constant_override("separation", 4)
	info.add_child(iv)

	iv.add_child(_lbl("炼丹房  Lv." + str(level) + "/" + str(max_lv), Color(1.0, 0.6, 0.2), 18))
	iv.add_child(_wlbl("安装丹炉提升炼制效果，等级越高可安装越多丹炉", Color(0.7, 0.7, 0.8), 11))

	var effects = ""
	if bonuses['cost_reduction'] > 0:
		effects += "炼制消耗-" + str(int(bonuses['cost_reduction'] * 100)) + "%  "
	if bonuses['speed'] > 0:
		effects += "炼制速度+" + str(int(bonuses['speed'] * 100)) + "%  "
	var total_success = 0.8 + bonuses['success']
	effects += "成功率" + str(int(total_success * 100)) + "%  "
	iv.add_child(_lbl("合计加成：" + effects, Color(0.4, 0.9, 0.5), 12))

	if level >= max_lv:
		iv.add_child(_lbl("已升至满级", Color(0.4, 0.8, 0.4), 13))
	else:
		var cost = int(1000 * pow(2.0, level))
		var can = _energy >= cost
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(_lbl("升级消耗：" + _fmt(cost) + " 灵气", Color(0.7, 0.7, 0.8), 12))
		var btn = Button.new()
		btn.text = "升级"
		btn.add_theme_font_size_override("font_size", 12)
		btn.disabled = not can
		btn.pressed.connect(func(): building_action_requested.emit(BID))
		row.add_child(btn)
		iv.add_child(row)

	list.add_child(info)

	var slot_header = _lbl("── 丹炉槽位（" + str(max_slots) + "个） ──", Color(1.0, 0.6, 0.2), 13)
	slot_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(slot_header)

	if max_slots <= 0:
		list.add_child(_lbl("升级炼丹房以解锁丹炉槽位", Color(0.5, 0.5, 0.6), 11))
	else:
		_ensure_furnace_array_size(max_slots)
		while _crafting_states.size() < max_slots:
			_crafting_states.append(null)
		for i in range(max_slots):
			var furnace = _equipped_furnaces[i] if i < _equipped_furnaces.size() else null
			_build_slot_card(list, i, furnace)

func _ensure_furnace_array_size(max_slots: int):
	while _equipped_furnaces.size() < max_slots:
		_equipped_furnaces.append(null)
	while _equipped_furnaces.size() > max_slots:
		var extra = _equipped_furnaces.pop_back()
		if extra != null:
			_furnace_inventory.append(extra)

func _build_slot_card(list: VBoxContainer, slot_idx: int, furnace):
	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _card_bg())
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	if furnace != null:
		var btn_row = HBoxContainer.new()
		btn_row.add_theme_constant_override("separation", 8)

		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		var fc = furnace.get('color', Color(0.8, 0.5, 0.2))
		info.add_child(_lbl("槽位" + str(slot_idx + 1) + "  " + furnace['name'], fc, 13))
		var stats = ""
		if furnace.get('speed_bonus', 0) > 0:
			stats += "速度+" + str(int(furnace['speed_bonus'] * 100)) + "%  "
		if furnace.get('success_bonus', 0) > 0:
			stats += "成功率+" + str(int(furnace['success_bonus'] * 100)) + "%  "
		info.add_child(_lbl(stats, Color(0.55, 0.7, 0.55), 11))
		btn_row.add_child(info)

		var craft_btn = Button.new()
		craft_btn.text = "炼制"
		craft_btn.add_theme_font_size_override("font_size", 11)
		craft_btn.disabled = _is_slot_crafting(slot_idx)
		var si_craft = slot_idx
		craft_btn.pressed.connect(func(): _open_craft_popup(si_craft))
		btn_row.add_child(craft_btn)

		var unequip_btn = Button.new()
		unequip_btn.text = "卸下"
		unequip_btn.add_theme_font_size_override("font_size", 11)
		unequip_btn.disabled = _is_slot_crafting(slot_idx)
		var si_unequip = slot_idx
		unequip_btn.pressed.connect(func(): unequip_furnace_requested.emit(si_unequip))
		btn_row.add_child(unequip_btn)

		vbox.add_child(btn_row)

		if _is_slot_crafting(slot_idx):
			var cs = _crafting_states[slot_idx]
			var prog_vbox = VBoxContainer.new()
			prog_vbox.add_theme_constant_override("separation", 2)

			var header_row = HBoxContainer.new()
			header_row.add_theme_constant_override("separation", 6)

			var batch_text = ""
			if cs['total'] > 1:
				batch_text = " (" + str(cs['total'] - cs['remaining']) + "/" + str(cs['total']) + ")"
			var prog_header = _lbl("炼制中" + batch_text, Color(1.0, 0.6, 0.2), 11)
			prog_header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header_row.add_child(prog_header)

			var cancel_btn = Button.new()
			cancel_btn.text = "取消"
			cancel_btn.add_theme_font_size_override("font_size", 10)
			var si_cancel = slot_idx
			cancel_btn.pressed.connect(func():
				_crafting_states[si_cancel] = null
				refresh()
			)
			header_row.add_child(cancel_btn)
			prog_vbox.add_child(header_row)

			var prog_name = _lbl(cs['recipe'].get('name', ''), Color(0.9, 0.7, 0.3), 10)
			prog_vbox.add_child(prog_name)

			var pb = ProgressBar.new()
			pb.min_value = 0
			pb.max_value = 100
			pb.value = cs['elapsed'] / cs['time_per'] * 100.0
			pb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			pb.name = "ProgBar_" + str(slot_idx)
			var fill_style = StyleBoxFlat.new()
			fill_style.bg_color = Color(1.0, 0.6, 0.2)
			pb.add_theme_stylebox_override("fill", fill_style)
			prog_vbox.add_child(pb)

			vbox.add_child(prog_vbox)
	else:
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var info = VBoxContainer.new()
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)
		info.add_child(_lbl("槽位" + str(slot_idx + 1) + "  空", Color(0.5, 0.5, 0.6), 13))
		info.add_child(_wlbl("安装丹炉提升炼制效果", Color(0.4, 0.45, 0.55), 11))
		row.add_child(info)

		var btn = Button.new()
		btn.text = "选择"
		btn.add_theme_font_size_override("font_size", 11)
		btn.disabled = _furnace_inventory.is_empty()
		var si = slot_idx
		btn.pressed.connect(func(): _open_furnace_select(si))
		row.add_child(btn)

		vbox.add_child(row)

	list.add_child(card)

# ===== 刷新 =====

func refresh():
	_update_tabs()

	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	_build_furnace_slots(list)

	list.add_child(HSeparator.new())

	if _current_tab == "craft":
		_build_recipes(list)
	else:
		_build_pills(list)

func _build_recipes(list: VBoxContainer):
	var h = _lbl("── 已学丹方 ──", Color(0.3, 0.8, 1.0), 14)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(h)

	if _recipes.is_empty():
		var e = _lbl("尚未学会任何丹方，请在商店购买", Color(0.5, 0.5, 0.6), 11)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(e)
		return

	var bonuses = _get_bonuses()
	var reduction = 1.0 - bonuses['cost_reduction']
	var speed = 1.0 + bonuses['speed']

	for recipe in _recipes:
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_bg())
		var vbox2 = VBoxContainer.new()
		vbox2.add_theme_constant_override("separation", 2)
		card.add_child(vbox2)

		vbox2.add_child(_lbl(recipe['name'], Color(1.0, 0.8, 0.5), 13))
		var cost = int(recipe['craft_cost'] * reduction)
		var craft_time = max(0.3, 2.0 / speed)
		vbox2.add_child(_wlbl(recipe['desc'] + " | " + _fmt(cost) + "灵 | " + str(craft_time).pad_decimals(1) + "秒", Color(0.55, 0.55, 0.7), 11))

		list.add_child(card)

func _build_pills(list: VBoxContainer):
	var h = _lbl("── 丹药背包 ──", Color(0.9, 0.6, 0.3), 14)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(h)

	if _pills.is_empty():
		var e = _lbl("暂无丹药", Color(0.5, 0.5, 0.6), 11)
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		list.add_child(e)
		return

	for pn in _pills:
		var cnt = _pills[pn]
		if cnt <= 0:
			continue
		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_bg())
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		card.add_child(row)

		var info = _lbl(pn + " x" + str(cnt), Color(0.9, 0.7, 0.5), 13)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var btn = Button.new()
		btn.text = "使用"
		btn.add_theme_font_size_override("font_size", 12)
		var name = pn
		btn.pressed.connect(func(): use_pill_requested.emit(name))
		row.add_child(btn)

		list.add_child(card)

# ===== 进程 =====

func _process(delta: float):
	if not visible:
		return

	var has_any_craft = false
	for si in range(_crafting_states.size()):
		var cs = _crafting_states[si]
		if cs == null:
			continue
		has_any_craft = true
		cs['elapsed'] += delta
		var bar = find_child("ProgBar_" + str(si), true, false)
		if bar and bar is ProgressBar:
			bar.value = cs['elapsed'] / cs['time_per'] * 100.0
		if cs['elapsed'] >= cs['time_per']:
			_complete_crafting(si)

	_needs_process = has_any_craft

	if _toast_active:
		_process_toast(delta)

	if not _needs_process and not _toast_active:
		set_process(false)

func _ready():
	$VBox/SubMenuBar/BtnTab1.text = "丹方"
	$VBox/SubMenuBar/BtnTab2.text = "丹药"

	$VBox/TopBar/BtnBack.pressed.connect(func():
		_clear_popup()
		back_requested.emit()
	)
	$VBox/SubMenuBar/BtnTab1.pressed.connect(func():
		_current_tab = "craft"
		refresh()
	)
	$VBox/SubMenuBar/BtnTab2.pressed.connect(func():
		_current_tab = "pills"
		refresh()
	)

	_init_toast()
	set_process(false)
