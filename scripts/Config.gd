extends Node2D

const types = []
const colors = {}

const custom_keywords = []
const keywords = {
	'void': [],
	'blocky': [],
	'colorful': [],
	'falling': [],
	'spreading': [],
	'rising': []
}

const reactions = {
	'decay': {},
	'spawn': {},
	'neighbor': {},
	'self': {},
}

const operators = ['<=', '>=', '!=', '<', '=', '>']

const difficulties = {
	'easy': {
		'target': 50, 'blocks': 1, 'speed': 0.5,
		'spawns': {'stone': 2, 'sand': 4, 'water': 4, 'empty': 2},
		'variables': {'plantgrowth': 0.01}
	},
	'medium': {
		'target': 25, 'blocks': 1, 'speed': 0.5,
		'spawns': {'stone': 2, 'sand': 2, 'water': 2, 'empty': 1, 'lava': 1},
		'variables': {'plantgrowth': 0.05}
	},
	'hard': {
		'target': 0, 'blocks': 1, 'speed': 1.0,
		'spawns': {'stone': 2, 'sand': 2, 'water': 2, 'empty': 2, 'lava': 2, 'acid': 1},
		'variables': {'plantgrowth': 0.001}
	},
	'insane': {
		'target': 0, 'blocks': 2, 'speed': 1.0,
		'spawns': {'stone': 2, 'sand': 2, 'water': 1, 'lava': 2, 'acid': 2},
		'variables': {'plantgrowth': 0.001}
	}
}

const physics = {
	'impulse': Vector2(25, 0),
	'gravity': Vector2(0, 100),
	'torque': 100,
	'lock_time': 0.1,
	'minimum_speed': 5.0,
}

const spawn_chance = 0.5
const color_variation = 0.1
		
func _ready():
	print('Loading config...')
	
	# These must exist, I have hard coded them several places
	# TODO: Fix this
	define_type('empty', Color(0, 0, 0), ['void'])
	define_type('stone', Color(0.75, 0.75, 0.75), ['blocky', 'colorful'])
	define_type('plant', Color(0, 1, 0), ['colorful'], [
		'spawn@0.1(plant<3 to plant)',
		'neighbor@0.1(water>1 to plant)',
		'self@0.1(hot to empty)'])
	# /must exist
	
	define_type('sand', Color(0.75, 0.70, 0.70), ['falling'])
	define_type('water', Color(0, 0, 1), ['colorful', 'falling', 'spreading'])
	
	define_type('lava', Color(1, 0.25, 0.25), ['hot', 'falling', 'spreading'], [
		'spawn@0.05(fire)',
		'neighbor(water to stone)',
		'self(water to stone)'
	])
	define_type('fire', Color(1, 0, 0), ['colorful', 'hot', 'rising', 'spreading'], ['decay@0.05'])
	define_type('smoke', Color(1, 1, 1, 0.5), ['colorful', 'rising', 'spreading'], ['decay@0.05'])
	
	define_type('acid', Color(1, 0, 1), ['falling', 'spreading'], [
		#'neighbor(* to empty)',
		'self(acid to acid)' # Recreate the acid if it reacted with other acid
	])
	
	define_type('ice', Color(0.65, 0.95, 0.95), ['blocky'], ['self@0.75(hot to water)'])
	
	define_type('wax', Color(0.94, 0.90, 0.83), ['blocky'], ['self@0.1(hot to hotwax)'])
	define_type('hot wax', Color(0.94, 0.90, 0.83), ['falling'], ['decay@0.1(wax)'])
	
	define_type(
		'rainbow',
		[Color(1, 0, 0), Color(0, 1, 0), Color(0, 0, 1), Color(1, 1, 0), Color(1, 0, 1), Color(0, 1, 1)],
		['falling', 'spreading', 'rising'], ['decay@0.01']
	)
		
	print('Done loading config')

func define_type(_name, _colors, _keywords, _reactions = []):
	assert(not _name in types)
	types.append(_name)
	
	if _colors is Color:
		colors[_name] = [_colors]
	else:
		colors[_name] = _colors
	
	for keyword in _keywords:
		if not keyword in keywords:
			keywords[keyword] = []
			custom_keywords.append(keyword)
			
		keywords[keyword].append(_name)
	
	for reaction in _reactions:
		var chance = 1.0
		var reagents = []
		var products = {}
		
		# If we have parameters, parse those first
		if '(' in reaction:
			var parameters = reaction.split('(')[1].rstrip(')')
			reaction = reaction.split('(')[0]
			
			# Reagents are optional, if we don't have any, skip this
			if ' to ' in parameters:
				for reagent in parameters.split(' to ')[0].split(' '):
					var operator = '>'
					var quantity = 0
					
					for possible_operator in operators:
						if possible_operator in reagent:
							operator = possible_operator
							quantity = int(reagent.split(operator)[1])
							reagent = reagent.split(operator)[0]
							break
							
					reagents.append([reagent, operator, quantity])
				
				parameters = parameters.split(' to ')[1]
			
			# Products must sum to 1.0, if any are not specified, split evenly
			var total_chance = 0.0
			for product in parameters.split(' '):
				var product_chance = INF
				
				if '@' in product:
					product_chance = float(product.split('@')[1])
					product = product.split('@')[0]
				
				if product in products:
					products[product] += product_chance
				else:
					products[product] = product_chance
					
				if product_chance != INF:
					total_chance += product_chance
					
			assert(total_chance >= 0 and total_chance <= 1)
			
			var missing_chance = 0
			for product in products:
				if products[product] == INF:
					missing_chance += 1
					
			if missing_chance > 0:
				for product in products:
					if products[product] == INF:
						products[product] = (1.0 - total_chance) / missing_chance
						
		# If we have a chance, split that off
		if '@' in reaction:
			chance = reaction.split('@')[1]
			chance = float(chance)
			assert(0 <= chance and chance <= 1)
			
			reaction = reaction.split('@')[0]
		
		assert(reaction in reactions)
		
		if not _name in reactions[reaction]:
			reactions[reaction][_name] = []
			
		reactions[reaction][_name].append([chance, reagents, products])
