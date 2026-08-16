extends Control

const UI := preload("res://scripts/ui_common.gd")

var spiritual_energy: float = 0.0
var mana_per_sec: float = 10.0
var realm: String = '练气一层'
var realm_level: int = 1
var offline_earnings: float = 0.0
var save_timer: float = 0.0
var max_log_lines: int = 100

# Toast 提示
var _toast_panel = null
var _toast_label = null
var _toast_style = null
var _toast_active: bool = false
var _toast_timer: float = 0.0

# 打坐冥想
var meditation_timer: float = 0.0
var meditation_cycle_time: float = 3.0
var meditation_cycles: int = 0
var pending_energy: float = 0.0
var player_name: String = ""
var spirit_root: Dictionary = {}
var age: int = 16
var age_timer: float = 0.0
var tooltip_node: PanelContainer = null
var tooltip_slot: String = ""

# 修炼速度乘区变量
var base_mana: float = 10.0
var realm_multiplier: float = 1.0
var technique_multiplier: float = 1.0
var spirit_root_multiplier: float = 1.0
var cave_multiplier: float = 1.0
var artifact_multiplier: float = 1.0
var time_coefficient: float = 1.0
var pill_flat_bonus: float = 0.0
var cave_level: int = 1
var cave_buildings: Dictionary = {}
var cave_base_bonus: float = 0.0
var cave_upgrade_limit: int = 1
var cave_upgrade_queue: Array = []
var spirit_ore: float = 0.0
var spirit_wood: float = 0.0

# 宗门系统
var sect_level: int = 1
var sect_buildings: Dictionary = {}
var sect_materials: Dictionary = {}
var disciples: Array = []
var disciple_capacity: int = 3
var sect_disciple_mana: float = 0.0

# 兵解重修 & 天赋
var reincarnation_count: int = 0
var enlightenment_points: int = 0
var talents: Dictionary = {}
var talent_multiplier: float = 1.0
var talent_mana_bonus: float = 0.0

# 玩家战斗属性
var player_hp: float = 100.0
var player_max_hp: float = 100.0

# 战斗状态
var in_battle: bool = false
var enemy_team: Array = []
var ally_team: Array = []
var battle_timer: float = 0.0
var battle_speed: float = 1.0
var attrs: Dictionary = {}  # 个人属性
var breakthrough_fail_timer: float = 0.0  # 突破失败冷却
var current_map: Dictionary = {}
var current_sub_map: int = 1
var battle_log: String = ""
var companions_unlocked: Array = []

# 法相系统
var dharma_unlocked: bool = false
var dharma_inventory: Array = []
var active_dharma_id: String = ""
var dharma_shards: Array = []
var dharma_multiplier: float = 1.0
var dharma_mana_pct: float = 0.0

# 地图设置
var auto_next_map: bool = false
var loop_current_map: bool = false
var map_sub_level: Dictionary = {}  # {'青云山麓': 1, '黑风谷': 1, ...}

const COMPANION_DEFS = [
	{'id': 'sword_servant', 'name': '剑侍', 'unlock_realm': 2, 'base_hp': 50, 'base_atk': 8, 'base_def': 4, 'color': Color(0.3, 0.8, 0.5)},
	{'id': 'formation_spirit', 'name': '阵灵', 'unlock_realm': 10, 'base_hp': 80, 'base_atk': 12, 'base_def': 8, 'color': Color(0.5, 0.5, 1.0)},
	{'id': 'pill_child', 'name': '丹童', 'unlock_realm': 18, 'base_hp': 60, 'base_atk': 10, 'base_def': 6, 'color': Color(0.3, 1.0, 0.7)},
	{'id': 'dharma_protector', 'name': '护法', 'unlock_realm': 37, 'base_hp': 150, 'base_atk': 20, 'base_def': 15, 'color': Color(1.0, 0.5, 0.3)},
	{'id': 'dao_partner', 'name': '道侣', 'unlock_realm': 28, 'base_hp': 200, 'base_atk': 30, 'base_def': 20, 'color': Color(1.0, 0.3, 0.7)},
]
var equipped_items = {
	'weapon': null,
	'helmet': null,
	'armor': null,
	'boots': null,
	'artifact': null,
	'accessory': null,
	'belt': null,
	'ring_left': null,
	'ring_right': null,
	'cloak': null
}

# 出售价格比例
const SELL_RATIO: float = 0.5

# 背包：已购买的功法秘笈（存储tech_id）
var inventory: Array = []

# 装备背包
var equipment_inventory: Array = []

# 已学会的功法 {tech_id: {level: int}}
var learned_techniques: Dictionary = {}
# 正在参悟的功法ID（同一时间只能参悟一门）
var comprehending_tech_id: String = ""
var comprehension_progress: float = 0.0
var comprehension_time_total: float = 0.0

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
# 丹方背包（未使用的丹方秘笈）
var recipe_inventory: Array = []

# 已学会的阵法列表
var learned_arrays: Array = []
# 当前洞府激活的阵法
var active_array: String = ""
# 阵法背包（未使用的阵法秘笈）
var array_inventory: Array = []

# 丹药背包 {丹药名: 数量}
var pill_inventory: Dictionary = {}

# 商店功法列表
var shop_skills = [
	{'name': '吐纳术', 'desc': '基础修炼功法，修炼速度x1.1', 'price': 50, 'mana_bonus': 1.0, 'mana_bonus_pct': 0.10, 'min_realm': 1, 'color': Color(0.20, 0.85, 0.55)},
	{'name': '聚灵诀', 'desc': '汇聚天地灵气，修炼速度x1.3', 'price': 200, 'mana_bonus': 3.0, 'mana_bonus_pct': 0.30, 'min_realm': 2, 'color': Color(0.15, 0.80, 0.55)},
	{'name': '御风诀', 'desc': '风属性功法，修炼速度x1.5', 'price': 800, 'mana_bonus': 5.0, 'mana_bonus_pct': 0.50, 'min_realm': 3, 'color': Color(0.10, 0.75, 0.55)},
	{'name': '焚天决', 'desc': '火属性功法，修炼速度x2.0', 'price': 3000, 'mana_bonus': 10.0, 'mana_bonus_pct': 1.00, 'min_realm': 10, 'color': Color(0.45, 0.75, 0.95)},
	{'name': '冰心诀', 'desc': '冰属性功法，修炼速度x3.0', 'price': 10000, 'mana_bonus': 20.0, 'mana_bonus_pct': 2.00, 'min_realm': 19, 'color': Color(1.00, 0.85, 0.25)},
	{'name': '天罡功', 'desc': '雷属性功法，修炼速度x6.0', 'price': 50000, 'mana_bonus': 50.0, 'mana_bonus_pct': 5.00, 'min_realm': 28, 'color': Color(0.75, 0.45, 0.95)},
]

# 商店阵法列表
var shop_arrays = [
	{'name': '乾天阵', 'desc': '天道循环，洞府修炼速度+5%', 'price': 100, 'effect_type': 'cave_mana_pct', 'effect_value': 0.05, 'min_realm': 1, 'color': Color(1.0, 0.84, 0.0), 'trigram': '☰'},
	{'name': '坤地阵', 'desc': '地势坤，防御+15%', 'price': 300, 'effect_type': 'def_pct', 'effect_value': 0.15, 'min_realm': 2, 'color': Color(0.8, 0.65, 0.15), 'trigram': '☷'},
	{'name': '震雷阵', 'desc': '雷霆万钧，攻击+15%', 'price': 800, 'effect_type': 'atk_pct', 'effect_value': 0.15, 'min_realm': 3, 'color': Color(0.3, 0.8, 0.3), 'trigram': '☳'},
	{'name': '离火阵', 'desc': '离火燎原，炼丹消耗-15%', 'price': 2500, 'effect_type': 'craft_discount', 'effect_value': 0.15, 'min_realm': 10, 'color': Color(1.0, 0.4, 0.2), 'trigram': '☲'},
	{'name': '坎水阵', 'desc': '上善若水，HP上限+25%', 'price': 5000, 'effect_type': 'hp_pct', 'effect_value': 0.25, 'min_realm': 14, 'color': Color(0.2, 0.5, 1.0), 'trigram': '☵'},
	{'name': '巽风阵', 'desc': '风行天下，参悟速度+25%', 'price': 12000, 'effect_type': 'comprehension_speed', 'effect_value': 0.25, 'min_realm': 18, 'color': Color(0.1, 0.85, 0.7), 'trigram': '☴'},
	{'name': '艮山阵', 'desc': '不动如山，洞府建筑效果+20%', 'price': 30000, 'effect_type': 'building_boost', 'effect_value': 0.20, 'min_realm': 37, 'color': Color(0.7, 0.5, 0.2), 'trigram': '☶'},
	{'name': '兑泽阵', 'desc': '泽被苍生，每秒灵气+15', 'price': 80000, 'effect_type': 'mana_flat', 'effect_value': 15.0, 'min_realm': 28, 'color': Color(0.9, 0.8, 0.3), 'trigram': '☱'},
]

var shop_equipment = [
	{'name': '竹剑', 'desc': '基础木剑', 'price': 100, 'slot': 'weapon', 'atk_bonus': 5, 'def_bonus': 0, 'mana_bonus': 0},
	{'name': '青锋剑', 'desc': '锋利铁剑', 'price': 500, 'slot': 'weapon', 'atk_bonus': 15, 'def_bonus': 0, 'mana_bonus': 0},
	{'name': '玄铁重剑', 'desc': '沉重无比', 'price': 3000, 'slot': 'weapon', 'atk_bonus': 40, 'def_bonus': 5, 'mana_bonus': 0},
	{'name': '落日弓', 'desc': '落日神弓', 'price': 12000, 'slot': 'weapon', 'atk_bonus': 85, 'def_bonus': 0, 'mana_bonus': 5},
	{'name': '粗布头巾', 'desc': '简陋头巾', 'price': 60, 'slot': 'helmet', 'atk_bonus': 0, 'def_bonus': 2, 'mana_bonus': 0},
	{'name': '铁冠', 'desc': '铁制头冠', 'price': 350, 'slot': 'helmet', 'atk_bonus': 0, 'def_bonus': 8, 'mana_bonus': 0},
	{'name': '紫金冠', 'desc': '紫金锻造', 'price': 2200, 'slot': 'helmet', 'atk_bonus': 0, 'def_bonus': 22, 'mana_bonus': 2},
	{'name': '布衣', 'desc': '粗布衣裳', 'price': 80, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 3, 'mana_bonus': 0},
	{'name': '铁甲', 'desc': '铸铁铠甲', 'price': 400, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 10, 'mana_bonus': 0},
	{'name': '金蚕丝甲', 'desc': '刀枪不入', 'price': 2500, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 30, 'mana_bonus': 1},
	{'name': '草鞋', 'desc': '草编鞋履', 'price': 50, 'slot': 'boots', 'atk_bonus': 0, 'def_bonus': 1, 'mana_bonus': 0},
	{'name': '疾风靴', 'desc': '身轻如燕', 'price': 400, 'slot': 'boots', 'atk_bonus': 3, 'def_bonus': 4, 'mana_bonus': 0},
	{'name': '踏云靴', 'desc': '如踏云端', 'price': 2400, 'slot': 'boots', 'atk_bonus': 8, 'def_bonus': 12, 'mana_bonus': 3},
	{'name': '拂尘', 'desc': '道家法器', 'price': 200, 'slot': 'artifact', 'atk_bonus': 3, 'def_bonus': 2, 'mana_bonus': 1, 'mana_bonus_pct': 0.10},
	{'name': '八卦镜', 'desc': '镇邪驱魔', 'price': 1500, 'slot': 'artifact', 'atk_bonus': 10, 'def_bonus': 10, 'mana_bonus': 3, 'mana_bonus_pct': 0.30},
	{'name': '灵玉佩', 'desc': '温养灵气', 'price': 300, 'slot': 'accessory', 'atk_bonus': 0, 'def_bonus': 0, 'mana_bonus': 2},
	{'name': '聚灵珠', 'desc': '汇聚灵气', 'price': 2000, 'slot': 'accessory', 'atk_bonus': 0, 'def_bonus': 0, 'mana_bonus': 8},
	{'name': '麻绳腰带', 'desc': '简陋麻绳', 'price': 40, 'slot': 'belt', 'atk_bonus': 0, 'def_bonus': 1, 'mana_bonus': 0},
	{'name': '犀皮带', 'desc': '坚韧皮带', 'price': 300, 'slot': 'belt', 'atk_bonus': 0, 'def_bonus': 6, 'mana_bonus': 1},
	{'name': '灵纹腰带', 'desc': '刻有灵纹', 'price': 1800, 'slot': 'belt', 'atk_bonus': 0, 'def_bonus': 14, 'mana_bonus': 4},
	{'name': '铁戒', 'desc': '普通铁戒', 'price': 120, 'slot': 'ring_left', 'atk_bonus': 2, 'def_bonus': 0, 'mana_bonus': 0},
	{'name': '白玉戒', 'desc': '温润白玉', 'price': 800, 'slot': 'ring_left', 'atk_bonus': 5, 'def_bonus': 0, 'mana_bonus': 3},
	{'name': '乾坤戒', 'desc': '内有乾坤', 'price': 3000, 'slot': 'ring_left', 'atk_bonus': 0, 'def_bonus': 0, 'mana_bonus': 12},
	{'name': '铜戒', 'desc': '普通铜戒', 'price': 120, 'slot': 'ring_right', 'atk_bonus': 0, 'def_bonus': 2, 'mana_bonus': 0},
	{'name': '玄铁戒', 'desc': '玄铁铸造', 'price': 800, 'slot': 'ring_right', 'atk_bonus': 0, 'def_bonus': 6, 'mana_bonus': 3},
	{'name': '须弥戒', 'desc': '须弥纳芥', 'price': 3000, 'slot': 'ring_right', 'atk_bonus': 0, 'def_bonus': 0, 'mana_bonus': 12},
	{'name': '麻布披风', 'desc': '粗麻布披', 'price': 70, 'slot': 'cloak', 'atk_bonus': 0, 'def_bonus': 2, 'mana_bonus': 0},
	{'name': '夜行斗篷', 'desc': '黑夜潜行', 'price': 1000, 'slot': 'cloak', 'atk_bonus': 5, 'def_bonus': 6, 'mana_bonus': 0},
	{'name': '天罗羽衣', 'desc': '仙羽织成', 'price': 3800, 'slot': 'cloak', 'atk_bonus': 10, 'def_bonus': 18, 'mana_bonus': 5},
]

var shop_furnaces = [
	{'name': '青铜丹炉', 'desc': '基础炼丹炉，略微加快炼制速度', 'price': 500, 'speed_bonus': 0.10, 'success_bonus': 0.00, 'min_realm': 1, 'color': Color(0.8, 0.5, 0.2)},
	{'name': '玄铁丹炉', 'desc': '玄铁铸就，炼丹速度+20%', 'price': 2000, 'speed_bonus': 0.20, 'success_bonus': 0.05, 'min_realm': 2, 'color': Color(0.4, 0.45, 0.55)},
	{'name': '紫金丹炉', 'desc': '紫金铸造，炼丹速度+35%，成功率+10%', 'price': 8000, 'speed_bonus': 0.35, 'success_bonus': 0.10, 'min_realm': 10, 'color': Color(0.85, 0.65, 0.1)},
	{'name': '九霄神炉', 'desc': '传说中的炉鼎，炼丹速度+60%，成功率+25%', 'price': 30000, 'speed_bonus': 0.60, 'success_bonus': 0.25, 'min_realm': 19, 'color': Color(1.0, 0.3, 0.85)},
	{'name': '混沌天炉', 'desc': '混沌至宝，炼丹速度x2.0，成功率+40%', 'price': 150000, 'speed_bonus': 1.00, 'success_bonus': 0.40, 'min_realm': 28, 'color': Color(1.0, 0.84, 0.0)},
]

var furnace_inventory: Array = []
var equipped_furnaces: Array = []

var shop_test_items = [
	{'name': '破境升天符', 'desc': '测试道具：使用后立即提升一阶境界', 'price': 100, 'effect_type': 'realm_up'},
	{'name': '降境归元符', 'desc': '测试道具：使用后立即降低一阶境界', 'price': 100, 'effect_type': 'realm_down'},
	{'name': '灵木', 'desc': '宗门建材：蕴含灵气的木材', 'price': 200, 'effect_type': 'buy_material', 'material': '灵木', 'amount': 5},
	{'name': '玄铁', 'desc': '宗门建材：漆黑如墨的矿石', 'price': 1000, 'effect_type': 'buy_material', 'material': '玄铁', 'amount': 3},
	{'name': '魂晶', 'desc': '宗门建材：凝结灵魂精华的晶体', 'price': 5000, 'effect_type': 'buy_material', 'material': '魂晶', 'amount': 1},
	{'name': '升级令', 'desc': '洞府同时升级建筑上限+1（可重复购买）', 'price': 500, 'effect_type': 'cave_upgrade_limit', 'effect_value': 1},
]

const SAVE_PATH = "user://save.json"

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

const ATTR_DEFS = {
	'physique':     {'name': '体魄', 'desc': '每点+3%气血上限', 'color': Color(1.0, 0.4, 0.3)},
	'bone':         {'name': '根骨', 'desc': '每点+3%防御', 'color': Color(0.4, 0.8, 1.0)},
	'strength':     {'name': '臂力', 'desc': '每点+3%攻击', 'color': Color(1.0, 0.6, 0.4)},
	'spirit':       {'name': '灵力', 'desc': '每点+3%基础灵气', 'color': Color(0.6, 0.4, 1.0)},
	'comprehension':{'name': '悟性', 'desc': '每点+5%参悟速度', 'color': Color(0.3, 0.9, 0.5)},
	'fortune':      {'name': '机缘', 'desc': '每点+5%突破概率', 'color': Color(1.0, 0.84, 0.0)},
	'agility':      {'name': '身法', 'desc': '每点+5%战斗速度', 'color': Color(0.5, 0.9, 0.9)},
	'critical':     {'name': '会心', 'desc': '每点+3%暴击率(1.5倍伤害)', 'color': Color(1.0, 0.5, 0.5)},
}

const SURNAMES = ["叶", "林", "萧", "楚", "苏", "白", "陆", "秦", "顾", "沈", "江", "谢", "赵", "周", "吴", "郑", "王", "冯", "陈", "褚"]
const GIVEN_NAMES = ["辰", "玄", "逸", "风", "云", "岚", "沐", "尘", "瑶", "霜", "雪", "月", "天", "星", "宇", "浩", "清", "灵", "玉", "寒"]

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

# 法相系统定义
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
const DHARMA_SHARD_COSTS = [20, 50, 100, 200, 500, 1000, 2000]
const DHARMA_MAX_STARS = 5
const DHARMA_LEVEL_PER_STAR_BONUS = 0.05

const DHARMA_DEFS = [
	{'id': 'ancient_tree', 'name': '古树法相', 'desc': '千年古树之灵，庇护万灵',
	 'star_affixes': ['根深：防御+10%', '叶茂：气血+15%', '年轮：修炼速度+8%', '枯荣：每秒回复2%气血', '【万古长青】全属性+50%，防御额外+30%'],
	 'grades': [
		{'atk': 5, 'def': 8, 'hp': 30, 'mana_pct': 0.05},
		{'atk': 15, 'def': 25, 'hp': 100, 'mana_pct': 0.12},
		{'atk': 40, 'def': 70, 'hp': 350, 'mana_pct': 0.25},
		{'atk': 120, 'def': 200, 'hp': 1200, 'mana_pct': 0.50},
		{'atk': 350, 'def': 550, 'hp': 4000, 'mana_pct': 1.00},
		{'atk': 1200, 'def': 1800, 'hp': 15000, 'mana_pct': 2.50},
		{'atk': 5000, 'def': 7000, 'hp': 60000, 'mana_pct': 6.00},
	]},
	{'id': 'flame_phoenix', 'name': '火凤法相', 'desc': '涅槃之火，焚尽万物',
	 'star_affixes': ['烈焰：攻击+10%', '焚天：暴击率+8%', '涅槃：死亡后复活一次恢复30%气血', '炎盾：受击反弹20%伤害', '【不死真凰】全属性+50%，攻击额外+30%'],
	 'grades': [
		{'atk': 10, 'def': 4, 'hp': 20, 'mana_pct': 0.05},
		{'atk': 30, 'def': 12, 'hp': 60, 'mana_pct': 0.12},
		{'atk': 85, 'def': 35, 'hp': 200, 'mana_pct': 0.25},
		{'atk': 250, 'def': 100, 'hp': 700, 'mana_pct': 0.50},
		{'atk': 750, 'def': 280, 'hp': 2500, 'mana_pct': 1.00},
		{'atk': 2500, 'def': 900, 'hp': 9000, 'mana_pct': 2.50},
		{'atk': 10000, 'def': 3500, 'hp': 38000, 'mana_pct': 6.00},
	]},
	{'id': 'azure_dragon', 'name': '青龙法相', 'desc': '东方青龙，掌御雷霆',
	 'star_affixes': ['雷威：攻击+10%', '龙鳞：防御+10%', '呼风：修炼速度+8%', '唤雨：暴击伤害+25%', '【苍龙之怒】全属性+50%，攻击额外+30%'],
	 'grades': [
		{'atk': 8, 'def': 6, 'hp': 25, 'mana_pct': 0.05},
		{'atk': 25, 'def': 18, 'hp': 80, 'mana_pct': 0.12},
		{'atk': 70, 'def': 50, 'hp': 280, 'mana_pct': 0.25},
		{'atk': 200, 'def': 150, 'hp': 1000, 'mana_pct': 0.50},
		{'atk': 600, 'def': 400, 'hp': 3200, 'mana_pct': 1.00},
		{'atk': 2000, 'def': 1300, 'hp': 12000, 'mana_pct': 2.50},
		{'atk': 8000, 'def': 5000, 'hp': 50000, 'mana_pct': 6.00},
	]},
	{'id': 'white_tiger', 'name': '白虎法相', 'desc': '西方白虎，锐不可当',
	 'star_affixes': ['锐爪：攻击+12%', '虎啸：暴击率+10%', '杀伐：击杀回复10%气血', '无畏：气血低于30%时攻击+40%', '【庚金战神】全属性+50%，暴击伤害+50%'],
	 'grades': [
		{'atk': 12, 'def': 3, 'hp': 18, 'mana_pct': 0.05},
		{'atk': 35, 'def': 10, 'hp': 55, 'mana_pct': 0.12},
		{'atk': 100, 'def': 28, 'hp': 180, 'mana_pct': 0.25},
		{'atk': 300, 'def': 85, 'hp': 600, 'mana_pct': 0.50},
		{'atk': 900, 'def': 240, 'hp': 2000, 'mana_pct': 1.00},
		{'atk': 3000, 'def': 750, 'hp': 7500, 'mana_pct': 2.50},
		{'atk': 12000, 'def': 3000, 'hp': 32000, 'mana_pct': 6.00},
	]},
	{'id': 'black_tortoise', 'name': '玄武法相', 'desc': '北方玄武，坚不可摧',
	 'star_affixes': ['龟甲：防御+15%', '玄水：气血+15%', '不动：受击减伤15%', '镇海：修炼速度+8%', '【北冥至尊】全属性+50%，防御额外+30%'],
	 'grades': [
		{'atk': 3, 'def': 12, 'hp': 40, 'mana_pct': 0.05},
		{'atk': 10, 'def': 35, 'hp': 130, 'mana_pct': 0.12},
		{'atk': 28, 'def': 100, 'hp': 450, 'mana_pct': 0.25},
		{'atk': 85, 'def': 300, 'hp': 1600, 'mana_pct': 0.50},
		{'atk': 240, 'def': 900, 'hp': 5000, 'mana_pct': 1.00},
		{'atk': 750, 'def': 3000, 'hp': 19000, 'mana_pct': 2.50},
		{'atk': 3000, 'def': 12000, 'hp': 75000, 'mana_pct': 6.00},
	]},
	{'id': 'vermilion_bird', 'name': '朱雀法相', 'desc': '南方朱雀，浴火永生',
	 'star_affixes': ['离火：攻击+10%', '焚羽：每秒回复1%气血', '赤霄：暴击率+8%', '不灭：死亡后保留1血持续3回合', '【炎帝临世】全属性+50%，攻击额外+30%'],
	 'grades': [
		{'atk': 9, 'def': 5, 'hp': 22, 'mana_pct': 0.05},
		{'atk': 28, 'def': 15, 'hp': 70, 'mana_pct': 0.12},
		{'atk': 80, 'def': 42, 'hp': 240, 'mana_pct': 0.25},
		{'atk': 230, 'def': 120, 'hp': 850, 'mana_pct': 0.50},
		{'atk': 680, 'def': 340, 'hp': 2800, 'mana_pct': 1.00},
		{'atk': 2300, 'def': 1100, 'hp': 10000, 'mana_pct': 2.50},
		{'atk': 9000, 'def': 4200, 'hp': 42000, 'mana_pct': 6.00},
	]},
	{'id': 'qilin', 'name': '麒麟法相', 'desc': '瑞兽麒麟，祥瑞降世',
	 'star_affixes': ['祥瑞：修炼速度+10%', '麟甲：全属性+8%', '踏云：战斗速度+20%', '赐福：突破成功率+10%', '【圣兽归元】全属性+50%，修炼速度额外+20%'],
	 'grades': [
		{'atk': 7, 'def': 7, 'hp': 28, 'mana_pct': 0.06},
		{'atk': 22, 'def': 22, 'hp': 90, 'mana_pct': 0.14},
		{'atk': 65, 'def': 65, 'hp': 300, 'mana_pct': 0.28},
		{'atk': 190, 'def': 190, 'hp': 1050, 'mana_pct': 0.55},
		{'atk': 550, 'def': 550, 'hp': 3500, 'mana_pct': 1.10},
		{'atk': 1800, 'def': 1800, 'hp': 13000, 'mana_pct': 2.80},
		{'atk': 7500, 'def': 7500, 'hp': 55000, 'mana_pct': 6.50},
	]},
	{'id': 'primordial_chaos', 'name': '混沌法相', 'desc': '混沌初开，万象归一',
	 'star_affixes': ['虚无：全属性+12%', '太初：修炼速度+15%', '归墟：暴击伤害+30%', '万象：战斗速度+25%', '【鸿蒙主宰】全属性+60%，所有词条效果翻倍'],
	 'grades': [
		{'atk': 15, 'def': 15, 'hp': 50, 'mana_pct': 0.10},
		{'atk': 45, 'def': 45, 'hp': 150, 'mana_pct': 0.22},
		{'atk': 130, 'def': 130, 'hp': 500, 'mana_pct': 0.45},
		{'atk': 380, 'def': 380, 'hp': 1700, 'mana_pct': 0.90},
		{'atk': 1100, 'def': 1100, 'hp': 5500, 'mana_pct': 1.80},
		{'atk': 3800, 'def': 3800, 'hp': 21000, 'mana_pct': 4.50},
		{'atk': 15000, 'def': 15000, 'hp': 90000, 'mana_pct': 10.00},
	]},
]

const BORN_DHARMA_DEF = {
	'id': 'born_nature', 'name': '本命法相', 'desc': '随境界突破而生，与道体交融的本命法相',
	'born': true,
	'star_affixes': ['道基：修炼速度+5%', '凝神：全属性+5%', '觉醒：暴击率+5%', '蜕变：突破成功率+8%', '【道我合一】全属性+40%，突破所需灵气-15%'],
	'grades': [
		{'atk': 3, 'def': 3, 'hp': 15, 'mana_pct': 0.03},
		{'atk': 10, 'def': 10, 'hp': 50, 'mana_pct': 0.08},
		{'atk': 30, 'def': 30, 'hp': 160, 'mana_pct': 0.18},
		{'atk': 90, 'def': 90, 'hp': 500, 'mana_pct': 0.40},
		{'atk': 260, 'def': 260, 'hp': 1600, 'mana_pct': 0.85},
		{'atk': 800, 'def': 800, 'hp': 5500, 'mana_pct': 2.00},
		{'atk': 3000, 'def': 3000, 'hp': 20000, 'mana_pct': 5.00},
	],
}

const DHARMA_BONDS = [
	{'name': '四象归位', 'dharmas': ['azure_dragon', 'white_tiger', 'vermilion_bird', 'black_tortoise'],
	 'effects': {'atk_pct': 0.35, 'def_pct': 0.35, 'hp_pct': 0.35, 'mana_pct': 0.25},
	 'desc': '青龙白虎朱雀玄武，四象齐聚，天地归元'},
	{'name': '龙凤呈祥', 'dharmas': ['flame_phoenix', 'azure_dragon'],
	 'effects': {'atk_pct': 0.45, 'hp_pct': 0.30},
	 'desc': '龙凤和鸣，祥瑞临门'},
	{'name': '混沌圣兽', 'dharmas': ['primordial_chaos', 'qilin'],
	 'effects': {'mana_pct': 0.50, 'atk_pct': 0.20, 'def_pct': 0.20},
	 'desc': '混沌麒麟，万象归一'},
	{'name': '生生不息', 'dharmas': ['ancient_tree', 'born_nature'],
	 'effects': {'hp_pct': 0.40, 'mana_pct': 0.20},
	 'desc': '古树本命，生生不息'},
	{'name': '涅槃重生', 'dharmas': ['flame_phoenix', 'vermilion_bird'],
	 'effects': {'atk_pct': 0.30, 'hp_pct': 0.20},
	 'desc': '双凤涅槃，永不言败'},
	{'name': '道法自然', 'dharmas': ['born_nature', 'ancient_tree', 'qilin'],
	 'effects': {'mana_pct': 0.40, 'def_pct': 0.25},
	 'desc': '三圣共鸣，道法自然'},
]

const EQUIPMENT_SLOTS = ['weapon', 'helmet', 'armor', 'boots', 'artifact', 'accessory', 'belt', 'ring_left', 'ring_right', 'cloak']
const EQUIPMENT_SLOT_NAMES = {
	'weapon': '武器',
	'helmet': '头盔',
	'armor': '防具',
	'boots': '鞋子',
	'artifact': '法宝',
	'accessory': '饰品',
	'belt': '腰带',
	'ring_left': '左戒',
	'ring_right': '右戒',
	'cloak': '披风',
}

const TECHNIQUE_GRADES = ["黄级", "玄级", "地级", "天级", "圣级"]
const TECHNIQUE_GRADE_COLORS = [
	Color(0.9, 0.85, 0.4),
	Color(0.35, 0.75, 0.9),
	Color(0.9, 0.55, 0.3),
	Color(0.65, 0.35, 0.95),
	Color(1.0, 0.25, 0.2),
]
const TECHNIQUE_GRADE_MAX_LEVELS = [3, 5, 7, 9, 12]

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

const TECHNIQUE_ID_MAP = {
	"吐纳术": "breathing_art",
	"聚灵诀": "spirit_gathering",
	"御风诀": "wind_control",
	"焚天决": "burning_heaven",
	"冰心诀": "ice_heart",
	"天罡功": "celestial_art",
}

# 境界宏定义：每个大境界含9个小层次
const REALM_MACRO = [
	{'name': '练气', 'hp_start': 100, 'hp_end': 200, 'atk_start': 10, 'atk_end': 20, 'cost_start': 100, 'cost_growth': 1.8, 'color': Color(0.20, 0.85, 0.55)},
	{'name': '筑基', 'hp_start': 500, 'hp_end': 1000, 'atk_start': 50, 'atk_end': 100, 'cost_start': 2000, 'cost_growth': 1.8, 'color': Color(0.45, 0.75, 0.95)},
	{'name': '金丹', 'hp_start': 2500, 'hp_end': 5000, 'atk_start': 250, 'atk_end': 500, 'cost_start': 30000, 'cost_growth': 1.8, 'color': Color(1.00, 0.85, 0.25)},
	{'name': '元婴', 'hp_start': 12500, 'hp_end': 25000, 'atk_start': 1250, 'atk_end': 2500, 'cost_start': 500000, 'cost_growth': 1.8, 'color': Color(0.75, 0.45, 0.95)},
	{'name': '化神', 'hp_start': 62500, 'hp_end': 125000, 'atk_start': 6250, 'atk_end': 12500, 'cost_start': 8000000, 'cost_growth': 1.8, 'color': Color(0.30, 0.55, 1.00)},
	{'name': '合体', 'hp_start': 312500, 'hp_end': 625000, 'atk_start': 31250, 'atk_end': 62500, 'cost_start': 130000000, 'cost_growth': 1.8, 'color': Color(1.00, 0.55, 0.20)},
	{'name': '大乘', 'hp_start': 1560000, 'hp_end': 3120000, 'atk_start': 156250, 'atk_end': 312500, 'cost_start': 2000000000, 'cost_growth': 1.8, 'color': Color(1.00, 0.25, 0.35)},
	{'name': '渡劫', 'hp_start': 7810000, 'hp_end': 15600000, 'atk_start': 781250, 'atk_end': 1560000, 'cost_start': 35000000000, 'cost_growth': 1.8, 'color': Color(1.00, 0.92, 0.55)},
	{'name': '真仙', 'hp_start': 39100000, 'hp_end': 78100000, 'atk_start': 3910000, 'atk_end': 7810000, 'cost_start': 500000000000, 'cost_growth': 1.8, 'color': Color(0.55, 1.00, 0.55)},
	{'name': '金仙', 'hp_start': 195000000, 'hp_end': 391000000, 'atk_start': 19500000, 'atk_end': 39100000, 'cost_start': 8000000000000, 'cost_growth': 1.8, 'color': Color(1.00, 0.84, 0.00)},
	{'name': '太乙', 'hp_start': 977000000, 'hp_end': 1950000000, 'atk_start': 97700000, 'atk_end': 195000000, 'cost_start': 120000000000000, 'cost_growth': 1.8, 'color': Color(0.60, 0.40, 1.00)},
	{'name': '大罗', 'hp_start': 4880000000, 'hp_end': 9760000000, 'atk_start': 488000000, 'atk_end': 977000000, 'cost_start': 2000000000000000, 'cost_growth': 1.8, 'color': Color(0.30, 0.90, 0.90)},
	{'name': '混元', 'hp_start': 24400000000, 'hp_end': 48800000000, 'atk_start': 2440000000, 'atk_end': 4880000000, 'cost_start': 30000000000000000, 'cost_growth': 1.8, 'color': Color(0.50, 0.10, 0.50)},
]

func _build_realms() -> Array:
	var result = []
	for macro in REALM_MACRO:
		var layers = 9
		var hp_step = (macro['hp_end'] - macro['hp_start']) / float(layers - 1)
		var atk_step = (macro['atk_end'] - macro['atk_start']) / float(layers - 1)
		for lv in range(layers):
			var hp = int(macro['hp_start'] + hp_step * lv)
			var atk = int(macro['atk_start'] + atk_step * lv)
			var def = int(atk * 0.65)
			var cost = int(macro['cost_start'] * pow(macro['cost_growth'], lv) * 10)
			var mana_bonus = 0
			var mana_pct = atk * 0.0001
			var layer_names = ['一', '二', '三', '四', '五', '六', '七', '八', '九']
			result.append({
				'name': macro['name'] + layer_names[lv] + '层',
				'cost': cost,
				'mana_bonus': mana_bonus,
				'mana_bonus_pct': mana_pct,
				'atk_bonus': atk,
				'def_bonus': def,
				'hp_bonus': hp,
				'color': macro['color'],
			})
	return result

# 境界列表，按顺序排列（由宏定义生成）
var realms = _build_realms()

# 地图数据
var maps = [
	{
		'name': '青云山麓', 'desc': '灵气充裕的山脚，适合初入修仙者',
		'min_level': 1, 'color': Color(0.3, 0.8, 0.3),
		'enemies': [
			{'name': '妖蛛', 'hp': 20, 'atk': 3, 'def': 1, 'exp': 10},
			{'name': '灰狼', 'hp': 35, 'atk': 5, 'def': 2, 'exp': 15},
			{'name': '毒蛇', 'hp': 28, 'atk': 7, 'def': 1, 'exp': 12},
			{'name': '石魔', 'hp': 50, 'atk': 4, 'def': 4, 'exp': 18},
			{'name': '妖兔', 'hp': 15, 'atk': 2, 'def': 0, 'exp': 8},
		]
	},
	{
		'name': '黑风谷', 'desc': '妖兽出没的峡谷，暗藏凶险',
		'min_level': 3, 'color': Color(0.5, 0.3, 0.3),
		'enemies': [
			{'name': '黑风虎', 'hp': 80, 'atk': 14, 'def': 6, 'exp': 30},
			{'name': '岩甲兽', 'hp': 150, 'atk': 10, 'def': 12, 'exp': 35},
			{'name': '噬魂蝠', 'hp': 60, 'atk': 18, 'def': 4, 'exp': 28},
			{'name': '腐尸鬼', 'hp': 120, 'atk': 12, 'def': 8, 'exp': 32},
			{'name': '毒雾蟾', 'hp': 90, 'atk': 16, 'def': 5, 'exp': 25},
			{'name': '黑影妖', 'hp': 70, 'atk': 20, 'def': 2, 'exp': 27},
		]
	},
	{
		'name': '天雷泽', 'desc': '雷电交加的沼泽，危机四伏',
		'min_level': 10, 'color': Color(0.6, 0.5, 1),
		'enemies': [
			{'name': '雷蛟', 'hp': 400, 'atk': 60, 'def': 25, 'exp': 200},
			{'name': '电鳗妖', 'hp': 300, 'atk': 75, 'def': 15, 'exp': 180},
			{'name': '霹雳熊', 'hp': 550, 'atk': 50, 'def': 35, 'exp': 220},
			{'name': '雷鹰', 'hp': 250, 'atk': 80, 'def': 10, 'exp': 190},
			{'name': '沼泽巨鳄', 'hp': 600, 'atk': 45, 'def': 40, 'exp': 210},
			{'name': '风暴妖', 'hp': 350, 'atk': 65, 'def': 20, 'exp': 195},
		]
	},
	{
		'name': '九幽冥海', 'desc': '阴气深重的海域，九死一生',
		'min_level': 19, 'color': Color(0.3, 0.2, 0.6),
		'enemies': [
			{'name': '冥海巨蟒', 'hp': 3000, 'atk': 500, 'def': 200, 'exp': 800},
			{'name': '幽冥鬼将', 'hp': 2500, 'atk': 650, 'def': 150, 'exp': 850},
			{'name': '九头妖龙', 'hp': 4500, 'atk': 400, 'def': 300, 'exp': 1000},
			{'name': '深海夜叉', 'hp': 2800, 'atk': 550, 'def': 180, 'exp': 820},
			{'name': '海妖女', 'hp': 2200, 'atk': 700, 'def': 120, 'exp': 880},
			{'name': '幽灵船长', 'hp': 3800, 'atk': 450, 'def': 250, 'exp': 900},
		]
	},
]

# ==================== 核心辅助函数 ====================

func get_realm_atk_bonus() -> float:
	if realm_level <= 0 or realm_level > realms.size():
		return 0.0
	return realms[realm_level - 1].get('atk_bonus', 0.0)

func get_realm_def_bonus() -> float:
	if realm_level <= 0 or realm_level > realms.size():
		return 0.0
	return realms[realm_level - 1].get('def_bonus', 0.0)

func get_realm_hp_bonus() -> float:
	if realm_level <= 0 or realm_level > realms.size():
		return 0.0
	return realms[realm_level - 1].get('hp_bonus', 0.0)

func get_realm_mana_bonus() -> float:
	if realm_level <= 0 or realm_level > realms.size():
		return 0.0
	return realms[realm_level - 1].get('mana_bonus', 0.0)

func get_player_atk() -> float:
	var atk = get_realm_atk_bonus() + get_technique_atk_bonus() + get_dharma_atk_bonus()
	for s in EQUIPMENT_SLOTS:
		var ei = equipped_items.get(s, null)
		if ei != null:
			atk += ei['atk_bonus']
	var bh_lv = talents.get('battle_hardened', 0)
	atk *= 1.0 + 0.10 * bh_lv
	atk *= 1.0 + get_active_array_bonus('atk_pct')
	atk *= get_attr_pct('strength', 0.03)
	return atk

func get_player_def() -> float:
	var def = get_realm_def_bonus() + get_technique_def_bonus() + get_dharma_def_bonus()
	for s in EQUIPMENT_SLOTS:
		var ei = equipped_items.get(s, null)
		if ei != null:
			def += ei['def_bonus']
	def *= 1.0 + get_active_array_bonus('def_pct')
	def *= get_attr_pct('bone', 0.03)
	return def

func update_max_hp():
	player_max_hp = (100.0 + get_realm_hp_bonus() + get_technique_hp_bonus() + get_dharma_hp_bonus()) * (1.0 + get_active_array_bonus('hp_pct')) * get_attr_pct('physique', 0.03)
	if player_hp > player_max_hp:
		player_hp = player_max_hp

func _process_comprehension(delta: float):
	if comprehending_tech_id == "":
		return
	if not TECHNIQUE_DEFS.has(comprehending_tech_id):
		comprehending_tech_id = ""
		return
	var tech = learned_techniques.get(comprehending_tech_id, {})
	var current_level = tech.get("level", 0)
	var defs = TECHNIQUE_DEFS[comprehending_tech_id]
	if current_level >= defs.levels.size():
		comprehending_tech_id = ""
		comprehension_progress = 0.0
		return
	var lib_bonus = 1.0 + 0.15 * cave_buildings.get("library", {}).get("level", 0)
	var array_comprehension_bonus = get_active_array_bonus('comprehension_speed')
	comprehension_progress += delta * lib_bonus * (1.0 + array_comprehension_bonus) * get_attr_pct('comprehension', 0.05)
	if comprehension_progress >= comprehension_time_total:
		_complete_comprehension()

func _complete_comprehension():
	var tid = comprehending_tech_id
	var tech = learned_techniques.get(tid, {})
	var new_level = tech.get("level", 0) + 1
	tech["level"] = new_level
	learned_techniques[tid] = tech
	var defs = TECHNIQUE_DEFS[tid]
	var lvl_data = defs.levels[new_level - 1]
	var effect_text = ""
	if lvl_data.effect != "":
		effect_text = "，觉醒特殊效果：" + lvl_data.effect
	log_message("[color=cyan]◆ 功法突破！" + defs.name + " " + _num_to_chinese(new_level) + "重" + effect_text + "[/color]")
	recalc_technique_multiplier()
	recalc_mana_per_sec()
	update_max_hp()
	comprehending_tech_id = ""
	comprehension_progress = 0.0
	comprehension_time_total = 0.0
	if $PanelSkills.visible:
		_refresh_skills()
	if $PanelProfile.visible:
		_refresh_profile()

func start_comprehension(tech_id: String):
	if not TECHNIQUE_DEFS.has(tech_id):
		return
	if comprehending_tech_id != "":
		log_message("[color=red]正在参悟" + TECHNIQUE_DEFS[comprehending_tech_id].name + "，无法同时参悟多门功法[/color]")
		return
	var tech = learned_techniques.get(tech_id, {})
	if not tech.has("level"):
		learned_techniques[tech_id] = {"level": 0}
		tech = learned_techniques[tech_id]
	var current_level = tech.get("level", 0)
	var defs = TECHNIQUE_DEFS[tech_id]
	if current_level >= defs.levels.size():
		log_message("[color=red]" + defs.name + "已修炼至最高重数[/color]")
		return
	var next_lvl = defs.levels[current_level]
	comprehending_tech_id = tech_id
	comprehension_time_total = next_lvl.time
	comprehension_progress = 0.0
	log_message("[color=cyan]开始参悟" + defs.name + " " + _num_to_chinese(current_level + 1) + "重（预计" + str(int(comprehension_time_total)) + "秒）...[/color]")
	if $PanelSkills.visible:
		_refresh_skills()

func _process_meditation(delta: float):
	if not $MeditationUI.visible:
		return
	meditation_timer += delta
	var bar = $MeditationUI/MeditationBar
	bar.max_value = meditation_cycle_time
	bar.value = min(meditation_timer, meditation_cycle_time)
	if meditation_timer >= meditation_cycle_time:
		meditation_timer -= meditation_cycle_time
		meditation_cycles += 1
		spiritual_energy += pending_energy
		pending_energy = 0.0

func get_technique_mana_pct() -> float:
	var total = 0.0
	for tid in learned_techniques:
		if not TECHNIQUE_DEFS.has(tid):
			continue
		var defs = TECHNIQUE_DEFS[tid]
		var tech = learned_techniques[tid]
		var level = tech.get("level", 0)
		for i in range(level):
			if i < defs.levels.size():
				total += defs.levels[i].mana_pct
		if defs.name == "天罡功" and level >= 12:
			total += 1.0
	return total

func get_technique_atk_bonus() -> float:
	var total = 0.0
	for tid in learned_techniques:
		if not TECHNIQUE_DEFS.has(tid):
			continue
		var defs = TECHNIQUE_DEFS[tid]
		var tech = learned_techniques[tid]
		var level = tech.get("level", 0)
		for i in range(level):
			if i < defs.levels.size():
				total += defs.levels[i].atk
	return total

func get_technique_def_bonus() -> float:
	var total = 0.0
	for tid in learned_techniques:
		if not TECHNIQUE_DEFS.has(tid):
			continue
		var defs = TECHNIQUE_DEFS[tid]
		var tech = learned_techniques[tid]
		var level = tech.get("level", 0)
		for i in range(level):
			if i < defs.levels.size():
				total += defs.levels[i].def
	return total

func get_technique_hp_bonus() -> float:
	var total = 0.0
	for tid in learned_techniques:
		if not TECHNIQUE_DEFS.has(tid):
			continue
		var defs = TECHNIQUE_DEFS[tid]
		var tech = learned_techniques[tid]
		var level = tech.get("level", 0)
		for i in range(level):
			if i < defs.levels.size():
				total += defs.levels[i].hp
	return total

func _get_dharma_def(dharma_id: String) -> Dictionary:
	if dharma_id == "":
		return {}
	if dharma_id == "born_nature":
		return BORN_DHARMA_DEF
	for d in DHARMA_DEFS:
		if d.id == dharma_id:
			return d
	return {}

func get_active_dharma() -> Dictionary:
	for dharma in dharma_inventory:
		if dharma.id == active_dharma_id:
			return dharma
	return {}

func _get_dharma_level_mult(dharma: Dictionary) -> float:
	if dharma.is_empty():
		return 1.0
	var level = dharma.get('level', 1)
	return 1.0 + (level - 1) * 0.02

func _get_dharma_star_mult(dharma: Dictionary) -> float:
	if dharma.is_empty():
		return 1.0
	var stars = dharma.get('stars', 0)
	return 1.0 + stars * DHARMA_LEVEL_PER_STAR_BONUS

func _get_dharma_base_stat(dharma: Dictionary, key: String) -> float:
	if dharma.is_empty():
		return 0.0
	return dharma.get(key, 0.0)

func _calc_dharma_stat(dharma: Dictionary, key: String) -> float:
	if dharma.is_empty():
		return 0.0
	var base = _get_dharma_base_stat(dharma, key)
	var level_mult = _get_dharma_level_mult(dharma)
	var star_mult = _get_dharma_star_mult(dharma)
	var val = base * level_mult * star_mult
	if dharma.get('stars', 0) >= DHARMA_MAX_STARS:
		val *= 1.5
	return val

func get_dharma_atk_bonus() -> float:
	return _calc_dharma_stat(get_active_dharma(), 'atk') * (1.0 + _get_bond_bonus('atk_pct'))

func get_dharma_def_bonus() -> float:
	return _calc_dharma_stat(get_active_dharma(), 'def') * (1.0 + _get_bond_bonus('def_pct'))

func get_dharma_hp_bonus() -> float:
	return _calc_dharma_stat(get_active_dharma(), 'hp') * (1.0 + _get_bond_bonus('hp_pct'))

func get_dharma_mana_bonus_pct() -> float:
	return _calc_dharma_stat(get_active_dharma(), 'mana_pct')

func recalc_dharma_bonuses():
	dharma_mana_pct = get_dharma_mana_bonus_pct()
	recalc_bond_bonuses()

func _get_bond_bonus(key: String) -> float:
	var total = 0.0
	for bond in DHARMA_BONDS:
		var all_owned = true
		for did in bond.dharmas:
			var found = false
			for dharma in dharma_inventory:
				if dharma.id == did:
					found = true
					break
			if not found:
				all_owned = false
				break
		if all_owned:
			total += bond.effects.get(key, 0.0)
	return total

func recalc_bond_bonuses():
	pass

func get_active_bonds() -> Array:
	var result = []
	for bond in DHARMA_BONDS:
		var all_owned = true
		for did in bond.dharmas:
			var found = false
			for dharma in dharma_inventory:
				if dharma.id == did:
					found = true
					break
			if not found:
				all_owned = false
				break
		if all_owned:
			result.append(bond)
	return result

func get_dharma_max_level() -> int:
	var macro_idx = int((realm_level - 1) / 9)
	var grade_max = macro_idx * 10 + 10
	if realm_level >= 19:
		return max(1, (realm_level - 18) * 5)
	return 1

func get_dharma_upgrade_cost(dharma: Dictionary) -> int:
	if dharma.is_empty():
		return 0
	var grade = dharma.get('grade', 0)
	var level = dharma.get('level', 1)
	return int((grade + 1) * 150 + level * 80)

func get_dharma_star_up_cost(dharma: Dictionary) -> int:
	if dharma.is_empty():
		return 999999
	var grade = dharma.get('grade', 0)
	var stars = dharma.get('stars', 0)
	if stars >= DHARMA_MAX_STARS:
		return 999999
	return DHARMA_SHARD_COSTS[grade] * (stars + 1)

func get_technique_comprehension_mult() -> float:
	if _has_tiangang_max_level():
		return 2.0
	return 1.0

func _has_tiangang_max_level() -> bool:
	var tech = learned_techniques.get("celestial_art", {})
	var level = tech.get("level", 0)
	var defs = TECHNIQUE_DEFS.get("celestial_art", {})
	if defs.is_empty():
		return false
	return level >= defs.levels.size()

func _format_num(n: float) -> String:
	return UI.format_num(n)

func _format_big(n: float) -> String:
	return UI.format_big(n)

func _num_to_chinese(n: int) -> String:
	var digits = ["零", "一", "二", "三", "四", "五", "六", "七", "八", "九", "十", "十一", "十二"]
	if n >= 0 and n < digits.size():
		return digits[n]
	return str(n)

func is_skill_learned(skill_name: String) -> bool:
	var tid = TECHNIQUE_ID_MAP.get(skill_name, "")
	if tid != "" and learned_techniques.has(tid):
		return learned_techniques[tid].get("level", 0) > 0
	return false

func is_recipe_learned(recipe_name: String) -> bool:
	for r in learned_recipes:
		if r['name'] == recipe_name:
			return true
	return false

# ==================== _ready ====================

func _ready():
	_init_toast()
	load_save()
	if spirit_root.is_empty():
		spirit_root = SPIRIT_ROOTS[randi() % SPIRIT_ROOTS.size()]
		var root_c = spirit_root['color'].to_html(false)
		log_message("[color=#" + root_c + "]灵根觉醒：" + spirit_root['name'] + " —— " + spirit_root['desc'] + "[/color]")
	if attrs.is_empty():
		_roll_attributes()
		var attr_msg = "个人属性："
		for key in ATTR_DEFS:
			attr_msg += ATTR_DEFS[key]['name'] + str(attrs[key]) + "  "
		log_message("[color=#ccaa55]" + attr_msg + "[/color]")
	recalc_battle_speed()
	if player_name == "":
		player_name = SURNAMES[randi() % SURNAMES.size()] + GIVEN_NAMES[randi() % GIVEN_NAMES.size()]
	recalc_realm_multiplier()
	recalc_technique_multiplier()
	recalc_artifact_multiplier()
	recalc_mana_per_sec()
	update_max_hp()
	log_message("[color=green]游戏启动，欢迎回来！[/color]")
	calc_offline_earnings()
	# 初始化洞府建筑（补齐旧存档缺失的建筑）
	for bid in $PanelCave.BUILDING_DEFS:
		if cave_buildings.has(bid):
			continue
		var defs = $PanelCave.BUILDING_DEFS[bid]
		cave_buildings[bid] = {'level': defs.get('init_level', 0), 'unlocked': defs.init_unlocked}
	_reconcile_cave_queue()
	recalc_cave_bonuses()
	recalc_mana_per_sec()
	# 初始化天赋
	if talents.is_empty():
		for tid in TALENT_DEFS:
			talents[tid] = 0
	recalc_talent_bonuses()
	recalc_mana_per_sec()
	# 初始化法相
	recalc_dharma_bonuses()
	recalc_mana_per_sec()
	update_max_hp()
	_check_dharma_unlock()
	# 连接面板信号
	$PanelProfile.back_requested.connect(_on_back)
	$PanelProfile.reincarnation_requested.connect(_on_reincarnate_clicked)
	$PanelSkills.back_requested.connect(_on_back)
	$PanelSkills.comprehend_requested.connect(start_comprehension)
	$PanelInventory.back_requested.connect(_on_back)
	$PanelInventory.use_skill_requested.connect(_on_use_skill)
	$PanelInventory.sell_skill_requested.connect(_on_sell_skill)
	$PanelInventory.use_pill_requested.connect(_on_use_pill)
	$PanelInventory.sell_pill_requested.connect(_on_sell_pill)
	$PanelInventory.equip_item_requested.connect(_on_equip_from_inventory)
	$PanelInventory.sell_equipment_requested.connect(_on_sell_equipment_from_inventory)
	$PanelInventory.use_array_requested.connect(_on_use_array)
	$PanelInventory.sell_array_requested.connect(_on_sell_array)
	$PanelInventory.use_recipe_requested.connect(_on_use_recipe)
	$PanelInventory.sell_recipe_requested.connect(_on_sell_recipe)
	$PanelInventory.sell_furnace_requested.connect(_on_sell_furnace_from_inventory)
	$PanelShop.back_requested.connect(_on_back)
	$PanelShop.buy_skill_requested.connect(_on_buy_skill)
	$PanelShop.buy_recipe_requested.connect(_on_buy_recipe)
	$PanelShop.buy_equipment_requested.connect(_on_buy_equipment)
	$PanelShop.buy_array_requested.connect(_on_buy_array)
	$PanelShop.buy_furnace_requested.connect(_on_buy_furnace)
	$PanelShop.buy_test_item_requested.connect(_on_buy_test_item)
	$PanelCave.upgrade_cave_requested.connect(_on_cave_upgrade)
	$PanelCave.building_action_requested.connect(_on_building_action)
	$PanelCave.cancel_upgrade_requested.connect(_on_cancel_upgrade)
	$PanelCave.craft_pill_requested.connect(_on_craft_pill_by_name)
	$PanelCave.use_pill_requested.connect(_on_use_pill)
	$PanelCave.back_requested.connect(_on_back)
	$PanelCave.set_array_requested.connect(_on_set_active_array)
	$PanelCave.equip_furnace_requested.connect(_on_equip_furnace)
	$PanelCave.unequip_furnace_requested.connect(_on_unequip_furnace)
	$PanelEquipment.back_requested.connect(_on_back)
	$PanelEquipment.unequip_requested.connect(_on_unequip)
	$PanelMap.back_requested.connect(_on_back)
	$PanelMap.start_battle_requested.connect(start_battle)
	$PanelMap.stop_battle_requested.connect(stop_battle)
	$PanelMap.settings_changed.connect(_on_map_settings_changed)
	$PanelTalents.back_requested.connect(_on_back)
	$PanelTalents.upgrade_talent_requested.connect(_on_upgrade_talent)
	$PanelTalents.select_spirit_root_requested.connect(_on_select_spirit_root)
	# 连接兵解确认
	$ReincarnateConfirm.confirmed.connect(_on_reincarnate_confirmed)
	# 动态创建帮助面板
	var help_scene = load("res://scripts/help_panel.gd")
	var panel_help = help_scene.new()
	panel_help.name = "PanelHelp"
	panel_help.visible = false
	panel_help.layout_mode = 1
	panel_help.anchors_preset = Control.PRESET_FULL_RECT
	panel_help.offset_left = 0.0
	panel_help.offset_top = 0.0
	panel_help.offset_right = 0.0
	panel_help.offset_bottom = 0.0
	panel_help.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_help.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel_help)
	panel_help.back_requested.connect(_on_back)
	# 动态创建法相面板
	var dharma_script = load("res://scripts/dharma_panel.gd")
	var panel_dharma = dharma_script.new()
	panel_dharma.name = "PanelDharma"
	panel_dharma.visible = false
	panel_dharma.layout_mode = 1
	panel_dharma.anchors_preset = Control.PRESET_FULL_RECT
	panel_dharma.offset_left = 0.0
	panel_dharma.offset_top = 0.0
	panel_dharma.offset_right = 0.0
	panel_dharma.offset_bottom = 0.0
	panel_dharma.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_dharma.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel_dharma)
	$PanelDharma.back_requested.connect(_on_back)
	$PanelDharma.activate_dharma_requested.connect(_on_activate_dharma)
	$PanelDharma.synthesize_dharma_requested.connect(_on_synthesize_dharma)
	$PanelDharma.buy_shard_requested.connect(_on_buy_dharma_shard)
	$PanelDharma.upgrade_dharma_requested.connect(_on_upgrade_dharma)
	$PanelDharma.star_up_dharma_requested.connect(_on_star_up_dharma)
	# 动态创建宗门面板
	var sect_script = load("res://scripts/sect_panel.gd")
	var panel_sect = sect_script.new()
	panel_sect.name = "PanelSect"
	panel_sect.visible = false
	panel_sect.layout_mode = 1
	panel_sect.anchors_preset = Control.PRESET_FULL_RECT
	panel_sect.offset_left = 0.0
	panel_sect.offset_top = 0.0
	panel_sect.offset_right = 0.0
	panel_sect.offset_bottom = 0.0
	panel_sect.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel_sect.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel_sect)
	$PanelSect.back_requested.connect(_on_back)
	$PanelSect.building_action_requested.connect(_on_sect_building_action)
	$PanelSect.recruit_disciple_requested.connect(_on_recruit_disciple)
	$PanelSect.dismiss_disciple_requested.connect(_on_dismiss_disciple)
	# 初始化宗门建筑
	if sect_buildings.is_empty():
		for bid in panel_sect.SECT_BUILDING_DEFS:
			var init_unlocked = panel_sect.SECT_BUILDING_DEFS[bid].init_unlocked
			sect_buildings[bid] = {'level': 0, 'unlocked': init_unlocked}
	recalc_sect_bonuses()
	# 绑定菜单按钮
	$MenuBar/BtnProfile.pressed.connect(_on_btn_profile)
	$MenuBar/BtnSkills.pressed.connect(_on_btn_skills)
	$MenuBar/BtnInventory.pressed.connect(_on_btn_inventory)
	$MenuBar/BtnShop.pressed.connect(_on_btn_shop)
	$MenuBar/BtnCave.pressed.connect(_on_btn_cave)
	$MenuBar/BtnTalents.pressed.connect(_on_btn_talents)
	$MenuBar/BtnEquipment.pressed.connect(_on_btn_equipment)
	$MenuBar/BtnMap.pressed.connect(_on_btn_map)
	$MenuBar/BtnDharma.pressed.connect(_on_btn_dharma)
	# 动态添加帮助按钮
	var btn_help = Button.new()
	btn_help.text = "帮助"
	btn_help.add_theme_font_size_override("font_size", 12)
	btn_help.pressed.connect(_on_btn_help)
	$MenuBar.add_child(btn_help)
	# 动态添加宗门按钮
	var btn_sect = Button.new()
	btn_sect.name = "BtnSect"
	btn_sect.text = "宗门"
	btn_sect.add_theme_font_size_override("font_size", 12)
	_apply_sect_lock(btn_sect, realm_level < 37)
	btn_sect.pressed.connect(_on_btn_sect)
	$MenuBar.add_child(btn_sect)
	show_panel("")

# ==================== 存档 ====================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()

func save_game():
	var data = {
		'save_version': 7,
		'spiritual_energy': spiritual_energy,
		'spirit_ore': spirit_ore,
		'spirit_wood': spirit_wood,
		'mana_per_sec': mana_per_sec,
		'base_mana': base_mana,
		'realm_multiplier': realm_multiplier,
		'technique_multiplier': technique_multiplier,
		'spirit_root_multiplier': spirit_root_multiplier,
		'cave_multiplier': cave_multiplier,
		'artifact_multiplier': artifact_multiplier,
		'time_coefficient': time_coefficient,
		'pill_flat_bonus': pill_flat_bonus,
		'realm': realm,
		'realm_level': realm_level,
		'inventory': inventory,
		'learned_techniques': learned_techniques,
		'comprehending_tech_id': comprehending_tech_id,
		'comprehension_progress': comprehension_progress,
		'comprehension_time_total': comprehension_time_total,
		'learned_recipes': learned_recipes,
		'pill_inventory': pill_inventory,
		'learned_arrays': learned_arrays,
		'active_array': active_array,
		'array_inventory': array_inventory,
		'recipe_inventory': recipe_inventory,
		'player_name': player_name,
		'spirit_root': spirit_root,
		'age': age,
		'equipped_items': equipped_items,
		'equipment_inventory': equipment_inventory,
		'furnace_inventory': furnace_inventory,
		'equipped_furnaces': equipped_furnaces,
		'player_hp': player_hp,
		'cave_level': cave_level,
		'cave_buildings': cave_buildings,
		'cave_upgrade_limit': cave_upgrade_limit,
		'cave_upgrade_queue': cave_upgrade_queue,
		'sect_level': sect_level,
		'sect_buildings': sect_buildings,
		'sect_materials': sect_materials,
		'disciples': disciples,
		'disciple_capacity': disciple_capacity,
		'reincarnation_count': reincarnation_count,
		'enlightenment_points': enlightenment_points,
		'talents': talents,
		'auto_next_map': auto_next_map,
		'loop_current_map': loop_current_map,
		'map_sub_level': map_sub_level,
		'attrs': attrs,
		'dharma_unlocked': dharma_unlocked,
		'dharma_inventory': dharma_inventory,
		'active_dharma_id': active_dharma_id,
		'dharma_shards': dharma_shards,
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
	spirit_ore = data.get('spirit_ore', 0.0)
	spirit_wood = data.get('spirit_wood', 0.0)
	mana_per_sec = data.get('mana_per_sec', 10.0)
	base_mana = data.get('base_mana', 10.0)
	realm_multiplier = data.get('realm_multiplier', 1.0)
	technique_multiplier = data.get('technique_multiplier', 1.0)
	spirit_root_multiplier = data.get('spirit_root_multiplier', 1.0)
	cave_multiplier = data.get('cave_multiplier', 1.0)
	artifact_multiplier = data.get('artifact_multiplier', 1.0)
	time_coefficient = data.get('time_coefficient', 1.0)
	pill_flat_bonus = data.get('pill_flat_bonus', 0.0)
	cave_level = data.get('cave_level', 1)
	cave_buildings = data.get('cave_buildings', {})
	cave_upgrade_limit = data.get('cave_upgrade_limit', 1)
	cave_upgrade_queue = data.get('cave_upgrade_queue', [])
	sect_level = data.get('sect_level', 1)
	sect_buildings = data.get('sect_buildings', {})
	sect_materials = data.get('sect_materials', {})
	disciples = data.get('disciples', [])
	disciple_capacity = data.get('disciple_capacity', 3)
	reincarnation_count = data.get('reincarnation_count', 0)
	enlightenment_points = data.get('enlightenment_points', 0)
	talents = data.get('talents', {})
	auto_next_map = data.get('auto_next_map', false)
	loop_current_map = data.get('loop_current_map', false)
	var load_version = data.get('save_version', 0)
	if load_version < 4:
		map_sub_level = {}  # 重置挑战进度
	else:
		map_sub_level = data.get('map_sub_level', {})
	attrs = data.get('attrs', {})
	dharma_unlocked = data.get('dharma_unlocked', false)
	dharma_inventory = data.get('dharma_inventory', [])
	for dharma in dharma_inventory:
		if not dharma.has('level'):
			dharma['level'] = 1
		if not dharma.has('stars'):
			dharma['stars'] = 0
	active_dharma_id = data.get('active_dharma_id', "")
	dharma_shards = data.get('dharma_shards', [])
	realm = data.get('realm', '练气一层')
	realm_level = data.get('realm_level', 1)
	inventory = data.get('inventory', [])
	equipment_inventory = data.get('equipment_inventory', [])
	learned_techniques = data.get('learned_techniques', {})
	comprehending_tech_id = data.get('comprehending_tech_id', "")
	comprehension_progress = data.get('comprehension_progress', 0.0)
	comprehension_time_total = data.get('comprehension_time_total', 0.0)
	learned_recipes = data.get('learned_recipes', [])
	learned_arrays = data.get('learned_arrays', [])
	active_array = data.get('active_array', "")
	array_inventory = data.get('array_inventory', [])
	recipe_inventory = data.get('recipe_inventory', [])
	pill_inventory = data.get('pill_inventory', {})
	player_name = data.get('player_name', "")
	spirit_root = data.get('spirit_root', {})
	age = data.get('age', 16)
	var loaded_eq = data.get('equipped_items', {})
	if loaded_eq.size() > 0:
		equipped_items = loaded_eq
	for slot in EQUIPMENT_SLOTS:
		if not equipped_items.has(slot):
			equipped_items[slot] = null
	player_hp = data.get('player_hp', 100.0)
	furnace_inventory = data.get('furnace_inventory', [])
	equipped_furnaces = data.get('equipped_furnaces', [])
	_fix_furnace_colors(furnace_inventory)
	_fix_furnace_colors(equipped_furnaces)

func _fix_furnace_colors(arr: Array):
	for item in arr:
		if item == null:
			continue
		if not item is Dictionary:
			continue
		if item.has('color') and not item['color'] is Color:
			var col_str = str(item['color'])
			var parts = col_str.split(",")
			if parts.size() >= 3:
				item['color'] = Color(float(parts[0]), float(parts[1]), float(parts[2]))
			else:
				item['color'] = Color(0.8, 0.5, 0.2)

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
		spirit_ore += get_ore_rate() * elapsed
		spirit_wood += get_wood_rate() * elapsed
		# 离线期间推进正在进行的建筑升级
		for bid in cave_buildings.keys():
			var b = cave_buildings[bid]
			if not b.get('upgrading', false):
				continue
			var remaining = b.get('upgrade_remaining', 0.0) - elapsed
			while remaining <= 0.0:
				b['level'] = b.get('level', 0) + 1
				var nd = _get_upgrade_duration(bid, b['level'])
				b['upgrade_duration'] = nd
				remaining += nd
			b['upgrade_remaining'] = remaining
		_promote_cave_queue()
		log_message("[color=cyan]离线收益：" + str(int(offline_earnings)) + " 灵气（离线 " + str(int(elapsed)) + " 秒）[/color]")
		while try_breakthrough():
			pass

# ==================== 主循环 ====================

func _process(delta: float):
	pending_energy += mana_per_sec * delta
	try_breakthrough()
	_check_dharma_unlock()
	update_ui()
	age_timer += delta
	if breakthrough_fail_timer > 0:
		breakthrough_fail_timer -= delta
	if age_timer >= 300.0:
		age_timer = 0.0
		age += 1
	_process_comprehension(delta)
	_process_meditation(delta)
	_process_disciple_cultivation(delta)
	save_timer += delta
	if save_timer >= 60.0:
		save_timer = 0.0
		save_game()
	_process_battle(delta)
	_process_toast(delta)
	_process_cave_buildings(delta)
	spirit_ore += get_ore_rate() * delta
	spirit_wood += get_wood_rate() * delta
	if $PanelCave.visible:
		$PanelCave.tick_upgrade_bars(spirit_ore, spirit_wood, get_ore_rate(), get_wood_rate())
	if tooltip_node and tooltip_node.visible:
		var mp = get_global_mouse_position()
		tooltip_node.position = Vector2(mp.x + 12, mp.y + 12)

## 洞府建筑升级计时：到期后提升等级
func _process_cave_buildings(delta: float):
	var upgraded := false
	for bid in cave_buildings.keys():
		var b = cave_buildings[bid]
		if not b.get('upgrading', false):
			continue
		b['upgrade_remaining'] = b.get('upgrade_remaining', 0.0) - delta
		if b['upgrade_remaining'] <= 0.0:
			b['upgrading'] = false
			b['level'] = b.get('level', 0) + 1
			var defs = $PanelCave.BUILDING_DEFS.get(bid, {})
			log_message("[color=cyan]" + defs.get('name', bid) + " 升至 " + str(b['level']) + " 级[/color]")
			upgraded = true
	if upgraded:
		recalc_cave_bonuses()
	_promote_cave_queue()

func try_breakthrough() -> bool:
	if realm_level >= realms.size():
		return false
	if breakthrough_fail_timer > 0:
		return false
	var next = realms[realm_level]
	if spiritual_energy >= next['cost']:
		var chance = 0.5 + attrs.get('fortune', 0) * 0.05
		if randf() < chance:
			spiritual_energy -= next['cost']
			realm_level += 1
			realm = next['name']
			recalc_realm_multiplier()
			recalc_mana_per_sec()
			var realm_c = get_realm_color().to_html(false)
			log_message("[color=#" + realm_c + "]◆ 突破成功！当前境界：" + realm + "[/color]")
			return true
		else:
			var waste = int(next['cost'] * 0.2)
			spiritual_energy = max(0, spiritual_energy - waste)
			breakthrough_fail_timer = 3.0
			log_message("[color=#ff8844]◆ 突破失败！灵气激荡，损失" + _format_num(waste) + "灵气[/color]")
			_show_toast("突破失败", Color(1.0, 0.5, 0.3))
	return false

func get_next_realm_cost() -> int:
	if realm_level >= realms.size():
		return -1
	var cost = realms[realm_level]['cost']
	var if_lv = talents.get('immortal_fortune', 0)
	var reduction = 0.05 * if_lv
	cost = int(cost * (1.0 - reduction))
	return max(1, cost)

func _roll_attributes():
	for key in ATTR_DEFS:
		attrs[key] = randi_range(1, 10)

func get_attr_pct(key: String, per_point: float) -> float:
	return 1.0 + attrs.get(key, 0) * per_point

func recalc_battle_speed():
	battle_speed = 1.0 * get_attr_pct('agility', 0.05)

# ==================== 乘区计算 ====================

func recalc_mana_per_sec():
	var array_flat = get_active_array_bonus('mana_flat')
	mana_per_sec = (base_mana + cave_base_bonus + talent_mana_bonus + array_flat) * realm_multiplier * spirit_root_multiplier * technique_multiplier * cave_multiplier * artifact_multiplier * time_coefficient * talent_multiplier * get_attr_pct('spirit', 0.03) + pill_flat_bonus + sect_disciple_mana
	mana_per_sec *= 1.0 + dharma_mana_pct + _get_bond_bonus('mana_pct')

func recalc_realm_multiplier():
	var sum = 0.0
	for i in range(realm_level):
		sum += realms[i].get('mana_bonus_pct', 0.0)
	realm_multiplier = 1.0 + sum

func recalc_technique_multiplier():
	var skill_sum = get_technique_mana_pct()
	var comp_mult = get_technique_comprehension_mult()
	spirit_root_multiplier = spirit_root.get('bonus', 1.0)
	technique_multiplier = (1.0 + skill_sum) * comp_mult

func recalc_artifact_multiplier():
	var art = equipped_items.get('artifact')
	if art != null:
		var pct = art.get('mana_bonus_pct', 0.0)
		if pct == 0.0 and art.has('mana_bonus') and art['mana_bonus'] > 0:
			pct = float(art['mana_bonus']) / base_mana
		artifact_multiplier = 1.0 + pct
	else:
		artifact_multiplier = 1.0

func recalc_talent_bonuses():
	var enl_lv = talents.get('enlightenment', 0)
	talent_multiplier = 1.0 + 0.10 * enl_lv
	var sturdy_lv = talents.get('sturdy_body', 0)
	talent_mana_bonus = 5.0 * sturdy_lv

# ==================== UI ====================

func log_message(msg: String):
	var time = Time.get_time_string_from_system()
	$MessageLog.append_text("[color=gray]" + time + "[/color] " + msg + "\n")
	var lines = $MessageLog.get_paragraph_count()
	if lines > max_log_lines:
		$MessageLog.remove_paragraph(0)

func _init_toast():
	var layer = CanvasLayer.new()
	layer.layer = 10
	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_panel.layout_mode = 1
	_toast_panel.anchor_left = 0.08
	_toast_panel.anchor_right = 0.92
	_toast_panel.anchor_top = 0.0
	_toast_panel.anchor_bottom = 0.0
	_toast_panel.offset_top = 56
	_toast_panel.offset_bottom = 102
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.1, 0.06, 0.95)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.25, 0.55, 0.25, 0.8)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	_toast_style = style
	_toast_panel.add_theme_stylebox_override("panel", style)
	_toast_label = Label.new()
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 14)
	_toast_panel.add_child(_toast_label)
	layer.add_child(_toast_panel)
	add_child(layer)

func _show_toast(msg: String, color: Color = Color(0.3, 1.0, 0.5)):
	_toast_label.text = msg
	_toast_label.add_theme_color_override("font_color", color)
	_toast_style.border_color = Color(color.r, color.g, color.b, 0.6)
	_toast_panel.modulate.a = 0.0
	_toast_panel.offset_top = 56
	_toast_panel.offset_bottom = 102
	_toast_panel.visible = true
	_toast_timer = 0.0
	_toast_active = true

func _process_toast(delta: float):
	if not _toast_active:
		return
	_toast_timer += delta
	if _toast_timer < 0.15:
		_toast_panel.modulate.a = _toast_timer / 0.15
		_toast_panel.offset_top = 56 + (1.0 - _toast_timer / 0.15) * 10
		_toast_panel.offset_bottom = 102 + (1.0 - _toast_timer / 0.15) * 10
	elif _toast_timer < 1.5:
		_toast_panel.modulate.a = 1.0
		_toast_panel.offset_top = 56
		_toast_panel.offset_bottom = 102
	elif _toast_timer < 1.9:
		var p = (_toast_timer - 1.5) / 0.4
		_toast_panel.modulate.a = 1.0 - p
		_toast_panel.offset_top = 56 - p * 40
		_toast_panel.offset_bottom = 102 - p * 40
	else:
		_toast_active = false
		_toast_panel.visible = false

func update_ui():
	$Label.text = "灵气：" + _format_big(spiritual_energy)
	$Label2.text = "每秒灵气：" + _format_big(mana_per_sec)
	$Label3.text = "境界：" + realm
	$Label3.add_theme_color_override("font_color", get_realm_color())
	$Label4.text = "突破所需：" + (_format_big(get_next_realm_cost()) if get_next_realm_cost() > 0 else "已达最高境界")
	$Label5.text = "HP：" + _format_big(player_hp) + "/" + _format_big(player_max_hp)
	var btn_sect = $MenuBar.get_node_or_null("BtnSect")
	if btn_sect:
		_apply_sect_lock(btn_sect, realm_level < 37)

## 宗门按钮锁定态：右上角挂「禁」角标（红圈粗体禁），代替原 lock 图片
func _apply_sect_lock(btn: Button, locked: bool):
	var badge: Control = btn.get_node_or_null("ForbidBadge")
	if locked and badge == null:
		badge = UI.forbid_badge(16)
		badge.name = "ForbidBadge"
		badge.anchor_left = 1.0
		badge.anchor_right = 1.0
		badge.anchor_top = 0.0
		badge.anchor_bottom = 0.0
		badge.offset_left = -20.0
		badge.offset_right = -4.0
		badge.offset_top = 3.0
		badge.offset_bottom = 19.0
		btn.add_child(badge)
	elif not locked and badge != null:
		btn.remove_child(badge)
		badge.queue_free()

func get_realm_color() -> Color:
	if realm_level >= 1 and realm_level <= realms.size():
		return realms[realm_level - 1].get('color', Color(0.6, 0.6, 0.8))
	return Color(0.6, 0.6, 0.8)

func show_panel(panel_name: String):
	hide_tooltip()
	var is_main = (panel_name == "")
	$Label.visible = is_main
	$Label2.visible = is_main
	$Label3.visible = is_main
	$Label4.visible = is_main
	$Label5.visible = is_main
	$MessageLog.visible = is_main
	$MenuBar.visible = is_main
	$TextureRect.visible = is_main
	$MeditationUI.visible = is_main
	$PanelProfile.visible = (panel_name == "profile")
	$PanelSkills.visible = (panel_name == "skills")
	$PanelInventory.visible = (panel_name == "inventory")
	$PanelShop.visible = (panel_name == "shop")
	$PanelCave.visible = (panel_name == "cave")
	$PanelEquipment.visible = (panel_name == "equipment")
	$PanelMap.visible = (panel_name == "map")
	$PanelTalents.visible = (panel_name == "talents")
	$PanelDharma.visible = (panel_name == "dharma")
	$PanelHelp.visible = (panel_name == "help")
	$PanelSect.visible = (panel_name == "sect")
	$ReincarnateConfirm.visible = false

func _on_back():
	show_panel("")

func hide_tooltip():
	if tooltip_node:
		tooltip_node.visible = false
		tooltip_node.queue_free()
		tooltip_node = null
		tooltip_slot = ""

# ==================== 面板刷新辅助 ====================

func _refresh_profile():
	$PanelProfile.set_state({
		'player_name': player_name,
		'realm': realm,
		'realm_level': realm_level,
		'spiritual_energy': spiritual_energy,
		'mana_per_sec': mana_per_sec,
		'age': age,
		'spirit_root': spirit_root,
		'learned_techniques': learned_techniques,
		'pill_inventory': pill_inventory,
		'reincarnation_count': reincarnation_count,
		'enlightenment_points': enlightenment_points,
		'realms': realms,
		'base_mana': base_mana,
		'cave_base_bonus': cave_base_bonus,
		'realm_mana_bonus': get_realm_mana_bonus(),
		'realm_multiplier': realm_multiplier,
		'technique_multiplier': technique_multiplier,
		'spirit_root_multiplier': spirit_root_multiplier,
		'cave_multiplier': cave_multiplier,
		'artifact_multiplier': artifact_multiplier,
		'time_coefficient': time_coefficient,
		'pill_flat_bonus': pill_flat_bonus,
		'talent_mana_bonus': talent_mana_bonus,
		'talent_multiplier': talent_multiplier,
		'player_hp': player_hp,
		'player_max_hp': player_max_hp,
		'reincarnation_clickable': realm_level >= 19 and realm_level < realms.size(),
		'player_atk': get_player_atk(),
		'player_def': get_player_def(),
		'spirit_roots_list': SPIRIT_ROOTS,
		'attrs': attrs,
		'attr_defs': ATTR_DEFS,
	})
	$PanelProfile.refresh()

func _refresh_skills():
	$PanelSkills.set_state({
		'learned_techniques': learned_techniques,
		'comprehending_tech_id': comprehending_tech_id,
		'comprehension_progress': comprehension_progress,
		'comprehension_time_total': comprehension_time_total,
	})
	$PanelSkills.refresh()

func _refresh_inventory():
	$PanelInventory.set_state({
		'inventory': inventory,
		'pill_inventory': pill_inventory,
		'equipment_inventory': equipment_inventory,
		'array_inventory': array_inventory,
		'recipe_inventory': recipe_inventory,
		'furnace_inventory': furnace_inventory,
		'shop_skills': shop_skills,
		'shop_recipes': shop_recipes,
		'shop_arrays': shop_arrays,
		'shop_furnaces': shop_furnaces,
		'realms': realms,
		'sell_ratio': SELL_RATIO,
		'realm_level': realm_level,
	})
	$PanelInventory.refresh()

func _refresh_shop():
	$PanelShop.set_state({
		'spiritual_energy': spiritual_energy,
		'realm_level': realm_level,
		'shop_skills': shop_skills,
		'shop_recipes': shop_recipes,
		'shop_equipment': shop_equipment,
		'shop_arrays': shop_arrays,
		'shop_furnaces': shop_furnaces,
		'shop_test_items': shop_test_items,
		'learned_techniques': learned_techniques,
		'learned_recipes': learned_recipes,
		'learned_arrays': learned_arrays,
		'array_inventory': array_inventory,
		'recipe_inventory': recipe_inventory,
		'equipped_items': equipped_items,
		'equipment_inventory': equipment_inventory,
		'furnace_inventory': furnace_inventory,
		'realms': realms,
		'equipment_slots': EQUIPMENT_SLOTS,
		'equipment_slot_names': EQUIPMENT_SLOT_NAMES,
	})
	$PanelShop.refresh()

func _refresh_equipment():
	$PanelEquipment.set_state({
		'equipped_items': equipped_items,
		'equipment_slots': EQUIPMENT_SLOTS,
		'equipment_slot_names': EQUIPMENT_SLOT_NAMES,
	})
	$PanelEquipment.refresh()

func _refresh_map():
	$PanelMap.set_state({
		'maps': maps,
		'realm_level': realm_level,
		'in_battle': in_battle,
		'enemy_team': enemy_team,
		'ally_team': ally_team,
		'battle_log': battle_log,
		'auto_next_map': auto_next_map,
		'loop_current_map': loop_current_map,
		'map_sub_level': map_sub_level,
		'current_map': current_map,
		'current_sub_map': current_sub_map,
	})
	$PanelMap.refresh()

func _refresh_talents():
	$PanelTalents.set_state({
		'talents': talents,
		'enlightenment_points': enlightenment_points,
		'realm_level': realm_level,
		'reincarnation_count': reincarnation_count,
	})
	$PanelTalents.refresh()

func _refresh_help():
	$PanelHelp.set_state({
		'realms': realms,
	})
	$PanelHelp.refresh()

func _refresh_dharma():
	$PanelDharma.set_state({
		'dharma_inventory': dharma_inventory,
		'active_dharma_id': active_dharma_id,
		'dharma_shards': dharma_shards,
		'realm_level': realm_level,
		'dharma_unlocked': dharma_unlocked,
		'spiritual_energy': spiritual_energy,
		'active_bonds': get_active_bonds(),
		'dharma_max_level': get_dharma_max_level(),
		'all_dharma_defs': DHARMA_DEFS,
		'born_dharma_def': BORN_DHARMA_DEF,
		'dharma_bonds': DHARMA_BONDS,
	})
	$PanelDharma.refresh()

# ==================== 菜单按钮 ====================

func _on_btn_profile():
	show_panel("profile")
	_refresh_profile()

func _on_btn_skills():
	show_panel("skills")
	_refresh_skills()

func _on_btn_inventory():
	show_panel("inventory")
	_refresh_inventory()

func _on_btn_shop():
	show_panel("shop")
	_refresh_shop()

func _on_btn_cave():
	show_panel("cave")
	refresh_cave()

func _on_btn_sect():
	if realm_level < 37:
		log_message("[color=#ff8844]需要达到化神期才能开启宗门玩法[/color]")
		_show_toast("需要达到化神期", Color(1.0, 0.5, 0.3))
		return
	show_panel("sect")
	refresh_sect()

func _on_btn_equipment():
	show_panel("equipment")
	_refresh_equipment()

func _on_btn_map():
	if in_battle:
		show_panel("map")
		_refresh_map()
	else:
		show_panel("map")
		_refresh_map()

func _on_btn_talents():
	show_panel("talents")
	_refresh_talents()

func _on_btn_help():
	show_panel("help")
	_refresh_help()

func _on_btn_dharma():
	show_panel("dharma")
	_refresh_dharma()

func get_max_furnace_slots() -> int:
	var room_lv = cave_buildings.get('alchemy_furnace', {}).get('level', 0)
	if room_lv <= 0:
		return 0
	elif room_lv <= 2:
		return 1
	elif room_lv <= 4:
		return 2
	else:
		return 3

func get_furnace_bonuses() -> Dictionary:
	var room_lv = cave_buildings.get('alchemy_furnace', {}).get('level', 0)
	var speed_bonus = 0.1 * room_lv
	var success_bonus = 0.0
	var cost_reduction = 0.05 * room_lv
	for furnace in equipped_furnaces:
		if furnace != null and furnace.has('speed_bonus'):
			speed_bonus += furnace['speed_bonus']
			success_bonus += furnace.get('success_bonus', 0.0)
	if speed_bonus < 0:
		speed_bonus = 0.0
	if success_bonus < 0:
		success_bonus = 0.0
	return {"speed": speed_bonus, "success": success_bonus, "cost_reduction": cost_reduction}

func _furnace_already_owned(furnace_name: String) -> bool:
	for f in furnace_inventory:
		if f.get('name', '') == furnace_name:
			return true
	for f in equipped_furnaces:
		if f != null and f.get('name', '') == furnace_name:
			return true
	return false

# ==================== 商店 ====================

func _on_buy_skill(skill: Dictionary):
	var skill_name = skill['name']
	var tid = TECHNIQUE_ID_MAP.get(skill_name, "")
	if tid == "":
		log_message("[color=red]未知功法：" + skill_name + "[/color]")
		return
	if is_skill_learned(skill_name):
		log_message("[color=red]已学会" + skill_name + "，无需重复购买[/color]")
		return
	if realm_level < skill.get('min_realm', 1):
		var req_realm = realms[skill['min_realm'] - 1]['name']
		log_message("[color=red]境界不足！需要达到" + req_realm + "才能修炼" + skill_name + "[/color]")
		_show_toast("境界不足", Color(1.0, 0.4, 0.4))
		return
	if spiritual_energy < skill['price']:
		log_message("[color=red]灵气不足，无法购买" + skill_name + "[/color]")
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	spiritual_energy -= skill['price']
	inventory.append(tid)
	log_message("[color=green]购买成功：" + skill_name + "[/color]")
	_show_toast("购买成功：" + skill_name)
	if $PanelShop.visible: _refresh_shop()
	if $PanelInventory.visible: _refresh_inventory()

func _on_buy_recipe(recipe: Dictionary):
	var recipe_name = recipe['name']
	if is_recipe_learned(recipe_name):
		log_message("[color=red]已学会丹方" + recipe_name + "，无需重复购买[/color]")
		return
	for r in recipe_inventory:
		if r['name'] == recipe_name:
			log_message("[color=red]背包中已有" + recipe_name + "[/color]")
			return
	if spiritual_energy < recipe['price']:
		log_message("[color=red]灵气不足，无法购买丹方" + recipe_name + "[/color]")
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	spiritual_energy -= recipe['price']
	recipe_inventory.append(recipe.duplicate())
	log_message("[color=green]购买丹方秘笈：" + recipe_name + "，已放入背包[/color]")
	_show_toast("购买成功：" + recipe_name)
	if $PanelShop.visible: _refresh_shop()
	if $PanelInventory.visible: _refresh_inventory()

func _on_use_recipe(index: int):
	if index >= recipe_inventory.size():
		return
	var recipe = recipe_inventory[index]
	var recipe_name = recipe['name']
	if is_recipe_learned(recipe_name):
		log_message("[color=red]已学会丹方" + recipe_name + "[/color]")
		recipe_inventory.remove_at(index)
		return
	recipe_inventory.remove_at(index)
	learned_recipes.append(recipe)
	log_message("[color=cyan]习得丹方：" + recipe_name + "（" + recipe.get('desc', '') + "）[/color]")
	if $PanelInventory.visible: _refresh_inventory()
	if $PanelCave.visible: refresh_cave()

func _on_sell_recipe(index: int):
	if index >= recipe_inventory.size():
		return
	var recipe = recipe_inventory[index]
	var sell_price = int(recipe['price'] * SELL_RATIO)
	spiritual_energy += sell_price
	recipe_inventory.remove_at(index)
	log_message("[color=yellow]出售了丹方秘笈【" + recipe['name'] + "】，获得" + _format_num(sell_price) + "灵气[/color]")
	if $PanelInventory.visible: _refresh_inventory()

func _on_buy_equipment(item: Dictionary):
	if spiritual_energy < item['price']:
		log_message("[color=red]灵气不足，无法购买" + item['name'] + "[/color]")
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	spiritual_energy -= item['price']
	equipment_inventory.append(item.duplicate())
	log_message("[color=green]购买成功：" + item['name'] + "，已放入背包，请在背包中装备[/color]")
	_show_toast("购买成功：" + item['name'])
	if $PanelShop.visible: _refresh_shop()
	if $PanelInventory.visible: _refresh_inventory()

func _on_buy_furnace(furnace: Dictionary):
	var fname = furnace['name']
	if _furnace_already_owned(fname):
		log_message("[color=red]已拥有" + fname + "，无需重复购买[/color]")
		return
	if realm_level < furnace.get('min_realm', 1):
		var req_realm = realms[furnace['min_realm'] - 1]['name']
		log_message("[color=red]境界不足！需要达到" + req_realm + "才能使用" + fname + "[/color]")
		_show_toast("境界不足", Color(1.0, 0.4, 0.4))
		return
	if spiritual_energy < furnace['price']:
		log_message("[color=red]灵气不足，无法购买" + fname + "[/color]")
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	spiritual_energy -= furnace['price']
	furnace_inventory.append(furnace.duplicate())
	log_message("[color=green]购买成功：" + fname + "，已放入背包[/color]")
	_show_toast("购买成功：" + fname)
	if $PanelShop.visible: _refresh_shop()
	if $PanelInventory.visible: _refresh_inventory()

func _on_buy_array(array_data: Dictionary):
	var array_name = array_data['name']
	if learned_arrays.has(array_name) or array_inventory.has(array_name):
		log_message("[color=red]已拥有" + array_name + "，无需重复购买[/color]")
		return
	if realm_level < array_data.get('min_realm', 1):
		var req_realm = realms[array_data['min_realm'] - 1]['name']
		log_message("[color=red]境界不足！需要达到" + req_realm + "才能布置" + array_name + "[/color]")
		_show_toast("境界不足", Color(1.0, 0.4, 0.4))
		return
	if spiritual_energy < array_data['price']:
		log_message("[color=red]灵气不足，无法购买" + array_name + "[/color]")
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	spiritual_energy -= array_data['price']
	array_inventory.append(array_name)
	log_message("[color=green]购买阵法秘笈：" + array_name + "，已放入背包[/color]")
	_show_toast("购买成功：" + array_name)
	if $PanelShop.visible: _refresh_shop()
	if $PanelInventory.visible: _refresh_inventory()

func _on_buy_test_item(item: Dictionary):
	var item_name = item['name']
	if spiritual_energy < item['price']:
		log_message("[color=red]灵气不足，无法购买" + item_name + "[/color]")
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	spiritual_energy -= item['price']
	var effect = item.get('effect_type', '')
	if effect == 'realm_up':
		if realm_level >= realms.size():
			log_message("[color=red]已达最高境界，无法提升[/color]")
			_show_toast("已达最高境界", Color(1.0, 0.4, 0.4))
			return
		realm_level += 1
		realm = realms[realm_level - 1]['name']
		recalc_realm_multiplier()
		recalc_mana_per_sec()
		update_max_hp()
		player_hp = player_max_hp
		log_message("[color=#00ff88]◆ 使用" + item_name + "，突破至" + realm + "！[/color]")
		_show_toast("突破至" + realm, Color(0.0, 1.0, 0.5))
	elif effect == 'realm_down':
		if realm_level <= 1:
			log_message("[color=red]已达最低境界，无法降低[/color]")
			_show_toast("已达最低境界", Color(1.0, 0.4, 0.4))
			return
		realm_level -= 1
		realm = realms[realm_level - 1]['name']
		recalc_realm_multiplier()
		recalc_mana_per_sec()
		update_max_hp()
		player_hp = player_max_hp
		log_message("[color=#ff8844]◆ 使用" + item_name + "，跌落至" + realm + "...[/color]")
		_show_toast("跌落至" + realm, Color(1.0, 0.5, 0.3))
	elif effect == 'buy_material':
		var mat = item.get('material', '')
		var amt = item.get('amount', 1)
		sect_materials[mat] = sect_materials.get(mat, 0) + amt
		log_message("[color=#88ff88]◆ 购买" + item_name + " x" + str(amt) + "，当前" + mat + "：" + str(sect_materials[mat]) + "[/color]")
		_show_toast("获得" + mat + " x" + str(amt))
	elif effect == 'cave_upgrade_limit':
		cave_upgrade_limit += item.get('effect_value', 1)
		log_message("[color=#00ff88]◆ 购买" + item_name + "，洞府升级上限提升至 " + str(cave_upgrade_limit) + "[/color]")
		_show_toast("升级上限 +1")
	if $PanelShop.visible: _refresh_shop()
	if $PanelProfile.visible: _refresh_profile()

func _on_use_array(index: int):
	if index >= array_inventory.size():
		return
	var array_name = array_inventory[index]
	if learned_arrays.has(array_name):
		log_message("[color=red]已学会" + array_name + "，无法重复学习[/color]")
		return
	var arr_data = _get_array_data(array_name)
	if arr_data.is_empty():
		log_message("[color=red]未知阵法：" + array_name + "[/color]")
		return
	if realm_level < arr_data.get('min_realm', 1):
		var req_realm = realms[arr_data['min_realm'] - 1]['name']
		log_message("[color=red]境界不足！需要达到" + req_realm + "才能学习" + array_name + "[/color]")
		return
	array_inventory.remove_at(index)
	learned_arrays.append(array_name)
	log_message("[color=cyan]习得阵法：" + array_name + "（" + arr_data['desc'] + "）[/color]")
	if $PanelInventory.visible: _refresh_inventory()
	if $PanelCave.visible: refresh_cave()

func _on_sell_array(index: int):
	if index >= array_inventory.size():
		return
	var array_name = array_inventory[index]
	var arr_data = _get_array_data(array_name)
	if arr_data.is_empty():
		log_message("[color=red]未知阵法：" + array_name + "[/color]")
		return
	var sell_price = int(arr_data['price'] * SELL_RATIO)
	spiritual_energy += sell_price
	array_inventory.remove_at(index)
	log_message("[color=yellow]出售了阵法秘笈【" + array_name + "】，获得" + _format_num(sell_price) + "灵气[/color]")
	if $PanelInventory.visible: _refresh_inventory()

func _on_set_active_array(array_name: String):
	if array_name == "":
		active_array = ""
		log_message("[color=gray]已取消当前阵法[/color]")
	elif learned_arrays.has(array_name):
		active_array = array_name
		var arr_data = _get_array_data(array_name)
		log_message("[color=cyan]洞府已激活阵法：" + array_name + "（" + arr_data.desc + "）[/color]")
	else:
		log_message("[color=red]未学会" + array_name + "[/color]")
		return
	recalc_cave_bonuses()
	recalc_mana_per_sec()
	update_max_hp()
	if $PanelCave.visible: refresh_cave()

func _get_array_data(array_name: String) -> Dictionary:
	for arr in shop_arrays:
		if arr['name'] == array_name:
			return arr
	return {}

func get_active_array_bonus(effect_type: String) -> float:
	if active_array == "":
		return 0.0
	var arr = _get_array_data(active_array)
	if arr.is_empty() or arr.get('effect_type') != effect_type:
		return 0.0
	return arr.get('effect_value', 0.0)

# ==================== 背包操作 ====================

func _on_use_skill(index: int):
	if index >= inventory.size():
		return
	var tid = inventory[index]
	if not TECHNIQUE_DEFS.has(tid):
		log_message("[color=red]未知功法ID：" + tid + "[/color]")
		return
	var defs = TECHNIQUE_DEFS[tid]
	if is_skill_learned(defs.name):
		log_message("[color=red]已学会" + defs.name + "，无法重复学习[/color]")
		return
	if realm_level < defs.get('min_realm', 1):
		var req_realm = realms[defs['min_realm'] - 1]['name']
		log_message("[color=red]境界不足！需要达到" + req_realm + "才能修炼" + defs.name + "[/color]")
		return
	inventory.remove_at(index)
	learned_techniques[tid] = {"level": 0}
	log_message("[color=cyan]获得功法：" + defs.name + "（" + TECHNIQUE_GRADES[defs.grade - 1] + "功法，共" + str(defs.levels.size()) + "重）[/color]")
	start_comprehension(tid)
	recalc_technique_multiplier()
	recalc_mana_per_sec()
	if $PanelInventory.visible: _refresh_inventory()
	if $PanelSkills.visible: _refresh_skills()

func _on_sell_skill(index: int):
	if index >= inventory.size():
		return
	var tid = inventory[index]
	if not TECHNIQUE_DEFS.has(tid):
		log_message("[color=red]未知功法ID：" + tid + "[/color]")
		return
	var defs = TECHNIQUE_DEFS[tid]
	var sell_price = int(defs['price'] * SELL_RATIO)
	spiritual_energy += sell_price
	inventory.remove_at(index)
	log_message("[color=yellow]出售了【" + defs.name + "】，获得" + _format_num(sell_price) + "灵气[/color]")
	if $PanelInventory.visible: _refresh_inventory()

func _on_sell_pill(pill_name: String):
	if not pill_inventory.has(pill_name) or pill_inventory[pill_name] <= 0:
		return
	var recipe_data = null
	for r in shop_recipes:
		if r['name'] == pill_name:
			recipe_data = r
			break
	if recipe_data == null:
		log_message("[color=red]未知丹药：" + pill_name + "[/color]")
		return
	var sell_price = int(recipe_data['price'] * SELL_RATIO)
	spiritual_energy += sell_price
	pill_inventory[pill_name] -= 1
	if pill_inventory[pill_name] <= 0:
		pill_inventory.erase(pill_name)
	log_message("[color=yellow]出售了【" + pill_name + "】，获得" + _format_num(sell_price) + "灵气[/color]")
	if $PanelInventory.visible: _refresh_inventory()

func _on_equip_from_inventory(index: int):
	if index >= equipment_inventory.size():
		return
	var item = equipment_inventory[index]
	var slot = item['slot']
	var old = equipped_items[slot]
	if old != null:
		equipment_inventory.append(old.duplicate())
		log_message("[color=gray]卸下" + old['name'] + "放回背包[/color]")
	equipped_items[slot] = item
	equipment_inventory.remove_at(index)
	if slot == 'artifact':
		recalc_artifact_multiplier()
		recalc_mana_per_sec()
	log_message("[color=green]装备了" + item['name'] + "[/color]")
	if $PanelInventory.visible: _refresh_inventory()
	if $PanelEquipment.visible: _refresh_equipment()

func _on_sell_equipment_from_inventory(index: int):
	if index >= equipment_inventory.size():
		return
	var item = equipment_inventory[index]
	var sell_price = int(item['price'] * SELL_RATIO)
	spiritual_energy += sell_price
	equipment_inventory.remove_at(index)
	log_message("[color=yellow]出售了【" + item['name'] + "】，获得" + _format_num(sell_price) + "灵气[/color]")
	if $PanelInventory.visible: _refresh_inventory()

func _on_equip_furnace(slot_index: int, inventory_index: int):
	if inventory_index >= furnace_inventory.size():
		return
	var max_slots = get_max_furnace_slots()
	if slot_index < 0 or slot_index >= max_slots:
		return
	while equipped_furnaces.size() < max_slots:
		equipped_furnaces.append(null)
	while equipped_furnaces.size() > max_slots:
		var extra = equipped_furnaces.pop_back()
		if extra != null:
			furnace_inventory.append(extra)
	var old = equipped_furnaces[slot_index]
	if old != null:
		furnace_inventory.append(old)
	var furnace = furnace_inventory[inventory_index]
	equipped_furnaces[slot_index] = furnace
	furnace_inventory.remove_at(inventory_index)
	log_message("[color=green]已将" + furnace['name'] + "安装到丹炉槽位" + str(slot_index + 1) + "[/color]")
	if $PanelInventory.visible: _refresh_inventory()
	if $PanelCave.visible: refresh_cave()

func _on_unequip_furnace(slot_index: int):
	var max_slots = get_max_furnace_slots()
	if slot_index < 0 or slot_index >= equipped_furnaces.size():
		return
	var furnace = equipped_furnaces[slot_index]
	if furnace == null:
		return
	equipped_furnaces[slot_index] = null
	furnace_inventory.append(furnace)
	log_message("[color=gray]卸下了" + furnace['name'] + "[/color]")
	while equipped_furnaces.size() > 0 and equipped_furnaces[equipped_furnaces.size() - 1] == null:
		if equipped_furnaces.size() <= get_max_furnace_slots():
			break
		equipped_furnaces.pop_back()
	if $PanelInventory.visible: _refresh_inventory()
	if $PanelCave.visible: refresh_cave()

func _on_sell_furnace_from_inventory(index: int):
	if index >= furnace_inventory.size():
		return
	var furnace = furnace_inventory[index]
	var sell_price = int(furnace['price'] * SELL_RATIO)
	spiritual_energy += sell_price
	furnace_inventory.remove_at(index)
	log_message("[color=yellow]出售了【" + furnace['name'] + "】，获得" + _format_num(sell_price) + "灵气[/color]")
	if $PanelInventory.visible: _refresh_inventory()

# ==================== 洞府 ====================

func refresh_cave():
	var panel = $PanelCave
	panel.set_state(cave_level, cave_buildings, spiritual_energy, realm_level, learned_recipes, pill_inventory, learned_arrays, active_array, shop_arrays, furnace_inventory, equipped_furnaces, spirit_ore, spirit_wood, get_ore_rate(), get_wood_rate(), cave_upgrade_queue, cave_upgrade_limit)
	panel.refresh()

func refresh_sect():
	var panel = $PanelSect
	panel.set_state({
		'spiritual_energy': spiritual_energy,
		'realm_level': realm_level,
		'sect_level': sect_level,
		'sect_buildings': sect_buildings,
		'sect_materials': sect_materials,
		'disciples': disciples,
		'disciple_capacity': disciple_capacity,
	})
	panel.refresh()

func recalc_sect_bonuses():
	disciple_capacity = 3
	var main_lv = sect_buildings.get('sect_main_hall', {}).get('level', 0)
	sect_level = max(1, main_lv)
	var residence_lv = sect_buildings.get('spirit_residence', {}).get('level', 0)
	if sect_buildings.get('spirit_residence', {}).get('unlocked', false):
		disciple_capacity = 3 + residence_lv * 5
	var old_mana = sect_disciple_mana
	sect_disciple_mana = 0.0
	for d in disciples:
		var grade_idx = d.get('grade', 0)
		var grade_mana = [0.15, 0.4, 1.0, 3.0, 8.0, 20.0][grade_idx]
		sect_disciple_mana += grade_mana * d.get('level', 1)

func _on_sect_building_action(bid: String):
	var building_defs = $PanelSect.SECT_BUILDING_DEFS
	if not building_defs.has(bid):
		return
	var def = building_defs[bid]
	var b_data = sect_buildings.get(bid, {'level': 0, 'unlocked': false})
	var unlocked = b_data.get('unlocked', false)
	var level = b_data.get('level', 0)

	if not unlocked:
		var req_bid = def.get('require_building', '')
		var req_lv = def.get('require_level', 1)
		if req_bid != '':
			var req_data = sect_buildings.get(req_bid, {})
			if not req_data.get('unlocked', false) or sect_level < req_lv:
				log_message("[color=red]条件不足，无法解锁" + def['name'] + "[/color]")
				return
		var material = def.get('material', '')
		var mat_cost = def.get('material_base', 3)
		if material != '' and sect_materials.get(material, 0) < mat_cost:
			log_message("[color=red]" + material + "不足（需要" + str(mat_cost) + "）[/color]")
			_show_toast("材料不足", Color(1.0, 0.4, 0.4))
			return
		if spiritual_energy < def['base_cost']:
			log_message("[color=red]灵气不足，无法解锁" + def['name'] + "[/color]")
			_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
			return
		spiritual_energy -= def['base_cost']
		if material != '':
			sect_materials[material] = sect_materials.get(material, 0) - mat_cost
		b_data['unlocked'] = true
		b_data['level'] = 0
		sect_buildings[bid] = b_data
		log_message("[color=green]解锁宗门建筑：" + def['name'] + "[/color]")
	else:
		if level >= def['max_level']:
			return
		var cost = int(def['base_cost'] * pow(def['cost_growth'], level))
		var material = def.get('material', '')
		var mat_cost = def.get('material_base', 3) + level * 2
		if material != '' and sect_materials.get(material, 0) < mat_cost:
			log_message("[color=red]" + material + "不足（需要" + str(mat_cost) + "）[/color]")
			_show_toast("材料不足", Color(1.0, 0.4, 0.4))
			return
		if spiritual_energy < cost:
			log_message("[color=red]灵气不足，无法升级" + def['name'] + "[/color]")
			_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
			return
		spiritual_energy -= cost
		if material != '':
			sect_materials[material] = sect_materials.get(material, 0) - mat_cost
		b_data['level'] = level + 1
		sect_buildings[bid] = b_data
		log_message("[color=green]" + def['name'] + "升级至Lv." + str(level + 1) + "[/color]")

	recalc_sect_bonuses()
	recalc_mana_per_sec()
	if $PanelSect.visible: refresh_sect()

func _on_recruit_disciple():
	var platform = sect_buildings.get('recruitment_platform', {})
	if not platform.get('unlocked', false):
		log_message("[color=red]需要先解锁接引台[/color]")
		return
	var lv = platform.get('level', 0)
	var cost = 500 * (lv + 1)
	if spiritual_energy < cost:
		log_message("[color=red]灵气不足，无法招收弟子[/color]")
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	if disciples.size() >= disciple_capacity:
		log_message("[color=red]弟子数量已达上限[/color]")
		return

	spiritual_energy -= cost
	var weights = $PanelSect.GRADE_WEIGHTS.duplicate()
	for i in range(1, weights.size()):
		weights[i] += lv * 0.02
	var total = 0.0
	for w in weights:
		total += w
	var roll = randf() * total
	var cumulative = 0.0
	var grade_idx = 0
	for i in range(weights.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			grade_idx = i
			break
	var surnames = ["云", "风", "清", "玄", "灵", "玉", "元", "道", "真", "明", "虚", "静"]
	var grade_data = $PanelSect.DISCIPLE_GRADES[grade_idx]
	var dname = surnames[randi() % surnames.size()] + surnames[randi() % surnames.size()]
	var disciple = {
		'name': dname,
		'grade': grade_idx,
		'level': 1,
		'hp': grade_data['hp'],
		'atk': grade_data['atk'],
		'def': grade_data['def'],
		'mana': grade_data['mana'],
		'cultivation_progress': 0.0,
		'cultivation_time': 30.0,
	}
	disciples.append(disciple)
	recalc_sect_bonuses()
	recalc_mana_per_sec()
	log_message("[color=#4488ff]◆ 招收弟子：" + dname + "（" + grade_data['name'] + "）[/color]")
	_show_toast("招收：" + grade_data['name'] + " " + dname)
	if $PanelSect.visible: refresh_sect()

func _on_dismiss_disciple(index: int):
	if index < 0 or index >= disciples.size():
		return
	var d = disciples[index]
	var grade_data = $PanelSect.DISCIPLE_GRADES[d.get('grade', 0)]
	log_message("[color=#ff8844]◆ 逐出弟子：" + d['name'] + "（" + grade_data['name'] + "）[/color]")
	disciples.remove_at(index)
	recalc_sect_bonuses()
	recalc_mana_per_sec()
	if $PanelSect.visible: refresh_sect()

func _process_disciple_cultivation(delta: float):
	var hall = sect_buildings.get('enlightenment_hall', {})
	var hall_lv = 0
	if hall.get('unlocked', false):
		hall_lv = hall.get('level', 0)
	var speed_mult = 1.0 + hall_lv * 0.15
	var leveled = false
	for d in disciples:
		d['cultivation_progress'] = d.get('cultivation_progress', 0.0) + delta * speed_mult
		var time_needed = d.get('cultivation_time', 30.0)
		if d['cultivation_progress'] >= time_needed:
			d['cultivation_progress'] -= time_needed
			d['level'] = d.get('level', 1) + 1
			var grade_idx = d.get('grade', 0)
			d['hp'] += 5 + grade_idx * 5
			d['atk'] += 1 + grade_idx * 2
			d['def'] += 1 + grade_idx
			var grade_mana = [0.15, 0.4, 1.0, 3.0, 8.0, 20.0][grade_idx]
			d['mana'] = grade_mana * d['level']
			d['cultivation_time'] = time_needed * 1.2
			leveled = true
	if leveled:
		recalc_sect_bonuses()
		recalc_mana_per_sec()

func _try_drop_sect_material():
	var roll = randf()
	var map_name = current_map.get('name', '')
	var map_lv = map_sub_level.get(map_name, 1)
	var drop_chance = 0.08 + map_lv * 0.01
	if roll > drop_chance:
		return
	var grade_roll = randf()
	var mat_name = "灵木"
	var amount = 1
	if grade_roll < 0.15 and map_lv >= 3:
		mat_name = "魂晶"
		amount = 1
	elif grade_roll < 0.40 and map_lv >= 2:
		mat_name = "玄铁"
		amount = 1
	sect_materials[mat_name] = sect_materials.get(mat_name, 0) + amount

func get_ore_rate() -> float:
	return cave_buildings.get('spirit_mine', {}).get('level', 0) * 1.0

func get_wood_rate() -> float:
	return cave_buildings.get('spirit_wood', {}).get('level', 0) * 1.0

## 建筑升级耗时（秒），随等级增长
func _get_upgrade_duration(bid: String, level: int) -> float:
	var defs = $PanelCave.BUILDING_DEFS.get(bid, {})
	return int(defs.get('base_time', 10.0) * pow(defs.get('time_growth', 1.2), level))

## 建筑升级货币：'energy'(灵气) / 'ore'(灵矿) / 'wood'(灵木) / 'both'(灵矿+灵木)
func _get_building_currency(bid: String) -> String:
	return $PanelCave.get_upgrade_currency(bid)

func recalc_cave_bonuses():
	var array_lv = cave_buildings.get('spirit_array', {}).get('level', 0)
	cave_multiplier = 1.0 + 0.1 * array_lv
	var room_lv = cave_buildings.get('cultivation_room', {}).get('level', 0)
	cave_base_bonus = room_lv * 1.0
	# 阵法加成：洞府修炼速度
	cave_multiplier += get_active_array_bonus('cave_mana_pct')
	# 阵法加成：建筑效果
	var building_boost = get_active_array_bonus('building_boost')
	if building_boost > 0:
		cave_multiplier *= 1.0 + building_boost
		cave_base_bonus *= 1.0 + building_boost

func _on_cave_upgrade():
	var ore_cost = int(100 * pow(2, cave_level))
	var wood_cost = int(100 * pow(2, cave_level))
	if spirit_ore < ore_cost or spirit_wood < wood_cost:
		log_message("[color=red]灵矿或灵木不足，无法升级洞府！[/color]")
		return
	spirit_ore -= ore_cost
	spirit_wood -= wood_cost
	cave_level += 1
	log_message("[color=green]洞府升至 " + str(cave_level) + " 级！所有建筑效果提升[/color]")
	recalc_cave_bonuses()
	recalc_mana_per_sec()
	refresh_cave()

func _on_building_action(bid: String):
	var defs = $PanelCave.BUILDING_DEFS[bid]
	var building = cave_buildings[bid]
	var level = building.level
	var unlocked = building.unlocked
	var cost = $PanelCave.get_upgrade_cost(bid) if unlocked else defs.base_cost
	var currency = _get_building_currency(bid)

	# 解锁：消耗灵气，即时解锁
	if not unlocked:
		if spiritual_energy < cost:
			log_message("[color=red]灵气不足！[/color]")
			return
		if realm_level < defs.unlock_realm:
			var realm_name = realms[defs.unlock_realm - 1]['name']
			log_message("[color=red]境界不足！需要达到" + realm_name + "才能解锁" + defs.name + "[/color]")
			return
		spiritual_energy -= cost
		building.unlocked = true
		building.level = 1
		log_message("[color=green]解锁" + defs.name + "！[/color]")
		recalc_cave_bonuses()
		recalc_mana_per_sec()
		refresh_cave()
		return

	# 升级：耗时制，先扣资源再等待（超出上限则进入排队）
	if defs.max_level >= 0 and level >= defs.max_level:
		return
	if building.get('upgrading', false):
		return
	if cave_upgrade_queue.has(bid):
		return
	if currency == 'energy':
		if spiritual_energy < cost:
			log_message("[color=red]灵气不足！[/color]")
			return
		spiritual_energy -= cost
	elif currency == 'ore':
		if spirit_ore < cost:
			log_message("[color=red]灵矿不足！[/color]")
			return
		spirit_ore -= cost
	elif currency == 'wood':
		if spirit_wood < cost:
			log_message("[color=red]灵木不足！[/color]")
			return
		spirit_wood -= cost
	else:
		if spirit_ore < cost or spirit_wood < cost:
			log_message("[color=red]灵矿或灵木不足！[/color]")
			return
		spirit_ore -= cost
		spirit_wood -= cost
	var dur = _get_upgrade_duration(bid, level)
	building['upgrade_remaining'] = dur
	building['upgrade_duration'] = dur
	if _active_upgrade_count() < cave_upgrade_limit:
		building['upgrading'] = true
		building['queued'] = false
		log_message("[color=cyan]" + defs.name + " 开始升级（耗时 " + str(int(dur)) + " 秒）[/color]")
	else:
		building['queued'] = true
		cave_upgrade_queue.append(bid)
		log_message("[color=cyan]" + defs.name + " 已加入升级队列（当前第 " + str(cave_upgrade_queue.size()) + " 位）[/color]")
	refresh_cave()

func _active_upgrade_count() -> int:
	var n := 0
	for bid in cave_buildings:
		if cave_buildings[bid].get('upgrading', false):
			n += 1
	return n

## 空槽时从队列头部提拔建筑开始升级
func _promote_cave_queue():
	var promoted := false
	while cave_upgrade_queue.size() > 0 and _active_upgrade_count() < cave_upgrade_limit:
		var bid = cave_upgrade_queue.pop_front()
		var b = cave_buildings.get(bid)
		if b == null:
			continue
		b['queued'] = false
		b['upgrading'] = true
		log_message("[color=cyan]" + $PanelCave.BUILDING_DEFS.get(bid, {}).get('name', bid) + " 开始升级[/color]")
		promoted = true
	if promoted:
		refresh_cave()

## 旧存档可能有多个建筑同时在升级：超限者降级为排队，并同步 queued 标志
func _reconcile_cave_queue():
	for bid in cave_upgrade_queue:
		if cave_buildings.has(bid):
			cave_buildings[bid]['queued'] = true
	while _active_upgrade_count() > cave_upgrade_limit:
		for bid in cave_buildings:
			var b = cave_buildings[bid]
			if b.get('upgrading', false):
				b['upgrading'] = false
				b['queued'] = true
				cave_upgrade_queue.append(bid)
				break

func _on_cancel_upgrade(bid: String):
	var idx = cave_upgrade_queue.find(bid)
	if idx < 0:
		return
	var b = cave_buildings.get(bid)
	if b == null:
		cave_upgrade_queue.remove_at(idx)
		return
	var cost = $PanelCave.get_upgrade_cost(bid)
	var currency = _get_building_currency(bid)
	match currency:
		'energy':
			spiritual_energy += cost
		'ore':
			spirit_ore += cost
		'wood':
			spirit_wood += cost
		_:
			spirit_ore += cost
			spirit_wood += cost
	cave_upgrade_queue.remove_at(idx)
	b['queued'] = false
	log_message("[color=#ffcc88]" + $PanelCave.BUILDING_DEFS.get(bid, {}).get('name', bid) + " 已取消排队，资源已退还[/color]")
	refresh_cave()

func _on_craft_pill_by_name(recipe_name: String):
	for recipe in learned_recipes:
		if recipe['name'] == recipe_name:
			var bonuses = get_furnace_bonuses()
			var cost_mult = 1.0 - bonuses['cost_reduction'] - get_active_array_bonus('craft_discount')
			var success_chance = 0.8 + bonuses['success']
			var actual_cost = int(recipe['craft_cost'] * cost_mult)

			if spiritual_energy < actual_cost:
				log_message("[color=red]灵气不足，无法炼制" + recipe_name + "[/color]")
				return
			spiritual_energy -= actual_cost

			if randf() > success_chance:
				log_message("[color=red]炼制失败，" + recipe_name + " 炼制失败（成功率" + str(int(success_chance * 100)) + "%），材料损坏[/color]")
			else:
				if pill_inventory.has(recipe_name):
					pill_inventory[recipe_name] += 1
				else:
					pill_inventory[recipe_name] = 1
				log_message("[color=green]炼制成功，" + recipe_name + "（减免后消耗" + str(actual_cost) + "灵气）[/color]")
			refresh_cave()
			if $PanelInventory.visible: _refresh_inventory()
			return
	log_message("[color=red]未知丹方：" + recipe_name + "[/color]")

func _on_use_pill(pill_name: String):
	if not pill_inventory.has(pill_name) or pill_inventory[pill_name] <= 0:
		log_message("[color=red]没有" + pill_name + "[/color]")
		return
	var recipe_data = null
	for r in shop_recipes:
		if r['name'] == pill_name:
			recipe_data = r
			break
	if recipe_data == null:
		log_message("[color=red]未知丹药：" + pill_name + "[/color]")
		return
	match recipe_data['effect_type']:
		'restore_energy':
			spiritual_energy += recipe_data['effect_value']
			log_message("[color=cyan]使用" + pill_name + "，回复" + str(recipe_data['effect_value']) + "灵气[/color]")
		'mana_per_sec':
			pill_flat_bonus += recipe_data['effect_value']
			recalc_mana_per_sec()
			log_message("[color=cyan]使用" + pill_name + "，每秒灵气+" + str(recipe_data['effect_value']) + "[/color]")
		'realm_break':
			if try_breakthrough():
				pass
			else:
				log_message("[color=red]已达最高境界，" + pill_name + "无效[/color]")
				spiritual_energy += recipe_data['craft_cost']
				pill_inventory[pill_name] += 1
				return
	pill_inventory[pill_name] -= 1
	if pill_inventory[pill_name] <= 0:
		pill_inventory.erase(pill_name)
	refresh_cave()
	if $PanelInventory.visible: _refresh_inventory()

# ==================== 装备 ====================

func _on_unequip(slot: String):
	var item = equipped_items[slot]
	if item == null:
		return
	hide_tooltip()
	equipped_items[slot] = null
	equipment_inventory.append(item.duplicate())
	if slot == 'artifact':
		recalc_artifact_multiplier()
		recalc_mana_per_sec()
	log_message("[color=gray]卸下了" + item['name'] + "，已放回背包[/color]")
	if $PanelEquipment.visible: _refresh_equipment()
	if $PanelInventory.visible: _refresh_inventory()

# ==================== 战斗 ====================

func start_battle(map: Dictionary, sub_map: int = 1):
	current_map = map
	var map_name = map.get('name', '')
	current_sub_map = sub_map
	if not map_sub_level.has(map_name):
		map_sub_level[map_name] = 1
	var expected_sub = map_sub_level.get(map_name, 1)
	if sub_map > expected_sub:
		log_message("[color=red]请按顺序挑战！当前进度：第" + str(expected_sub) + "层[/color]")
		return
	in_battle = true
	battle_timer = 0.0
	battle_log = ""
	update_max_hp()
	player_hp = player_max_hp
	build_ally_team()
	spawn_enemy_team()
	show_panel("map")
	_refresh_map()
	log_message("[color=yellow]进入" + map_name + "第" + str(sub_map) + "层开始历练！我方" + str(get_alive_ally_count()) + "人 vs 敌方" + str(get_alive_enemy_count()) + "人[/color]")

func get_alive_ally_count() -> int:
	var count = 0
	for a in ally_team:
		if a.alive:
			count += 1
	return count

func get_alive_enemy_count() -> int:
	var count = 0
	for e in enemy_team:
		if e.alive:
			count += 1
	return count

func stop_battle():
	in_battle = false
	enemy_team.clear()
	ally_team.clear()
	current_map = {}
	current_sub_map = 1
	battle_log = ""
	player_hp = player_max_hp
	log_message("[color=gray]停止历练，已恢复HP[/color]")
	_refresh_map()

func _on_map_settings_changed(auto_next: bool, loop_current: bool):
	auto_next_map = auto_next
	loop_current_map = loop_current

func _process_battle(delta: float):
	if not in_battle:
		return
	battle_timer += delta
	if battle_timer >= 1.0 / battle_speed:
		battle_timer -= 1.0 / battle_speed
		_do_battle_tick()

func _do_battle_tick():
	var log_lines: Array = []
	
	# 我方角色攻击
	for ally in ally_team:
		if not ally.alive:
			continue
		var target = _pick_random_alive_enemy()
		if target == null:
			continue
		var dmg = max(1, int(ally.atk - target.def + randi_range(-3, 3)))
		var crit_chance = attrs.get('critical', 0) * 0.03
		var is_crit = randf() < crit_chance
		if is_crit:
			dmg = int(dmg * 1.5)
		target.hp -= dmg
		log_lines.append("[color=#88ff88]" + ally.name + "[/color] 攻击 [color=#ff8888]" + target.name + "[/color]，造成 " + str(dmg) + " 点伤害" + (" [color=orange]暴击！[/color]" if is_crit else ""))
		if target.hp <= 0:
			target.hp = 0
			target.alive = false
			log_lines.append("[color=yellow]◆ 击杀 " + target.name + "！获得 " + str(target.exp) + " 灵气[/color]")
			spiritual_energy += target.exp
			log_message("[color=green]击杀" + target.name + "！获得 " + str(target.exp) + " 灵气[/color]")
			_try_drop_dharma_shard()
			_try_drop_sect_material()
	
	# 检查敌方是否全灭
	if get_alive_enemy_count() == 0:
		var map_name = current_map.get('name', '')
		var max_sub = current_map.get('max_sub', 100)
		var sub = map_sub_level.get(map_name, 1)

		log_lines.append("[color=cyan]◇ 敌方全灭！第" + str(sub) + "层通关[/color]")

		# 首次通关当前层时推进进度（循环模式不推进）
		if not loop_current_map and sub == map_sub_level.get(map_name, 1) and sub < max_sub:
			map_sub_level[map_name] = sub + 1

		if loop_current_map:
			log_lines.append("[color=yellow]重复刷本层（第" + str(sub) + "层）[/color]")
			spawn_enemy_team()
		elif auto_next_map:
			if sub < max_sub:
				var next_sub = sub + 1
				map_sub_level[map_name] = next_sub
				current_sub_map = next_sub
				log_lines.append("[color=yellow]自动进入第" + str(next_sub) + "层！[/color]")
				log_message("[color=yellow]" + map_name + " 第" + str(sub) + "层通关，自动进入第" + str(next_sub) + "层[/color]")
				spawn_enemy_team()
			else:
				log_lines.append("[color=gold]◆ " + map_name + " 全部100层通关！[/color]")
				log_message("[color=gold]" + map_name + " 全部100层通关！[/color]")
				stop_battle()
				if $PanelMap.visible:
					show_panel("map")
					_refresh_map()
				return
		else:
			log_lines.append("[color=gray]第" + str(sub) + "层通关，停止历练[/color]")
			log_message("[color=cyan]" + map_name + " 第" + str(sub) + "层通关！[/color]")
			stop_battle()
			if $PanelMap.visible:
				show_panel("map")
				_refresh_map()
			return

		if $PanelMap.visible:
			_refresh_map()
		return
	
	# 敌方角色攻击
	for enemy in enemy_team:
		if not enemy.alive:
			continue
		var target = _pick_random_alive_ally()
		if target == null:
			continue
		var dmg = max(1, int(enemy.atk - target.def + randi_range(-3, 3)))
		target.hp -= dmg
		log_lines.append("[color=#ff8888]" + enemy.name + "[/color] 攻击 [color=#88ff88]" + target.name + "[/color]，造成 " + str(dmg) + " 点伤害")
		if target.hp <= 0:
			target.hp = 0
			target.alive = false
			if target.is_player:
				log_lines.append("[color=red]◆ " + target.name + " 阵亡！[/color]")
			else:
				log_lines.append("[color=red]◆ " + target.name + " 阵亡！[/color]")
	
	# 检查我方是否全灭
	if get_alive_ally_count() == 0:
		log_lines.append("[color=red]◇ 全军覆没！[/color]")
		log_message("[color=red]全军覆没，被迫撤退...[/color]")
		stop_battle()
		if $PanelMap.visible:
			show_panel("map")
			_refresh_map()
		return
	
	# 更新玩家HP（同步主角的生命值）
	for ally in ally_team:
		if ally.is_player:
			player_hp = ally.hp
			break
	
	if log_lines.size() > 0:
		battle_log = "\n".join(log_lines)
	
	if $PanelMap.visible:
		_refresh_map()

func _pick_random_alive_enemy():
	var alive: Array = []
	for e in enemy_team:
		if e.alive:
			alive.append(e)
	if alive.size() == 0:
		return null
	return alive[randi() % alive.size()]

func _pick_random_alive_ally():
	var alive: Array = []
	for a in ally_team:
		if a.alive:
			alive.append(a)
	if alive.size() == 0:
		return null
	return alive[randi() % alive.size()]

func get_available_companions() -> Array:
	var result: Array = []
	for comp in COMPANION_DEFS:
		if realm_level >= comp.unlock_realm:
			result.append(comp)
	return result

func build_ally_team():
	ally_team.clear()
	var scale = 1.0 + realm_level * 0.3
	ally_team.append({
		'name': player_name,
		'hp': player_max_hp,
		'max_hp': player_max_hp,
		'atk': get_player_atk(),
		'def': get_player_def(),
		'alive': true,
		'is_player': true,
		'color': get_realm_color(),
	})
	for comp in COMPANION_DEFS:
		if realm_level >= comp.unlock_realm:
			ally_team.append({
				'name': comp.name,
				'hp': comp.base_hp * scale,
				'max_hp': comp.base_hp * scale,
				'atk': comp.base_atk * scale,
				'def': comp.base_def * scale,
				'alive': true,
				'is_player': false,
				'color': comp.color,
			})

func spawn_enemy_team():
	enemy_team.clear()
	var sub_level = map_sub_level.get(current_map.get('name', ''), 1)
	var enemy_scale = 1.0 + (realm_level - current_map['min_level']) * 0.15
	enemy_scale *= 1.0 + (sub_level - 1) * 0.05
	var templates = current_map['enemies']
	var count = min(templates.size(), 6)
	var used_indices: Array = []
	for _i in range(count):
		var idx: int
		while true:
			idx = randi() % templates.size()
			if not used_indices.has(idx):
				used_indices.append(idx)
				break
		var template = templates[idx]
		enemy_team.append({
			'name': template['name'],
			'hp': template['hp'] * enemy_scale,
			'max_hp': template['hp'] * enemy_scale,
			'atk': template['atk'] * enemy_scale,
			'def': template['def'] * enemy_scale,
			'exp': int(template['exp'] * enemy_scale),
			'alive': true,
		})

# ==================== 天赋 ====================

func _on_upgrade_talent(tid: String):
	if not TALENT_DEFS.has(tid):
		return
	var defs = TALENT_DEFS[tid]
	var level = talents.get(tid, 0)
	if level >= defs.max_level:
		return
	if enlightenment_points < defs.cost:
		return
	enlightenment_points -= defs.cost
	talents[tid] = level + 1
	recalc_talent_bonuses()
	recalc_mana_per_sec()
	log_message("[color=green]天赋升级：" + defs.name + " → Lv." + str(talents[tid]) + "[/color]")
	if $PanelTalents.visible: _refresh_talents()

func _on_select_spirit_root(root_name: String):
	for root in SPIRIT_ROOTS:
		if root.name == root_name:
			spirit_root = root
			var c = root.color.to_html(false)
			log_message("[color=#" + c + "]灵根已更换为：" + root.name + " - " + root.desc + "[/color]")
			recalc_technique_multiplier()
			recalc_mana_per_sec()
			if $PanelTalents.visible: _refresh_talents()
			return
	log_message("[color=red]未知灵根：" + root_name + "[/color]")

# ==================== 兵解重修 ====================

func _on_reincarnate_clicked():
	$ReincarnateConfirm.popup_centered()

func _on_reincarnate_confirmed():
	var gained = 1 + floor(realm_level / 9.0)
	enlightenment_points += gained
	reincarnation_count += 1

	realm_level = 1
	realm = realms[0]['name']
	spiritual_energy = 0.0
	base_mana = 10.0
	inventory = []
	learned_techniques = {}
	comprehending_tech_id = ""
	comprehension_progress = 0.0
	comprehension_time_total = 0.0
	learned_recipes = []
	learned_arrays = []
	active_array = ""
	array_inventory = []
	recipe_inventory = []
	pill_inventory = {}
	equipped_items = {
		'weapon': null,
		'helmet': null,
		'armor': null,
		'boots': null,
		'artifact': null,
		'accessory': null,
		'belt': null,
		'ring_left': null,
		'ring_right': null,
		'cloak': null
	}
	equipment_inventory = []
	furnace_inventory = []
	equipped_furnaces = []
	player_hp = 100.0
	player_max_hp = 100.0
	dharma_inventory = []
	active_dharma_id = ""
	dharma_shards = []
	dharma_unlocked = false
	recalc_dharma_bonuses()

	recalc_realm_multiplier()
	recalc_technique_multiplier()
	recalc_artifact_multiplier()
	recalc_cave_bonuses()
	recalc_talent_bonuses()
	recalc_mana_per_sec()
	update_max_hp()

	log_message("[color=yellow]◇ 兵解重修！获得 " + str(gained) + " 悟道点（累计 " + str(reincarnation_count) + " 次）[/color]")
	show_panel("profile")
	_refresh_profile()

# ==================== 法相系统 ====================

func _check_dharma_unlock():
	if not dharma_unlocked and realm_level >= 19:
		dharma_unlocked = true
		var born_dharma = {
			'id': 'born_nature',
			'name': '本命法相',
			'desc': '随境界突破而生，与道体交融的本命法相',
			'grade': 0,
			'atk': BORN_DHARMA_DEF.grades[0].atk,
			'def': BORN_DHARMA_DEF.grades[0].def,
			'hp': BORN_DHARMA_DEF.grades[0].hp,
			'mana_pct': BORN_DHARMA_DEF.grades[0].mana_pct,
			'born': true,
			'level': 1,
			'stars': 0,
		}
		dharma_inventory.append(born_dharma)
		active_dharma_id = 'born_nature'
		recalc_dharma_bonuses()
		recalc_mana_per_sec()
		update_max_hp()
		log_message("[color=#ffd700]◆ 金丹已成！本命法相觉醒 —— 体内道基显化，本命法相初现！[/color]")

func _on_activate_dharma(dharma_id: String):
	for dharma in dharma_inventory:
		if dharma.id == dharma_id:
			active_dharma_id = dharma_id
			recalc_dharma_bonuses()
			recalc_mana_per_sec()
			update_max_hp()
			log_message("[color=cyan]激活法相：" + dharma.name + "[/color]")
			if $PanelDharma.visible:
				_refresh_dharma()
			return
	log_message("[color=red]法相不存在[/color]")

func _on_synthesize_dharma(grade: int):
	if grade < 0 or grade >= DHARMA_SHARD_COSTS.size():
		return
	var shard_count = 0
	var shard_idx = -1
	for i in range(dharma_shards.size()):
		if dharma_shards[i].grade == grade:
			shard_count = dharma_shards[i].count
			shard_idx = i
			break
	var needed = DHARMA_SHARD_COSTS[grade]
	if shard_count < needed:
		log_message("[color=red]碎片不足！需要" + str(needed) + "个，当前只有" + str(shard_count) + "个[/color]")
		return
	dharma_shards[shard_idx].count -= needed
	if dharma_shards[shard_idx].count <= 0:
		dharma_shards.remove_at(shard_idx)
	var available = []
	for d in DHARMA_DEFS:
		var already_have = false
		for owned in dharma_inventory:
			if owned.id == d.id:
				already_have = true
				break
		if not already_have:
			available.append(d)
	if available.is_empty():
		spiritual_energy += needed * 10
		log_message("[color=yellow]所有法相已拥有，碎片转化为" + str(needed * 10) + "灵气[/color]")
	else:
		var chosen = available[randi() % available.size()]
		var grade_data = chosen.grades[grade]
		var new_dharma = {
			'id': chosen.id,
			'name': chosen.name,
			'desc': chosen.desc,
			'grade': grade,
			'atk': grade_data.atk,
			'def': grade_data.def,
			'hp': grade_data.hp,
			'mana_pct': grade_data.mana_pct,
			'source': 'shard',
			'level': 1,
			'stars': 0,
		}
		dharma_inventory.append(new_dharma)
		var grade_name = DHARMA_GRADE_NAMES[grade]
		var color = DHARMA_GRADE_COLORS[grade]
		log_message("[color=#" + color.to_html(false) + "]◆ 法相合成成功！获得[" + grade_name + "级]" + chosen.name + "[/color]")
	recalc_dharma_bonuses()
	if $PanelDharma.visible:
		_refresh_dharma()

func _add_dharma_shard(grade: int):
	if grade < 0 or grade >= DHARMA_SHARD_COSTS.size():
		return
	for i in range(dharma_shards.size()):
		if dharma_shards[i].grade == grade:
			dharma_shards[i].count += 1
			return
	dharma_shards.append({'grade': grade, 'count': 1})

func _try_drop_dharma_shard():
	if not dharma_unlocked:
		return
	if randf() > 0.12:
		return
	var grade_weights = [0.45, 0.25, 0.15, 0.08, 0.04, 0.02, 0.01]
	var r = randf()
	var cumulative = 0.0
	var grade = 0
	for i in range(grade_weights.size()):
		cumulative += grade_weights[i]
		if r <= cumulative:
			grade = i
			break
	_add_dharma_shard(grade)
	var grade_name = DHARMA_GRADE_NAMES[grade]
	var color = DHARMA_GRADE_COLORS[grade]
	log_message("[color=#" + color.to_html(false) + "]◇ 获得法相碎片[" + grade_name + "级]×1[/color]")

func _on_buy_dharma_shard(grade: int):
	if grade < 0 or grade >= DHARMA_GRADE_NAMES.size():
		return
	var price = int(pow(3, grade + 1) * 50)
	if spiritual_energy < price:
		log_message("[color=red]灵气不足，无法购买法相碎片[/color]")
		_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
		return
	spiritual_energy -= price
	_add_dharma_shard(grade)
	var grade_name = DHARMA_GRADE_NAMES[grade]
	log_message("[color=green]购买了法相碎片[" + grade_name + "级]×1，花费" + _format_num(price) + "灵气[/color]")
	if $PanelDharma.visible:
		_refresh_dharma()

func _on_upgrade_dharma(dharma_id: String):
	for dharma in dharma_inventory:
		if dharma.id == dharma_id:
			var max_lv = get_dharma_max_level()
			var current_lv = dharma.get('level', 1)
			if current_lv >= max_lv:
				log_message("[color=red]已达当前境界等级上限 Lv." + str(max_lv) + "[/color]")
				return
			var cost = get_dharma_upgrade_cost(dharma)
			if spiritual_energy < cost:
				log_message("[color=red]灵气不足，升级需要" + _format_num(cost) + "灵气[/color]")
				_show_toast("灵气不足", Color(1.0, 0.4, 0.4))
				return
			spiritual_energy -= cost
			dharma['level'] = current_lv + 1
			log_message("[color=cyan]" + dharma.name + " 升至 Lv." + str(dharma.level) + "[/color]")
			if active_dharma_id == dharma_id:
				recalc_dharma_bonuses()
				recalc_mana_per_sec()
				update_max_hp()
			if $PanelDharma.visible:
				_refresh_dharma()
			return

func _on_star_up_dharma(dharma_id: String):
	for dharma in dharma_inventory:
		if dharma.id == dharma_id:
			var stars = dharma.get('stars', 0)
			if stars >= DHARMA_MAX_STARS:
				log_message("[color=red]已达满星，无法继续升星[/color]")
				return
			var grade = dharma.get('grade', 0)
			var cost = DHARMA_SHARD_COSTS[grade] * (stars + 1)
			var shard_count = 0
			var shard_idx = -1
			for i in range(dharma_shards.size()):
				if dharma_shards[i].grade == grade:
					shard_count = dharma_shards[i].count
					shard_idx = i
					break
			if shard_count < cost:
				log_message("[color=red]碎片不足！升星需要" + str(cost) + "个[" + DHARMA_GRADE_NAMES[grade] + "级碎片]，当前只有" + str(shard_count) + "个[/color]")
				return
			dharma_shards[shard_idx].count -= cost
			if dharma_shards[shard_idx].count <= 0:
				dharma_shards.remove_at(shard_idx)
			dharma['stars'] = stars + 1
			var def_d = _get_dharma_def(dharma_id)
			var affix_text = def_d.get('star_affixes', [])[stars] if not def_d.is_empty() and def_d.has('star_affixes') and stars < def_d.star_affixes.size() else ""
			log_message("[color=#ffaa00]◆ " + dharma.name + " 升星成功！★" + str(dharma.stars) + "[/color]")
			if affix_text != "":
				log_message("[color=#ffcc00]  解锁词条：" + affix_text + "[/color]")
			if dharma.stars >= DHARMA_MAX_STARS:
				log_message("[color=#ff4444]◆ 满星达成！终极法相形态解锁！[/color]")
			if active_dharma_id == dharma_id:
				recalc_dharma_bonuses()
				recalc_mana_per_sec()
				update_max_hp()
			else:
				recalc_bond_bonuses()
				recalc_mana_per_sec()
			if $PanelDharma.visible:
				_refresh_dharma()
			return
