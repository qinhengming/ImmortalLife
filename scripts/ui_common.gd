extends RefCounted
## 《修仙人生》UI 通用工具类
## 依据 docs/UI规范.md 实现，所有面板统一调用本类的静态方法，
## 保证配色、卡片、文字、数字格式化的一致性。
##
## 用法（在各面板脚本顶部）：
##   const UI = preload("res://scripts/ui_common.gd")
##   UI.lbl("文字", UI.COLOR_MAIN, 14)
##

# =====================================================================
# 2. 通用配色体系
# =====================================================================

# ---- 2.1 背景与容器 ----
const COLOR_BG         := Color("#0A0D12")  # 全局背景
const COLOR_MAIN_PANEL := Color("#0D1117")  # 主面板底色
const COLOR_CARD       := Color("#1A1F26")  # 卡片底色-默认
const COLOR_CARD_LIGHT := Color("#161A22")  # 卡片底色-亮
const COLOR_CARD_DARK  := Color("#101318")  # 卡片底色-暗
const COLOR_CARD_HOVER := Color("#2A3140")  # 卡片悬停
const COLOR_DIVIDER    := Color("#2A3140")  # 分隔线

# ---- 2.2 文本色板 ----
const COLOR_MAIN       := Color("#E8EAF0")  # 主文本
const COLOR_SUBTEXT    := Color("#8A93A3")  # 次级文本
const COLOR_WEAK       := Color("#5A6270")  # 弱文本/禁用
const COLOR_GOLD       := Color("#FFD54A")  # 高亮强调/金钱/等级
const COLOR_SUCCESS    := Color("#66CC66")  # 成功/升级/已拥有
const COLOR_DANGER     := Color("#E05555")  # 危险/失败/不足
const COLOR_INFO       := Color("#4DB8FF")  # 信息/教程

# ---- 2.4 品级/稀有度（黄玄地天圣）----
const GRADE_YELLOW  := Color("#8AC49A")  # 凡/黄级
const GRADE_BLUE    := Color("#4DB8FF")  # 灵/玄级
const GRADE_ORANGE  := Color("#FF8C42")  # 宝/地级
const GRADE_PURPLE  := Color("#B35CF7")  # 仙/天级
const GRADE_RED     := Color("#FF3B30")  # 神/圣级

# =====================================================================
# 数字格式化
# =====================================================================

const BIG_UNITS := ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']

## 大数字 -> 中文单位（万/亿/兆...）
static func format_big(n) -> String:
	if n is float:
		n = int(n)
	if n < 10000:
		return str(n)
	var val := float(n)
	var unit_idx := 0
	while val >= 10000 and unit_idx < BIG_UNITS.size() - 1:
		val /= 10000.0
		unit_idx += 1
	return str(val).pad_decimals(1) + BIG_UNITS[unit_idx]

## 千分位格式化
static func format_num(n) -> String:
	if n is float:
		n = int(n)
	var s := str(n)
	var result := ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return result

# =====================================================================
# 基础组件
# =====================================================================

## Label：统一文本创建
static func lbl(text: String, color: Color = COLOR_MAIN, size: int = 12) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label

## 自动换行 Label：用于描述文本（次级色，11号）
static func wlbl(text: String, color: Color = COLOR_SUBTEXT, size: int = 11) -> Label:
	var label := lbl(text, color, size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

## 区块标题（居中，── 标题 ── 样式）
static func section_title(text: String, color: Color = COLOR_INFO, size: int = 14) -> Label:
	var label := lbl("── " + text + " ──", color, size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

# =====================================================================
# 卡片组件
# =====================================================================

## 卡片背景 StyleBoxFlat：统一圆角6、内边距 10/6
static func card_bg(color: Color = COLOR_CARD, radius: int = 6, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	if border.a > 0.0:
		s.border_width_left = 1
		s.border_width_right = 1
		s.border_width_top = 1
		s.border_width_bottom = 1
		s.border_color = border
	s.corner_radius_top_left = radius
	s.corner_radius_top_right = radius
	s.corner_radius_bottom_left = radius
	s.corner_radius_bottom_right = radius
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

## 创建带卡片背景的 PanelContainer
static func card(color: Color = COLOR_CARD, border: Color = Color(0, 0, 0, 0)) -> PanelContainer:
	var c := PanelContainer.new()
	c.add_theme_stylebox_override("panel", card_bg(color, 6, border))
	return c

## 商城类卡片三态底色（见规范 §5.2）
static func shop_card_color(owned: bool, affordable: bool) -> Color:
	if owned:
		return Color("#142019")
	elif affordable:
		return Color("#161C22")
	else:
		return Color("#1C1212")
