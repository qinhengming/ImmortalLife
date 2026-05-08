extends Control

var spiritual_energy: float = 0.0
var mana_per_sec: float = 10.0
var realm: String = '练气一层'
var realm_level: int = 1
var offline_earnings: float = 0.0
var save_timer: float = 0.0
var max_log_lines: int = 100
var player_name: String = ""
var spirit_root: Dictionary = {}
var age: int = 16
var age_timer: float = 0.0
var tooltip_node: PanelContainer = null
var tooltip_slot: String = ""

# 玩家战斗属性
var player_hp: float = 100.0
var player_max_hp: float = 100.0

# 战斗状态
var in_battle: bool = false
var current_enemy: Dictionary = {}
var battle_timer: float = 0.0
var battle_speed: float = 1.0
var current_map: Dictionary = {}
var battle_log: String = ""
var equipped_items = {
	'weapon': null,
	'armor': null,
	'accessory': null,
	'artifact': null
}

# 背包：已购买的功法列表（存储功法名称）
var inventory: Array = []

# 已学会的功法列表
var learned_skills: Array = []

# 商店丹方列表
var shop_recipes = [
	{'name': '回灵丹', 'desc': '瞬间回复100灵气', 'price': 100, 'effect_type': 'restore_energy', 'effect_value': 100, 'craft_cost': 50},
	{'name': '培元丹', 'desc': '永久每秒灵气+0.5', 'price': 500, 'effect_type': 'mana_per_sec', 'effect_value': 0.5, 'craft_cost': 200},
	{'name': '破境丹', 'desc': '直接突破一个小境界', 'price': 2000, 'effect_type': 'realm_break', 'effect_value': 0, 'craft_cost': 1000},
	{'name': '聚灵丹', 'desc': '瞬间回复500灵气', 'price': 3000, 'effect_type': 'restore_energy', 'effect_value': 500, 'craft_cost': 1500},
	{'name': '天元丹', 'desc': '永久每秒灵气+2', 'price': 15000, 'effect_type': 'mana_per_sec', 'effect_value': 2.0, 'craft_cost': 8000},
]

# 已学会的丹方列表
var learned_recipes: Array = []

# 丹药背包 {丹药名: 数量}
var pill_inventory: Dictionary = {}

# 商店功法列表
var shop_skills = [
	{'name': '吐纳术', 'desc': '基础修炼功法，每秒灵气+1', 'price': 50, 'mana_bonus': 1.0},
	{'name': '聚灵诀', 'desc': '汇聚天地灵气，每秒灵气+3', 'price': 200, 'mana_bonus': 3.0},
	{'name': '御风诀', 'desc': '风属性功法，每秒灵气+5', 'price': 800, 'mana_bonus': 5.0},
	{'name': '焚天决', 'desc': '火属性功法，每秒灵气+10', 'price': 3000, 'mana_bonus': 10.0},
	{'name': '冰心诀', 'desc': '冰属性功法，每秒灵气+20', 'price': 10000, 'mana_bonus': 20.0},
	{'name': '天罡功', 'desc': '雷属性功法，每秒灵气+50', 'price': 50000, 'mana_bonus': 50.0},
]

var shop_equipment = [
	{'name': '竹剑', 'desc': '基础木剑', 'price': 100, 'slot': 'weapon', 'atk_bonus': 5, 'def_bonus': 0, 'mana_bonus': 0},
	{'name': '青锋剑', 'desc': '锋利铁剑', 'price': 500, 'slot': 'weapon', 'atk_bonus': 15, 'def_bonus': 0, 'mana_bonus': 0},
	{'name': '玄铁重剑', 'desc': '沉重无比', 'price': 3000, 'slot': 'weapon', 'atk_bonus': 40, 'def_bonus': 5, 'mana_bonus': 0},
	{'name': '布衣', 'desc': '粗布衣裳', 'price': 80, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 3, 'mana_bonus': 0},
	{'name': '铁甲', 'desc': '铸铁铠甲', 'price': 400, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 10, 'mana_bonus': 0},
	{'name': '金蚕丝甲', 'desc': '刀枪不入', 'price': 2500, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 30, 'mana_bonus': 1},
	{'name': '灵玉佩', 'desc': '温养灵气', 'price': 300, 'slot': 'accessory', 'atk_bonus': 0, 'def_bonus': 0, 'mana_bonus': 2},
	{'name': '聚灵珠', 'desc': '汇聚灵气', 'price': 2000, 'slot': 'accessory', 'atk_bonus': 0, 'def_bonus': 0, 'mana_bonus': 8},
	{'name': '拂尘', 'desc': '道家法器', 'price': 200, 'slot': 'artifact', 'atk_bonus': 3, 'def_bonus': 2, 'mana_bonus': 1},
	{'name': '八卦镜', 'desc': '镇邪驱魔', 'price': 1500, 'slot': 'artifact', 'atk_bonus': 10, 'def_bonus': 10, 'mana_bonus': 3},
]

const SAVE_PATH = "user://save.json"

const SPIRIT_ROOTS = [
	{'name': '金灵根', 'color': Color(1, 0.84, 0), 'bonus': 2.0, 'desc': '金系单灵根，修炼速度x2.0'},
	{'name': '木灵根', 'color': Color(0, 1, 0.5), 'bonus': 2.0, 'desc': '木系单灵根，修炼速度x2.0'},
	{'name': '水灵根', 'color': Color(0.3, 0.5, 1), 'bonus': 2.0, 'desc': '水系单灵根，修炼速度x2.0'},
	{'name': '火灵根', 'color': Color(1, 0.3, 0.3), 'bonus': 2.0, 'desc': '火系单灵根，修炼速度x2.0'},
	{'name': '土灵根', 'color': Color(0.8, 0.6, 0.2), 'bonus': 2.0, 'desc': '土系单灵根，修炼速度x2.0'},
	{'name': '雷灵根', 'color': Color(0.6, 0.3, 1), 'bonus': 3.0, 'desc': '变异雷灵根，修炼速度x3.0'},
	{'name': '冰灵根', 'color': Color(0.5, 0.8, 1), 'bonus': 3.0, 'desc': '变异冰灵根，修炼速度x3.0'},
	{'name': '风灵根', 'color': Color(0.3, 1, 0.8), 'bonus': 3.0, 'desc': '变异风灵根，修炼速度x3.0'},
	{'name': '天灵根', 'color': Color(1, 0.5, 0), 'bonus': 5.0, 'desc': '先天道体，修炼速度x5.0'},
]

const SURNAMES = ["叶", "林", "萧", "楚", "苏", "白", "陆", "秦", "顾", "沈", "江", "谢", "赵", "周", "吴", "郑", "王", "冯", "陈", "褚"]
const GIVEN_NAMES = ["辰", "玄", "逸", "风", "云", "岚", "沐", "尘", "瑶", "霜", "雪", "月", "天", "星", "宇", "浩", "清", "灵", "玉", "寒"]

const EQUIPMENT_SLOTS = ['weapon', 'armor', 'accessory', 'artifact']
const EQUIPMENT_SLOT_NAMES = {'weapon': '武器', 'armor': '防具', 'accessory': '饰品', 'artifact': '法宝'}

# 境界列表，按顺序排列
var realms = [
	{'name': '练气一层', 'cost': 100, 'mana_bonus': 0.5},
	{'name': '练气二层', 'cost': 300, 'mana_bonus': 0.5},
	{'name': '练气三层', 'cost': 800, 'mana_bonus': 1.0},
	{'name': '筑基初期', 'cost': 2000, 'mana_bonus': 2.0},
	{'name': '筑基中期', 'cost': 5000, 'mana_bonus': 3.0},
	{'name': '筑基后期', 'cost': 12000, 'mana_bonus': 5.0},
	{'name': '金丹初期', 'cost': 30000, 'mana_bonus': 10.0},
	{'name': '金丹中期', 'cost': 80000, 'mana_bonus': 15.0},
	{'name': '金丹后期', 'cost': 200000, 'mana_bonus': 25.0},
]

# 地图数据
var maps = [
	{
		'name': '青云山麓', 'desc': '灵气充裕的山脚，适合初入修仙者',
		'min_level': 1, 'color': Color(0.3, 0.8, 0.3),
		'enemies': [
			{'name': '妖蛛', 'hp': 30, 'atk': 5, 'def': 2, 'exp': 10},
			{'name': '灰狼', 'hp': 50, 'atk': 8, 'def': 3, 'exp': 15},
			{'name': '毒蛇', 'hp': 40, 'atk': 10, 'def': 1, 'exp': 12},
		]
	},
	{
		'name': '黑风谷', 'desc': '妖兽出没的峡谷，暗藏凶险',
		'min_level': 3, 'color': Color(0.5, 0.3, 0.3),
		'enemies': [
			{'name': '黑风虎', 'hp': 120, 'atk': 18, 'def': 8, 'exp': 30},
			{'name': '岩甲兽', 'hp': 200, 'atk': 12, 'def': 15, 'exp': 35},
			{'name': '噬魂蝠', 'hp': 80, 'atk': 22, 'def': 5, 'exp': 28},
		]
	},
	{
		'name': '天雷泽', 'desc': '雷电交加的沼泽，危机四伏',
		'min_level': 5, 'color': Color(0.6, 0.5, 1),
		'enemies': [
			{'name': '雷蛟', 'hp': 350, 'atk': 35, 'def': 18, 'exp': 80},
			{'name': '电鳗妖', 'hp': 250, 'atk': 40, 'def': 10, 'exp': 70},
			{'name': '霹雳熊', 'hp': 450, 'atk': 30, 'def': 25, 'exp': 90},
		]
	},
	{
		'name': '九幽冥海', 'desc': '阴气深重的海域，九死一生',
		'min_level': 7, 'color': Color(0.3, 0.2, 0.6),
		'enemies': [
			{'name': '冥海巨蟒', 'hp': 800, 'atk': 60, 'def': 30, 'exp': 200},
			{'name': '幽冥鬼将', 'hp': 600, 'atk': 75, 'def': 20, 'exp': 220},
			{'name': '九头妖龙', 'hp': 1200, 'atk': 50, 'def': 40, 'exp': 300},
		]
	},
]

func get_player_atk() -> float:
	var atk = realm_level * 15.0
	for s in EQUIPMENT_SLOTS:
		var ei = equipped_items[s]
		if ei != null:
			atk += ei['atk_bonus']
	return atk

func get_player_def() -> float:
	var def = realm_level * 10.0
	for s in EQUIPMENT_SLOTS:
		var ei = equipped_items[s]
		if ei != null:
			def += ei['def_bonus']
	return def

func update_max_hp():
	player_max_hp = 100.0 + realm_level * 50.0
	if player_hp > player_max_hp:
		player_hp = player_max_hp

func _ready():
	load_save()
	if spirit_root.is_empty():
		spirit_root = SPIRIT_ROOTS[randi() % SPIRIT_ROOTS.size()]
		log_message("[color=cyan]灵根觉醒：" + spirit_root['name'] + " —— " + spirit_root['desc'] + "[/color]")
	if player_name == "":
		player_name = SURNAMES[randi() % SURNAMES.size()] + GIVEN_NAMES[randi() % GIVEN_NAMES.size()]
	update_max_hp()
	log_message("[color=green]游戏启动，欢迎回来！[/color]")
	calc_offline_earnings()
	# 绑定菜单按钮
	$MenuBar/BtnProfile.pressed.connect(_on_btn_profile)
	$MenuBar/BtnSkills.pressed.connect(_on_btn_skills)
	$MenuBar/BtnInventory.pressed.connect(_on_btn_inventory)
	$MenuBar/BtnShop.pressed.connect(_on_btn_shop)
	$MenuBar/BtnAlchemy.pressed.connect(_on_btn_alchemy)
	$MenuBar/BtnEquipment.pressed.connect(_on_btn_equipment)
	$MenuBar/BtnMap.pressed.connect(_on_btn_map)
	show_panel("profile")
	refresh_profile()
	refresh_shop()
	refresh_inventory()
	refresh_equipment_panel()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()

func save_game():
	var data = {
		'spiritual_energy': spiritual_energy,
		'mana_per_sec': mana_per_sec,
		'realm': realm,
		'realm_level': realm_level,
		'inventory': inventory,
		'learned_skills': learned_skills,
		'learned_recipes': learned_recipes,
		'pill_inventory': pill_inventory,
		'player_name': player_name,
		'spirit_root': spirit_root,
		'age': age,
		'equipped_items': equipped_items,
		'player_hp': player_hp,
		'last_time': Time.get_unix_time_from_system(),
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_save():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return
	spiritual_energy = data.get('spiritual_energy', 0.0)
	mana_per_sec = data.get('mana_per_sec', 10.0)
	realm = data.get('realm', '练气一层')
	realm_level = data.get('realm_level', 1)
	inventory = data.get('inventory', [])
	learned_skills = data.get('learned_skills', [])
	learned_recipes = data.get('learned_recipes', [])
	pill_inventory = data.get('pill_inventory', {})
	player_name = data.get('player_name', "")
	spirit_root = data.get('spirit_root', {})
	age = data.get('age', 16)
	var loaded_eq = data.get('equipped_items', {})
	if loaded_eq.size() > 0:
		equipped_items = loaded_eq
	player_hp = data.get('player_hp', 100.0)

func calc_offline_earnings():
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var json = JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data = json.data
	if typeof(data) != TYPE_DICTIONARY or not data.has('last_time'):
		return
	var last_time = data['last_time']
	var now = Time.get_unix_time_from_system()
	var elapsed = now - last_time
	if elapsed > 0:
		offline_earnings = mana_per_sec * elapsed
		spiritual_energy += offline_earnings
		log_message("[color=cyan]离线收益：" + str(int(offline_earnings)) + " 灵气（离线 " + str(int(elapsed)) + " 秒）[/color]")
		# 检查是否可以突破
		while try_breakthrough():
			pass

func _process(delta: float):
	spiritual_energy += mana_per_sec * delta
	try_breakthrough()
	update_ui()
	# 年龄增长（每300秒涨1岁）
	age_timer += delta
	if age_timer >= 300.0:
		age_timer = 0.0
		age += 1
	# 每60秒自动保存
	save_timer += delta
	if save_timer >= 60.0:
		save_timer = 0.0
		save_game()
	# 战斗逻辑
	_process_battle(delta)
	# tooltip 跟踪鼠标
	if tooltip_node and tooltip_node.visible:
		var mp = get_global_mouse_position()
		tooltip_node.position = Vector2(mp.x + 12, mp.y + 12)

func try_breakthrough() -> bool:
	if realm_level >= realms.size():
		return false
	var next = realms[realm_level]
	if spiritual_energy >= next['cost']:
		spiritual_energy -= next['cost']
		mana_per_sec += next['mana_bonus']
		realm_level += 1
		realm = next['name']
		log_message("[color=yellow]突破成功！当前境界：" + realm + "[/color]")
		return true
	return false

func get_next_realm_cost() -> int:
	if realm_level >= realms.size():
		return -1
	return realms[realm_level]['cost']

func log_message(msg: String):
	var time = Time.get_time_string_from_system()
	$MessageLog.append_text("[color=gray]" + time + "[/color] " + msg + "\n")
	# 限制最大行数
	var lines = $MessageLog.get_line_count()
	if lines > max_log_lines:
		$MessageLog.remove_line(0)

func update_ui():
	$Label.text = "灵气：" + str(int(spiritual_energy))
	$Label2.text = "每秒灵气：" + str(int(mana_per_sec))
	$Label3.text = "境界：" + realm
	$Label4.text = "突破所需：" + (str(get_next_realm_cost()) if get_next_realm_cost() > 0 else "已达最高境界")
	$Label5.text = "HP：" + str(int(player_hp)) + "/" + str(int(player_max_hp))

func show_panel(name: String):
	hide_tooltip()
	$PanelProfile.visible = (name == "profile")
	$PanelSkills.visible = (name == "skills")
	$PanelInventory.visible = (name == "inventory")
	$PanelShop.visible = (name == "shop")
	$PanelAlchemy.visible = (name == "alchemy")
	$PanelEquipment.visible = (name == "equipment")
	$PanelMap.visible = (name == "map")

func _on_btn_profile():
	show_panel("profile")
	refresh_profile()

func get_realm_title() -> String:
	match realm_level:
		1,2,3: return "练气修士"
		4,5,6: return "筑基真人"
		7,8,9: return "金丹真君"
		_: return "散修"

func _make_profile_card(bg: Color) -> PanelContainer:
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

func _profile_label(text: String, color: Color = Color(0.9, 0.9, 1.0), size: int = 13) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", size)
	return label

func refresh_profile():
	var list = $PanelProfile/VBox/ScrollList/ItemList
	for child in list.get_children():
		child.queue_free()

	# === 称号卡 ===
	var header = _make_profile_card(Color(0.12, 0.12, 0.2))
	var hv = VBoxContainer.new()
	hv.add_theme_constant_override("separation", 2)
	header.add_child(hv)

	var nl = _profile_label(player_name, Color(1, 0.84, 0), 20)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(nl)

	var tl = _profile_label("「" + get_realm_title() + "」", Color(0.6, 0.6, 0.8), 11)
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(tl)

	list.add_child(header)
	list.add_child(HSeparator.new())

	# === 境界卡 ===
	var rc = _make_profile_card(Color(0.14, 0.16, 0.22))
	var rv = VBoxContainer.new()
	rv.add_theme_constant_override("separation", 4)
	rc.add_child(rv)

	var realm_row = HBoxContainer.new()
	realm_row.add_child(_profile_label("◇ ", Color(0.3, 0.8, 1)))
	realm_row.add_child(_profile_label("境界：" + realm, Color(0.3, 0.8, 1), 14))
	rv.add_child(realm_row)

	if realm_level < realms.size():
		var cost = realms[realm_level]['cost']
		var progress = ProgressBar.new()
		progress.min_value = 0
		progress.max_value = cost
		progress.value = min(spiritual_energy, cost)
		progress.show_percentage = false
		rv.add_child(progress)

		rv.add_child(_profile_label(_format_num(spiritual_energy) + " / " + _format_num(cost) + " 灵气", Color(0.7, 0.7, 0.8), 11))
	else:
		rv.add_child(_profile_label("已达最高境界", Color(1, 0.84, 0)))

	list.add_child(rc)
	list.add_child(HSeparator.new())

	# === 灵根卡 ===
	var sc = _make_profile_card(Color(0.16, 0.14, 0.22))
	var sv = VBoxContainer.new()
	sv.add_theme_constant_override("separation", 4)
	sc.add_child(sv)

	var sr_row = HBoxContainer.new()
	var root_color = spirit_root.get('color', Color(1, 1, 1))
	sr_row.add_child(_profile_label("◇ ", root_color))
	sr_row.add_child(_profile_label("灵根：" + spirit_root.get('name', '未觉醒'), root_color, 14))
	sv.add_child(sr_row)
	sv.add_child(_profile_label(spirit_root.get('desc', ''), Color(0.6, 0.6, 0.8), 11))

	list.add_child(sc)
	list.add_child(HSeparator.new())

	# === 属性卡 ===
	var ac = _make_profile_card(Color(0.14, 0.18, 0.16))
	var av = VBoxContainer.new()
	av.add_theme_constant_override("separation", 4)
	ac.add_child(av)

	var atk = get_player_atk()
	var def = get_player_def()

	var attr_row1 = HBoxContainer.new()
	attr_row1.add_child(_profile_label("攻击：" + str(int(atk)), Color(1, 0.6, 0.4)))
	attr_row1.add_child(_profile_label("  |  ", Color(0.3, 0.3, 0.4)))
	attr_row1.add_child(_profile_label("防御：" + str(int(def)), Color(0.4, 0.8, 1)))
	av.add_child(attr_row1)

	var attr_row2 = HBoxContainer.new()
	attr_row2.add_child(_profile_label("灵气：" + _format_num(spiritual_energy), Color(1, 0.84, 0)))
	attr_row2.add_child(_profile_label("  |  ", Color(0.3, 0.3, 0.4)))
	attr_row2.add_child(_profile_label("每秒：" + str(int(mana_per_sec)), Color(0.3, 1, 0.5)))
	av.add_child(attr_row2)

	var attr_row3 = HBoxContainer.new()
	attr_row3.add_child(_profile_label("HP：" + str(int(player_hp)) + "/" + str(int(player_max_hp)), Color(0.4, 1, 0.4)))
	av.add_child(attr_row3)

	list.add_child(ac)
	list.add_child(HSeparator.new())

	# === 修行统计卡 ===
	var tc = _make_profile_card(Color(0.16, 0.16, 0.18))
	var tv = VBoxContainer.new()
	tv.add_theme_constant_override("separation", 4)
	tc.add_child(tv)

	tv.add_child(_profile_label("年龄：" + str(age) + "岁", Color(0.7, 0.7, 0.9)))

	var stat_row = HBoxContainer.new()
	stat_row.add_child(_profile_label("功法：" + str(learned_skills.size()) + "门", Color(0.4, 0.9, 0.4)))
	stat_row.add_child(_profile_label("  |  ", Color(0.3, 0.3, 0.4)))
	var pill_count = 0
	for p in pill_inventory:
		pill_count += pill_inventory[p]
	stat_row.add_child(_profile_label("丹药：" + str(pill_count) + "颗", Color(0.9, 0.6, 0.3)))
	tv.add_child(stat_row)

	list.add_child(tc)

func _on_btn_skills():
	show_panel("skills")
	refresh_skills()

func _on_btn_inventory():
	show_panel("inventory")
	refresh_inventory()

func _on_btn_shop():
	show_panel("shop")
	refresh_shop()

func _on_btn_alchemy():
	show_panel("alchemy")
	refresh_alchemy()

func _on_btn_equipment():
	show_panel("equipment")
	refresh_equipment_panel()

func _on_btn_map():
	if in_battle:
		show_panel("map")
		refresh_battle_ui()
	else:
		show_panel("map")
		refresh_map_panel()

func is_skill_learned(skill_name: String) -> bool:
	for s in learned_skills:
		if s['name'] == skill_name:
			return true
	return false

func is_recipe_learned(recipe_name: String) -> bool:
	for r in learned_recipes:
		if r['name'] == recipe_name:
			return true
	return false

# ---- 商店 ----

func _format_num(n: float) -> String:
	var s = str(int(n))
	var result = ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return result

func _make_card_bg(owned: bool, affordable: bool) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	if owned:
		style.bg_color = Color(0.12, 0.16, 0.12)
	elif affordable:
		style.bg_color = Color(0.14, 0.18, 0.16)
	else:
		style.bg_color = Color(0.19, 0.13, 0.13)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _make_item_card(data: Dictionary, type: String) -> PanelContainer:
	var owned = is_skill_learned(data['name']) if type == "skill" else is_recipe_learned(data['name'])
	var affordable = spiritual_energy >= data['price']

	var card = PanelContainer.new()
	card.add_theme_stylebox_override("panel", _make_card_bg(owned, affordable))

	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_theme_constant_override("separation", 6)
	card.add_child(hbox)

	# 名称+描述
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(info_vbox)

	var name_label = Label.new()
	name_label.text = data['name']
	name_label.add_theme_font_size_override("font_size", 13)
	if owned:
		name_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	else:
		name_label.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
	info_vbox.add_child(name_label)

	var desc_label = Label.new()
	if type == "skill":
		desc_label.text = data['desc'] + " | 每秒灵气+" + str(data['mana_bonus'])
	else:
		desc_label.text = data['desc'] + " | 炼制消耗：" + _format_num(data['craft_cost'])
	desc_label.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
	desc_label.add_theme_font_size_override("font_size", 11)
	info_vbox.add_child(desc_label)

	# 价格标签
	var price_box = HBoxContainer.new()
	hbox.add_child(price_box)

	var price_label = Label.new()
	price_label.text = _format_num(data['price'])
	price_label.add_theme_font_size_override("font_size", 13)
	if owned:
		price_label.add_theme_color_override("font_color", Color(0.3, 0.5, 0.3))
	elif affordable:
		price_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	else:
		price_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
	price_box.add_child(price_label)

	var unit = Label.new()
	unit.text = "灵"
	unit.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	unit.add_theme_font_size_override("font_size", 11)
	unit.add_theme_constant_override("margin_right", 4)
	price_box.add_child(unit)

	# 按钮
	var btn = Button.new()
	if owned:
		btn.text = "已习得"
		btn.disabled = true
	else:
		btn.text = "购买"
		if type == "skill":
			btn.pressed.connect(_on_buy_skill.bind(data))
		else:
			btn.pressed.connect(_on_buy_recipe.bind(data))
	hbox.add_child(btn)

	return card

func refresh_shop():
	var list = $PanelShop/VBox/ScrollList/ItemList
	for child in list.get_children():
		child.queue_free()

	# 当前灵气栏
	var header = HBoxContainer.new()
	var hl = Label.new()
	hl.text = "当前灵气："
	var hv = Label.new()
	hv.text = _format_num(spiritual_energy)
	hv.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	hv.add_theme_font_size_override("font_size", 15)
	header.add_child(hl)
	header.add_child(hv)
	list.add_child(header)
	list.add_child(HSeparator.new())

	# 功法区
	var st = Label.new()
	st.text = "── 功法秘笈 ──"
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	st.add_theme_font_size_override("font_size", 13)
	st.add_theme_constant_override("margin_top", 6)
	st.add_theme_constant_override("margin_bottom", 4)
	list.add_child(st)
	for skill in shop_skills:
		list.add_child(_make_item_card(skill, "skill"))

	# 丹方区
	var rt = Label.new()
	rt.text = "── 丹方大全 ──"
	rt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rt.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	rt.add_theme_font_size_override("font_size", 13)
	rt.add_theme_constant_override("margin_top", 8)
	rt.add_theme_constant_override("margin_bottom", 4)
	list.add_child(rt)
	for recipe in shop_recipes:
		list.add_child(_make_item_card(recipe, "recipe"))

	# 装备区
	var eq_label = Label.new()
	eq_label.text = "── 装备 ──"
	eq_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eq_label.add_theme_color_override("font_color", Color(0.3, 0.8, 1.0))
	eq_label.add_theme_font_size_override("font_size", 13)
	eq_label.add_theme_constant_override("margin_top", 8)
	eq_label.add_theme_constant_override("margin_bottom", 4)
	list.add_child(eq_label)

	for equip in shop_equipment:
		var affordable = spiritual_energy >= equip['price']
		var card = PanelContainer.new()
		var es = StyleBoxFlat.new()
		es.bg_color = Color(0.14, 0.18, 0.16) if affordable else Color(0.19, 0.13, 0.13)
		es.corner_radius_top_left = 5
		es.corner_radius_top_right = 5
		es.corner_radius_bottom_left = 5
		es.corner_radius_bottom_right = 5
		es.content_margin_left = 10
		es.content_margin_right = 10
		es.content_margin_top = 6
		es.content_margin_bottom = 6
		card.add_theme_stylebox_override("panel", es)

		var hbox = HBoxContainer.new()
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_theme_constant_override("separation", 6)
		card.add_child(hbox)

		var vbox = VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 2)
		hbox.add_child(vbox)

		var nl = Label.new()
		nl.text = equip['name']
		nl.add_theme_font_size_override("font_size", 13)
		nl.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0))
		vbox.add_child(nl)

		var stat_parts = []
		stat_parts.append(EQUIPMENT_SLOT_NAMES[equip['slot']])
		if equip['atk_bonus'] > 0: stat_parts.append("攻击+" + str(equip['atk_bonus']))
		if equip['def_bonus'] > 0: stat_parts.append("防御+" + str(equip['def_bonus']))
		if equip['mana_bonus'] > 0: stat_parts.append("灵气+" + str(equip['mana_bonus']))

		var dl = Label.new()
		dl.text = equip['desc'] + " | " + " ".join(stat_parts)
		dl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.7))
		dl.add_theme_font_size_override("font_size", 11)
		vbox.add_child(dl)

		var price_box = HBoxContainer.new()
		hbox.add_child(price_box)

		var pl = Label.new()
		pl.text = _format_num(equip['price'])
		pl.add_theme_font_size_override("font_size", 13)
		pl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3) if affordable else Color(1.0, 0.35, 0.35))
		price_box.add_child(pl)

		var ul = Label.new()
		ul.text = "灵"
		ul.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		ul.add_theme_font_size_override("font_size", 11)
		ul.add_theme_constant_override("margin_right", 4)
		price_box.add_child(ul)

		var btn = Button.new()
		btn.text = "购买"
		btn.pressed.connect(_on_buy_equipment.bind(equip))
		hbox.add_child(btn)

		list.add_child(card)

func _on_buy_skill(skill: Dictionary):
	if is_skill_learned(skill['name']):
		log_message("[color=red]已学会" + skill['name'] + "，无需重复购买[/color]")
		return
	if spiritual_energy < skill['price']:
		log_message("[color=red]灵气不足，无法购买" + skill['name'] + "[/color]")
		return
	spiritual_energy -= skill['price']
	inventory.append(skill['name'])
	log_message("[color=green]购买成功：" + skill['name'] + "[/color]")
	refresh_shop()
	refresh_inventory()

func _on_buy_recipe(recipe: Dictionary):
	if is_recipe_learned(recipe['name']):
		log_message("[color=red]已学会丹方" + recipe['name'] + "，无需重复购买[/color]")
		return
	if spiritual_energy < recipe['price']:
		log_message("[color=red]灵气不足，无法购买丹方" + recipe['name'] + "[/color]")
		return
	spiritual_energy -= recipe['price']
	learned_recipes.append(recipe)
	log_message("[color=green]购买丹方成功：" + recipe['name'] + "[/color]")
	refresh_shop()

func _on_buy_equipment(item: Dictionary):
	if spiritual_energy < item['price']:
		log_message("[color=red]灵气不足，无法购买" + item['name'] + "[/color]")
		return
	spiritual_energy -= item['price']
	var slot = item['slot']
	var old = equipped_items[slot]
	if old != null:
		mana_per_sec -= old['mana_bonus']
		log_message("[color=green]替换装备：" + old['name'] + " → " + item['name'] + "[/color]")
	else:
		log_message("[color=green]装备成功：" + item['name'] + "[/color]")
	mana_per_sec += item['mana_bonus']
	equipped_items[slot] = item
	refresh_shop()
	refresh_equipment_panel()

# ---- 已学功法 ----

func refresh_skills():
	var list = $PanelSkills/VBox/ScrollList/ItemList
	for child in list.get_children():
		child.queue_free()
	if learned_skills.is_empty():
		var empty = Label.new()
		empty.text = "尚未学会任何功法"
		list.add_child(empty)
		return
	for skill in learned_skills:
		var label = Label.new()
		label.text = skill['name'] + "  " + skill['desc'] + "  每秒灵气+" + str(skill['mana_bonus'])
		list.add_child(label)

# ---- 背包 ----

func refresh_inventory():
	var list = $PanelInventory/VBox/ScrollList/ItemList
	for child in list.get_children():
		child.queue_free()
	# 功法物品
	if not inventory.is_empty():
		var skill_title = Label.new()
		skill_title.text = "=== 功法 ==="
		list.add_child(skill_title)
		for i in range(inventory.size()):
			var skill_name = inventory[i]
			var row = HBoxContainer.new()
			var info = Label.new()
			info.text = skill_name
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)
			var btn = Button.new()
			btn.text = "使用"
			btn.pressed.connect(_on_use_skill.bind(i))
			row.add_child(btn)
			list.add_child(row)
	# 丹药
	var has_pills = false
	for pill_name in pill_inventory:
		if pill_inventory[pill_name] > 0:
			has_pills = true
			break
	if has_pills:
		var pill_title = Label.new()
		pill_title.text = "=== 丹药 ==="
		list.add_child(pill_title)
		for pill_name in pill_inventory:
			var count = pill_inventory[pill_name]
			if count <= 0:
				continue
			var row = HBoxContainer.new()
			var info = Label.new()
			info.text = pill_name + " x" + str(count)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)
			var btn = Button.new()
			btn.text = "使用"
			btn.pressed.connect(_on_use_pill.bind(pill_name))
			row.add_child(btn)
			list.add_child(row)
	if inventory.is_empty() and not has_pills:
		var empty = Label.new()
		empty.text = "背包为空"
		list.add_child(empty)

func _on_use_skill(index: int):
	if index >= inventory.size():
		return
	var skill_name = inventory[index]
	if is_skill_learned(skill_name):
		log_message("[color=red]已学会" + skill_name + "，无法重复学习[/color]")
		return
	var skill_data = null
	for s in shop_skills:
		if s['name'] == skill_name:
			skill_data = s
			break
	if skill_data == null:
		log_message("[color=red]未知功法：" + skill_name + "[/color]")
		return
	mana_per_sec += skill_data['mana_bonus']
	inventory.remove_at(index)
	learned_skills.append({'name': skill_name, 'mana_bonus': skill_data['mana_bonus'], 'desc': skill_data['desc']})
	log_message("[color=cyan]使用功法：" + skill_name + "，每秒灵气+" + str(skill_data['mana_bonus']) + "[/color]")
	refresh_inventory()
	refresh_skills()

# ---- 炼丹 ----

func refresh_alchemy():
	var list = $PanelAlchemy/VBox/ScrollList/ItemList
	for child in list.get_children():
		child.queue_free()
	if learned_recipes.is_empty():
		var empty = Label.new()
		empty.text = "尚未学会任何丹方，请在商店购买"
		list.add_child(empty)
		return
	for recipe in learned_recipes:
		var row = HBoxContainer.new()
		var info = Label.new()
		info.text = recipe['name'] + "  " + recipe['desc'] + "  炼制消耗：" + str(recipe['craft_cost']) + "灵气"
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var btn = Button.new()
		btn.text = "炼制"
		btn.pressed.connect(_on_craft_pill.bind(recipe))
		row.add_child(btn)
		list.add_child(row)
	# 显示丹药背包
	var pill_title = Label.new()
	pill_title.text = "=== 丹药背包 ==="
	list.add_child(pill_title)
	if pill_inventory.is_empty():
		var empty = Label.new()
		empty.text = "暂无丹药"
		list.add_child(empty)
	else:
		for pill_name in pill_inventory:
			var count = pill_inventory[pill_name]
			if count <= 0:
				continue
			var row = HBoxContainer.new()
			var info = Label.new()
			info.text = pill_name + " x" + str(count)
			info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(info)
			var btn = Button.new()
			btn.text = "使用"
			btn.pressed.connect(_on_use_pill.bind(pill_name))
			row.add_child(btn)
			list.add_child(row)

func _on_craft_pill(recipe: Dictionary):
	if spiritual_energy < recipe['craft_cost']:
		log_message("[color=red]灵气不足，无法炼制" + recipe['name'] + "[/color]")
		return
	spiritual_energy -= recipe['craft_cost']
	if pill_inventory.has(recipe['name']):
		pill_inventory[recipe['name']] += 1
	else:
		pill_inventory[recipe['name']] = 1
	log_message("[color=green]炼制成功：" + recipe['name'] + "[/color]")
	refresh_alchemy()
	refresh_inventory()

func _on_use_pill(pill_name: String):
	if not pill_inventory.has(pill_name) or pill_inventory[pill_name] <= 0:
		log_message("[color=red]没有" + pill_name + "[/color]")
		return
	# 查找丹药效果
	var recipe_data = null
	for r in shop_recipes:
		if r['name'] == pill_name:
			recipe_data = r
			break
	if recipe_data == null:
		log_message("[color=red]未知丹药：" + pill_name + "[/color]")
		return
	# 执行效果
	match recipe_data['effect_type']:
		'restore_energy':
			spiritual_energy += recipe_data['effect_value']
			log_message("[color=cyan]使用" + pill_name + "，回复" + str(recipe_data['effect_value']) + "灵气[/color]")
		'mana_per_sec':
			mana_per_sec += recipe_data['effect_value']
			log_message("[color=cyan]使用" + pill_name + "，每秒灵气+" + str(recipe_data['effect_value']) + "[/color]")
		'realm_break':
			if try_breakthrough():
				pass
			else:
				log_message("[color=red]已达最高境界，" + pill_name + "无效[/color]")
				spiritual_energy += recipe_data['craft_cost']  # 退还消耗
				pill_inventory[pill_name] += 1  # 还原丹药
				return
	pill_inventory[pill_name] -= 1
	if pill_inventory[pill_name] <= 0:
		pill_inventory.erase(pill_name)
	refresh_alchemy()
	refresh_inventory()

# ---- 装备 ----

func refresh_equipment_panel():
	var list = $PanelEquipment/VBox/ScrollList/ItemList
	for child in list.get_children():
		child.queue_free()

	# 装备格子行
	var grid = HBoxContainer.new()
	grid.alignment = BoxContainer.ALIGNMENT_CENTER
	grid.add_theme_constant_override("separation", 12)
	list.add_child(grid)

	var total_atk = 0
	var total_def = 0
	var total_mana = 0

	for slot in EQUIPMENT_SLOTS:
		var item = equipped_items[slot]
		if item != null:
			total_atk += item['atk_bonus']
			total_def += item['def_bonus']
			total_mana += item['mana_bonus']
		grid.add_child(_make_equip_grid_cell(slot, item))

	# 总加成
	var tp = []
	if total_atk > 0: tp.append("攻击+" + str(total_atk))
	if total_def > 0: tp.append("防御+" + str(total_def))
	if total_mana > 0: tp.append("灵气+" + str(total_mana))

	var stat_label = _profile_label("", Color(1, 0.84, 0), 12)
	if tp.size() > 0:
		stat_label.text = "总加成：" + "  ".join(tp)
	else:
		stat_label.text = "未装备任何物品"
		stat_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(stat_label)

	# 提示
	var hint = _profile_label("── 点击方格可卸下装备 ──", Color(0.35, 0.35, 0.45), 10)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(hint)

func _make_equip_grid_cell(slot: String, item) -> PanelContainer:
	var cell = PanelContainer.new()
	cell.custom_minimum_size = Vector2(100, 60)

	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 6
	style.content_margin_right = 6
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1

	if item != null:
		style.bg_color = Color(0.1, 0.14, 0.22)
		style.border_color = Color(0.25, 0.5, 0.8)
	else:
		style.bg_color = Color(0.12, 0.12, 0.14)
		style.border_color = Color(0.3, 0.3, 0.35)
	cell.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 1)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cell.add_child(vbox)

	# 槽位名
	var slot_label = Label.new()
	slot_label.text = EQUIPMENT_SLOT_NAMES[slot]
	slot_label.add_theme_font_size_override("font_size", 10)
	slot_label.add_theme_color_override("font_color", Color(0.45, 0.55, 0.7))
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slot_label)

	# 物品名
	var name_label = Label.new()
	if item != null:
		name_label.text = item['name']
		name_label.add_theme_font_size_override("font_size", 13)
		# 按槽位着色
		match slot:
			"weapon": name_label.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
			"armor": name_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
			"accessory": name_label.add_theme_color_override("font_color", Color(0.9, 0.7, 1))
			"artifact": name_label.add_theme_color_override("font_color", Color(1, 0.84, 0))
	else:
		name_label.text = "[ 空 ]"
		name_label.add_theme_font_size_override("font_size", 11)
		name_label.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# 鼠标事件
	var slot_copy = slot
	var item_copy = item
	cell.mouse_entered.connect(func(): _show_tooltip(slot_copy, item_copy))
	cell.mouse_exited.connect(hide_tooltip)
	cell.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if item_copy != null:
				_on_unequip(slot_copy)
	)

	return cell

func _show_tooltip(slot: String, item):
	hide_tooltip()
	tooltip_slot = slot
	tooltip_node = PanelContainer.new()
	tooltip_node.z_index = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.95)
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.4, 0.5, 0.7)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	tooltip_node.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 3)
	tooltip_node.add_child(vbox)

	# 物品名
	var title = Label.new()
	if item != null:
		title.text = item['name']
		title.add_theme_font_size_override("font_size", 14)
		match slot:
			"weapon": title.add_theme_color_override("font_color", Color(1, 0.6, 0.4))
			"armor": title.add_theme_color_override("font_color", Color(0.4, 0.8, 1))
			"accessory": title.add_theme_color_override("font_color", Color(0.9, 0.7, 1))
			"artifact": title.add_theme_color_override("font_color", Color(1, 0.84, 0))
	else:
		title.text = EQUIPMENT_SLOT_NAMES[slot] + "（空）"
		title.add_theme_font_size_override("font_size", 13)
		title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	vbox.add_child(title)

	# 类型
	var type_label = Label.new()
	type_label.text = "类型：" + EQUIPMENT_SLOT_NAMES[slot]
	type_label.add_theme_font_size_override("font_size", 11)
	type_label.add_theme_color_override("font_color", Color(0.5, 0.6, 0.75))
	vbox.add_child(type_label)

	if item != null:
		# 描述
		var desc = Label.new()
		desc.text = item['desc']
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
		vbox.add_child(desc)

		# 分隔线
		var sep = HSeparator.new()
		sep.add_theme_constant_override("separation", 4)
		vbox.add_child(sep)

		# 属性
		var stats = []
		if item['atk_bonus'] > 0: stats.append("攻击  +" + str(item['atk_bonus']))
		if item['def_bonus'] > 0: stats.append("防御  +" + str(item['def_bonus']))
		if item['mana_bonus'] > 0: stats.append("灵气  +" + str(item['mana_bonus']))
		for s in stats:
			var sl = Label.new()
			sl.text = s
			sl.add_theme_font_size_override("font_size", 12)
			sl.add_theme_color_override("font_color", Color(0.4, 1, 0.4))
			vbox.add_child(sl)

		# 分隔线
		var sep2 = HSeparator.new()
		vbox.add_child(sep2)

		# 操作提示
		var action = Label.new()
		action.text = "点击卸下"
		action.add_theme_font_size_override("font_size", 10)
		action.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
		action.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(action)

	add_child(tooltip_node)
	tooltip_node.visible = true
	var mp = get_global_mouse_position()
	tooltip_node.position = Vector2(mp.x + 12, mp.y + 12)

func hide_tooltip():
	if tooltip_node:
		tooltip_node.visible = false
		tooltip_node.queue_free()
		tooltip_node = null
		tooltip_slot = ""

func _on_unequip(slot: String):
	var item = equipped_items[slot]
	if item == null:
		return
	hide_tooltip()
	mana_per_sec -= item['mana_bonus']
	equipped_items[slot] = null
	log_message("[color=gray]卸下了" + item['name'] + "[/color]")
	refresh_equipment_panel()

# ---- 地图 & 战斗 ----

func refresh_map_panel():
	var list = $PanelMap/VBox/ScrollList/ItemList
	for child in list.get_children():
		child.queue_free()

	if in_battle:
		refresh_battle_ui()
		return

	var title = _profile_label("选择地图进行历练", Color(0.6, 0.6, 0.8), 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(title)
	list.add_child(HSeparator.new())

	for map in maps:
		var unlocked = realm_level >= map['min_level']
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
			style.border_color = map['color'] * 0.5
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

		var nameLabel = Label.new()
		nameLabel.text = map['name']
		nameLabel.add_theme_font_size_override("font_size", 14)
		if unlocked:
			nameLabel.add_theme_color_override("font_color", map['color'])
		else:
			nameLabel.add_theme_color_override("font_color", Color(0.35, 0.35, 0.4))
		vbox.add_child(nameLabel)

		var descLabel = Label.new()
		descLabel.text = map['desc']
		descLabel.add_theme_font_size_override("font_size", 11)
		descLabel.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
		vbox.add_child(descLabel)

		var levelLabel = Label.new()
		if unlocked:
			levelLabel.text = "可进入"
			levelLabel.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
		else:
			levelLabel.text = "需要境界等级 " + str(map['min_level']) + "（当前 " + str(realm_level) + "）"
			levelLabel.add_theme_color_override("font_color", Color(0.8, 0.3, 0.3))
		levelLabel.add_theme_font_size_override("font_size", 10)
		vbox.add_child(levelLabel)

		if unlocked:
			var btn = Button.new()
			btn.text = "历练"
			var map_ref = map
			btn.pressed.connect(func(): start_battle(map_ref))
			hbox.add_child(btn)

		list.add_child(card)

func start_battle(map: Dictionary):
	current_map = map
	in_battle = true
	battle_timer = 0.0
	battle_log = ""
	update_max_hp()
	player_hp = player_max_hp
	spawn_enemy()
	show_panel("map")
	refresh_battle_ui()
	log_message("[color=yellow]进入" + map['name'] + "开始历练！[/color]")

func spawn_enemy():
	var template = current_map['enemies'][randi() % current_map['enemies'].size()]
	# 敌人属性按地图等级浮动
	var scale = 1.0 + (realm_level - current_map['min_level']) * 0.15
	current_enemy = {
		'name': template['name'],
		'hp': template['hp'] * scale,
		'max_hp': template['hp'] * scale,
		'atk': template['atk'] * scale,
		'def': template['def'] * scale,
		'exp': int(template['exp'] * scale),
	}

func refresh_battle_ui():
	var list = $PanelMap/VBox/ScrollList/ItemList
	for child in list.get_children():
		child.queue_free()

	if not in_battle:
		return

	# 敌人信息
	var enemy_title = _profile_label("── 战斗中 ──", Color(1, 0.4, 0.3), 14)
	enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	list.add_child(enemy_title)

	var enemy_name = _profile_label("敌人：" + current_enemy['name'], Color(1, 0.6, 0.4), 13)
	list.add_child(enemy_name)

	# 敌人血条
	var enemy_hp_bar = _make_hp_bar(current_enemy['hp'], current_enemy['max_hp'], Color(0.8, 0.2, 0.2))
	list.add_child(enemy_hp_bar)

	var enemy_hp_text = _profile_label("HP：" + str(int(current_enemy['hp'])) + "/" + str(int(current_enemy['max_hp'])), Color(0.9, 0.7, 0.7), 11)
	list.add_child(enemy_hp_text)

	list.add_child(HSeparator.new())

	# 玩家信息
	var player_title = _profile_label("你的状态", Color(0.4, 0.8, 1), 13)
	list.add_child(player_title)

	# 玩家血条
	var player_hp_bar = _make_hp_bar(player_hp, player_max_hp, Color(0.2, 0.7, 0.3))
	list.add_child(player_hp_bar)

	var player_hp_text = _profile_label("HP：" + str(int(player_hp)) + "/" + str(int(player_max_hp)), Color(0.7, 0.9, 0.7), 11)
	list.add_child(player_hp_text)

	var stat_row = HBoxContainer.new()
	stat_row.add_child(_profile_label("攻击：" + str(int(get_player_atk())), Color(1, 0.6, 0.4)))
	stat_row.add_child(_profile_label("  |  ", Color(0.3, 0.3, 0.4)))
	stat_row.add_child(_profile_label("防御：" + str(int(get_player_def())), Color(0.4, 0.8, 1)))
	list.add_child(stat_row)

	list.add_child(HSeparator.new())

	# 战斗日志
	if battle_log != "":
		var log_label = _profile_label(battle_log, Color(0.7, 0.7, 0.8), 11)
		list.add_child(log_label)

	# 停止按钮
	var stop_btn = Button.new()
	stop_btn.text = "停止历练"
	stop_btn.pressed.connect(stop_battle)
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

func stop_battle():
	in_battle = false
	current_enemy = {}
	current_map = {}
	battle_log = ""
	player_hp = player_max_hp
	log_message("[color=gray]停止历练，已恢复HP[/color]")
	refresh_map_panel()

func _process_battle(delta: float):
	if not in_battle:
		return
	battle_timer += delta
	if battle_timer >= 1.0 / battle_speed:
		battle_timer -= 1.0 / battle_speed
		_do_battle_tick()

func _do_battle_tick():
	# 玩家攻击敌人
	var damage = max(1, int(get_player_atk() - current_enemy['def'] + randi_range(-2, 2)))
	current_enemy['hp'] -= damage
	battle_log = "你对" + current_enemy['name'] + "造成 " + str(damage) + " 点伤害"

	# 敌人死亡
	if current_enemy['hp'] <= 0:
		spiritual_energy += current_enemy['exp']
		battle_log = "击杀了" + current_enemy['name'] + "，获得 " + str(current_enemy['exp']) + " 灵气"
		log_message("[color=green]击杀" + current_enemy['name'] + "！获得 " + str(current_enemy['exp']) + " 灵气[/color]")
		spawn_enemy()
		if $PanelMap.visible:
			refresh_battle_ui()
		return

	# 敌人攻击玩家
	var enemy_damage = max(1, int(current_enemy['atk'] - get_player_def() + randi_range(-2, 2)))
	player_hp -= enemy_damage
	battle_log += "\n" + current_enemy['name'] + "对你造成 " + str(enemy_damage) + " 点伤害"

	# 玩家死亡
	if player_hp <= 0:
		player_hp = 0
		in_battle = false
		log_message("[color=red]你被" + current_enemy['name'] + "击败了！回城恢复[/color]")
		player_hp = player_max_hp
		current_enemy = {}
		current_map = {}
		battle_log = ""
		if $PanelMap.visible:
			refresh_map_panel()
		return

	if $PanelMap.visible:
		refresh_battle_ui()
