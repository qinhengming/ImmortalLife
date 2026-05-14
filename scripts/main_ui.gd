extends Control

var spiritual_energy: float = 0.0
var mana_per_sec: float = 10.0
var realm: String = '练气一层'
var realm_level: int = 1
var offline_earnings: float = 0.0
var save_timer: float = 0.0
var max_log_lines: int = 100

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
var cave_multiplier: float = 1.0
var artifact_multiplier: float = 1.0
var time_coefficient: float = 1.0
var pill_flat_bonus: float = 0.0
var cave_level: int = 1
var cave_buildings: Dictionary = {}
var cave_base_bonus: float = 0.0

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
var current_map: Dictionary = {}
var battle_log: String = ""
var companions_unlocked: Array = []

const COMPANION_DEFS = [
	{'id': 'sword_servant', 'name': '剑侍', 'unlock_realm': 2, 'base_hp': 50, 'base_atk': 8, 'base_def': 4, 'color': Color(0.3, 0.8, 0.5)},
	{'id': 'formation_spirit', 'name': '阵灵', 'unlock_realm': 10, 'base_hp': 80, 'base_atk': 12, 'base_def': 8, 'color': Color(0.5, 0.5, 1.0)},
	{'id': 'pill_child', 'name': '丹童', 'unlock_realm': 18, 'base_hp': 60, 'base_atk': 10, 'base_def': 6, 'color': Color(0.3, 1.0, 0.7)},
	{'id': 'dharma_protector', 'name': '护法', 'unlock_realm': 37, 'base_hp': 150, 'base_atk': 20, 'base_def': 15, 'color': Color(1.0, 0.5, 0.3)},
	{'id': 'dao_partner', 'name': '道侣', 'unlock_realm': 28, 'base_hp': 200, 'base_atk': 30, 'base_def': 20, 'color': Color(1.0, 0.3, 0.7)},
]
var equipped_items = {
	'weapon': null,
	'armor': null,
	'accessory': null,
	'artifact': null
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
	{'name': '布衣', 'desc': '粗布衣裳', 'price': 80, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 3, 'mana_bonus': 0},
	{'name': '铁甲', 'desc': '铸铁铠甲', 'price': 400, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 10, 'mana_bonus': 0},
	{'name': '金蚕丝甲', 'desc': '刀枪不入', 'price': 2500, 'slot': 'armor', 'atk_bonus': 0, 'def_bonus': 30, 'mana_bonus': 1},
	{'name': '灵玉佩', 'desc': '温养灵气', 'price': 300, 'slot': 'accessory', 'atk_bonus': 0, 'def_bonus': 0, 'mana_bonus': 2},
	{'name': '聚灵珠', 'desc': '汇聚灵气', 'price': 2000, 'slot': 'accessory', 'atk_bonus': 0, 'def_bonus': 0, 'mana_bonus': 8},
	{'name': '拂尘', 'desc': '道家法器', 'price': 200, 'slot': 'artifact', 'atk_bonus': 3, 'def_bonus': 2, 'mana_bonus': 1, 'mana_bonus_pct': 0.10},
	{'name': '八卦镜', 'desc': '镇邪驱魔', 'price': 1500, 'slot': 'artifact', 'atk_bonus': 10, 'def_bonus': 10, 'mana_bonus': 3, 'mana_bonus_pct': 0.30},
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

const EQUIPMENT_SLOTS = ['weapon', 'armor', 'accessory', 'artifact']
const EQUIPMENT_SLOT_NAMES = {'weapon': '武器', 'armor': '防具', 'accessory': '饰品', 'artifact': '法宝'}

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
			var cost = int(macro['cost_start'] * pow(macro['cost_growth'], lv))
			var mana_bonus = hp * 0.01
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
	var atk = get_realm_atk_bonus() + get_technique_atk_bonus()
	for s in EQUIPMENT_SLOTS:
		var ei = equipped_items[s]
		if ei != null:
			atk += ei['atk_bonus']
	var bh_lv = talents.get('battle_hardened', 0)
	atk *= 1.0 + 0.10 * bh_lv
	atk *= 1.0 + get_active_array_bonus('atk_pct')
	return atk

func get_player_def() -> float:
	var def = get_realm_def_bonus() + get_technique_def_bonus()
	for s in EQUIPMENT_SLOTS:
		var ei = equipped_items[s]
		if ei != null:
			def += ei['def_bonus']
	def *= 1.0 + get_active_array_bonus('def_pct')
	return def

func update_max_hp():
	player_max_hp = (100.0 + get_realm_hp_bonus() + get_technique_hp_bonus()) * (1.0 + get_active_array_bonus('hp_pct'))
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
	comprehension_progress += delta * lib_bonus * (1.0 + array_comprehension_bonus)
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
	var s = str(int(n))
	var result = ""
	for i in range(s.length()):
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return result

const BIG_UNITS = ['', '万', '亿', '兆', '京', '垓', '秭', '穰', '沟', '涧', '正', '载', '极']

func _format_big(n: float) -> String:
	if n < 10000:
		return _format_num(n)
	var val = n
	var unit_idx = 0
	while val >= 10000 and unit_idx < BIG_UNITS.size() - 1:
		val /= 10000.0
		unit_idx += 1
	if val >= 10000:
		val /= 10000.0
		unit_idx += 1
	var s = str(val)
	var dot = s.find(".")
	if dot > 0:
		if dot >= 4:
			s = s.substr(0, 4)
		else:
			s = s.substr(0, min(s.length(), dot + 2))
	else:
		if s.length() > 4:
			s = s.substr(0, 4)
	return s + BIG_UNITS[unit_idx]

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
	load_save()
	if spirit_root.is_empty():
		spirit_root = SPIRIT_ROOTS[randi() % SPIRIT_ROOTS.size()]
		var root_c = spirit_root['color'].to_html(false)
		log_message("[color=#" + root_c + "]灵根觉醒：" + spirit_root['name'] + " —— " + spirit_root['desc'] + "[/color]")
	if player_name == "":
		player_name = SURNAMES[randi() % SURNAMES.size()] + GIVEN_NAMES[randi() % GIVEN_NAMES.size()]
	recalc_realm_multiplier()
	recalc_technique_multiplier()
	recalc_artifact_multiplier()
	recalc_mana_per_sec()
	update_max_hp()
	log_message("[color=green]游戏启动，欢迎回来！[/color]")
	calc_offline_earnings()
	# 初始化洞府建筑
	if cave_buildings.is_empty():
		for bid in $PanelCave.BUILDING_DEFS:
			var init_unlocked = $PanelCave.BUILDING_DEFS[bid].init_unlocked
			cave_buildings[bid] = {'level': 0, 'unlocked': init_unlocked}
	recalc_cave_bonuses()
	recalc_mana_per_sec()
	# 初始化天赋
	if talents.is_empty():
		for tid in TALENT_DEFS:
			talents[tid] = 0
	recalc_talent_bonuses()
	recalc_mana_per_sec()
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
	$PanelCave.upgrade_cave_requested.connect(_on_cave_upgrade)
	$PanelCave.building_action_requested.connect(_on_building_action)
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
	add_child(panel_help)
	panel_help.back_requested.connect(_on_back)
	# 绑定菜单按钮
	$MenuBar/BtnProfile.pressed.connect(_on_btn_profile)
	$MenuBar/BtnSkills.pressed.connect(_on_btn_skills)
	$MenuBar/BtnInventory.pressed.connect(_on_btn_inventory)
	$MenuBar/BtnShop.pressed.connect(_on_btn_shop)
	$MenuBar/BtnCave.pressed.connect(_on_btn_cave)
	$MenuBar/BtnTalents.pressed.connect(_on_btn_talents)
	$MenuBar/BtnEquipment.pressed.connect(_on_btn_equipment)
	$MenuBar/BtnMap.pressed.connect(_on_btn_map)
	# 动态添加帮助按钮
	var btn_help = Button.new()
	btn_help.text = "帮助"
	btn_help.add_theme_font_size_override("font_size", 12)
	btn_help.pressed.connect(_on_btn_help)
	$MenuBar.add_child(btn_help)
	show_panel("")

# ==================== 存档 ====================

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST:
		save_game()

func save_game():
	var data = {
		'save_version': 3,
		'spiritual_energy': spiritual_energy,
		'mana_per_sec': mana_per_sec,
		'base_mana': base_mana,
		'realm_multiplier': realm_multiplier,
		'technique_multiplier': technique_multiplier,
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
		'reincarnation_count': reincarnation_count,
		'enlightenment_points': enlightenment_points,
		'talents': talents,
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
	base_mana = data.get('base_mana', 10.0)
	realm_multiplier = data.get('realm_multiplier', 1.0)
	technique_multiplier = data.get('technique_multiplier', 1.0)
	cave_multiplier = data.get('cave_multiplier', 1.0)
	artifact_multiplier = data.get('artifact_multiplier', 1.0)
	time_coefficient = data.get('time_coefficient', 1.0)
	pill_flat_bonus = data.get('pill_flat_bonus', 0.0)
	cave_level = data.get('cave_level', 1)
	cave_buildings = data.get('cave_buildings', {})
	reincarnation_count = data.get('reincarnation_count', 0)
	enlightenment_points = data.get('enlightenment_points', 0)
	talents = data.get('talents', {})
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
		log_message("[color=cyan]离线收益：" + str(int(offline_earnings)) + " 灵气（离线 " + str(int(elapsed)) + " 秒）[/color]")
		while try_breakthrough():
			pass

# ==================== 主循环 ====================

func _process(delta: float):
	pending_energy += mana_per_sec * delta
	try_breakthrough()
	update_ui()
	age_timer += delta
	if age_timer >= 300.0:
		age_timer = 0.0
		age += 1
	_process_comprehension(delta)
	_process_meditation(delta)
	save_timer += delta
	if save_timer >= 60.0:
		save_timer = 0.0
		save_game()
	_process_battle(delta)
	if tooltip_node and tooltip_node.visible:
		var mp = get_global_mouse_position()
		tooltip_node.position = Vector2(mp.x + 12, mp.y + 12)

func try_breakthrough() -> bool:
	if realm_level >= realms.size():
		return false
	var next = realms[realm_level]
	if spiritual_energy >= next['cost']:
		spiritual_energy -= next['cost']
		realm_level += 1
		realm = next['name']
		recalc_realm_multiplier()
		recalc_mana_per_sec()
		var realm_c = get_realm_color().to_html(false)
		log_message("[color=#" + realm_c + "]◆ 突破成功！当前境界：" + realm + "[/color]")
		return true
	return false

func get_next_realm_cost() -> int:
	if realm_level >= realms.size():
		return -1
	var cost = realms[realm_level]['cost']
	var if_lv = talents.get('immortal_fortune', 0)
	var reduction = 0.05 * if_lv
	cost = int(cost * (1.0 - reduction))
	return max(1, cost)

# ==================== 乘区计算 ====================

func recalc_mana_per_sec():
	var array_flat = get_active_array_bonus('mana_flat')
	var realm_mana = get_realm_mana_bonus()
	mana_per_sec = (base_mana + realm_mana + cave_base_bonus + talent_mana_bonus + array_flat) * realm_multiplier * technique_multiplier * cave_multiplier * artifact_multiplier * time_coefficient * talent_multiplier + pill_flat_bonus

func recalc_realm_multiplier():
	var sum = 0.0
	for i in range(realm_level):
		sum += realms[i].get('mana_bonus_pct', 0.0)
	realm_multiplier = 1.0 + sum

func recalc_technique_multiplier():
	var skill_sum = get_technique_mana_pct()
	var comp_mult = get_technique_comprehension_mult()
	technique_multiplier = spirit_root.get('bonus', 1.0) * (1.0 + skill_sum) * comp_mult

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

func update_ui():
	$Label.text = "灵气：" + _format_big(spiritual_energy)
	$Label2.text = "每秒灵气：" + _format_big(mana_per_sec)
	$Label3.text = "境界：" + realm
	$Label3.add_theme_color_override("font_color", get_realm_color())
	$Label4.text = "突破所需：" + (_format_big(get_next_realm_cost()) if get_next_realm_cost() > 0 else "已达最高境界")
	$Label5.text = "HP：" + _format_big(player_hp) + "/" + _format_big(player_max_hp)

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
	$PanelHelp.visible = (panel_name == "help")
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
		'cave_multiplier': cave_multiplier,
		'artifact_multiplier': artifact_multiplier,
		'time_coefficient': time_coefficient,
		'pill_flat_bonus': pill_flat_bonus,
		'player_hp': player_hp,
		'player_max_hp': player_max_hp,
		'reincarnation_clickable': realm_level >= 19 and realm_level < realms.size(),
		'player_atk': get_player_atk(),
		'player_def': get_player_def(),
		'spirit_roots_list': SPIRIT_ROOTS,
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
		return
	if spiritual_energy < skill['price']:
		log_message("[color=red]灵气不足，无法购买" + skill_name + "[/color]")
		return
	spiritual_energy -= skill['price']
	inventory.append(tid)
	log_message("[color=green]购买成功：" + skill_name + "[/color]")
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
		return
	spiritual_energy -= recipe['price']
	recipe_inventory.append(recipe.duplicate())
	log_message("[color=green]购买丹方秘笈：" + recipe_name + "，已放入背包[/color]")
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
		return
	spiritual_energy -= item['price']
	equipment_inventory.append(item.duplicate())
	log_message("[color=green]购买成功：" + item['name'] + "，已放入背包，请在背包中装备[/color]")
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
		return
	if spiritual_energy < furnace['price']:
		log_message("[color=red]灵气不足，无法购买" + fname + "[/color]")
		return
	spiritual_energy -= furnace['price']
	furnace_inventory.append(furnace.duplicate())
	log_message("[color=green]购买成功：" + fname + "，已放入背包[/color]")
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
		return
	if spiritual_energy < array_data['price']:
		log_message("[color=red]灵气不足，无法购买" + array_name + "[/color]")
		return
	spiritual_energy -= array_data['price']
	array_inventory.append(array_name)
	log_message("[color=green]购买阵法秘笈：" + array_name + "，已放入背包[/color]")
	if $PanelShop.visible: _refresh_shop()
	if $PanelInventory.visible: _refresh_inventory()

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
	panel.set_state(cave_level, cave_buildings, spiritual_energy, realm_level, learned_recipes, pill_inventory, learned_arrays, active_array, shop_arrays, furnace_inventory, equipped_furnaces)
	panel.refresh()

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
	var cost = 5000 * int(pow(2, cave_level))
	if spiritual_energy < cost:
		log_message("[color=red]灵气不足，无法升级洞府！[/color]")
		return
	spiritual_energy -= cost
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

	if spiritual_energy < cost:
		log_message("[color=red]灵气不足！[/color]")
		return

	if not unlocked:
		if realm_level < defs.unlock_realm:
			var realm_name = realms[defs.unlock_realm - 1]['name']
			log_message("[color=red]境界不足！需要达到" + realm_name + "才能解锁" + defs.name + "[/color]")
			return
		building.unlocked = true
		building.level = 1
		log_message("[color=green]解锁" + defs.name + "！[/color]")
	elif level < defs.max_level:
		building.level += 1
		log_message("[color=cyan]" + defs.name + "升至 " + str(building.level) + " 级[/color]")
	else:
		return

	spiritual_energy -= cost
	recalc_cave_bonuses()
	recalc_mana_per_sec()
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
				log_message("[color=red]炼制失败！" + recipe_name + " 炼制失败（成功率" + str(int(success_chance * 100)) + "%），材料损耗[/color]")
			else:
				if pill_inventory.has(recipe_name):
					pill_inventory[recipe_name] += 1
				else:
					pill_inventory[recipe_name] = 1
				log_message("[color=green]炼制成功：" + recipe_name + "（减免后消耗" + str(actual_cost) + "灵）[/color]")
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

func start_battle(map: Dictionary):
	current_map = map
	in_battle = true
	battle_timer = 0.0
	battle_log = ""
	update_max_hp()
	player_hp = player_max_hp
	build_ally_team()
	spawn_enemy_team()
	show_panel("map")
	_refresh_map()
	log_message("[color=yellow]进入" + map['name'] + "开始历练！我方" + str(get_alive_ally_count()) + "人 vs 敌方" + str(get_alive_enemy_count()) + "人[/color]")

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
	battle_log = ""
	player_hp = player_max_hp
	log_message("[color=gray]停止历练，已恢复HP[/color]")
	_refresh_map()

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
		target.hp -= dmg
		log_lines.append("[color=#88ff88]" + ally.name + "[/color] 攻击 [color=#ff8888]" + target.name + "[/color]，造成 " + str(dmg) + " 点伤害")
		if target.hp <= 0:
			target.hp = 0
			target.alive = false
			log_lines.append("[color=yellow]◆ 击杀 " + target.name + "！获得 " + str(target.exp) + " 灵气[/color]")
			spiritual_energy += target.exp
			log_message("[color=green]击杀" + target.name + "！获得 " + str(target.exp) + " 灵气[/color]")
	
	# 检查敌方是否全灭 → 刷新敌人
	if get_alive_enemy_count() == 0:
		log_lines.append("[color=cyan]◇ 敌方全灭！新一波敌人出现[/color]")
		spawn_enemy_team()
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
	var enemy_scale = 1.0 + (realm_level - current_map['min_level']) * 0.15
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
		'armor': null,
		'accessory': null,
		'artifact': null
	}
	equipment_inventory = []
	furnace_inventory = []
	equipped_furnaces = []
	player_hp = 100.0
	player_max_hp = 100.0

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
