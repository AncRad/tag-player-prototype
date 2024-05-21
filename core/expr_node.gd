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
		
		Type.Not:
			return false
	return false

func is_operand() -> bool:
	match type:
		Type.MatchString, Type.Tag, Type.SubExpression:
			return true
	return false

func to_text() -> String:
	match type:
		Type.Not:
			return 'NOT'
		
		Type.And:
			return 'AND'
		
		Type.Or:
			return 'OR'
		
		Type.Tag:
			return '[tag:%d]' % tag.key
		
		Type.MatchString:
			return '[%s]' % get_value()
		
		Type.BracketOpen:
			return '('
		
		Type.BracketClose:
			return ')'
		
		Type.SubExpression:
			var texts : Array[String] = []
			for node in expressions:
				if node.is_operand() or node.is_operator():
					if node.enabled:
						if node.type == Type.SubExpression:
							texts.append('( %s )' % node.to_text())
						else:
							texts.append(node.to_text())
			return ' '.join(texts)
		
		_:
			return '<err expr>'

func changes_up() -> void:
	if not _changed:
		_changed = true
		if parent and is_instance_valid(parent.get_ref()):
			parent.get_ref().changes_up()
		print('EMIT_CHANGED', type == Type.SubExpression)
		emit_changed()

func clear() -> void:
	tag = null
	match_string = ''
	for node in expressions:
		node.parent = null
	expressions.clear()
	changes_up()

func solve(track : DataBase.Track) -> bool:
	if _changed:
		_solver.all = false
		_solver.invert = false
		_solver.items.clear()
		repair()
		_compile(_solver)
	return _solver.solve(track)

## SubExpression
func insert(index : int, node : ExprNode) -> void:
	assert(not node.parent or not is_instance_valid(node.parent.get_ref()))
	assert(node.type != Type.SubExpression)
	node.parent = weakref(self)
	expressions.insert(index, node)
	changes_up()

func append(node : ExprNode) -> void:
	insert(expressions.size(), node)

func remove_at(index : int) -> void:
	var node := expressions[index]
	node.parent = null
	expressions.remove_at(index)
	changes_up()

func repair() -> void:
	var pos : int = 0
	var brackets := 0
	var not_openned := 0
	while pos < expressions.size():
		var node := expressions[pos]
		
		if node.virtual:
			remove_at(pos)
		
		else:
			if node.type == ExprNode.Type.BracketOpen:
				brackets += 1
			elif node.type == ExprNode.Type.BracketClose:
				if brackets == 0:
					not_openned += 1
				else:
					brackets -= 1
			
			node.enabled = true
			pos += 1
	
	for i in not_openned:
		var bracket := ExprNode.new(ExprNode.Type.BracketOpen)
		bracket.virtual = true
		insert(0, bracket)
	
	while maxi(0, pos) < expressions.size():
		if pos < 0:
			pos = 0
		
		var this := expressions[pos]
		if not this.enabled:
			pos += 1
			continue
		
		var left : ExprNode
		var right : ExprNode
		var left_pos := pos
		while left_pos > 0:
			left_pos -= 1
			var n := expressions[left_pos]
			if n.enabled:
				if n.is_operator() or n.is_operand():
					left = n
					break
		if not left:
			left_pos = 0
		var right_pos := pos
		while right_pos < expressions.size() - 1:
			right_pos += 1
			var n := expressions[right_pos]
			if n.enabled:
				if n.is_operator() or n.is_operand():
					right = n
					break
		if not right:
			right_pos = 0
		
		if this.is_operator():
			if this.is_binary():
				if not left or not right or not left.is_operand():
					this.enabled = false
					pos = left_pos
					continue
			
			else:
				if not right:
					this.enabled = false
					pos = left_pos
					continue
				
				if right.is_operator():
					if right.is_binary():
						this.enabled = false
						pos = left_pos
						continue
				
				if right.type == ExprNode.Type.Not:
					this.enabled = false
					right.enabled = false
					pos = left_pos
					continue
		
		elif this.is_operand():
			if right:
				if right.is_operand() or not right.is_binary():
					right = ExprNode.new(ExprNode.Type.And)
					right.virtual = true
					insert(pos + 1, right)
					pos += 2
					continue
		
		else:
			this.enabled = false
			pos = left_pos
			continue
		
		pos += 1

## Tag, MatchString
func get_value() -> Variant:
	if type == Type.Tag:
		return tag
	if type == Type.MatchString:
		return '*%s*' % '*'.join(match_string.replace('*', ' ').split(' ', false))
		#return match_string
	return

func _compile(solver : Solver, begin := 0) -> int:
	var pos := begin
	
	var invert := false
	var stack_up := false
	while pos < expressions.size():
		var node := expressions[pos]
		if node.enabled:
			match node.type:
				ExprNode.Type.SubExpression:
					assert(false)
				
				ExprNode.Type.Not:
					invert = true
				
				ExprNode.Type.BracketClose:
					return pos + 1
				
				ExprNode.Type.And, ExprNode.Type.Or:
					if solver.items.size() >= 2:
						stack_up = solver.all != (node.type == ExprNode.Type.And)
						if stack_up and begin != 0:
							return pos
					
					else:
						solver.all = node.type == ExprNode.Type.And
				
				ExprNode.Type.MatchString, ExprNode.Type.Tag, ExprNode.Type.BracketOpen:
					var operand
					if node.type == ExprNode.Type.BracketOpen:
						operand = Solver.new()
						operand.invert = invert
						pos = _compile(operand, pos + 1)
					
					elif invert:
						operand = Solver.new()
						operand.invert = invert
						operand.items.append(node.get_value())
					
					else:
						operand = node.get_value()
					
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
						else:
							next.all = not solver.all
							next.invert = invert
							next.items = [solver.items[-1]]
							solver.items[-1] = next
							pos = _compile(next, pos)
					
					else:
						solver.items.append(operand)
					
					invert = false
		
		node._changed = false
		pos += 1
	
	_changed = false
	return pos

#@warning_ignore('shadowed_variable')
#static func _decompile(solver : Solver) -> Array[ExprNode]:
	#var root := [] as Array[ExprNode]
	#var expressions := root
	#
	#if solver.invert:
		#var node := ExprNode.new()
		#expressions.append(node)
		#node.type = ExprNode.Type.Not
		#if solver.items.size() != 1:
			#node = ExprNode.new()
			#expressions.append(node)
			#node.type = ExprNode.Type.SubExpression
			#expressions = node.expressions
	#
	#for i in solver.items.size():
		#var item = solver.items[i]
		#if item is Solver:
			#assert(solver.items)
			#
			#if not item.all and solver.all and not (item.invert and item.items.size() == 1):
				#var node := ExprNode.new()
				#expressions.append(node)
				#node.type = ExprNode.Type.SubExpression
				#node.expressions = _decompile(item)
			#else:
				#expressions.append_array(_decompile(item))
		#
		#elif item is DataBase.Tag:
			#var node := ExprNode.new()
			#expressions.append(node)
			#node.type = ExprNode.Type.Tag
			#node.tag = item
		#
		#elif item is String:
			#var node := ExprNode.new()
			#expressions.append(node)
			#node.type = ExprNode.Type.MatchString
			#node.match_string = item
		#
		#else:
			#assert(false)
		#
		#if i < solver.items.size() - 1:
			#var node := ExprNode.new()
			#expressions.append(node)
			#if solver.all:
				#node.type = ExprNode.Type.And
			#else:
				#node.type = ExprNode.Type.Or
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
				#node = ExprNode.new()
				#expressions.append(node)
				#node.type = ExprNode.Type.SubExpression
				#expressions = node.expressions
		
		for i in items.size():
			var item = items[i]
			if item is Solver:
				assert(items)
				
				if not item.all and all and not (item.invert and item.items.size() == 1):
					#var node := ExprNode.new()
					#expressions.append(node)
					#node.type = ExprNode.Type.SubExpression
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
