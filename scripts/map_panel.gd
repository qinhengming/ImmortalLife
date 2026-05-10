extends PanelContainer

signal back_requested()
signal start_battle_requested(map: Dictionary)
signal stop_battle_requested()

# 数据
var _maps: Array = []
var _realm_level: int = 1
var _in_battle: bool = false
var _current_enemy: Dictionary = {}
var _player_hp: float = 100.0
var _player_max_hp: float = 100.0
var _player_atk: float = 10.0
var _player_def: float = 5.0
var _battle_log: String = ""

func set_state(data: Dictionary):
	_maps = data.get('maps', [])
	_realm_level = data.get('realm_level', 1)
	_in_battle = data.get('in_battle', false)
	_current_enemy = data.get('current_enemy', {})
	_player_hp = data.get('player_hp', 100.0)
	_player_max_hp = data.get('player_max_hp', 100.0)
	_player_atk = data.get('player_atk', 10.0)
	_player_def = data.get('player_def', 5.0)
	_battle_log = data.get('battle_log', "")

func refresh():
	if _in_battle:
		refresh_battle_ui()
	else:
		refresh_map_list()

func refresh_map_list():
	var list = $VBox/ScrollList/ItemList
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	var title = _pl("选择地图进行历练", Color(0.6, 0.6, 0.8), 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)
	list.add_child(HSeparator.new())

	for map_dict in _maps:
		var unlocked = _realm_level >= map_dict['min_level']
		var card = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6
		if unlocked:
			style.bg_color = Color(0.12, 0.16, 0.14)
			style.border_width_left = 1
			style.border_width_right = 1
			style.border_width_top = 1
			style.border_width_bottom = 1
			style.border_color = map_dict['color'] * 0.5
		else:
			style.bg_color = Color(0.1, 0.1, 0.12)
		card.add_theme_stylebox_override("panel", style)

		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 8)
		card.add_child(hbox)

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(vbox)

		var name_label = Label.new()
		name_label.text = map_dict['name']
		name_label.add_theme_font_size_override("font_size", 14)
		if unlocked:
			name_label.add_theme_color_override("font_color", map_dict['color'])
		else:
			name_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
		vbox.add_child(name_label)

		var desc_label = Label.new()
		desc_label.text = map_dict['desc']
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		vbox.add_child(desc_label)

		var level_label = Label.new()
		if unlocked:
			level_label.text = "可进入"
			level_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			level_label.text = "需要境界等级 " + str(map_dict['min_level']) + "（当前 " + str(_realm_level) + "）"
			level_label.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		level_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(level_label)

		if unlocked:
			var btn = Button.new()
			btn.text = "历练"
			var map_ref = map_dict
			btn.pressed.connect(func(): start_battle_requested.emit(map_ref))
			hbox.add_child(btn)

		list.add_child(card)

func refresh_battle_ui():
	var list = $VBox/ScrollList/ItemList
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	if not _in_battle:
		return

	# 敌人信息
	var enemy_title = _pl("── 战斗中 ──", Color(1, 0.4, 0.3), 14)
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(enemy_title)

	var enemy_name = _pl("敌人：" + _current_enemy.get('name', ''), Color(1, 0.6, 0.4), 13)
	list.add_child(enemy_name)

	# 敌人血条
	var enemy_hp_bar = _make_hp_bar(_current_enemy.get('hp', 0), _current_enemy.get('max_hp', 1), Color(0.8, 0.2, 0.2))
	list.add_child(enemy_hp_bar)

	var enemy_hp_text = _pl("HP：" + str(int(_current_enemy.get('hp', 0))) + "/" + str(int(_current_enemy.get('max_hp', 0))), Color(0.9, 0.7, 0.7), 11)
	list.add_child(enemy_hp_text)

	list.add_child(HSeparator.new())

	# 玩家信息
	var player_title = _pl("你的状态", Color(0.4, 0.8, 1), 13)
	list.add_child(player_title)

	# 玩家血条
	var player_hp_bar = _make_hp_bar(_player_hp, _player_max_hp, Color(0.2, 0.7, 0.3))
	list.add_child(player_hp_bar)

	var player_hp_text = _pl("HP：" + str(int(_player_hp)) + "/" + str(int(_player_max_hp)), Color(0.7, 0.9, 0.7), 11)
	list.add_child(player_hp_text)

	var stat_row = HBoxContainer.new()
	stat_row.add_child(_pl("攻击：" + str(int(_player_atk)), Color(1, 0.6, 0.4)))
	stat_row.add_child(_pl("  |  ", Color(0.3, 0.3, 0.4)))
	stat_row.add_child(_pl("防御：" + str(int(_player_def)), Color(0.4, 0.8, 1)))
	list.add_child(stat_row)

	list.add_child(HSeparator.new())

	# 战斗日志
	if _battle_log != "":
		var log_label = _pl(_battle_log, Color(0.7, 0.7, 0.8), 11)
		list.add_child(log_label)

	# 停止按钮
	var stop_btn = Button.new()
	stop_btn.text = "停止历练"
	stop_btn.pressed.connect(func(): stop_battle_requested.emit())
	list.add_child(stop_btn)

func _make_hp_bar(current: float, maximum: float, color: Color) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.custom_minimum_size = Vector2(0, 16)

	var ratio = clampf(current / maximum, 0.0, 1.0)

	# 填充部分
	var fill = PanelContainer.new()
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3 if ratio >= 0.99 else 0
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3 if ratio >= 0.99 else 0
	fill.add_theme_stylebox_override("panel", fill_style)
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.size_flags_stretch_ratio = max(ratio, 0.01)
	hbox.add_child(fill)

	# 空白部分
	if ratio < 0.99:
		var empty = PanelContainer.new()
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0.15, 0.15, 0.18)
		empty_style.corner_radius_top_right = 3
		empty_style.corner_radius_bottom_right = 3
		empty.add_theme_stylebox_override("panel", empty_style)
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty.size_flags_stretch_ratio = 1.0 - ratio
		hbox.add_child(empty)

	return hbox

func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
