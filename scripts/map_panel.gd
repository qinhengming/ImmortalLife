extends PanelContainer

const UI := preload("res://scripts/ui_common.gd")

signal back_requested()
signal start_battle_requested(map: Dictionary, sub_map: int)
signal stop_battle_requested()
signal settings_changed(auto_next: bool, loop_current: bool)

var _maps: Array = []
var _realm_level: int = 1
var _in_battle: bool = false
var _enemy_team: Array = []
var _ally_team: Array = []
var _battle_log: String = ""
var _auto_next_map: bool = false
var _loop_current_map: bool = false
var _map_sub_level: Dictionary = {}
var _current_map: Dictionary = {}
var _current_sub_map: int = 1
var _selected_map: String = ""
var _selected_sub: int = 1
var _settings_popup: Control = null
var _detail_popup: Control = null


func set_state(data: Dictionary):
	_maps = data.get('maps', [])
	_realm_level = data.get('realm_level', 1)
	_in_battle = data.get('in_battle', false)
	_enemy_team = data.get('enemy_team', [])
	_ally_team = data.get('ally_team', [])
	_battle_log = data.get('battle_log', "")
	_auto_next_map = data.get('auto_next_map', false)
	_loop_current_map = data.get('loop_current_map', false)
	_map_sub_level = data.get('map_sub_level', {}).duplicate()
	_current_map = data.get('current_map', {})
	_current_sub_map = data.get('current_sub_map', 1)


func refresh():
	$VBox/MapArea.visible = not _in_battle
	$VBox/BattleArea.visible = _in_battle
	if _in_battle:
		refresh_battle_ui()
	else:
		refresh_map_list()


func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
	$VBox/TopBar/BtnSettings.pressed.connect(_show_settings_popup)
	$VBox/BattleArea/StopBtn.pressed.connect(func(): stop_battle_requested.emit())


func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	return UI.lbl(text, color, font_size)


func _make_card_bg(color: Color) -> PanelContainer:
	var card := UI.card(color, Color(0, 0, 0, 0))
	return card


func refresh_map_list():
	var list = $VBox/MapArea/ScrollList/ItemList
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	for mi in range(_maps.size()):
		var map_dict = _maps[mi]
		var map_name = map_dict['name']
		var unlocked = _realm_level >= map_dict['min_level']
		var current_sub = _map_sub_level.get(map_name, 1)

		if not _selected_map.is_empty() and _selected_map == map_name:
			pass
		elif _selected_map.is_empty() and unlocked:
			_selected_map = map_name
			_selected_sub = current_sub

		var card_color = Color(0.14, 0.16, 0.22) if unlocked else Color(0.08, 0.08, 0.1)
		var card = _make_card_bg(card_color)
		var card_vbox = VBoxContainer.new()
		card_vbox.add_theme_constant_override("separation", 4)
		card.add_child(card_vbox)

		var header_row = HBoxContainer.new()
		header_row.add_theme_constant_override("separation", 8)
		card_vbox.add_child(header_row)

		var map_color = map_dict['color'] if unlocked else Color(0.3, 0.3, 0.35)
		header_row.add_child(_pl(map_name, map_color, 15))

		var sub_info = _pl("第" + str(current_sub) + "/100层", Color(0.55, 0.65, 0.8), 10)
		sub_info.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		header_row.add_child(sub_info)

		if unlocked:
			var enter_btn = Button.new()
			enter_btn.text = "历练"
			enter_btn.add_theme_font_size_override("font_size", 11)
			enter_btn.custom_minimum_size = Vector2(48, 24)
			var map_ref = map_dict
			var sub_ref = _selected_sub if _selected_map == map_name else current_sub
			enter_btn.pressed.connect(func():
				var sub = _selected_sub if _selected_map == map_ref['name'] else _map_sub_level.get(map_ref['name'], 1)
				start_battle_requested.emit(map_ref, sub)
			)
			header_row.add_child(enter_btn)
		else:
			var lock_label = _pl("境界不足", Color(0.5, 0.2, 0.2), 10)
			lock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			header_row.add_child(lock_label)

		card_vbox.add_child(_pl(map_dict['desc'], Color(0.5, 0.5, 0.6), 10))

		if unlocked:
			var grid = GridContainer.new()
			grid.columns = 10
			grid.add_theme_constant_override("h_separation", 2)
			grid.add_theme_constant_override("v_separation", 2)

			for sub in range(1, 101):
				var cell = PanelContainer.new()
				cell.custom_minimum_size = Vector2(26, 20)
				var cell_style = StyleBoxFlat.new()
				cell_style.corner_radius_top_left = 2
				cell_style.corner_radius_top_right = 2
				cell_style.corner_radius_bottom_left = 2
				cell_style.corner_radius_bottom_right = 2

				var is_selected = (_selected_map == map_name and _selected_sub == sub)
				var is_passed = sub < current_sub
				var is_current = (sub == current_sub and not is_selected)

				if is_selected:
					cell_style.bg_color = Color(0.2, 0.7, 0.2)
					cell_style.border_width_left = 1
					cell_style.border_width_right = 1
					cell_style.border_width_top = 1
					cell_style.border_width_bottom = 1
					cell_style.border_color = Color(0.3, 1, 0.3)
				elif is_passed:
					cell_style.bg_color = Color(0.1, 0.35, 0.1)
				elif is_current:
					cell_style.bg_color = Color(0.12, 0.25, 0.12)
					cell_style.border_width_left = 1
					cell_style.border_width_right = 1
					cell_style.border_width_top = 1
					cell_style.border_width_bottom = 1
					cell_style.border_color = Color(0.4, 0.7, 0.4)
				else:
					cell_style.bg_color = Color(0.1, 0.12, 0.16)

				cell.add_theme_stylebox_override("panel", cell_style)

				var num_label = Label.new()
				num_label.text = str(sub)
				num_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				num_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				num_label.add_theme_font_size_override("font_size", 9)

				if is_selected:
					num_label.add_theme_color_override("font_color", Color(1, 1, 1))
				elif is_passed:
					num_label.add_theme_color_override("font_color", Color(0.3, 0.7, 0.3))
				elif is_current:
					num_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
				else:
					num_label.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))

				cell.add_child(num_label)

				var map_name_copy = map_name
				var sub_copy = sub
				if sub <= current_sub:
					cell.gui_input.connect(
						func(event: InputEvent):
							if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
								_selected_map = map_name_copy
								_selected_sub = sub_copy
								refresh_map_list()
					)
				grid.add_child(cell)

			card_vbox.add_child(grid)

		list.add_child(card)

		if mi < _maps.size() - 1:
			var sep = HSeparator.new()
			list.add_child(sep)


func _show_settings_popup():
	_close_popups()

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
	bg.gui_input.connect(
		func(event: InputEvent):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_close_popups()
	)
	overlay.add_child(bg)

	var center = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(240, 160)
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
	card_vbox.add_theme_constant_override("separation", 8)
	card_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(card_vbox)

	var title = _pl("地图设置", Color(0.4, 0.8, 1), 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(title)

	var sep = HSeparator.new()
	card_vbox.add_child(sep)

	var auto_row = HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 8)
	card_vbox.add_child(auto_row)

	var auto_check = CheckBox.new()
	auto_check.button_pressed = _auto_next_map
	auto_check.add_theme_font_size_override("font_size", 12)
	auto_row.add_child(auto_check)
	auto_row.add_child(_pl("自动进入下一层", Color(0.9, 0.9, 1), 13))

	var loop_row = HBoxContainer.new()
	loop_row.add_theme_constant_override("separation", 8)
	card_vbox.add_child(loop_row)

	var loop_check = CheckBox.new()
	loop_check.button_pressed = _loop_current_map
	loop_check.add_theme_font_size_override("font_size", 12)
	loop_row.add_child(loop_check)
	loop_row.add_child(_pl("重复刷当前层", Color(0.9, 0.9, 1), 13))

	var hint = _pl("两选项互斥，同时勾选时优先重复刷", Color(0.5, 0.5, 0.6), 9)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_vbox.add_child(hint)

	if _auto_next_map and _loop_current_map:
		hint.text = "已自动取消「自动进入」"
		auto_check.button_pressed = false

	auto_check.toggled.connect(func(pressed: bool):
		if pressed:
			loop_check.button_pressed = false
		_auto_next_map = auto_check.button_pressed
		_loop_current_map = loop_check.button_pressed
		settings_changed.emit(_auto_next_map, _loop_current_map)
	)

	loop_check.toggled.connect(func(pressed: bool):
		if pressed:
			auto_check.button_pressed = false
		_auto_next_map = auto_check.button_pressed
		_loop_current_map = loop_check.button_pressed
		settings_changed.emit(_auto_next_map, _loop_current_map)
	)

	var close_btn = Button.new()
	close_btn.text = "关 闭"
	close_btn.custom_minimum_size = Vector2(80, 30)
	close_btn.add_theme_font_size_override("font_size", 13)
	close_btn.pressed.connect(_close_popups)
	card_vbox.add_child(close_btn)

	add_child(overlay)
	_settings_popup = overlay


func _close_popups():
	if _settings_popup:
		_settings_popup.queue_free()
		_settings_popup = null


func refresh_battle_ui():
	var enemy_label = $VBox/BattleArea/EnemyLabel
	var ally_label = $VBox/BattleArea/AllyLabel
	var enemy_grid = $VBox/BattleArea/EnemyGrid
	var ally_grid = $VBox/BattleArea/AllyGrid
	var battle_log_label = $VBox/BattleArea/BattleLogLabel

	var map_name = _current_map.get('name', '')
	var sub = _current_sub_map
	enemy_label.text = "── 敌方阵营（" + map_name + "第" + str(sub) + "层）──"
	ally_label.text = "── 我方阵营 ──"

	for child in enemy_grid.get_children():
		child.queue_free()
	for child in ally_grid.get_children():
		child.queue_free()

	if _enemy_team.is_empty() and _ally_team.is_empty():
		enemy_label.text = "── 敌方阵营 ──"

	for e in _enemy_team:
		enemy_grid.add_child(_make_char_card(e, false))

	for a in _ally_team:
		ally_grid.add_child(_make_char_card(a, true))

	var max_cells = 6
	while enemy_grid.get_child_count() < max_cells:
		enemy_grid.add_child(_make_empty_card(true))
	while ally_grid.get_child_count() < max_cells:
		ally_grid.add_child(_make_empty_card(false))

	battle_log_label.text = _battle_log


func _make_char_card(data: Dictionary, is_ally: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(105, 85)

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4

	if data.get('alive', false):
		style.bg_color = Color(0.1, 0.22, 0.12) if is_ally else Color(0.22, 0.1, 0.1)
	else:
		style.bg_color = Color(0.08, 0.08, 0.1)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var name_label = Label.new()
	name_label.text = data.get('name', '未知')
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.4, 1, 0.4) if is_ally else Color(1, 0.4, 0.4))
	vbox.add_child(name_label)

	var hp_bar = ProgressBar.new()
	hp_bar.custom_minimum_size = Vector2(0, 10)
	hp_bar.min_value = 0
	hp_bar.max_value = data.get('max_hp', 1)
	hp_bar.value = data.get('hp', 0)
	hp_bar.show_percentage = false
	vbox.add_child(hp_bar)

	var hp_text = Label.new()
	hp_text.text = str(int(data.get('hp', 0))) + "/" + str(int(data.get('max_hp', 0)))
	hp_text.add_theme_font_size_override("font_size", 9)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_text.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(hp_text)

	var stats = HBoxContainer.new()
	stats.alignment = BoxContainer.ALIGNMENT_CENTER
	stats.add_theme_constant_override("separation", 4)
	vbox.add_child(stats)
	stats.add_child(_pl("攻" + str(int(data.get('atk', 0))), Color(1, 0.6, 0.4), 9))
	stats.add_child(_pl("防" + str(int(data.get('def', 0))), Color(0.4, 0.8, 1), 9))

	return card


func _make_empty_card(is_enemy: bool) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(105, 85)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.07, 0.09)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	card.add_child(vbox)
	vbox.add_child(_pl("空", Color(0.2, 0.2, 0.25), 10))

	return card
