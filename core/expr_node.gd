class_name ExprNode
extends Resource

signal enable_changed
signal virtual_changed
signal type_changed

enum Type {Null, Not, And, Or, Tag, MatchString, BracketOpen, BracketClose, SubExpression}

@export var type : Type:
	set(value):
		if value != type:
			assert(parent or value != Type.SubExpression)
			type = value
			changes_up()
			type_changed.emit()

var parent := WeakRef.new()

var virtual := false:
	set(value):
		if value != virtual:
			virtual = value
			changes_up()
			virtual_changed.emit()

var enabled := true:
	set(value):
		if value != enabled:
			enabled = value
			changes_up()
			enable_changed.emit()
	get:
		return enabled and type != Type.Null

## Tag
var tag : DataBase.Tag:
	set(value):
		if value != tag:
			tag = value
			changes_up()
## MatchString
var match_string : String:
	set(value):
		if value != match_string:
			match_string = value
			changes_up()
## SubExpression
var expressions : Array[ExprNode] = []

var _changed : bool = false
var _solver := Solver.new()


func _init(p_type := Type.MatchString) -> void:
	type = p_type

func is_operator() -> bool:
	match type:
		Type.Not, Type.And, Type.Or:
			return true
	return false

func is_binary() -> bool:
	match type:
		Type.And, Type.Or:
			return true
	return false

func is_unary() -> bool:
	return type == Type.Not

func is_operand() -> bool:
	match type:
		Type.MatchString, Type.Tag, Type.SubExpression:
			return true
	return false

func is_bracket_close() -> bool:
	return type == Type.BracketClose

func is_bracket_open() -> bool:
	return type == Type.BracketOpen

func is_bracket() -> bool:
	return type == Type.BracketOpen or type == Type.BracketClose

func is_empty() -> bool:
	match type:
		Type.MatchString:
			return match_string.is_empty()
		
		Type.Tag:
			return tag == null or not tag.valid
		
		Type.SubExpression:
			for expr in expressions:
				if not expr.is_empty():
					return false
			return true
		
		_:
			return not (is_operator() or is_bracket())

func is_valid() -> bool:
	return enabled and not is_empty()

func to_text() -> String:
	match type:
		ExprNode.Type.Null:
			return ''
		
		ExprNode.Type.Not:
			return 'NOT'
		
		ExprNode.Type.And:
			return 'AND'
		
		ExprNode.Type.Or:
			return 'OR'
		
		ExprNode.Type.Tag:
			if tag and tag.valid:
				if tag.names:
					assert(tag.names[0])
					return tag.names[0]
				
				return '[Unnamed tag]'
			
			else:
				return '[Invalid tag]'
		
		ExprNode.Type.MatchString:
			return match_string
		
		ExprNode.Type.BracketOpen:
			return '('
		
		ExprNode.Type.BracketClose:
			return ')'
		
		Type.SubExpression:
			var texts : Array[String] = []
			for expr in expressions:
				if expr.enabled:
					if expr.type == Type.SubExpression:
						texts.append('( %s )' % expr.to_text())
					else:
						texts.append(expr.to_text())
			return ' '.join(texts)
		
		_:
			return '<err expr>'

func changes_up() -> void:
	if not _changed:
		_changed = true
		if parent and is_instance_valid(parent.get_ref()):
			parent.get_ref().changes_up()
	emit_changed()

func clear() -> void:
	tag = null
	match_string = ''
	for expr in expressions:
		expr.parent = null
	expressions.clear()
	changes_up()

func solve(track : DataBase.Track) -> bool:
	if _changed:
		update()
	
	return _solver.solve(track)

## SubExpression
func insert(index : int, expr : ExprNode) -> void:
	assert(not expr.parent or not is_instance_valid(expr.parent.get_ref()))
	assert(expr.type != Type.SubExpression)
	assert(not expr in expressions)
	expr.parent = weakref(self)
	expressions.insert(index, expr)
	changes_up()

func append(expr : ExprNode) -> void:
	insert(expressions.size(), expr)

func remove_at(index : int) -> void:
	var expr := expressions[index]
	expr.parent = null
	expressions.remove_at(index)
	changes_up()

func erase(expr : ExprNode) -> void:
	expressions.erase(expr)
	changes_up()

func has(expr : ExprNode) -> bool:
	return expr in expressions

func update() -> void:
	var pos : int = 0
	var brackets := 0
	var not_openned := 0
	while pos < expressions.size():
		var expr := expressions[pos]
		
		if expr.virtual:
			expressions.remove_at(pos)
			continue
		
		else:
			if expr.type == ExprNode.Type.BracketOpen:
				brackets += 1
			elif expr.type == ExprNode.Type.BracketClose:
				if brackets == 0:
					not_openned += 1
				else:
					brackets -= 1
			
			expr.enabled = not expr.is_empty()
			pos += 1
	for i in not_openned:
		var bracket := ExprNode.new(ExprNode.Type.BracketOpen)
		bracket.virtual = true
		insert(0, bracket)
	
	pos = 0
	while maxi(0, pos) < expressions.size():
		if pos < 0:
			pos = 0
		
		var this := expressions[pos]
		if not this.is_valid():
			pos += 1
			continue
		
		var left : ExprNode
		var left_pos : int = 0
		for i in range(pos - 1, -1, -1):
			if expressions[i].is_valid():
				left = expressions[i]
				left_pos = i
				break
		var right : ExprNode
		var right_pos := 0
		for i in range(pos + 1, expressions.size()):
			if expressions[i].is_valid():
				right = expressions[i]
				right_pos = i
				break
		
		if this.is_operator():
			if this.is_binary():
				if not (left and right and (left.is_operand() or left.is_bracket_close())
						and (left.is_operand() or right.is_bracket_open() or right.is_unary())):
					this.enabled = false
					pos = left_pos
					continue
			
			else:
				if not right or right.is_bracket_close() or right.is_binary():
					this.enabled = false
					pos = left_pos
					continue
				
				if right.type == ExprNode.Type.Not:
					this.enabled = false
					right.enabled = false
					pos = left_pos
					continue
		
		elif this.is_operand() or this.is_bracket_close():
			if right:
				if right.is_operand() or right.is_unary() or right.is_bracket_open():
					right = ExprNode.new(ExprNode.Type.And)
					right.virtual = true
					insert(right_pos, right)
					right_pos = pos + 1
					pos = right_pos + 1
					continue
		
		elif this.is_bracket_open():
			if not right or right.is_bracket_close():
				this.enabled = false
				if right:
					right.enabled = false
				pos = left_pos
				continue
		
		elif this.is_bracket():
			pass
		
		else:
			this.enabled = false
			pos = left_pos
			continue
		
		pos += 1
	
	_solver.all = false
	_solver.invert = false
	_solver.items.clear()
	_compile(_solver)

## Tag, MatchString
func get_value() -> Variant:
	if type == Type.Tag:
		return tag
	if type == Type.MatchString:
		var split := match_string.replace('*', ' ').split(' ', false)
		if split:
			return '*%s*' % '*'.join(split)
		return ''
	return

func _compile(solver : Solver, begin := 0) -> int:
	var pos := begin
	
	var invert := false
	var stack_up := false
	while pos < expressions.size():
		var expr := expressions[pos]
		if expr.is_valid():
			match expr.type:
				ExprNode.Type.SubExpression:
					assert(false)
				
				ExprNode.Type.Not:
					invert = true
				
				ExprNode.Type.BracketClose:
					expr._changed = false
					return pos
				
				ExprNode.Type.And, ExprNode.Type.Or:
					if solver.items.size() >= 2:
						stack_up = solver.all != (expr.type == ExprNode.Type.And)
						if stack_up and begin != 0:
							expr._changed = false
							return pos
					
					else:
						solver.all = expr.type == ExprNode.Type.And
				
				ExprNode.Type.MatchString, ExprNode.Type.Tag, ExprNode.Type.BracketOpen:
					var operand
					if expr.type == ExprNode.Type.BracketOpen:
						operand = Solver.new()
						operand.invert = invert
					
					elif invert:
						operand = Solver.new()
						operand.invert = invert
						operand.items.append(expr.get_value())
					
					else:
						operand = expr.get_value()
					
					if stack_up:
						stack_up = false
						var next := Solver.new()
						
						if solver.all:
							next.all = solver.all
							next.invert = solver.invert
							next.items = solver.items
							
							solver.all = not solver.all
							solver.invert = false
							solver.items = [next, operand]
							if expr.type == ExprNode.Type.BracketOpen:
								pos = _compile(operand, pos + 1)
						else:
							next.all = not solver.all
							next.invert = invert
							next.items = [solver.items[-1], operand]
							solver.items[-1] = next
							if expr.type == ExprNode.Type.BracketOpen:
								pos = _compile(operand, pos + 1)
							pos = _compile(next, pos + 1)
					
					else:
						solver.items.append(operand)
						if expr.type == ExprNode.Type.BracketOpen:
							pos = _compile(operand, pos + 1)
					
					invert = false
		
		expr._changed = false
		pos += 1
	
	_changed = false
	return pos

#@warning_ignore('shadowed_variable')
#static func _decompile(solver : Solver) -> Array[ExprNode]:
	#var root := [] as Array[ExprNode]
	#var expressions := root
	#
	#if solver.invert:
		#var expr := ExprNode.new()
		#expressions.append(expr)
		#expr.type = ExprNode.Type.Not
		#if solver.items.size() != 1:
			#expr = ExprNode.new()
			#expressions.append(expr)
			#expr.type = ExprNode.Type.SubExpression
			#expressions = expr.expressions
	#
	#for i in solver.items.size():
		#var item = solver.items[i]
		#if item is Solver:
			#assert(solver.items)
			#
			#if not item.all and solver.all and not (item.invert and item.items.size() == 1):
				#var expr := ExprNode.new()
				#expressions.append(expr)
				#expr.type = ExprNode.Type.SubExpression
				#expr.expressions = _decompile(item)
			#else:
				#expressions.append_array(_decompile(item))
		#
		#elif item is DataBase.Tag:
			#var expr := ExprNode.new()
			#expressions.append(expr)
			#expr.type = ExprNode.Type.Tag
			#expr.tag = item
		#
		#elif item is String:
			#var expr := ExprNode.new()
			#expressions.append(expr)
			#expr.type = ExprNode.Type.MatchString
			#expr.match_string = item
		#
		#else:
			#assert(false)
		#
		#if i < solver.items.size() - 1:
			#var expr := ExprNode.new()
			#expressions.append(expr)
			#if solver.all:
				#expr.type = ExprNode.Type.And
			#else:
				#expr.type = ExprNode.Type.Or
	#
	#return root


class Solver:
	var invert := false
	var all := false
	var items : Array
	
	
	func _init(p_invert : bool = false, p_all : bool = false, p_items : Array = []):
		invert = p_invert
		all = p_all
		items = p_items
	
	func solve(track : DataBase.Track) -> bool:
		var condition := true
		for item in items:
			condition = false
			if item is DataBase.Tag:
				condition = track.is_tagged(item)
			elif item is String:
				condition = track.find_string.matchn(item)
			elif item is Solver:
				condition = item.solve(track)
			else:
				assert(false)
			
			if all != condition:
				break
		
		if invert:
			return not condition
		return condition
	
	func to_text() -> String:
		var strs := [] as Array[String]
		
		if invert:
			strs.append('Not')
			#if items.size() != 1:
				#expr = ExprNode.new()
				#expressions.append(expr)
				#expr.type = ExprNode.Type.SubExpression
				#expressions = expr.expressions
		
		for i in items.size():
			var item = items[i]
			if item is Solver:
				assert(items)
				
				if not item.all and all and not (item.invert and item.items.size() == 1):
					#var expr := ExprNode.new()
					#expressions.append(expr)
					#expr.type = ExprNode.Type.SubExpression
					strs.append(item.to_text())
				else:
					strs.append(item.to_text())
			
			elif item is DataBase.Tag:
				strs.append(item.get_name())
			
			elif item is String:
				strs.append(item)
			
			else:
				assert(false)
			
			if i < items.size() - 1:
				if all:
					strs.append('AND')
				else:
					strs.append('OR')
		
		return ' '.join(strs)
