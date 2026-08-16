extends CanvasLayer
## 《修仙人生》共享 Toast 提示组件
## 依据 docs/UI规范.md §10 实现。
## 用法（绑定到面板，或在 main_ui 全局使用）：
##   var toast = preload("res://scripts/toast.gd").new()
##   add_child(toast)
##   toast.show_toast("炼制完成！", Color("#66CC66"))
##

var _panel: PanelContainer
var _label: Label
var _style: StyleBoxFlat
var _timer: float = 0.0
var _active: bool = false
var _need_hide: bool = false

# 动画参数（规范 §10）
const FADE_IN := 0.15
const HOLD := 1.35
const FADE_OUT := 0.4
const START_TOP := 56.0
const START_BOTTOM := 102.0


func _init():
	layer = 20
	_process_mode = Node.PROCESS_MODE_ALWAYS

	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.anchor_left = 0.08
	_panel.anchor_right = 0.92
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_top = START_TOP
	_panel.offset_bottom = START_BOTTOM

	_style = StyleBoxFlat.new()
	_style.bg_color = Color(0.06, 0.10, 0.06, 0.95)
	_style.corner_radius_top_left = 10
	_style.corner_radius_top_right = 10
	_style.corner_radius_bottom_left = 10
	_style.corner_radius_bottom_right = 10
	_style.border_width_left = 1
	_style.border_width_right = 1
	_style.border_width_top = 1
	_style.border_width_bottom = 1
	_style.border_color = Color(0.40, 0.66, 0.40, 0.8)
	_style.content_margin_left = 18
	_style.content_margin_right = 18
	_style.content_margin_top = 8
	_style.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", _style)

	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_label)

	add_child(_panel)
	set_process(false)


## 显示一条 Toast 提示
func show_toast(msg: String, color: Color = Color("#66CC66")):
	_label.text = msg
	_label.add_theme_color_override("font_color", color)
	_style.border_color = Color(color.r, color.g, color.b, 0.6)
	_panel.modulate.a = 0.0
	_panel.offset_top = START_TOP
	_panel.offset_bottom = START_BOTTOM
	_panel.visible = true
	_timer = 0.0
	_active = true
	set_process(true)


func _process(delta: float):
	if not _active:
		return
	_timer += delta
	if _timer < FADE_IN:
		var t := _timer / FADE_IN
		_panel.modulate.a = t
		_panel.offset_top = START_TOP + (1.0 - t) * 10
		_panel.offset_bottom = START_BOTTOM + (1.0 - t) * 10
	elif _timer < FADE_IN + HOLD:
		_panel.modulate.a = 1.0
		_panel.offset_top = START_TOP
		_panel.offset_bottom = START_BOTTOM
	elif _timer < FADE_IN + HOLD + FADE_OUT:
		var t := (_timer - FADE_IN - HOLD) / FADE_OUT
		_panel.modulate.a = 1.0 - t
		_panel.offset_top = START_TOP - t * 40
		_panel.offset_bottom = START_BOTTOM - t * 40
	else:
		_active = false
		_panel.visible = false
		set_process(false)
