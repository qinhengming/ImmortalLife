extends PanelContainer

const UI := preload("res://scripts/ui_common.gd")

const BID = "spirit_wood"
const NAME = "灵木林"
const COLOR = Color(0.7, 0.55, 0.35)
const RATE_NAME = "灵木"
const BASE_COST = 30
const COST_GROWTH = 1.5
const RATE_PER_LEVEL = 1.0

var _building: Dictionary = {}
var _wood: float = 0.0
var _wood_rate: float = 0.0

var _wood_label: Label = null

signal back_requested()
signal building_action_requested(bid: String)

func set_state(building: Dictionary, ore: float = 0.0, wood: float = 0.0, ore_rate: float = 0.0, wood_rate: float = 0.0):
	_building = building.duplicate()
	_wood = wood
	_wood_rate = wood_rate

func _card_bg(color: Color = Color(0.1, 0.12, 0.18)) -> StyleBoxFlat:
	return UI.card_bg(color, 6)

func _lbl(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 12) -> Label:
	return UI.lbl(text, color, size)

func _fmt(n: float) -> String:
	return UI.format_big(n)

func refresh():
	var list = $VBox/ScrollList/ItemList
	for c in list.get_children():
		list.remove_child(c)
		c.queue_free()

	var level = _building.get('level', 0)
	var upgrading = _building.get('upgrading', false)

	var info = PanelContainer.new()
	info.add_theme_stylebox_override("panel", _card_bg(Color(0.08, 0.12, 0.18)))
	var iv = VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	info.add_child(iv)

	iv.add_child(_lbl(NAME + "  Lv." + str(level) + "（无上限）", COLOR, 18))
	iv.add_child(_lbl("种植灵木，随时间产出" + RATE_NAME, Color(0.7, 0.7, 0.8), 12))
	_wood_label = _lbl("当前库存：" + RATE_NAME + " " + _fmt(_wood), Color(0.9, 0.75, 0.3), 13)
	iv.add_child(_wood_label)
	iv.add_child(_lbl("当前产量：" + _fmt(_wood_rate) + " " + RATE_NAME + "/秒", Color(0.4, 0.9, 0.5), 12))

	if upgrading:
		if _building.get('queued', false):
			iv.add_child(_lbl("排队中…", Color(0.5, 0.55, 0.7), 13))
		else:
			iv.add_child(_lbl("升级中…", Color(0.4, 0.8, 0.4), 13))
	else:
		var cost = int(BASE_COST * pow(COST_GROWTH, level))
		var can = _wood >= cost
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(_lbl("升级消耗：" + _fmt(cost) + " " + RATE_NAME, Color(0.7, 0.7, 0.8), 12))
		var btn = Button.new()
		btn.text = "升级"
		btn.add_theme_font_size_override("font_size", 12)
		btn.disabled = not can
		btn.pressed.connect(func(): building_action_requested.emit(BID))
		row.add_child(btn)
		iv.add_child(row)

	list.add_child(info)
	list.add_child(HSeparator.new())

	var desc = _lbl(NAME + "种植蕴含灵气的林木，" + RATE_NAME + "用于洞府扩建。", COLOR, 12)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	list.add_child(desc)
	var next = _lbl("下一级效果：产量提升至 " + _fmt((level + 1) * RATE_PER_LEVEL) + " " + RATE_NAME + "/秒", Color(0.4, 1.0, 0.5), 12)
	list.add_child(next)

## 实时刷新资源库存（由洞府面板 tick_upgrade_bars 每帧调用）
func tick_upgrade(building: Dictionary, ore: float = 0.0, wood: float = 0.0, ore_rate: float = 0.0, wood_rate: float = 0.0):
	_wood = wood
	_wood_rate = wood_rate
	if _wood_label:
		_wood_label.text = "当前库存：" + RATE_NAME + " " + _fmt(_wood)

func _ready():
	$VBox/TopBar/BtnBack.pressed.connect(func(): back_requested.emit())
