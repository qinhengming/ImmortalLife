extends PanelContainer

signal back_requested()

var _player_name: String = ""
var _realm: String = ""
var _realm_level: int = 1
var _spiritual_energy: float = 0.0
var _mana_per_sec: float = 0.0
var _age: int = 16
var _spirit_root: Dictionary = {}
var _learned_techniques: Dictionary = {}
var _pill_inventory: Dictionary = {}
var _reincarnation_count: int = 0
var _enlightenment_points: int = 0
var _realms: Array = []
var _base_mana: float = 10.0
var _cave_base_bonus: float = 0.0
var _realm_mana_bonus: float = 0.0
var _realm_multiplier: float = 1.0
var _technique_multiplier: float = 1.0
var _cave_multiplier: float = 1.0
var _artifact_multiplier: float = 1.0
var _time_coefficient: float = 1.0
var _pill_flat_bonus: float = 0.0
var _player_hp: float = 100.0
var _player_max_hp: float = 100.0
var _reincarnation_clickable: bool = false
var _player_atk: float = 10.0
var _player_def: float = 5.0
var _spirit_roots_list: Array = []

func set_state(data: Dictionary):
	_player_name = data.get('player_name', "")
	_realm = data.get('realm', "")
	_realm_level = data.get('realm_level', 1)
	_spiritual_energy = data.get('spiritual_energy', 0.0)
	_mana_per_sec = data.get('mana_per_sec', 0.0)
	_age = data.get('age', 16)
	_spirit_root = data.get('spirit_root', {})
	_learned_techniques = data.get('learned_techniques', {})
	_pill_inventory = data.get('pill_inventory', {})
	_reincarnation_count = data.get('reincarnation_count', 0)
	_enlightenment_points = data.get('enlightenment_points', 0)
	_realms = data.get('realms', [])
	_base_mana = data.get('base_mana', 10.0)
	_cave_base_bonus = data.get('cave_base_bonus', 0.0)
	_realm_mana_bonus = data.get('realm_mana_bonus', 0.0)
	_realm_multiplier = data.get('realm_multiplier', 1.0)
	_technique_multiplier = data.get('technique_multiplier', 1.0)
	_cave_multiplier = data.get('cave_multiplier', 1.0)
	_artifact_multiplier = data.get('artifact_multiplier', 1.0)
	_time_coefficient = data.get('time_coefficient', 1.0)
	_pill_flat_bonus = data.get('pill_flat_bonus', 0.0)
	_player_hp = data.get('player_hp', 100.0)
	_player_max_hp = data.get('player_max_hp', 100.0)
	_reincarnation_clickable = data.get('reincarnation_clickable', false)
	_player_atk = data.get('player_atk', 10.0)
	_player_def = data.get('player_def', 5.0)
	_spirit_roots_list = data.get('spirit_roots_list', [])

func _make_card(bg: Color) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)
	return card

func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _format_num(n: float) -> String:
	if n < 10000:
		return str(int(n))
	var val = n
	var unit_idx = 0
	var units = ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']
	while val >= 10000 and unit_idx < units.size() - 1:
		val /= 10000.0
		unit_idx += 1
	return str(val).pad_decimals(1) + units[unit_idx]

func get_realm_title() -> String:
	var mr = floor((_realm_level - 1) / 9)
	var titles = ['练气修士', '筑基真人', '金丹真君', '元婴大能', '化神尊者', '合体圣者', '大乘仙尊', '渡劫准仙', '真仙', '金仙', '太乙金仙', '大罗金仙', '混元道祖']
	if mr >= 0 and mr < titles.size():
		return titles[mr]
	return "未知"

func get_realm_color() -> Color:
	if _realm_level >= 1 and _realm_level <= _realms.size():
		return _realms[_realm_level - 1].get('color', Color(0.6, 0.6, 0.8))
	return Color(0.6, 0.6, 0.8)

func get_title_color() -> Color:
	var mr = floor((_realm_level - 1) / 9)
	return get_realm_color()

func refresh():
	var list = $VBox/ScrollList/ItemList
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	# === 称号卡 ===
	var title_c = get_title_color()
	var header = _make_card(Color(0.12, 0.12, 0.2).lerp(title_c, 0.08))
	var hv = VBoxContainer.new()
	hv.add_theme_constant_override("separation", 2)
	header.add_child(hv)

	var nl = _pl(_player_name, Color(1, 0.84, 0), 20)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(nl)

	var tl = _pl("「" + get_realm_title() + "」", get_title_color(), 11)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(tl)

	list.add_child(header)
	list.add_child(HSeparator.new())

	# === 境界卡 ===
	var rc = _make_card(Color(0.14, 0.16, 0.22))
	var rv = VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	rc.add_child(rv)

	var realm_row = HBoxContainer.new()
	var rc_color = get_realm_color()
	realm_row.add_child(_pl("◇ ", rc_color))
	realm_row.add_child(_pl("境界：" + _realm, rc_color, 14))
	rv.add_child(realm_row)

	if _realm_level < _realms.size():
		var cost = _realms[_realm_level]['cost']
		var progress = ProgressBar.new()
		progress.min_value = 0
		progress.max_value = cost
		progress.value = min(_spiritual_energy, cost)
		progress.show_percentage = false
		rv.add_child(progress)
		rv.add_child(_pl(_format_num(_spiritual_energy) + " / " + _format_num(cost) + " 灵气", Color(0.7, 0.7, 0.8), 11))
	else:
		rv.add_child(_pl("已达最高境界", Color(1, 0.84, 0)))

	list.add_child(rc)
	list.add_child(HSeparator.new())

	# === 灵根卡 ===
	var sc = _make_card(Color(0.16, 0.14, 0.22))
	var sv = VBoxContainer.new()
	sv.add_theme_constant_override("separation", 4)
	sc.add_child(sv)

	var sr_row = HBoxContainer.new()
	var root_color = Color(1, 1, 1)
	var sr_name = _spirit_root.get('name', '')
	for sr in _spirit_roots_list:
		if sr['name'] == sr_name:
			root_color = sr['color']
			break
	sr_row.add_child(_pl("◇ ", root_color))
	sr_row.add_child(_pl("灵根：" + sr_name, root_color, 14))
	sv.add_child(sr_row)
	sv.add_child(_pl(_spirit_root.get('desc', ''), Color(0.6, 0.6, 0.8), 11))

	list.add_child(sc)
	list.add_child(HSeparator.new())

	# === 修炼速度卡 ===
	var mc = _make_card(Color(0.18, 0.14, 0.12))
	var mv = VBoxContainer.new()
	mv.add_theme_constant_override("separation", 4)
	mc.add_child(mv)

	mv.add_child(_pl("修炼速度分解", Color(1, 0.84, 0), 14))

	var zones = [
		{"name": "基础灵气", "value": _base_mana, "is_flat": true},
		{"name": "境界灵气", "value": _realm_mana_bonus, "is_flat": true},
		{"name": "洞府加成", "value": _cave_base_bonus, "is_flat": true},
		{"name": "境界倍率", "value": _realm_multiplier, "is_flat": false},
		{"name": "功法倍率", "value": _technique_multiplier, "is_flat": false},
		{"name": "洞府效率", "value": _cave_multiplier, "is_flat": false},
		{"name": "法宝加成", "value": _artifact_multiplier, "is_flat": false},
		{"name": "时间系数", "value": _time_coefficient, "is_flat": false},
	]

	for zone in zones:
		var zr = HBoxContainer.new()
		zr.add_theme_constant_override("separation", 4)
		var active = zone['value'] > (1.0 if not zone['is_flat'] else 0.0)
		var name_color = Color(0.6, 0.8, 0.6) if active else Color(0.5, 0.5, 0.6)
		zr.add_child(_pl(zone['name'] + "：", name_color, 12))
		if zone['is_flat']:
			zr.add_child(_pl(_format_num(zone['value']), Color(1, 0.84, 0), 12))
		else:
			var display_val = "x" + str(zone['value']) if zone['value'] != 1.0 else "x1.0 (无加成)"
			zr.add_child(_pl(display_val, Color(0.3, 1, 0.5) if active else Color(0.5, 0.5, 0.6), 12))
		mv.add_child(zr)

	if _pill_flat_bonus > 0:
		var pr = HBoxContainer.new()
		pr.add_theme_constant_override("separation", 4)
		pr.add_child(_pl("丹药加成：", Color(0.9, 0.6, 0.3), 12))
		pr.add_child(_pl("+" + _format_num(_pill_flat_bonus), Color(1, 0.84, 0), 12))
		mv.add_child(pr)

	var total_row = HBoxContainer.new()
	total_row.add_child(_pl("总计每秒灵气：", Color(1, 0.84, 0), 14))
	total_row.add_child(_pl(_format_num(_mana_per_sec), Color(0.3, 1, 0.5), 14))
	mv.add_child(total_row)

	list.add_child(mc)
	list.add_child(HSeparator.new())

	# === 属性卡 ===
	var ac = _make_card(Color(0.14, 0.18, 0.16))
	var av = VBoxContainer.new()
	av.add_theme_constant_override("separation", 4)
	ac.add_child(av)

	var atk = _player_atk
	var def = _player_def

	var attr_row1 = HBoxContainer.new()
	attr_row1.add_child(_pl("攻击：" + str(int(atk)), Color(1, 0.6, 0.4)))
	attr_row1.add_child(_pl("  |  ", Color(0.3, 0.3, 0.4)))
	attr_row1.add_child(_pl("防御：" + str(int(def)), Color(0.4, 0.8, 1)))
	av.add_child(attr_row1)

	var attr_row2 = HBoxContainer.new()
	attr_row2.add_child(_pl("灵气：" + _format_num(_spiritual_energy), Color(1, 0.84, 0)))
	attr_row2.add_child(_pl("  |  ", Color(0.3, 0.3, 0.4)))
	attr_row2.add_child(_pl("HP：" + str(int(_player_hp)) + "/" + str(int(_player_max_hp)), Color(0.4, 1, 0.4)))
	av.add_child(attr_row2)

	list.add_child(ac)
	list.add_child(HSeparator.new())

	# === 修行统计卡 ===
	var tc = _make_card(Color(0.16, 0.16, 0.18))
	var tv = VBoxContainer.new()
	tv.add_theme_constant_override("separation", 4)
	tc.add_child(tv)

	tv.add_child(_pl("年龄：" + str(_age) + "岁", Color(0.7, 0.7, 0.9)))

	var stat_row = HBoxContainer.new()
	stat_row.add_child(_pl("功法：" + str(_learned_techniques.size()) + "门", Color(0.4, 0.9, 0.4)))
	stat_row.add_child(_pl("  |  ", Color(0.3, 0.3, 0.4)))
	var pill_count = 0
	for p in _pill_inventory:
		pill_count += _pill_inventory[p]
	stat_row.add_child(_pl("丹药：" + str(pill_count) + "颗", Color(0.9, 0.6, 0.3)))
	tv.add_child(stat_row)

	list.add_child(tc)

	# === 兵解重修信息 ===
	if _reincarnation_count > 0:
		var rc_info = _make_card(Color(0.16, 0.14, 0.12))
		var rv_info = VBoxContainer.new()
		rv_info.add_theme_constant_override("separation", 4)
		rc_info.add_child(rv_info)
		rv_info.add_child(_pl("兵解次数：" + str(_reincarnation_count), Color(1.0, 0.6, 0.3)))
		rv_info.add_child(_pl("悟道点：" + str(_enlightenment_points), Color(0.6, 1.0, 0.6)))
		list.add_child(rc_info)
		list.add_child(HSeparator.new())

	# === 兵解重修按钮 ===
	if _reincarnation_clickable:
		var re_card = _make_card(Color(0.22, 0.1, 0.1))
		var re_vbox = VBoxContainer.new()
		re_vbox.add_theme_constant_override("separation", 6)
		re_card.add_child(re_vbox)
		re_vbox.add_child(_pl("── 兵解重修 ──", Color(1.0, 0.4, 0.3), 14))
		re_vbox.add_child(_pl("放弃一切修为，转世重修", Color(0.7, 0.5, 0.5), 11))
		var re_btn = Button.new()
		re_btn.text = "兵解重修"
		re_btn.pressed.connect(func(): reincarnation_requested.emit())
		re_vbox.add_child(re_btn)
		list.add_child(re_card)

signal reincarnation_requested()

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
