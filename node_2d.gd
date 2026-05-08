extends Control

var spiritual_energy: float = 0.0
var mana_per_sec: float = 10.0
var realm: String = '练气一层'
var realm_level: int = 1
var offline_earnings: float = 0.0
var save_timer: float = 0.0
var max_log_lines: int = 100

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

const SAVE_PATH = "user://save.json"

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

func _ready():
	load_save()
	log_message("[color=green]游戏启动，欢迎回来！[/color]")
	calc_offline_earnings()
	# 绑定菜单按钮
	$MenuBar/BtnProfile.pressed.connect(_on_btn_profile)
	$MenuBar/BtnSkills.pressed.connect(_on_btn_skills)
	$MenuBar/BtnInventory.pressed.connect(_on_btn_inventory)
	$MenuBar/BtnShop.pressed.connect(_on_btn_shop)
	$MenuBar/BtnAlchemy.pressed.connect(_on_btn_alchemy)
	show_panel("profile")
	refresh_shop()
	refresh_inventory()

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
	# 每60秒自动保存
	save_timer += delta
	if save_timer >= 60.0:
		save_timer = 0.0
		save_game()

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
	$Label5.text = ""

func show_panel(name: String):
	$PanelProfile.visible = (name == "profile")
	$PanelSkills.visible = (name == "skills")
	$PanelInventory.visible = (name == "inventory")
	$PanelShop.visible = (name == "shop")
	$PanelAlchemy.visible = (name == "alchemy")

func _on_btn_profile():
	show_panel("profile")

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

func refresh_shop():
	var list = $PanelShop/VBox/ScrollList/ItemList
	# 清空旧内容
	for child in list.get_children():
		child.queue_free()
	# 功法区
	var skill_title = Label.new()
	skill_title.text = "=== 功法 ==="
	list.add_child(skill_title)
	for skill in shop_skills:
		var row = HBoxContainer.new()
		var info = Label.new()
		info.text = skill['name'] + "  " + skill['desc'] + "  灵气：" + str(skill['price'])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var btn = Button.new()
		if is_skill_learned(skill['name']):
			btn.text = "已学会"
			btn.disabled = true
		else:
			btn.text = "购买"
			btn.pressed.connect(_on_buy_skill.bind(skill))
		row.add_child(btn)
		list.add_child(row)
	# 丹方区
	var recipe_title = Label.new()
	recipe_title.text = "=== 丹方 ==="
	list.add_child(recipe_title)
	for recipe in shop_recipes:
		var row = HBoxContainer.new()
		var info = Label.new()
		info.text = recipe['name'] + "  " + recipe['desc'] + "  灵气：" + str(recipe['price'])
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var btn = Button.new()
		if is_recipe_learned(recipe['name']):
			btn.text = "已学会"
			btn.disabled = true
		else:
			btn.text = "购买"
			btn.pressed.connect(_on_buy_recipe.bind(recipe))
		row.add_child(btn)
		list.add_child(row)

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
