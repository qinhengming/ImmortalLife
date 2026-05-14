extends PanelContainer

const BID = "spirit_array"

var _building: Dictionary = {}
var _energy: float = 0.0
var _learned_arrays: Array = []
var _active_array: String = ""
var _shop_arrays: Array = []

var _array_select_popup: PopupPanel = null

signal back_requested()
signal building_action_requested(bid: String)
signal set_array_requested(array_name: String)

# 八卦方位
const TRIGRAM_ORDER = ['☰', '☱', '☲', '☳', '☴', '☵', '☶', '☷']
const TRIGRAM_NAMES = {'☰': '乾', '☱': '兑', '☲': '离', '☳': '震', '☴': '巽', '☵': '坎', '☶': '艮', '☷': '坤'}

func set_state(building: Dictionary, energy: float, learned_arrs: Array = [], active_arr: String = "", shop_arrs: Array = []):
	_building = building.duplicate()
	_energy = energy
	_learned_arrays = learned_arrs
	_active_array = active_arr
	_shop_arrays = shop_arrs

func _get_array_data(array_name: String) -> Dictionary:
	for arr in _shop_arrays:
		if arr['name'] == array_name:
			return arr
	return {}

func _card_bg(color: Color = Color(0.1, 0.12, 0.18), border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
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

func _lbl(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	return l

func _fmt(n: float) -> String:
	var s = str(int(n))
	var r = ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			r += ","
		r += s[i]
	return r

# ==================== 八卦图绘制 ====================

func _draw_bagua_bg(ctrl: Control):
	var cx = ctrl.size.x / 2.0
	var cy = ctrl.size.y / 2.0
	var r = min(cx, cy) - 20.0

	# 外圈双环
	ctrl.draw_arc(Vector2(cx, cy), r + 3, 0, TAU, 64, Color(0.1, 0.25, 0.4), 3)
	ctrl.draw_arc(Vector2(cx, cy), r, 0, TAU, 64, Color(0.2, 0.5, 0.75), 2)
	ctrl.draw_arc(Vector2(cx, cy), r - 3, 0, TAU, 64, Color(0.15, 0.35, 0.55), 1.5)

	# 内圈
	var inner_r = r * 0.40
	ctrl.draw_arc(Vector2(cx, cy), inner_r, 0, TAU, 64, Color(0.25, 0.55, 0.8), 1.5)

	# 中圈（分隔环）
	var mid_r = r * 0.68
	ctrl.draw_arc(Vector2(cx, cy), mid_r, 0, TAU, 64, Color(0.18, 0.38, 0.58, 0.5), 1)

	# 8条分割线（内圈到外圈）
	for i in range(8):
		var angle = -PI / 2.0 + i * TAU / 8.0
		var x1 = cx + cos(angle) * inner_r
		var y1 = cy + sin(angle) * inner_r
		var x2 = cx + cos(angle) * r
		var y2 = cy + sin(angle) * r
		ctrl.draw_line(Vector2(x1, y1), Vector2(x2, y2), Color(0.18, 0.38, 0.6, 0.55), 1)

	# 卦名符号（外圈）
	for i in range(8):
		var angle = -PI / 2.0 + i * TAU / 8.0
		var px = cx + cos(angle) * r * 0.84
		var py = cy + sin(angle) * r * 0.84
		ctrl.draw_circle(Vector2(px, py), 6, Color(0.25, 0.6, 0.85, 0.6), false, 1.2)

	# 中心——太极图
	var cr = inner_r * 0.82

	# 深色底色
	ctrl.draw_circle(Vector2(cx, cy), cr, Color(0.12, 0.14, 0.22, 0.75))

	# 左半（阳）——亮色覆盖
	var pts_yang = PackedVector2Array()
	pts_yang.append(Vector2(cx, cy))
	for deg in range(-90, 91):
		var a = deg_to_rad(deg)
		pts_yang.append(Vector2(cx + cos(a) * cr, cy + sin(a) * cr))
	var half_cr = cr / 2.0
	for deg in range(90, -91, -1):
		var a = deg_to_rad(deg)
		pts_yang.append(Vector2(cx - half_cr + cos(a) * half_cr, cy + sin(a) * half_cr))
	ctrl.draw_colored_polygon(pts_yang, Color(0.75, 0.82, 0.95, 0.55))

	# 两个"鱼眼"
	ctrl.draw_circle(Vector2(cx + half_cr, cy), half_cr * 0.35, Color(0.85, 0.88, 0.95, 0.9))
	ctrl.draw_circle(Vector2(cx - half_cr, cy), half_cr * 0.35, Color(0.12, 0.14, 0.22, 0.9))

	# 内圈装饰线
	ctrl.draw_arc(Vector2(cx, cy), cr, 0, TAU, 64, Color(0.35, 0.65, 0.95, 0.5), 1)


func refresh():
	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	var level = _building.get('level', 0)
	var max_lv = 10

	# ========== 八卦图区域 ==========
	var bagua_control = Control.new()
	bagua_control.custom_minimum_size = Vector2(340, 340)
	bagua_control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bagua_control.draw.connect(_draw_bagua_bg.bind(bagua_control))
	list.add_child(bagua_control)

	# 八卦图尺寸计算
	var cx = 170.0
	var cy = 170.0
	var r = min(cx, cy) - 20.0
	var inner_r = r * 0.40

	# 8个卦名标签（外圈小圆点处）
	for i in range(8):
		var angle = -PI / 2.0 + i * TAU / 8.0
		var trigram_char = TRIGRAM_ORDER[i]
		var trigram_name = TRIGRAM_NAMES.get(trigram_char, '?')
		var lx = cx + cos(angle) * r * 0.84 - 12
		var ly = cy + sin(angle) * r * 0.84 - 22
		var tlabel = Label.new()
		tlabel.text = trigram_char
		tlabel.add_theme_font_size_override("font_size", 12)
		tlabel.add_theme_color_override("font_color", Color(0.4, 0.7, 0.95))
		tlabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tlabel.position = Vector2(lx, ly)
		tlabel.size = Vector2(24, 20)
		bagua_control.add_child(tlabel)

	# 8个卦名文字（中圈位置）
	for i in range(8):
		var angle = -PI / 2.0 + i * TAU / 8.0
		var trigram_char = TRIGRAM_ORDER[i]
		var trigram_name = TRIGRAM_NAMES.get(trigram_char, '?')
		var px = cx + cos(angle) * r * 0.55 - 16
		var py = cy + sin(angle) * r * 0.55 - 10
		var nl = Label.new()
		nl.text = trigram_name
		nl.add_theme_font_size_override("font_size", 10)
		nl.add_theme_color_override("font_color", Color(0.3, 0.5, 0.7))
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.position = Vector2(px, py)
		nl.size = Vector2(32, 20)
		bagua_control.add_child(nl)

	# ========== 中心阵法槽位 ==========
	var center_size = int(inner_r * 1.4)
	var center_x = int(cx - center_size / 2.0)
	var center_y = int(cy - center_size / 2.0)

	var array_slot = PanelContainer.new()
	array_slot.position = Vector2(center_x, center_y)
	array_slot.size = Vector2(center_size, center_size)
	var slot_style = StyleBoxFlat.new()
	slot_style.bg_color = Color(0.08, 0.1, 0.16, 0.85)
	slot_style.corner_radius_top_left = int(center_size / 2)
	slot_style.corner_radius_top_right = int(center_size / 2)
	slot_style.corner_radius_bottom_left = int(center_size / 2)
	slot_style.corner_radius_bottom_right = int(center_size / 2)
	slot_style.border_width_left = 2
	slot_style.border_width_right = 2
	slot_style.border_width_top = 2
	slot_style.border_width_bottom = 2
	slot_style.border_color = Color(0.35, 0.7, 1.0, 0.8)
	slot_style.content_margin_left = 4
	slot_style.content_margin_right = 4
	slot_style.content_margin_top = 4
	slot_style.content_margin_bottom = 4
	array_slot.add_theme_stylebox_override("panel", slot_style)
	bagua_control.add_child(array_slot)

	var slot_vbox = VBoxContainer.new()
	slot_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	slot_vbox.add_theme_constant_override("separation", 4)
	array_slot.add_child(slot_vbox)

	var array_icon = Label.new()
	array_icon.text = "☯"
	array_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	array_icon.add_theme_font_size_override("font_size", 22)
	array_icon.add_theme_color_override("font_color", Color(0.5, 0.85, 1.0))
	slot_vbox.add_child(array_icon)

	var array_name_label = Label.new()
	if _active_array != "":
		var arr_data = _get_array_data(_active_array)
		array_name_label.text = arr_data.get('name', _active_array)
		array_name_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6))
	else:
		array_name_label.text = "未设阵"
		array_name_label.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
	array_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	array_name_label.add_theme_font_size_override("font_size", 12)
	slot_vbox.add_child(array_name_label)

	var array_btn = Button.new()
	array_btn.text = "选择阵法"
	array_btn.add_theme_font_size_override("font_size", 11)
	array_btn.custom_minimum_size = Vector2(0, 24)
	array_btn.pressed.connect(_open_array_select)
	slot_vbox.add_child(array_btn)

	# ========== 建筑信息卡 ==========
	var info = PanelContainer.new()
	info.add_theme_stylebox_override("panel", _card_bg(Color(0.08, 0.12, 0.18)))
	var iv = VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	info.add_child(iv)

	iv.add_child(_lbl("聚灵阵  Lv." + str(level) + "/" + str(max_lv), Color(0.3, 0.8, 1.0), 18))
	iv.add_child(_lbl("汇聚天地灵气，提升修炼效率", Color(0.7, 0.7, 0.8), 12))
	iv.add_child(_lbl("效果：每级提升洞府效率10%", Color(0.4, 0.9, 0.5), 12))
	iv.add_child(_lbl("当前加成：洞府效率 +" + str(level * 10) + "%", Color(0.9, 0.75, 0.3), 13))

	if level >= max_lv:
		iv.add_child(_lbl("已升至满级", Color(0.4, 0.8, 0.4), 13))
	else:
		var cost = int(500 * pow(1.5, level))
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

	# 说明
	var desc_label = _lbl("在此设置阵法，可激活已掌握的阵法之力。", Color(0.3, 0.8, 1.0), 12)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(desc_label)


# ==================== 阵法选择弹窗 ====================

func _open_array_select():
	if _array_select_popup != null and is_instance_valid(_array_select_popup):
		_array_select_popup.queue_free()
		_array_select_popup = null
	_create_array_select_popup()
	_populate_array_select()
	_array_select_popup.popup_centered()

func _create_array_select_popup():
	_array_select_popup = PopupPanel.new()
	_array_select_popup.title = "选择阵法"
	_array_select_popup.size = Vector2(280, 350)
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.1, 0.12, 0.2)
	popup_style.corner_radius_top_left = 8
	popup_style.corner_radius_top_right = 8
	popup_style.corner_radius_bottom_left = 8
	popup_style.corner_radius_bottom_right = 8
	popup_style.content_margin_left = 8
	popup_style.content_margin_right = 8
	popup_style.content_margin_top = 8
	popup_style.content_margin_bottom = 8
	_array_select_popup.add_theme_stylebox_override("panel", popup_style)

	var vbox = VBoxContainer.new()
	vbox.name = "PopupVBox"
	vbox.add_theme_constant_override("separation", 6)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_array_select_popup.add_child(vbox)

	var scroll = ScrollContainer.new()
	scroll.name = "PopupScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var item_list = VBoxContainer.new()
	item_list.name = "ArrayItemList"
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 4)
	scroll.add_child(item_list)
	_array_select_popup.set_meta("item_list", item_list)

	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(func():
		_array_select_popup.hide()
		_array_select_popup.queue_free()
		_array_select_popup = null
	)
	vbox.add_child(close_btn)

	add_child(_array_select_popup)

func _populate_array_select():
	var item_list = _array_select_popup.get_meta("item_list")
	if item_list == null:
		return
	for c in item_list.get_children():
		item_list.remove_child(c)
		c.queue_free()

	# 取消阵法选项
	var cancel_card = _make_select_card("", "取消阵法", "", Color(0.5, 0.5, 0.6), _active_array == "")
	item_list.add_child(cancel_card)

	# 已学会的阵法
	for arr_name in _learned_arrays:
		var arr_data = _get_array_data(arr_name)
		if arr_data.is_empty():
			continue
		var selected = (_active_array == arr_name)
		var trigram = arr_data.get('trigram', '')
		var card = _make_select_card(arr_name, trigram + " " + arr_name, arr_data.get('desc', ''), arr_data.get('color', Color(0.7, 0.7, 0.8)), selected)
		item_list.add_child(card)

	if _learned_arrays.is_empty():
		var empty_label = Label.new()
		empty_label.text = "尚未学会任何阵法\n请前往商店购买"
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.5, 0.6))
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.add_theme_constant_override("margin_top", 20)
		item_list.add_child(empty_label)

func _make_select_card(array_name: String, display_name: String, desc: String, accent_color: Color, selected: bool) -> PanelContainer:
	var card = PanelContainer.new()

	var s = StyleBoxFlat.new()
	if selected:
		s.bg_color = Color(0.08, 0.2, 0.12)
		s.border_width_left = 2
		s.border_width_right = 2
		s.border_width_top = 2
		s.border_width_bottom = 2
		s.border_color = Color(0.3, 1.0, 0.5)
	else:
		s.bg_color = Color(0.08, 0.1, 0.16)
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.border_color = Color(0.2, 0.2, 0.3)
	s.corner_radius_top_left = 5
	s.corner_radius_top_right = 5
	s.corner_radius_bottom_left = 5
	s.corner_radius_bottom_right = 5
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", s)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	card.add_child(hbox)

	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", accent_color)
	info_vbox.add_child(name_label)

	if desc != "":
		var desc_label = Label.new()
		desc_label.text = desc
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
		desc_label.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(desc_label)

	if selected:
		var sel_label = Label.new()
		sel_label.text = "▶ 当前激活"
		sel_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		sel_label.add_theme_font_size_override("font_size", 11)
		hbox.add_child(sel_label)
	else:
		var btn = Button.new()
		btn.text = "激活"
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(48, 24)
		var an = array_name
		btn.pressed.connect(func():
			set_array_requested.emit(an)
			if is_instance_valid(_array_select_popup):
				_array_select_popup.hide()
				_array_select_popup.queue_free()
				_array_select_popup = null
		)
		hbox.add_child(btn)

	return card


func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
