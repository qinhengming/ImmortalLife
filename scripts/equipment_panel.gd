extends PanelContainer

const UI := preload("res://scripts/ui_common.gd")

signal back_requested()
signal unequip_requested(slot: String)

var _equipped_items: Dictionary = {}
var _equipment_slots: Array = [
	"weapon", "helmet", "armor", "boots", "artifact",
	"accessory", "belt", "ring_left", "ring_right", "cloak"
]
var _equipment_slot_names: Dictionary = {
	"weapon": "武器",
	"helmet": "头盔",
	"armor": "防具",
	"boots": "鞋子",
	"artifact": "法宝",
	"accessory": "饰品",
	"belt": "腰带",
	"ring_left": "左戒",
	"ring_right": "右戒",
	"cloak": "披风",
}
var _slot_colors: Dictionary = {
	"weapon": Color(1, 0.6, 0.4),
	"helmet": Color(0.7, 0.73, 0.85),
	"armor": Color(0.4, 0.8, 1),
	"boots": Color(0.5, 1, 0.5),
	"artifact": Color(1, 0.84, 0),
	"accessory": Color(0.9, 0.7, 1),
	"belt": Color(1, 0.85, 0.65),
	"ring_left": Color(0.3, 1, 0.85),
	"ring_right": Color(0.3, 1, 0.85),
	"cloak": Color(0.75, 0.6, 0.9),
}
var _realms: Array = []
var _detail_popup: Control = null


func set_state(data: Dictionary):
	_equipped_items = data.get('equipped_items', {}).duplicate()
	if data.has('equipment_slots'):
		_equipment_slots = data.get('equipment_slots', _equipment_slots)
	if data.has('equipment_slot_names'):
		_equipment_slot_names = data.get('equipment_slot_names', _equipment_slot_names)
	if data.has('realms'):
		_realms = data.get('realms', [])


func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())


func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	return UI.lbl(text, color, font_size)


func _get_slot_color(slot: String) -> Color:
	return _slot_colors.get(slot, Color(0.95, 0.95, 1.0))


func refresh():
	_close_detail_popup()

	var list = $VBox/ScrollList/ItemList
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	var mid = _equipment_slots.size() / 2
	var left_slots = _equipment_slots.slice(0, mid)
	var right_slots = _equipment_slots.slice(mid)

	var columns = HBoxContainer.new()
	columns.alignment = BoxContainer.ALIGNMENT_CENTER
	columns.add_theme_constant_override("separation", 16)
	list.add_child(columns)

	var left_col = VBoxContainer.new()
	left_col.alignment = BoxContainer.ALIGNMENT_CENTER
	left_col.add_theme_constant_override("separation", 8)
	columns.add_child(left_col)

	var right_col = VBoxContainer.new()
	right_col.alignment = BoxContainer.ALIGNMENT_CENTER
	right_col.add_theme_constant_override("separation", 8)
	columns.add_child(right_col)

	var total_atk = 0
	var total_def = 0

	for slot in _equipment_slots:
		var item = _equipped_items.get(slot, null)
		if item != null:
			total_atk += item.get('atk_bonus', 0)
			total_def += item.get('def_bonus', 0)

		var col = left_col if left_slots.has(slot) else right_col
		col.add_child(_make_equip_grid_cell(slot, item))

	var separator = HSeparator.new()
	list.add_child(separator)

	var stat_label = _pl("", Color(1, 0.84, 0), 12)
	if total_atk > 0 or total_def > 0:
		var tp = []
		if total_atk > 0:
			tp.append("攻击+" + str(total_atk))
		if total_def > 0:
			tp.append("防御+" + str(total_def))
		stat_label.text = "总加成：" + "  ".join(tp)
	else:
		stat_label.text = "未装备任何物品"
		stat_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(stat_label)

	var hint = _pl("── 点击装备槽查看详情 ──", Color(0.35, 0.35, 0.45), 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(hint)


func _make_equip_grid_cell(slot: String, item) -> PanelContainer:
	var cell = PanelContainer.new()
	cell.custom_minimum_size = Vector2(140, 64)
	cell.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	if item != null:
		style.bg_color = Color(0.1, 0.14, 0.22)
		var slot_color = _get_slot_color(slot)
		style.border_color = slot_color.darkened(0.3)
	else:
		style.bg_color = Color(0.12, 0.12, 0.14)
		style.border_color = Color(0.3, 0.3, 0.35)
	cell.add_theme_stylebox_override("panel", style)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.add_child(hbox)

	var icon = PanelContainer.new()
	icon.custom_minimum_size = Vector2(36, 36)
	var icon_style = StyleBoxFlat.new()
	icon_style.corner_radius_top_left = 4
	icon_style.corner_radius_top_right = 4
	icon_style.corner_radius_bottom_left = 4
	icon_style.corner_radius_bottom_right = 4
	if item != null:
		icon_style.bg_color = _get_slot_color(slot).darkened(0.5)
		icon_style.border_color = _get_slot_color(slot)
		icon_style.border_width_left = 1
		icon_style.border_width_right = 1
		icon_style.border_width_top = 1
		icon_style.border_width_bottom = 1
	else:
		icon_style.bg_color = Color(0.08, 0.08, 0.1)
		icon_style.border_color = Color(0.25, 0.25, 0.3)
		icon_style.border_width_left = 1
		icon_style.border_width_right = 1
		icon_style.border_width_top = 1
		icon_style.border_width_bottom = 1
	icon.add_theme_stylebox_override("panel", icon_style)

	var icon_label = _pl("", _get_slot_color(slot), 18)
	if item != null:
		icon_label.text = item['name'].substr(0, 1)
	else:
		icon_label.text = "◻"
		icon_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icon_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	icon.add_child(icon_label)
	hbox.add_child(icon)

	var info_vbox = VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 0)
	info_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var slot_label = _pl(_equipment_slot_names.get(slot, slot), Color(0.45, 0.55, 0.7), 10)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_vbox.add_child(slot_label)

	var name_label = Label.new()
	if item != null:
		name_label.text = item['name']
		name_label.add_theme_font_size_override("font_size", 12)
		name_label.add_theme_color_override("font_color", _get_slot_color(slot))
	else:
		name_label.text = "空"
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_vbox.add_child(name_label)

	var slot_copy = slot
	var item_copy = item
	cell.gui_input.connect(
		func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_show_detail_popup(slot_copy, item_copy)
	)

	return cell


func _show_detail_popup(slot: String, item):
	_close_detail_popup()

	var overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 100
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.5)
	var bg = Panel.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	bg.add_theme_stylebox_override("panel", bg_style)
	overlay.add_child(bg)
	bg.gui_input.connect(
		func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_close_detail_popup()
	)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(220, 140)
	var card_style = StyleBoxFlat.new()
	card_style.bg_color = Color(0.1, 0.12, 0.18, 0.98)
	card_style.border_width_left = 1
	card_style.border_width_right = 1
	card_style.border_width_top = 1
	card_style.border_width_bottom = 1
	card_style.border_color = Color(0.3, 0.45, 0.65)
	card_style.corner_radius_top_left = 8
	card_style.corner_radius_top_right = 8
	card_style.corner_radius_bottom_left = 8
	card_style.corner_radius_bottom_right = 8
	card_style.content_margin_left = 14
	card_style.content_margin_right = 14
	card_style.content_margin_top = 12
	card_style.content_margin_bottom = 12
	card.add_theme_stylebox_override("panel", card_style)
	center.add_child(card)

	var card_vbox = VBoxContainer.new()
	card_vbox.add_theme_constant_override("separation", 6)
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(card_vbox)

	var slot_color = _get_slot_color(slot)

	if item != null:
		var title = _pl(item['name'], slot_color, 18)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(title)

		var type_text = _equipment_slot_names.get(slot, slot)
		var type_label = _pl(type_text, Color(0.55, 0.65, 0.8), 12)
		type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(type_label)

		var sep = HSeparator.new()
		card_vbox.add_child(sep)

		var desc_label = Label.new()
		desc_label.text = item['desc']
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.8))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card_vbox.add_child(desc_label)

		var sep2 = HSeparator.new()
		card_vbox.add_child(sep2)

		var stats_hbox = HBoxContainer.new()
		stats_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
		stats_hbox.add_theme_constant_override("separation", 14)
		card_vbox.add_child(stats_hbox)

		if item['atk_bonus'] > 0:
			stats_hbox.add_child(_pl("攻击+" + str(item['atk_bonus']), Color(1, 0.55, 0.4), 13))
		if item['def_bonus'] > 0:
			stats_hbox.add_child(_pl("防御+" + str(item['def_bonus']), Color(0.4, 0.8, 1), 13))
		if item['mana_bonus'] > 0:
			stats_hbox.add_child(_pl("灵气+" + str(item['mana_bonus']), Color(0.5, 1, 0.5), 13))

		var sep3 = HSeparator.new()
		card_vbox.add_child(sep3)

		var btn_row = HBoxContainer.new()
		btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
		btn_row.add_theme_constant_override("separation", 12)
		card_vbox.add_child(btn_row)

		var unequip_btn = Button.new()
		unequip_btn.text = "卸 下"
		unequip_btn.custom_minimum_size = Vector2(70, 30)
		unequip_btn.add_theme_font_size_override("font_size", 13)
		var slot_ref = slot
		var item_ref = item
		unequip_btn.pressed.connect(func():
			_close_detail_popup()
			unequip_requested.emit(slot_ref)
		)
		btn_row.add_child(unequip_btn)

		var close_btn = Button.new()
		close_btn.text = "关 闭"
		close_btn.custom_minimum_size = Vector2(70, 30)
		close_btn.add_theme_font_size_override("font_size", 13)
		close_btn.pressed.connect(_close_detail_popup)
		btn_row.add_child(close_btn)

	else:
		var title = _pl(_equipment_slot_names.get(slot, slot) + "（空）", Color(0.4, 0.4, 0.5), 16)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(title)

		var hint_text = _pl("该槽位未装备物品", Color(0.5, 0.5, 0.6), 12)
		hint_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card_vbox.add_child(hint_text)

		var sep3 = HSeparator.new()
		card_vbox.add_child(sep3)

		var close_btn = Button.new()
		close_btn.text = "关 闭"
		close_btn.custom_minimum_size = Vector2(70, 30)
		close_btn.add_theme_font_size_override("font_size", 13)
		close_btn.pressed.connect(_close_detail_popup)
		card_vbox.add_child(close_btn)

	add_child(overlay)
	_detail_popup = overlay


func _close_detail_popup():
	if _detail_popup:
		_detail_popup.queue_free()
		_detail_popup = null
		_detail_popup = null
