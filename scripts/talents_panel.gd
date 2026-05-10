extends PanelContainer

signal back_requested()
signal upgrade_talent_requested(tid: String)
signal select_spirit_root_requested(root_name: String)

const TALENT_DEFS = {
	'spirit_root_selector': {
		'name': '灵根掌控',
		'desc': '兵解后可重新选择灵根',
		'max_level': 1,
		'cost': 2,
		'color': Color(1.0, 0.84, 0),
	},
	'enlightenment': {
		'name': '悟性',
		'desc': '每级修炼速度x1.1',
		'max_level': 10,
		'cost': 1,
		'color': Color(0.3, 0.8, 1.0),
	},
	'sturdy_body': {
		'name': '道体',
		'desc': '每级基础灵气+5',
		'max_level': 10,
		'cost': 1,
		'color': Color(0.3, 1.0, 0.5),
	},
	'battle_hardened': {
		'name': '战意',
		'desc': '每级攻击+10%',
		'max_level': 5,
		'cost': 2,
		'color': Color(1.0, 0.6, 0.4),
	},
	'immortal_fortune': {
		'name': '仙缘',
		'desc': '每级突破灵气消耗-5%',
		'max_level': 5,
		'cost': 2,
		'color': Color(1.0, 0.8, 0.3),
	},
}

const SPIRIT_ROOTS = [
	{'name': '金灵根', 'color': Color(1.0, 0.90, 0.10), 'bonus': 2.0, 'desc': '金系单灵根，修炼速度x2.0'},
	{'name': '木灵根', 'color': Color(0.10, 1.0, 0.35), 'bonus': 2.0, 'desc': '木系单灵根，修炼速度x2.0'},
	{'name': '水灵根', 'color': Color(0.15, 0.60, 1.0), 'bonus': 2.0, 'desc': '水系单灵根，修炼速度x2.0'},
	{'name': '火灵根', 'color': Color(1.0, 0.18, 0.10), 'bonus': 2.0, 'desc': '火系单灵根，修炼速度x2.0'},
	{'name': '土灵根', 'color': Color(1.0, 0.82, 0.5), 'bonus': 2.0, 'desc': '土系单灵根，修炼速度x2.0'},
	{'name': '雷灵根', 'color': Color(0.65, 0.20, 1.0), 'bonus': 3.0, 'desc': '变异雷灵根，修炼速度x3.0'},
	{'name': '冰灵根', 'color': Color(0.30, 0.90, 1.0), 'bonus': 3.0, 'desc': '变异冰灵根，修炼速度x3.0'},
	{'name': '风灵根', 'color': Color(0.10, 1.0, 0.70), 'bonus': 3.0, 'desc': '变异风灵根，修炼速度x3.0'},
	{'name': '天灵根', 'color': Color(1.0, 0.55, 0.0), 'bonus': 5.0, 'desc': '先天道体，修炼速度x5.0'},
]

var _talents: Dictionary = {}
var _enlightenment_points: int = 0
var _realm_level: int = 1
var _reincarnation_count: int = 0

func set_state(data: Dictionary):
	_talents = data.get('talents', {})
	_enlightenment_points = data.get('enlightenment_points', 0)
	_realm_level = data.get('realm_level', 1)
	_reincarnation_count = data.get('reincarnation_count', 0)

func refresh():
	var list = $VBox/ScrollList/ItemList
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()

	# 悟道点头部
	var title = Label.new()
	title.text = "悟道点：" + str(_enlightenment_points)
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)
	list.add_child(HSeparator.new())

	# 天赋列表
	for tid in TALENT_DEFS:
		var defs = TALENT_DEFS[tid]
		var level = _talents.get(tid, 0)
		var maxed = level >= defs.max_level

		var card = PanelContainer.new()
		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.14, 0.18)
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 6
		style.content_margin_bottom = 6
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
		name_label.text = defs.name + "  Lv." + str(level) + "/" + str(defs.max_level)
		name_label.add_theme_font_size_override("font_size", 13)
		name_label.add_theme_color_override("font_color", defs.color)
		vbox.add_child(name_label)

		vbox.add_child(Label.new())

		var desc_label = Label.new()
		desc_label.text = defs.desc
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
		vbox.add_child(desc_label)

		# 具体效果
		var effect_text = ""
		match tid:
			'enlightenment':
				var curr_mult = 1.0 + 0.10 * level
				effect_text = "修炼速度x" + str(curr_mult)
			'sturdy_body':
				var curr_bonus = 5.0 * level
				effect_text = "基础灵气+" + str(curr_bonus)
			'battle_hardened':
				var curr_atk = 1.0 + 0.10 * level
				effect_text = "攻击x" + str(curr_atk)
			'immortal_fortune':
				var curr_red = 0.05 * level
				effect_text = "突破消耗-" + str(int(curr_red * 100)) + "%"
			'spirit_root_selector':
				effect_text = "兵解后可重新选择灵根"

		var effect_label = Label.new()
		effect_label.text = effect_text
		effect_label.add_theme_font_size_override("font_size", 11)
		effect_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
		vbox.add_child(effect_label)

		# 升级按钮
		if maxed:
			var max_label = Label.new()
			max_label.text = "已满级"
			max_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			max_label.add_theme_font_size_override("font_size", 11)
			hbox.add_child(max_label)
		else:
			var can_afford = _enlightenment_points >= defs.cost
			var btn = Button.new()
			btn.text = "升级（" + str(defs.cost) + "悟道点）"
			btn.disabled = not can_afford
			var tid_copy = tid
			btn.pressed.connect(func(): upgrade_talent_requested.emit(tid_copy))
			hbox.add_child(btn)

		list.add_child(card)

	# 灵根选择（兵解后且有灵根掌控天赋）
	if spirit_root_selector_unlocked():
		list.add_child(HSeparator.new())
		var sr_label = Label.new()
		sr_label.text = "── 灵根选择 ──"
		sr_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		sr_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0))
		list.add_child(sr_label)

		for root in SPIRIT_ROOTS:
			var row = HBoxContainer.new()
			var rl = Label.new()
			rl.text = root.name + "  " + root.desc
			rl.add_theme_color_override("font_color", root.color)
			rl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(rl)
			var btn = Button.new()
			btn.text = "选择"
			var r_name = root.name
			btn.pressed.connect(func(): select_spirit_root_requested.emit(r_name))
			row.add_child(btn)
			list.add_child(row)

func spirit_root_selector_unlocked() -> bool:
	return _talents.get('spirit_root_selector', 0) >= 1 and _reincarnation_count > 0

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
