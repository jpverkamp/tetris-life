extends Node2D

var types = []
var colors = {}

var custom_keywords = []
var keywords = {
	'void': [],
	'blocky': [],
	'colorful': [],
	'falling': [],
	'spreading': [],
	'rising': [],
	'growing': []
}

var reactions = {
	'decay': {},
	'grow': {},
	'spawn': {},
	'neighbor': {},
	'self': {},
}

var difficulties = {
	'easy': {
		'target': 50, 'blocks': 1, 'speed': 0.5,
		'spawns': {'wall': 2, 'sand': 4, 'water': 4, 'empty': 2},
		'variables': {'plantgrowth': 0.01}
	},
	'medium': {
		'target': 25, 'blocks': 1, 'speed': 0.5,
		'spawns': {'wall': 2, 'sand': 2, 'water': 2, 'empty': 1, 'lava': 1},
		'variables': {'plantgrowth': 0.05}
	},
	'hard': {
		'target': 0, 'blocks': 1, 'speed': 1.0,
		'spawns': {'wall': 2, 'sand': 2, 'water': 2, 'empty': 2, 'lava': 2, 'acid': 1},
		'variables': {'plantgrowth': 0.001}
	},
	'insane': {
		'target': 0, 'blocks': 2, 'speed': 1.0,
		'spawns': {'wall': 2, 'sand': 2, 'water': 1, 'lava': 2, 'acid': 2},
		'variables': {'plantgrowth': 0.001}
	}
}

var physics = {
	'impulse': Vector2(25, 0),
	'gravity': Vector2(0, 100),
	'torque': 100,
	'lock_time': 0.1,
	'minimum_speed': 5.0
}

func define_type(name, colors, keywords, reactions = []):
	assert(not name in types)
	self.types.append(name)
	
	if colors is Color: colors = [colors]
	self.colors[name] = colors
	
	for keyword in keywords:
		if not keyword in self.keywords:
			self.keywords[keyword] = []
			self.custom_keywords.append(keyword)
			
		self.keywords[keyword].append(name)
	
	for reaction in reactions:
		var chance = 1.0
		var reagents = []
		var products = []
		
		# If we have parameters, parse those first
		if '(' in reaction:
			var parameters = reaction.split('(')[1].rstrip(')')
			reaction = reaction.split('(')[0]
			
		# If we have a chance, split that off
		if '@' in reaction:
			chance = reaction.split('@')[1]
			chance = float(chance)
			assert(0 <= chance and chance <= 1)
			
			reaction = reaction.split('@')[0]
			
		assert(reaction in self.reactions)
		
		if not name in self.reactions[reaction]:
			self.reactions[reaction][name] = []
			
		self.reactions[reaction][name] = [chance, reagents, products]
		
func _ready():
	print('Loading config...')
	
	define_type('empty', Color(0, 0, 0), ['void'])
	define_type('stone', Color(0.75, 0.75, 0.75), ['blocky', 'colorful'])
	define_type('sand', Color(0.75, 0.70, 0.70), ['falling'])
	define_type('water', Color(0, 0, 1), ['colorful', 'falling', 'spreading'])
	define_type('plant', Color(0, 1, 0), ['colorful'], [
		'grow(plantgrowth)',
		'neighbor@0.1(water>1 to plant)',
		'self@0.1(hot to empty)'])
	
	define_type('lava', Color(1, 0.25, 0.25), ['hot', 'falling', 'spreading'], [
		'spawn@0.05(fire)',
		'neighbor(water to stone)',
		'self(water to stone)'
	])
	define_type('fire', Color(1, 0, 0), ['hot', 'rising', 'spreading'], ['decay@0.05'])
	define_type('smoke', Color(1, 1, 1, 0.5), ['rising', 'spreading'], ['decay@0.05'])
	
	define_type('acid', Color(1, 0, 1), ['falling', 'spreading'], [
		'neighbor(* to empty)',
		'self(acid to acid)' # Recreate the acid if it reacted with other acid
	])
	
	define_type('ice', Color(0.65, 0.95, 0.95), ['blocky'], ['self@0.75(hot to water)'])
	
	define_type('wax', Color(0.94, 0.90, 0.83), ['blocky'], ['self@0.1(hot to hotwax)'])
	define_type('hot wax', Color(0.94, 0.90, 0.83), ['falling'], ['decay@0.1(wax)'])
	
	define_type('rainbow', [
		Color(1, 0, 0),
		Color(0, 1, 0),
		Color(0, 0, 1),
		Color(1, 1, 0),
		Color(1, 0, 1),
		Color(0, 1, 1),
	], ['falling', 'spreading', 'rising'], ['decay@0.01'])
		
	print(reactions)
	
	print('Done loading config')
