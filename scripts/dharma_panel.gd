extends PanelContainer

signal back_requested()
signal activate_dharma_requested(dharma_id: String)
signal synthesize_dharma_requested(grade: int)
signal buy_shard_requested(grade: int)
signal upgrade_dharma_requested(dharma_id: String)
signal star_up_dharma_requested(dharma_id: String)

var _dharma_inventory: Array = []
var _active_dharma_id: String = ""
var _dharma_shards: Array = []
var _realm_level: int = 1
var _dharma_unlocked: bool = false
var _spiritual_energy: float = 0.0
var _active_bonds: Array = []
var _dharma_max_level: int = 1
var _all_dharma_defs: Array = []
var _born_dharma_def: Dictionary = {}
var _dharma_bonds: Array = []
var _current_tab: String = "manage"

const DHARMA_GRADE_NAMES = ["凡", "灵", "宝", "仙", "神", "至尊", "鸿蒙"]
const DHARMA_GRADE_COLORS = [
	Color(0.65, 0.65, 0.65),
	Color(0.30, 0.85, 0.45),
	Color(0.30, 0.60, 1.00),
	Color(0.75, 0.45, 0.95),
	Color(1.00, 0.70, 0.10),
	Color(1.00, 0.25, 0.25),
	Color(0.10, 1.00, 0.90),
]
const SHARD_COSTS = [20, 50, 100, 200, 500, 1000, 2000]
const DHARMA_MAX_STARS = 5

func _ready():
	_build_ui_structure()

func _build_ui_structure():
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.layout_mode = 2
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	var topbar = HBoxContainer.new()
	topbar.name = "TopBar"
	topbar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var btn_back = Button.new()
	btn_back.text = "← 返回"
	btn_back.add_theme_font_size_override("font_size", 14)
	btn_back.pressed.connect(func(): back_requested.emit())
	topbar.add_child(btn_back)
	
	var tab_bar = HBoxContainer.new()
	tab_bar.name = "TabBar"
	tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tab_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	tab_bar.add_theme_constant_override("separation", 4)
	
	var btn_manage = Button.new()
	btn_manage.name = "BtnManage"
	btn_manage.text = "法相"
	btn_manage.add_theme_font_size_override("font_size", 13)
	btn_manage.pressed.connect(func(): _switch_tab("manage"))
	tab_bar.add_child(btn_manage)
	
	var btn_encyc = Button.new()
	btn_encyc.name = "BtnEncyc"
	btn_encyc.text = "图鉴"
	btn_encyc.add_theme_font_size_override("font_size", 13)
	btn_encyc.pressed.connect(func(): _switch_tab("encyc"))
	tab_bar.add_child(btn_encyc)
	
	topbar.add_child(tab_bar)
	vbox.add_child(topbar)
	
	var scroll = ScrollContainer.new()
	scroll.name = "Scroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	var content = VBoxContainer.new()
	content.name = "Content"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)
	
	vbox.add_child(scroll)
	add_child(vbox)

func _switch_tab(tab: String):
	_current_tab = tab
	_update_tab_buttons()
	refresh()

func _update_tab_buttons():
	var tabbar = $VBox/TopBar/TabBar
	var btn_manage = tabbar.get_node("BtnManage")
	var btn_encyc = tabbar.get_node("BtnEncyc")
	var active_color = Color(1.0, 0.84, 0.0)
	var inactive_color = Color(0.5, 0.5, 0.5)
	btn_manage.add_theme_color_override("font_color", active_color if _current_tab == "manage" else inactive_color)
	btn_encyc.add_theme_color_override("font_color", active_color if _current_tab == "encyc" else inactive_color)

func set_state(data: Dictionary):
	_dharma_inventory = data.get('dharma_inventory', [])
	_active_dharma_id = data.get('active_dharma_id', "")
	_dharma_shards = data.get('dharma_shards', [])
	_realm_level = data.get('realm_level', 1)
	_dharma_unlocked = data.get('dharma_unlocked', false)
	_spiritual_energy = data.get('spiritual_energy', 0.0)
	_active_bonds = data.get('active_bonds', [])
	_dharma_max_level = data.get('dharma_max_level', 1)
	_all_dharma_defs = data.get('all_dharma_defs', [])
	_born_dharma_def = data.get('born_dharma_def', {})
	_dharma_bonds = data.get('dharma_bonds', [])

func refresh():
	var content = $VBox/Scroll/Content
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	if not _dharma_unlocked:
		_show_locked(content)
		return
	_update_tab_buttons()
	if _current_tab == "encyc":
		_build_encyclopedia(content)
	else:
		_build_manage(content)

func _show_locked(content: Control):
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 80)
	content.add_child(spacer)
	var lock_label = Label.new()
	lock_label.text = "突破至金丹期方可开启法相系统"
	lock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lock_label.add_theme_font_size_override("font_size", 14)
	lock_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	content.add_child(lock_label)

func _find_owned(dharma_id: String) -> Dictionary:
	for d in _dharma_inventory:
		if d.id == dharma_id:
			return d
	return {}

func _build_encyclopedia(content: Control):
	var title = Label.new()
	title.text = "■ 法相图鉴"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	content.add_child(title)
	
	# 收集进度
	var owned_ids = []
	for d in _dharma_inventory:
		owned_ids.append(d.id)
	var total_count = _all_dharma_defs.size() + 1
	var owned_count = owned_ids.size()
	var progress = Label.new()
	progress.text = "收集进度: " + str(owned_count) + "/" + str(total_count)
	progress.add_theme_font_size_override("font_size", 12)
	progress.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	content.add_child(progress)
	content.add_child(_build_separator())
	
	# 按羁绊分组展示
	for bond in _dharma_bonds:
		var bond_section = _build_bond_section(bond)
		content.add_child(bond_section)
	
	# 未归属任何羁绊的法相
	var in_any_bond = []
	for bond in _dharma_bonds:
		for did in bond.dharmas:
			if not in_any_bond.has(did):
				in_any_bond.append(did)
	
	var ungrouped = []
	for d in _all_dharma_defs:
		if not in_any_bond.has(d.id):
			ungrouped.append(d.id)
	if not _born_dharma_def.is_empty() and not in_any_bond.has(_born_dharma_def.id):
		ungrouped.append(_born_dharma_def.id)
	
	if ungrouped.size() > 0:
		content.add_child(_build_separator())
		var other_title = Label.new()
		other_title.text = "■ 独立法相"
		other_title.add_theme_font_size_override("font_size", 13)
		other_title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		content.add_child(other_title)
		for did in ungrouped:
			var owned = _find_owned(did)
			var dharma = _get_dharma_info(did)
			var card = _build_encyc_card(dharma, owned)
			content.add_child(card)

func _get_dharma_info(dharma_id: String) -> Dictionary:
	if dharma_id == "born_nature":
		return _born_dharma_def
	for d in _all_dharma_defs:
		if d.id == dharma_id:
			return d
	return {}

func _build_bond_section(bond: Dictionary) -> Control:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	
	var sep = _build_separator()
	vbox.add_child(sep)
	
	# 羁绊标题
	var active = false
	var all_owned = true
	for did in bond.dharmas:
		var owned = _find_owned(did)
		if owned.is_empty():
			all_owned = false
	active = all_owned
	
	var bond_row = HBoxContainer.new()
	bond_row.add_theme_constant_override("separation", 6)
	
	var status_icon = Label.new()
	status_icon.text = "✓" if active else "○"
	status_icon.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2) if active else Color(0.4, 0.4, 0.4))
	status_icon.add_theme_font_size_override("font_size", 14)
	bond_row.add_child(status_icon)
	
	var bond_name = Label.new()
	bond_name.text = "【" + bond.name + "】" + ("" if active else "（未激活）")
	bond_name.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2) if active else Color(0.5, 0.5, 0.5))
	bond_name.add_theme_font_size_override("font_size", 13)
	bond_row.add_child(bond_name)
	
	var bond_desc = Label.new()
	bond_desc.text = bond.desc
	bond_desc.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	bond_desc.add_theme_font_size_override("font_size", 10)
	
	vbox.add_child(bond_row)
	vbox.add_child(bond_desc)
	
	# 羁绊效果
	var effects_text = ""
	for key in bond.effects:
		var val = bond.effects[key]
		match key:
			'atk_pct': effects_text += "攻+" + ("%.0f" % (val * 100)) + "% "
			'def_pct': effects_text += "防+" + ("%.0f" % (val * 100)) + "% "
			'hp_pct': effects_text += "血+" + ("%.0f" % (val * 100)) + "% "
			'mana_pct': effects_text += "修炼+" + ("%.0f" % (val * 100)) + "% "
	var eff_label = Label.new()
	eff_label.text = "  → " + effects_text
	eff_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5) if active else Color(0.35, 0.35, 0.35))
	eff_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(eff_label)
	
	# 所需法相列表
	for did in bond.dharmas:
		var owned = _find_owned(did)
		var dharma = _get_dharma_info(did)
		var card = _build_encyc_card(dharma, owned)
		vbox.add_child(card)
	
	return vbox

func _build_encyc_card(dharma_def: Dictionary, owned: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	
	if not owned.is_empty():
		var grade_color = DHARMA_GRADE_COLORS[owned.grade]
		style.bg_color = Color(grade_color.r * 0.1, grade_color.g * 0.1, grade_color.b * 0.15, 0.75)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(grade_color.r * 0.6, grade_color.g * 0.6, grade_color.b * 0.6)
	else:
		style.bg_color = Color(0.04, 0.04, 0.06, 0.6)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.15, 0.15, 0.15)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 6)
	
	# 左侧状态标记
	var status = Label.new()
	if not owned.is_empty():
		status.text = "✓"
		status.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5))
	else:
		status.text = "？"
		status.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	status.add_theme_font_size_override("font_size", 12)
	hbox.add_child(status)
	
	# 名称与描述
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 1)
	
	var name_row = HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 4)
	
	if not owned.is_empty():
		var g = owned.grade
		var gl = Label.new()
		gl.text = "[" + DHARMA_GRADE_NAMES[g] + "]"
		gl.add_theme_color_override("font_color", DHARMA_GRADE_COLORS[g])
		gl.add_theme_font_size_override("font_size", 12)
		name_row.add_child(gl)
	
	var name_lbl = Label.new()
	if not owned.is_empty():
		name_lbl.text = owned.name
		name_lbl.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	else:
		name_lbl.text = dharma_def.name if not dharma_def.is_empty() else "本命法相"
		name_lbl.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	name_lbl.add_theme_font_size_override("font_size", 12)
	name_row.add_child(name_lbl)
	
	if not owned.is_empty():
		var lv_lbl = Label.new()
		lv_lbl.text = "Lv." + str(owned.get('level', 1))
		lv_lbl.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		lv_lbl.add_theme_font_size_override("font_size", 10)
		name_row.add_child(lv_lbl)
		
		var stars = owned.get('stars', 0)
		var star_text = ""
		for i in range(DHARMA_MAX_STARS):
			star_text += "★" if i < stars else "☆"
		var star_lbl = Label.new()
		star_lbl.text = star_text
		star_lbl.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1))
		star_lbl.add_theme_font_size_override("font_size", 10)
		name_row.add_child(star_lbl)
	
	info_vbox.add_child(name_row)
	
	if not owned.is_empty():
		var stats = "攻+%.0f  防+%.0f  HP+%.0f  修炼+%.0f%%" % [owned.atk, owned.def, owned.hp, owned.mana_pct * 100]
		var stats_lbl = Label.new()
		stats_lbl.text = stats
		stats_lbl.add_theme_color_override("font_color", Color(0.45, 0.6, 0.45))
		stats_lbl.add_theme_font_size_override("font_size", 9)
		info_vbox.add_child(stats_lbl)
	else:
		var desc = ""
		if not dharma_def.is_empty() and dharma_def.has('desc'):
			desc = dharma_def.desc
		elif not _born_dharma_def.is_empty():
			desc = _born_dharma_def.get('desc', '')
		var hint = Label.new()
		hint.text = desc
		hint.add_theme_color_override("font_color", Color(0.3, 0.3, 0.3))
		hint.add_theme_font_size_override("font_size", 9)
		info_vbox.add_child(hint)
	
	hbox.add_child(info_vbox)
	card.add_child(hbox)
	return card

func _build_manage(content: Control):
	# 羁绊
	if not _active_bonds.is_empty():
		var bond_title = Label.new()
		bond_title.text = "◆ 已激活羁绊"
		bond_title.add_theme_font_size_override("font_size", 13)
		bond_title.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2))
		content.add_child(bond_title)
		for bond in _active_bonds:
			var bond_card = _build_bond_card(bond)
			content.add_child(bond_card)
	
	# 当前激活法相
	var active = _get_active_dharma_data()
	if not active.is_empty():
		var active_box = _build_dharma_card(active, true)
		content.add_child(active_box)
	else:
		var no_active = Label.new()
		no_active.text = "未激活法相"
		no_active.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_active.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		content.add_child(no_active)
	
	var inv_title = Label.new()
	inv_title.text = "■ 拥有法相"
	inv_title.add_theme_font_size_override("font_size", 13)
	inv_title.add_theme_color_override("font_color", Color(0.9, 0.85, 0.4))
	content.add_child(inv_title)
	
	var has_owned = false
	for dharma in _dharma_inventory:
		if dharma.id == _active_dharma_id:
			continue
		has_owned = true
		var card = _build_dharma_card(dharma, false)
		content.add_child(card)
	if not has_owned:
		var no_owned = Label.new()
		no_owned.text = "  暂无其他法相"
		no_owned.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		no_owned.add_theme_font_size_override("font_size", 11)
		content.add_child(no_owned)
	
	content.add_child(_build_separator())
	var shard_title = Label.new()
	shard_title.text = "■ 法相碎片合成"
	shard_title.add_theme_font_size_override("font_size", 13)
	shard_title.add_theme_color_override("font_color", Color(0.6, 0.4, 1.0))
	content.add_child(shard_title)
	
	for grade_idx in range(DHARMA_GRADE_NAMES.size()):
		var shard_count = 0
		for s in _dharma_shards:
			if s.grade == grade_idx:
				shard_count = s.count
				break
		var needed = SHARD_COSTS[grade_idx]
		var grade_name = DHARMA_GRADE_NAMES[grade_idx]
		var grade_color = DHARMA_GRADE_COLORS[grade_idx]
		var can_synth = shard_count >= needed
		
		var row = HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var name_label = Label.new()
		name_label.text = "[" + grade_name + "级碎片]"
		name_label.add_theme_color_override("font_color", grade_color)
		name_label.add_theme_font_size_override("font_size", 12)
		row.add_child(name_label)
		var count_label = Label.new()
		count_label.text = "拥有: " + str(shard_count) + "/" + str(needed)
		count_label.add_theme_font_size_override("font_size", 12)
		row.add_child(count_label)
		var btn = Button.new()
		btn.text = "合成" if can_synth else "不足"
		btn.disabled = not can_synth
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(50, 0)
		var g = grade_idx
		btn.pressed.connect(func(): synthesize_dharma_requested.emit(g))
		row.add_child(btn)
		content.add_child(row)
	
	content.add_child(_build_separator())
	var shop_title = Label.new()
	shop_title.text = "■ 碎片兑换"
	shop_title.add_theme_font_size_override("font_size", 13)
	shop_title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.3))
	content.add_child(shop_title)
	
	for grade_idx in range(DHARMA_GRADE_NAMES.size()):
		var grade_name = DHARMA_GRADE_NAMES[grade_idx]
		var grade_color = DHARMA_GRADE_COLORS[grade_idx]
		var price = int(pow(3, grade_idx + 1) * 50)
		var srow = HBoxContainer.new()
		srow.add_theme_constant_override("separation", 6)
		var sn_label = Label.new()
		sn_label.text = "[" + grade_name + "级碎片]"
		sn_label.add_theme_color_override("font_color", grade_color)
		sn_label.add_theme_font_size_override("font_size", 12)
		srow.add_child(sn_label)
		var sp_label = Label.new()
		sp_label.text = "价格: " + _format_num(price) + " 灵气"
		sp_label.add_theme_font_size_override("font_size", 11)
		srow.add_child(sp_label)
		var sbtn = Button.new()
		sbtn.text = "购买"
		sbtn.disabled = _spiritual_energy < price
		sbtn.add_theme_font_size_override("font_size", 11)
		sbtn.custom_minimum_size = Vector2(50, 0)
		var g2 = grade_idx
		sbtn.pressed.connect(func(): buy_shard_requested.emit(g2))
		srow.add_child(sbtn)
		content.add_child(srow)

func _build_separator() -> HSeparator:
	var sep = HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 4)
	return sep

func _get_active_dharma_data() -> Dictionary:
	if _active_dharma_id == "":
		return {}
	for dharma in _dharma_inventory:
		if dharma.id == _active_dharma_id:
			return dharma
	return {}

func _build_bond_card(bond: Dictionary) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.08, 0.02, 0.85)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(1.0, 0.5, 0.2, 0.5)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	var name_lbl = Label.new()
	name_lbl.text = "【" + bond.name + "】" + bond.desc
	name_lbl.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))
	name_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(name_lbl)
	
	var effects_text = ""
	for key in bond.effects:
		var val = bond.effects[key]
		match key:
			'atk_pct': effects_text += "攻击+" + ("%.0f" % (val * 100)) + "% "
			'def_pct': effects_text += "防御+" + ("%.0f" % (val * 100)) + "% "
			'hp_pct': effects_text += "气血+" + ("%.0f" % (val * 100)) + "% "
			'mana_pct': effects_text += "修炼速度+" + ("%.0f" % (val * 100)) + "% "
	var eff_lbl = Label.new()
	eff_lbl.text = effects_text
	eff_lbl.add_theme_color_override("font_color", Color(0.7, 0.9, 0.7))
	eff_lbl.add_theme_font_size_override("font_size", 10)
	vbox.add_child(eff_lbl)
	card.add_child(vbox)
	return card

func _build_dharma_card(dharma: Dictionary, is_active: bool) -> PanelContainer:
	var card = PanelContainer.new()
	var style = StyleBoxFlat.new()
	var grade_color = DHARMA_GRADE_COLORS[dharma.grade]
	if is_active:
		style.bg_color = Color(grade_color.r * 0.15, grade_color.g * 0.15, grade_color.b * 0.2, 0.85)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = grade_color
	else:
		style.bg_color = Color(0.06, 0.08, 0.1, 0.85)
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.2, 0.2, 0.25)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 2)
	
	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 4)
	
	var grade_label = Label.new()
	grade_label.text = "[" + DHARMA_GRADE_NAMES[dharma.grade] + "]"
	grade_label.add_theme_color_override("font_color", grade_color)
	grade_label.add_theme_font_size_override("font_size", 13)
	title_row.add_child(grade_label)
	
	var name_label = Label.new()
	var source_tag = ""
	if dharma.get('born', false):
		source_tag = " · 本命"
	elif dharma.get('source', '') == 'shard':
		source_tag = " · 合成"
	name_label.text = dharma.name + source_tag
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 0.8))
	name_label.add_theme_font_size_override("font_size", 13)
	title_row.add_child(name_label)
	
	if is_active:
		var active_tag = Label.new()
		active_tag.text = "[激活中]"
		active_tag.add_theme_color_override("font_color", Color(1.0, 0.84, 0.1))
		active_tag.add_theme_font_size_override("font_size", 11)
		title_row.add_child(active_tag)
	
	var stars = dharma.get('stars', 0)
	var star_text = ""
	for i in range(DHARMA_MAX_STARS):
		star_text += "★" if i < stars else "☆"
	var star_label = Label.new()
	star_label.text = star_text
	star_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.1))
	star_label.add_theme_font_size_override("font_size", 11)
	title_row.add_child(star_label)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(spacer)
	
	var level = dharma.get('level', 1)
	var lv_label = Label.new()
	lv_label.text = "Lv." + str(level)
	lv_label.add_theme_color_override("font_color", Color(0.6, 0.85, 0.6))
	lv_label.add_theme_font_size_override("font_size", 11)
	title_row.add_child(lv_label)
	
	if not is_active:
		var btn = Button.new()
		btn.text = "激活"
		btn.add_theme_font_size_override("font_size", 11)
		btn.custom_minimum_size = Vector2(45, 0)
		var did = dharma.id
		btn.pressed.connect(func(): activate_dharma_requested.emit(did))
		title_row.add_child(btn)
	
	vbox.add_child(title_row)
	
	var desc_label = Label.new()
	desc_label.text = dharma.desc
	desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.55))
	desc_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc_label)
	
	var level_mult = 1.0 + (level - 1) * 0.02
	var star_mult = 1.0 + stars * 0.05
	var base_mult = level_mult * star_mult * (1.5 if stars >= DHARMA_MAX_STARS else 1.0)
	var stats_text = "攻+%.0f  防+%.0f  HP+%.0f  修炼速度+%.0f%%" % [dharma.atk * base_mult, dharma.def * base_mult, dharma.hp * base_mult, dharma.mana_pct * base_mult * 100]
	var stats_label = Label.new()
	stats_label.text = stats_text
	stats_label.add_theme_color_override("font_color", Color(0.7, 0.85, 0.7))
	stats_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(stats_label)
	
	if stars > 0:
		var aff_text = "已激活词条：" + str(stars) + "/" + str(DHARMA_MAX_STARS)
		if stars >= DHARMA_MAX_STARS:
			aff_text = "★满星·终极形态已解锁"
		var aff_label = Label.new()
		aff_label.text = "◆ " + aff_text
		aff_label.add_theme_color_override("font_color", Color(1.0, 0.65, 0.2))
		aff_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(aff_label)
	
	var btn_row = HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 4)
	
	var upgrade_cost = int((dharma.grade + 1) * 150 + level * 80)
	var can_upgrade = level < _dharma_max_level and _spiritual_energy >= upgrade_cost
	var upgrade_btn = Button.new()
	var max_lv_text = " (上限Lv." + str(_dharma_max_level) + ")" if level >= _dharma_max_level else ""
	upgrade_btn.text = "升级(" + _format_num(upgrade_cost) + "灵)" + max_lv_text
	upgrade_btn.disabled = not can_upgrade
	upgrade_btn.add_theme_font_size_override("font_size", 10)
	var did_u = dharma.id
	upgrade_btn.pressed.connect(func(): upgrade_dharma_requested.emit(did_u))
	btn_row.add_child(upgrade_btn)
	
	var star_cost = SHARD_COSTS[dharma.grade] * (stars + 1)
	var shard_cnt = 0
	for s in _dharma_shards:
		if s.grade == dharma.grade:
			shard_cnt = s.count
			break
	var can_star = stars < DHARMA_MAX_STARS and shard_cnt >= star_cost
	var star_btn = Button.new()
	var star_btn_text = "升星(" + str(star_cost) + "碎)"
	if stars >= DHARMA_MAX_STARS:
		star_btn_text = "已满星"
	star_btn.text = star_btn_text
	star_btn.disabled = not can_star
	star_btn.add_theme_font_size_override("font_size", 10)
	var did_s = dharma.id
	star_btn.pressed.connect(func(): star_up_dharma_requested.emit(did_s))
	btn_row.add_child(star_btn)
	
	var btn_spacer = Control.new()
	btn_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_row.add_child(btn_spacer)
	vbox.add_child(btn_row)
	
	card.add_child(vbox)
	return card

func _format_num(n: float) -> String:
	var s = str(int(n))
	var result = ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return result
