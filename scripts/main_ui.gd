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

# 丹药背包 {丹药名: 数量}
var pill_inventory: Dictionary = {}

# 商店功法列表
var shop_skills = [
	{'name': '吐纳术', 'desc': '基础修炼功法，修炼速度x1.1', 'price': 50, 'mana_bonus': 1.0, 'mana_bonus_pct': 0.10, 'min_realm': 1, 'color': Color(0.20, 0.85, 0.55)},
	{'name': '聚灵诀', 'desc': '汇聚天地灵气，修炼速度x1.3', 'price': 200, 'mana_bonus': 3.0, 'mana_bonus_pct': 0.30, 'min_realm': 2, 'color': Color(0.15, 0.80, 0.55)},
	{'name': '御风诀', 'desc': '风属性功法，修炼速度x1.5', 'price': 800, 'mana_bonus': 5.0, 'mana_bonus_pct': 0.50, 'min_realm': 3, 'color': Color(0.10, 0.75, 0.55)},
	{'name': '焚天决', 'desc': '火属性功法，修炼速度x2.0', 'price': 3000, 'mana_bonus': 10.0, 'mana_bonus_pct': 1.00, 'min_realm': 4, 'color': Color(0.45, 0.75, 0.95)},
	{'name': '冰心诀', 'desc': '冰属性功法，修炼速度x3.0', 'price': 10000, 'mana_bonus': 20.0, 'mana_bonus_pct': 2.00, 'min_realm': 7, 'color': Color(1.00, 0.85, 0.25)},
	{'name': '天罡功', 'desc': '雷属性功法，修炼速度x6.0', 'price': 50000, 'mana_bonus': 50.0, 'mana_bonus_pct': 5.00, 'min_realm': 10, 'color': Color(0.75, 0.45, 0.95)},
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
		"price": 3000, "min_realm": 4,
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
		"price": 10000, "min_realm": 7,
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
		"price": 50000, "min_realm": 10,
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

# 境界列表，按顺序排列
var realms = [
	{'name': '练气一层', 'cost': 100, 'mana_bonus': 0.5, 'mana_bonus_pct': 0.05, 'color': Color(0.20, 0.85, 0.55)},
	{'name': '练气二层', 'cost': 300, 'mana_bonus': 0.5, 'mana_bonus_pct': 0.05, 'color': Color(0.15, 0.80, 0.55)},
	{'name': '练气三层', 'cost': 800, 'mana_bonus': 1.0, 'mana_bonus_pct': 0.10, 'color': Color(0.10, 0.75, 0.55)},
	{'name': '筑基初期', 'cost': 2000, 'mana_bonus': 2.0, 'mana_bonus_pct': 0.20, 'color': Color(0.45, 0.75, 0.95)},
	{'name': '筑基中期', 'cost': 5000, 'mana_bonus': 3.0, 'mana_bonus_pct': 0.30, 'color': Color(0.35, 0.70, 0.95)},
	{'name': '筑基后期', 'cost': 12000, 'mana_bonus': 5.0, 'mana_bonus_pct': 0.50, 'color': Color(0.25, 0.65, 0.95)},
	{'name': '金丹初期', 'cost': 30000, 'mana_bonus': 10.0, 'mana_bonus_pct': 1.00, 'color': Color(1.00, 0.85, 0.25)},
	{'name': '金丹中期', 'cost': 80000, 'mana_bonus': 15.0, 'mana_bonus_pct': 1.50, 'color': Color(1.00, 0.78, 0.15)},
	{'name': '金丹后期', 'cost': 200000, 'mana_bonus': 25.0, 'mana_bonus_pct': 2.50, 'color': Color(1.00, 0.70, 0.05)},
	{'name': '元婴初期', 'cost': 500000, 'mana_bonus': 50.0, 'mana_bonus_pct': 5.00, 'color': Color(0.75, 0.45, 0.95)},
	{'name': '元婴中期', 'cost': 1500000, 'mana_bonus': 80.0, 'mana_bonus_pct': 8.00, 'color': Color(0.70, 0.35, 0.95)},
	{'name': '元婴后期', 'cost': 5000000, 'mana_bonus': 130.0, 'mana_bonus_pct': 13.00, 'color': Color(0.65, 0.25, 0.95)},
	{'name': '化神初期', 'cost': 15000000, 'mana_bonus': 200.0, 'mana_bonus_pct': 20.00, 'color': Color(0.30, 0.55, 1.00)},
	{'name': '化神中期', 'cost': 50000000, 'mana_bonus': 350.0, 'mana_bonus_pct': 35.00, 'color': Color(0.22, 0.45, 1.00)},
	{'name': '化神后期', 'cost': 150000000, 'mana_bonus': 600.0, 'mana_bonus_pct': 60.00, 'color': Color(0.15, 0.35, 1.00)},
	{'name': '合体初期', 'cost': 500000000, 'mana_bonus': 1000.0, 'mana_bonus_pct': 100.00, 'color': Color(1.00, 0.55, 0.20)},
	{'name': '合体中期', 'cost': 2000000000, 'mana_bonus': 1800.0, 'mana_bonus_pct': 180.00, 'color': Color(1.00, 0.45, 0.10)},
	{'name': '合体后期', 'cost': 8000000000, 'mana_bonus': 3000.0, 'mana_bonus_pct': 300.00, 'color': Color(0.95, 0.35, 0.05)},
	{'name': '大乘初期', 'cost': 30000000000, 'mana_bonus': 5000.0, 'mana_bonus_pct': 500.00, 'color': Color(1.00, 0.25, 0.35)},
	{'name': '大乘中期', 'cost': 100000000000, 'mana_bonus': 9000.0, 'mana_bonus_pct': 900.00, 'color': Color(0.95, 0.15, 0.25)},
	{'name': '大乘后期', 'cost': 500000000000, 'mana_bonus': 15000.0, 'mana_bonus_pct': 1500.00, 'color': Color(0.90, 0.05, 0.20)},
	{'name': '渡劫期', 'cost': 2000000000000, 'mana_bonus': 30000.0, 'mana_bonus_pct': 3000.00, 'color': Color(1.00, 0.92, 0.55)},
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

# ==================== 核心辅助函数 ====================

func get_player_atk() -> float:
	var atk = realm_level * 15.0 + get_technique_atk_bonus()
	for s in EQUIPMENT_SLOTS:
		var ei = equipped_items[s]
		if ei != null:
			atk += ei['atk_bonus']
	var bh_lv = talents.get('battle_hardened', 0)
	atk *= 1.0 + 0.10 * bh_lv
	return atk

func get_player_def() -> float:
	var def = realm_level * 10.0 + get_technique_def_bonus()
	for s in EQUIPMENT_SLOTS:
		var ei = equipped_items[s]
		if ei != null:
			def += ei['def_bonus']
	return def

func update_max_hp():
	player_max_hp = 100.0 + realm_level * 50.0 + get_technique_hp_bonus()
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
	comprehension_progress += delta * lib_bonus
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
	$PanelShop.back_requested.connect(_on_back)
	$PanelShop.buy_skill_requested.connect(_on_buy_skill)
	$PanelShop.buy_recipe_requested.connect(_on_buy_recipe)
	$PanelShop.buy_equipment_requested.connect(_on_buy_equipment)
	$PanelCave.upgrade_cave_requested.connect(_on_cave_upgrade)
	$PanelCave.building_action_requested.connect(_on_building_action)
	$PanelCave.craft_pill_requested.connect(_on_craft_pill_by_name)
	$PanelCave.use_pill_requested.connect(_on_use_pill)
	$PanelCave.back_requested.connect(_on_back)
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
	# 绑定菜单按钮
	$MenuBar/BtnProfile.pressed.connect(_on_btn_profile)
	$MenuBar/BtnSkills.pressed.connect(_on_btn_skills)
	$MenuBar/BtnInventory.pressed.connect(_on_btn_inventory)
	$MenuBar/BtnShop.pressed.connect(_on_btn_shop)
	$MenuBar/BtnCave.pressed.connect(_on_btn_cave)
	$MenuBar/BtnTalents.pressed.connect(_on_btn_talents)
	$MenuBar/BtnEquipment.pressed.connect(_on_btn_equipment)
	$MenuBar/BtnMap.pressed.connect(_on_btn_map)
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
		'player_name': player_name,
		'spirit_root': spirit_root,
		'age': age,
		'equipped_items': equipped_items,
		'equipment_inventory': equipment_inventory,
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
	mana_per_sec = (base_mana + cave_base_bonus + talent_mana_bonus) * realm_multiplier * technique_multiplier * cave_multiplier * artifact_multiplier * time_coefficient * talent_multiplier + pill_flat_bonus

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
	var lines = $MessageLog.get_line_count()
	if lines > max_log_lines:
		$MessageLog.remove_line(0)

func update_ui():
	$Label.text = "灵气：" + str(int(spiritual_energy))
	$Label2.text = "每秒灵气：" + str(int(mana_per_sec))
	$Label3.text = "境界：" + realm
	$Label3.add_theme_color_override("font_color", get_realm_color())
	$Label4.text = "突破所需：" + (str(get_next_realm_cost()) if get_next_realm_cost() > 0 else "已达最高境界")
	$Label5.text = "HP：" + str(int(player_hp)) + "/" + str(int(player_max_hp))

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
		'realm_multiplier': realm_multiplier,
		'technique_multiplier': technique_multiplier,
		'cave_multiplier': cave_multiplier,
		'artifact_multiplier': artifact_multiplier,
		'time_coefficient': time_coefficient,
		'pill_flat_bonus': pill_flat_bonus,
		'player_hp': player_hp,
		'player_max_hp': player_max_hp,
		'reincarnation_clickable': realm_level >= 10 and realm_level < realms.size(),
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
		'shop_skills': shop_skills,
		'shop_recipes': shop_recipes,
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
		'learned_techniques': learned_techniques,
		'learned_recipes': learned_recipes,
		'equipped_items': equipped_items,
		'equipment_inventory': equipment_inventory,
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
		'current_enemy': current_enemy,
		'player_hp': player_hp,
		'player_max_hp': player_max_hp,
		'player_atk': get_player_atk(),
		'player_def': get_player_def(),
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
	if is_recipe_learned(recipe['name']):
		log_message("[color=red]已学会丹方" + recipe['name'] + "，无需重复购买[/color]")
		return
	if spiritual_energy < recipe['price']:
		log_message("[color=red]灵气不足，无法购买丹方" + recipe['name'] + "[/color]")
		return
	spiritual_energy -= recipe['price']
	learned_recipes.append(recipe)
	log_message("[color=green]购买丹方成功：" + recipe['name'] + "[/color]")
	if $PanelShop.visible: _refresh_shop()

func _on_buy_equipment(item: Dictionary):
	if spiritual_energy < item['price']:
		log_message("[color=red]灵气不足，无法购买" + item['name'] + "[/color]")
		return
	spiritual_energy -= item['price']
	equipment_inventory.append(item.duplicate())
	log_message("[color=green]购买成功：" + item['name'] + "，已放入背包，请在背包中装备[/color]")
	if $PanelShop.visible: _refresh_shop()
	if $PanelInventory.visible: _refresh_inventory()

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

# ==================== 洞府 ====================

func refresh_cave():
	var panel = $PanelCave
	panel.set_state(cave_level, cave_buildings, spiritual_energy, realm_level, learned_recipes, pill_inventory)
	panel.refresh()

func recalc_cave_bonuses():
	var array_lv = cave_buildings.get('spirit_array', {}).get('level', 0)
	cave_multiplier = 1.0 + 0.1 * array_lv
	var room_lv = cave_buildings.get('cultivation_room', {}).get('level', 0)
	cave_base_bonus = room_lv * 1.0

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
			var furnace_lv = cave_buildings.get('alchemy_furnace', {}).get('level', 0)
			var cost_mult = 1.0 - furnace_lv * 0.05
			var actual_cost = int(recipe['craft_cost'] * cost_mult)

			if spiritual_energy < actual_cost:
				log_message("[color=red]灵气不足，无法炼制" + recipe_name + "[/color]")
				return
			spiritual_energy -= actual_cost
			if pill_inventory.has(recipe_name):
				pill_inventory[recipe_name] += 1
			else:
				pill_inventory[recipe_name] = 1
			log_message("[color=green]炼制成功：" + recipe_name + "（炼丹炉减免后消耗" + str(actual_cost) + "灵）[/color]")
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
	spawn_enemy()
	show_panel("map")
	_refresh_map()
	log_message("[color=yellow]进入" + map['name'] + "开始历练！[/color]")

func spawn_enemy():
	var template = current_map['enemies'][randi() % current_map['enemies'].size()]
	var enemy_scale = 1.0 + (realm_level - current_map['min_level']) * 0.15
	current_enemy = {
		'name': template['name'],
		'hp': template['hp'] * enemy_scale,
		'max_hp': template['hp'] * enemy_scale,
		'atk': template['atk'] * enemy_scale,
		'def': template['def'] * enemy_scale,
		'exp': int(template['exp'] * enemy_scale),
	}

func stop_battle():
	in_battle = false
	current_enemy = {}
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
	var damage = max(1, int(get_player_atk() - current_enemy['def'] + randi_range(-2, 2)))
	current_enemy['hp'] -= damage
	battle_log = "你对" + current_enemy['name'] + "造成 " + str(damage) + " 点伤害"

	if current_enemy['hp'] <= 0:
		spiritual_energy += current_enemy['exp']
		battle_log = "击杀了" + current_enemy['name'] + "，获得 " + str(current_enemy['exp']) + " 灵气"
		log_message("[color=green]击杀" + current_enemy['name'] + "！获得 " + str(current_enemy['exp']) + " 灵气[/color]")
		spawn_enemy()
		if $PanelMap.visible:
			_refresh_map()

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
	var gained = 1 + floor(realm_level / 3.0)
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
	pill_inventory = {}
	equipped_items = {
		'weapon': null,
		'armor': null,
		'accessory': null,
		'artifact': null
	}
	equipment_inventory = []
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
