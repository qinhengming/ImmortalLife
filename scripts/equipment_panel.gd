extends PanelContainer

signal back_requested()
signal unequip_requested(slot: String)

var _equipped_items: Dictionary = {}
var _equipment_slots: Array = ["weapon", "armor", "accessory", "artifact"]
var _equipment_slot_names: Dictionary = {
	"weapon": "武器",
	"armor": "防具",
	"accessory": "饰品",
	"artifact": "法宝",
}
var _realms: Array = []
var _tooltip_node: PanelContainer = null


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


func _process(_delta: float):
	if _tooltip_node and _tooltip_node.visible:
		var mp = get_global_mouse_position()
		_tooltip_node.position = Vector2(mp.x + 12, mp.y + 12)


func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label


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


func refresh():
	var list = $VBox/ScrollList/ItemList
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	# 装备格子行
	var grid = HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 12)
	list.add_child(grid)

	var total_atk = 0
	var total_def = 0

	for slot in _equipment_slots:
		var item = _equipped_items.get(slot, null)
		if item != null:
			total_atk += item.get('atk_bonus', 0)
			total_def += item.get('def_bonus', 0)
		grid.add_child(_make_equip_grid_cell(slot, item))

	# 总加成
	var tp = []
	if total_atk > 0:
		tp.append("攻击+" + str(total_atk))
	if total_def > 0:
		tp.append("防御+" + str(total_def))

	var stat_label = _pl("", Color(1, 0.84, 0), 12)
	if tp.size() > 0:
		stat_label.text = "总加成：" + "  ".join(tp)
	else:
		stat_label.text = "未装备任何物品"
		stat_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(stat_label)

	# 提示
	var hint = _pl("── 点击方格可卸下装备 ──", Color(0.35, 0.35, 0.45), 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(hint)


func _make_equip_grid_cell(slot: String, item) -> PanelContainer:
	var cell = PanelContainer.new()
	cell.custom_minimum_size = Vector2(100, 60)

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	if item != null:
		style.bg_color = Color(0.1, 0.14, 0.22)
		style.border_color = Color(0.25, 0.5, 0.8)
	else:
		style.bg_color = Color(0.12, 0.12, 0.14)
		style.border_color = Color(0.3, 0.3, 0.35)
	cell.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.add_child(vbox)

	# 槽位名
	var slot_label = _pl(_equipment_slot_names.get(slot, slot), Color(0.45, 0.55, 0.7), 10)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slot_label)

	# 物品名
	var name_label = Label.new()
	if item != null:
		name_label.text = item['name']
		name_label.add_theme_font_size_override("font_size", 13)
		match slot:
			"weapon":
				name_label.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
			"armor":
				name_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
			"accessory":
				name_label.add_theme_color_override("font_color", Color(0.9, 0.7, 1))
			"artifact":
				name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	else:
		name_label.text = "[ 空 ]"
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# 鼠标事件
	var slot_copy = slot
	var item_copy = item
	cell.mouse_entered.connect(func(): _show_tooltip(slot_copy, item_copy))
	cell.mouse_exited.connect(hide_tooltip)
	cell.gui_input.connect(
		func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				if item_copy != null:
					unequip_requested.emit(slot_copy)
					hide_tooltip()
	)

	return cell


func _show_tooltip(slot: String, item):
	hide_tooltip()
	_tooltip_node = PanelContainer.new()
	_tooltip_node.z_index = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.5, 0.7)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_tooltip_node.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	_tooltip_node.add_child(vbox)

	# 物品名
	var title = Label.new()
	if item != null:
		title.text = item['name']
		title.add_theme_font_size_override("font_size", 14)
		match slot:
			"weapon":
				title.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
			"armor":
				title.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
			"accessory":
				title.add_theme_color_override("font_color", Color(0.9, 0.7, 1))
			"artifact":
				title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	else:
		title.text = _equipment_slot_names.get(slot, slot) + "（空）"
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(title)

	# 类型
	var type_label = _pl("类型：" + _equipment_slot_names.get(slot, slot), Color(0.5, 0.6, 0.75), 11)
	vbox.add_child(type_label)

	if item != null:
		# 描述
		var desc = Label.new()
		desc.text = item['desc']
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		vbox.add_child(desc)

		# 分隔线
		var sep = HSeparator.new()
		sep.add_theme_constant_override("separation", 4)
		vbox.add_child(sep)

		# 属性
		var stats = []
		if item['atk_bonus'] > 0:
			stats.append("攻击  +" + str(item['atk_bonus']))
		if item['def_bonus'] > 0:
			stats.append("防御  +" + str(item['def_bonus']))
		if item['mana_bonus'] > 0:
			stats.append("灵气  +" + str(item['mana_bonus']))
		for s in stats:
			var sl = Label.new()
			sl.text = s
			sl.add_theme_font_size_override("font_size", 12)
			sl.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
			vbox.add_child(sl)

		# 分隔线
		var sep2 = HSeparator.new()
		vbox.add_child(sep2)

		# 操作提示
		var action = Label.new()
		action.text = "点击卸下"
		action.add_theme_font_size_override("font_size", 10)
		action.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(action)

	add_child(_tooltip_node)
	_tooltip_node.visible = true
	var mp = get_global_mouse_position()
	_tooltip_node.position = Vector2(mp.x + 12, mp.y + 12)


func hide_tooltip():
	if _tooltip_node:
		_tooltip_node.visible = false
		_tooltip_node.queue_free()
		_tooltip_node = null
