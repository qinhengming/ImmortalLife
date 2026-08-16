extends PanelContainer

const UI := preload("res://scripts/ui_common.gd")

const BID = "library"

var _building: Dictionary = {}
var _energy: float = 0.0

signal back_requested()
signal building_action_requested(bid: String)

func set_state(building: Dictionary, energy: float):
	_building = building.duplicate()
	_energy = energy

func _card_bg(color: Color = Color(0.1, 0.12, 0.18)) -> StyleBoxFlat:
	return UI.card_bg(color, 6)

func _lbl(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	return UI.lbl(text, color, size)

func _fmt(n: float) -> String:
	return UI.format_num(n)

func refresh():
	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	var level = _building.get('level', 0)
	var max_lv = 5

	# 建筑信息卡
	var info = PanelContainer.new()
	info.add_theme_stylebox_override("panel", _card_bg(Color(0.08, 0.12, 0.18)))
	var iv = VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	info.add_child(iv)

	iv.add_child(_lbl("藏经阁  Lv." + str(level) + "/" + str(max_lv), Color(0.7, 0.3, 0.95), 18))
	iv.add_child(_lbl("参悟功法奥秘，提升修炼速度", Color(0.7, 0.7, 0.8), 12))
	iv.add_child(_lbl("效果：每级功法加成+15%", Color(0.4, 0.9, 0.5), 12))
	iv.add_child(_lbl("当前加成：功法加成 +" + str(level * 15) + "%", Color(0.9, 0.75, 0.3), 13))

	if level >= max_lv:
		iv.add_child(_lbl("已升至满级", Color(0.4, 0.8, 0.4), 13))
	else:
		var cost = int(5000 * pow(2.5, level))
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
	list.add_child(HSeparator.new())

	var desc = _lbl("藏经阁收录天下功法，参悟后可加速功法修炼。", Color(0.7, 0.3, 0.95), 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(desc)

	if level < max_lv:
		var next = _lbl("下一级效果：功法加成 +" + str((level + 1) * 15) + "%", Color(0.85, 0.55, 1.0), 12)
		list.add_child(next)

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
