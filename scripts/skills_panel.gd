extends PanelContainer

signal back_requested()
signal comprehend_requested(tech_id: String)

const TECHNIQUE_GRADES = ["黄级", "玄级", "地级", "天级", "圣级"]
const TECHNIQUE_GRADE_COLORS = [
	Color(0.9, 0.85, 0.4),
	Color(0.35, 0.75, 0.9),
	Color(0.9, 0.55, 0.3),
	Color(0.65, 0.35, 0.95),
	Color(1.0, 0.25, 0.2),
]

const TECHNIQUE_DEFS = {
	"breathing_art": {
		"name": "吐纳术", "grade": 1, "desc": "修仙入门基础功法",
		"price": 50, "min_realm": 1,
		"color": Color(0.20, 0.85, 0.55),
		"levels": [
			{"time": 25, "mana_pct": 0.10, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 35, "mana_pct": 0.05, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 50, "mana_pct": 0.08, "atk": 0, "def": 0, "hp": 10, "effect": "灵气恢复+3"},
		],
	},
	"spirit_gathering": {
		"name": "聚灵诀", "grade": 2, "desc": "汇聚天地灵气之法",
		"price": 200, "min_realm": 2,
		"color": Color(0.15, 0.80, 0.55),
		"levels": [
			{"time": 40, "mana_pct": 0.15, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 55, "mana_pct": 0.10, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 70, "mana_pct": 0.10, "atk": 0, "def": 0, "hp": 20, "effect": "HP上限+20"},
			{"time": 90, "mana_pct": 0.10, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 110, "mana_pct": 0.15, "atk": 0, "def": 8, "hp": 0, "effect": "防御+8"},
		],
	},
	"wind_control": {
		"name": "御风诀", "grade": 3, "desc": "风属性功法，身法灵动",
		"price": 800, "min_realm": 3,
		"color": Color(0.10, 0.75, 0.55),
		"levels": [
			{"time": 55, "mana_pct": 0.20, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 70, "mana_pct": 0.12, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 85, "mana_pct": 0.12, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 100, "mana_pct": 0.12, "atk": 12, "def": 0, "hp": 0, "effect": "攻击+12"},
			{"time": 120, "mana_pct": 0.12, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 140, "mana_pct": 0.15, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 160, "mana_pct": 0.18, "atk": 0, "def": 5, "hp": 30, "effect": "修炼速度额外+10%"},
		],
	},
	"burning_heaven": {
		"name": "焚天决", "grade": 4, "desc": "火属性至强功法，焚尽八荒",
		"price": 3000, "min_realm": 10,
		"color": Color(1.0, 0.45, 0.2),
		"levels": [
			{"time": 70, "mana_pct": 0.25, "atk": 3, "def": 0, "hp": 0, "effect": ""},
			{"time": 90, "mana_pct": 0.15, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 110, "mana_pct": 0.15, "atk": 5, "def": 0, "hp": 0, "effect": ""},
			{"time": 130, "mana_pct": 0.15, "atk": 0, "def": 0, "hp": 30, "effect": ""},
			{"time": 150, "mana_pct": 0.20, "atk": 15, "def": 0, "hp": 0, "effect": "攻击+15"},
			{"time": 170, "mana_pct": 0.15, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 190, "mana_pct": 0.15, "atk": 5, "def": 5, "hp": 0, "effect": ""},
			{"time": 210, "mana_pct": 0.20, "atk": 0, "def": 0, "hp": 50, "effect": ""},
			{"time": 240, "mana_pct": 0.30, "atk": 20, "def": 10, "hp": 0, "effect": "暴击率+10%，修炼速度额外+15%"},
		],
	},
	"ice_heart": {
		"name": "冰心诀", "grade": 4, "desc": "冰属性功法，心如寒冰",
		"price": 10000, "min_realm": 19,
		"color": Color(0.30, 0.85, 1.0),
		"levels": [
			{"time": 80, "mana_pct": 0.30, "atk": 0, "def": 3, "hp": 0, "effect": ""},
			{"time": 100, "mana_pct": 0.20, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 120, "mana_pct": 0.20, "atk": 0, "def": 5, "hp": 20, "effect": ""},
			{"time": 140, "mana_pct": 0.20, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 160, "mana_pct": 0.25, "atk": 0, "def": 12, "hp": 0, "effect": "防御+12"},
			{"time": 180, "mana_pct": 0.20, "atk": 0, "def": 0, "hp": 30, "effect": ""},
			{"time": 200, "mana_pct": 0.20, "atk": 5, "def": 5, "hp": 0, "effect": ""},
			{"time": 220, "mana_pct": 0.25, "atk": 0, "def": 0, "hp": 50, "effect": ""},
			{"time": 250, "mana_pct": 0.35, "atk": 10, "def": 15, "hp": 0, "effect": "突破灵气消耗-10%"},
		],
	},
	"celestial_art": {
		"name": "天罡功", "grade": 5, "desc": "圣级功法，雷属性至强",
		"price": 50000, "min_realm": 28,
		"color": Color(0.75, 0.30, 0.95),
		"levels": [
			{"time": 100, "mana_pct": 0.40, "atk": 8, "def": 3, "hp": 10, "effect": ""},
			{"time": 130, "mana_pct": 0.25, "atk": 0, "def": 0, "hp": 0, "effect": ""},
			{"time": 160, "mana_pct": 0.25, "atk": 10, "def": 0, "hp": 0, "effect": ""},
			{"time": 190, "mana_pct": 0.30, "atk": 0, "def": 8, "hp": 30, "effect": ""},
			{"time": 220, "mana_pct": 0.30, "atk": 0, "def": 0, "hp": 50, "effect": ""},
			{"time": 250, "mana_pct": 0.30, "atk": 25, "def": 10, "hp": 0, "effect": "攻击+25 防御+10"},
			{"time": 280, "mana_pct": 0.35, "atk": 0, "def": 0, "hp": 80, "effect": ""},
			{"time": 310, "mana_pct": 0.35, "atk": 10, "def": 10, "hp": 0, "effect": ""},
			{"time": 340, "mana_pct": 0.40, "atk": 0, "def": 0, "hp": 100, "effect": ""},
			{"time": 370, "mana_pct": 0.40, "atk": 15, "def": 5, "hp": 0, "effect": ""},
			{"time": 400, "mana_pct": 0.50, "atk": 10, "def": 10, "hp": 120, "effect": ""},
			{"time": 450, "mana_pct": 0.60, "atk": 40, "def": 20, "hp": 0, "effect": "全修炼速度x2，暴击率+15%"},
		],
	},
}

var _learned_techniques: Dictionary = {}
var _comprehending_tech_id: String = ""
var _comprehension_progress: float = 0.0
var _comprehension_time_total: float = 0.0

func set_state(data: Dictionary):
	_learned_techniques = data.get("learned_techniques", {}).duplicate()
	_comprehending_tech_id = data.get("comprehending_tech_id", "")
	_comprehension_progress = data.get("comprehension_progress", 0.0)
	_comprehension_time_total = data.get("comprehension_time_total", 0.0)

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

func _pl(text: String, color: Color = Color(0.9, 0.9, 1.0), font_size: int = 13) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label

func _calc_total_stats(tech_id: String, level: int) -> Dictionary:
	var defs = TECHNIQUE_DEFS[tech_id]
	var total_mana = 0.0
	var total_atk = 0.0
	var total_def = 0.0
	var total_hp = 0.0
	for i in range(level):
		if i < defs.levels.size():
			total_mana += defs.levels[i].mana_pct
			total_atk += defs.levels[i].atk
			total_def += defs.levels[i].def
			total_hp += defs.levels[i].hp
	return {"mana": total_mana, "atk": total_atk, "def": total_def, "hp": total_hp}

func _num_to_chinese(n: int) -> String:
	var digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]
	if n >= 0 and n < digits.size():
		return digits[n]
	return str(n)

func refresh():
	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	if _learned_techniques.is_empty():
		var empty = Label.new()
		empty.text = "尚未学会任何功法"
		empty.add_theme_font_size_override("font_size", 13)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		list.add_child(empty)
		return

	for tid in _learned_techniques:
		if not TECHNIQUE_DEFS.has(tid):
			continue
		var defs = TECHNIQUE_DEFS[tid]
		var tech = _learned_techniques[tid]
		var level = tech.get("level", 0)
		var max_level = defs.levels.size()
		var grade_idx = defs.grade - 1
		var grade_name = TECHNIQUE_GRADES[grade_idx] if grade_idx >= 0 and grade_idx < TECHNIQUE_GRADES.size() else "未知"
		var grade_color = TECHNIQUE_GRADE_COLORS[grade_idx] if grade_idx >= 0 and grade_idx < TECHNIQUE_GRADE_COLORS.size() else Color(0.5, 0.5, 0.5)
		var is_comprehending = (_comprehending_tech_id == tid)
		var is_maxed = level >= max_level

		var card = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_card_bg(Color(0.12, 0.14, 0.18), defs.color * 0.4))

		var vbox = VBoxContainer.new()
		vbox.add_theme_constant_override("separation", 3)
		card.add_child(vbox)

		# 名称行: [品级] 功法名  Lv./Max
		var header = HBoxContainer.new()
		header.add_theme_constant_override("separation", 6)

		var grade_badge = _pl("[" + grade_name + "]", grade_color, 11)
		header.add_child(grade_badge)

		var name_label = _pl(defs.name, defs.color, 14)
		header.add_child(name_label)

		var lv_label = _pl(_num_to_chinese(level) + "重/共" + _num_to_chinese(max_level) + "重", Color(0.7, 0.8, 1.0), 12)
		header.add_child(lv_label)

		vbox.add_child(header)

		# 描述
		vbox.add_child(_pl(defs.desc, Color(0.55, 0.55, 0.7), 11))

		# 当前属性加成
		var stats = _calc_total_stats(tid, level)
		var stat_texts = []
		if stats.mana > 0:
			stat_texts.append("修炼速度+" + str(int(stats.mana * 100)) + "%")
		if stats.atk > 0:
			stat_texts.append("攻击+" + str(int(stats.atk)))
		if stats.def > 0:
			stat_texts.append("防御+" + str(int(stats.def)))
		if stats.hp > 0:
			stat_texts.append("HP+" + str(int(stats.hp)))
		if stat_texts.size() > 0:
			vbox.add_child(_pl("  ".join(stat_texts), Color(0.3, 1.0, 0.5), 11))

		# 各重详情（折叠展示，当前用简洁模式）
		var level_info = ""
		for i in range(max_level):
			var lv = defs.levels[i]
			var parts = []
			if lv.mana_pct > 0:
				parts.append("修炼+" + str(int(lv.mana_pct * 100)) + "%")
			if lv.atk > 0:
				parts.append("攻击+" + str(int(lv.atk)))
			if lv.def > 0:
				parts.append("防御+" + str(int(lv.def)))
			if lv.hp > 0:
				parts.append("HP+" + str(int(lv.hp)))
			var mark = ""
			if i < level:
				mark = " ✓"
			elif lv.effect != "":
				mark = " ★" + lv.effect
			var lv_str = _num_to_chinese(i + 1) + "重: " + (" ".join(parts) if parts.size() > 0 else "—") + mark
			var lv_color = Color(0.4, 1.0, 0.4) if i < level else Color(0.45, 0.45, 0.55)
			if lv.effect != "" and i >= level:
				lv_color = Color(1.0, 0.84, 0)
			vbox.add_child(_pl("  " + lv_str, lv_color, 10))

		# 参悟进度条 / 按钮
		if is_comprehending:
			var prog_box = VBoxContainer.new()
			prog_box.add_theme_constant_override("separation", 2)
			var progress = ProgressBar.new()
			progress.name = "ComprehensionBar"
			progress.min_value = 0
			progress.max_value = _comprehension_time_total
			progress.value = min(_comprehension_progress, _comprehension_time_total)
			progress.show_percentage = false
			prog_box.add_child(progress)
			var pct = min(_comprehension_progress / _comprehension_time_total * 100, 100)
			var progress_label = _pl("参悟中... " + str(int(pct)) + "%（" + _num_to_chinese(level + 1) + "重）", Color(1.0, 0.84, 0), 11)
			progress_label.name = "ComprehensionLabel"
			prog_box.add_child(progress_label)
			vbox.add_child(prog_box)
		elif not is_maxed:
			var btn_row = HBoxContainer.new()
			var btn = Button.new()
			btn.text = "参悟" + _num_to_chinese(level + 1) + "重（" + str(int(defs.levels[level].time)) + "秒）"
			var tech_id = tid
			btn.pressed.connect(func(): comprehend_requested.emit(tech_id))
			btn_row.add_child(btn)
			vbox.add_child(btn_row)
		else:
			vbox.add_child(_pl("已达最高重数", Color(1.0, 0.84, 0), 11))

		list.add_child(card)

func _process(_delta):
	if not visible:
		return
	var main = get_parent()
	var cid = main.comprehending_tech_id
	if cid == "":
		return
	var bar = find_child("ComprehensionBar", true, false)
	var lbl = find_child("ComprehensionLabel", true, false)
	var total = main.comprehension_time_total
	var progress = main.comprehension_progress
	if bar:
		bar.max_value = total
		bar.value = min(progress, total)
	if lbl:
		var pct = min(progress / total * 100, 100) if total > 0 else 0
		var tech = main.learned_techniques.get(cid, {})
		var level = tech.get("level", 0)
		lbl.text = "参悟中... " + str(int(pct)) + "%（" + _num_to_chinese(level + 1) + "重）"

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
