extends PanelContainer

signal back_requested()
signal start_battle_requested(map: Dictionary)
signal stop_battle_requested()

var _maps: Array = []
var _realm_level: int = 1
var _in_battle: bool = false
var _enemy_team: Array = []
var _ally_team: Array = []
var _battle_log: String = ""

func set_state(data: Dictionary):
	_maps = data.get('maps', [])
	_realm_level = data.get('realm_level', 1)
	_in_battle = data.get('in_battle', false)
	_enemy_team = data.get('enemy_team', [])
	_ally_team = data.get('ally_team', [])
	_battle_log = data.get('battle_log', "")

func refresh():
	$VBox/MapArea.visible = not _in_battle
	$VBox/BattleArea.visible = _in_battle
	if _in_battle:
		$VBox/TopBar/Title.text = "-- 战斗中 --"
		refresh_battle_ui()
	else:
		$VBox/TopBar/Title.text = "-- 选择地图 --"
		refresh_map_list()

func refresh_map_list():
	var list = $VBox/MapArea/ScrollList/ItemList
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
	var enemy_grid = $VBox/BattleArea/EnemyGrid
	var ally_grid = $VBox/BattleArea/AllyGrid
	var log_label = $VBox/BattleArea/BattleLogLabel
	var enemy_label = $VBox/BattleArea/EnemyLabel
	var ally_label = $VBox/BattleArea/AllyLabel

	# 更新标题
	var alive_e = 0
	for e in _enemy_team:
		if e.get('alive', false):
			alive_e += 1
	var alive_a = 0
	for a in _ally_team:
		if a.get('alive', false):
			alive_a += 1
	enemy_label.text = "── 敌方阵营 " + str(alive_e) + "/" + str(_enemy_team.size()) + " ──"
	ally_label.text = "── 我方阵营 " + str(alive_a) + "/" + str(_ally_team.size()) + " ──"

	# 清空网格
	for child in enemy_grid.get_children():
		enemy_grid.remove_child(child)
		child.queue_free()
	for child in ally_grid.get_children():
		ally_grid.remove_child(child)
		child.queue_free()

	# 填充敌人卡片（最多6个）
	for enemy in _enemy_team:
		var card = _make_char_card(enemy, false)
		enemy_grid.add_child(card)
	# 填充空位
	var enemy_empty = 6 - _enemy_team.size()
	for _i in range(enemy_empty):
		var card = _make_empty_card(false)
		enemy_grid.add_child(card)

	# 填充我方卡片（最多6个）
	for ally in _ally_team:
		var card = _make_char_card(ally, true)
		ally_grid.add_child(card)
	# 填充空位
	var ally_empty = 6 - _ally_team.size()
	for _i in range(ally_empty):
		var card = _make_empty_card(true)
		ally_grid.add_child(card)

	# 战斗日志
	log_label.text = _battle_log if _battle_log != "" else "战斗开始..."

func _make_char_card(char_data: Dictionary, is_ally: bool) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	if char_data.get('alive', true):
		style.bg_color = Color(0.08, 0.09, 0.12)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		var border_col = char_data.get('color', Color(0.4, 0.4, 0.5))
		style.border_color = border_col * 0.6
	else:
		style.bg_color = Color(0.06, 0.04, 0.04)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.1, 0.1)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(vbox)

	# 名字
	var name_label = Label.new()
	name_label.text = char_data.get('name', '???')
	name_label.add_theme_font_size_override("font_size", 11)
	if char_data.get('alive', true):
		var col = char_data.get('color', Color(0.8, 0.8, 0.8))
		name_label.add_theme_color_override("font_color", col)
	else:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.2, 0.2))
	vbox.add_child(name_label)

	var hp = char_data.get('hp', 0.0)
	var max_hp = char_data.get('max_hp', 1.0)
	var hp_bar = _make_mini_hp_bar(hp, max_hp, char_data.get('alive', true), is_ally)
	vbox.add_child(hp_bar)

	# 属性
	var atk = char_data.get('atk', 0.0)
	var def = char_data.get('def', 0.0)
	var stat_text = "ATK:" + str(int(atk)) + " DEF:" + str(int(def))
	var stat_label = Label.new()
	stat_label.text = stat_text
	stat_label.add_theme_font_size_override("font_size", 9)
	if char_data.get('alive', true):
		stat_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	else:
		stat_label.add_theme_color_override("font_color", Color(0.3, 0.2, 0.2))
	vbox.add_child(stat_label)

	return card

func _make_empty_card(is_ally: bool) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	style.bg_color = Color(0.05, 0.05, 0.06)
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	card.add_child(vbox)

	var name_label = Label.new()
	name_label.text = "空"
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.18))
	vbox.add_child(name_label)

	var empty_bar = PanelContainer.new()
	empty_bar.custom_minimum_size = Vector2(0, 10)
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.04, 0.04, 0.05)
	bar_style.corner_radius_top_left = 2
	bar_style.corner_radius_top_right = 2
	bar_style.corner_radius_bottom_left = 2
	bar_style.corner_radius_bottom_right = 2
	empty_bar.add_theme_stylebox_override("panel", bar_style)
	empty_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(empty_bar)

	var stat_label = Label.new()
	stat_label.text = "  -"
	stat_label.add_theme_font_size_override("font_size", 9)
	stat_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.12))
	vbox.add_child(stat_label)

	return card

func _make_mini_hp_bar(current: float, maximum: float, alive: bool, is_ally: bool) -> HBoxContainer:
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 0)
	hbox.custom_minimum_size = Vector2(0, 10)

	var ratio = clampf(current / maximum, 0.0, 1.0)

	var color: Color
	if not alive:
		color = Color(0.25, 0.1, 0.1)
	elif is_ally:
		color = Color(0.2, 0.7, 0.3)
	else:
		color = Color(0.8, 0.2, 0.2)

	var fill = PanelContainer.new()
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2 if ratio >= 0.99 else 0
	fill_style.corner_radius_bottom_left = 2
	fill_style.corner_radius_bottom_right = 2 if ratio >= 0.99 else 0
	fill.add_theme_stylebox_override("panel", fill_style)
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.size_flags_stretch_ratio = max(ratio, 0.01)
	hbox.add_child(fill)

	if ratio < 0.99:
		var empty = PanelContainer.new()
		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0.08, 0.08, 0.1)
		empty_style.corner_radius_top_right = 2
		empty_style.corner_radius_bottom_right = 2
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
	$VBox/BattleArea/StopBtn.pressed.connect(func(): stop_battle_requested.emit())
