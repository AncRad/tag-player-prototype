class_name ExprNode
extends Resource

signal enable_changed

const FilterItem = preload('res://gui/find_panel/filter_item.gd')

enum Type {
	Not = FilterItem.Type.Not,
	And = FilterItem.Type.And,
	Or = FilterItem.Type.Or,
	Tag = FilterItem.Type.Tag,
	MatchString = FilterItem.Type.MatchString,
	BracketOpen = FilterItem.Type.BracketOpen,
	BracketClose = FilterItem.Type.BracketClose,
	SubExpression,
}
@export var type : Type
var parent : WeakRef
var virtual := false
var enabled := true:
	set(value):
		enabled = value
		enable_changed.emit()

## Tag
var tag : DataBase.Tag


## MatchString
var match_string : String


## SubExpression
var expressions : Array[ExprNode] = []

func insert(index : int, node : ExprNode) -> void:
	assert(not node.parent or not is_instance_valid(node.parent.get_value()))
	node.parent = weakref(node.parent)
	expressions.insert(index, node)

func append(node : ExprNode) -> void:
	insert(expressions.size(), node)

func clear() -> void:
	for node in expressions:
		node.parent = null
	expressions.clear()

func remove_at(index : int) -> void:
	var node := expressions[index]
	node.parent = null
	expressions.remove_at(index)


## Tag, MatchString
func get_value() -> Variant:
	if type == Type.Tag:
		return tag
	if type == Type.MatchString:
		return '*%s*' % '*'.join(match_string.replace('*', ' ').split(' ', false))
		#return match_string
	return


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
			return '[%s]' % match_string
		
		Type.BracketOpen:
			return '('
		
		Type.BracketClose:
			return ')'
		
		Type.SubExpression:
			var texts : Array[String] = []
			for node in expressions:
				if node.enabled:
					if node.type == Type.SubExpression:
						texts.append('( %s )' % node.to_text())
					else:
						texts.append(node.to_text())
			return ' '.join(texts)
		
		_:
			return '<err expr>'

func compile(solver : Solver, begin := 0) -> int:
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
					var right
					if node.type == ExprNode.Type.BracketOpen:
						right = Solver.new()
						right.invert = invert
						pos = compile(right, pos + 1)
					
					elif invert:
						right = Solver.new()
						right.invert = invert
						right.items.append(node.get_value())
					
					else:
						right = node.get_value()
					
					if stack_up:
						stack_up = false
						var next := Solver.new()
						
						if solver.all:
							next.all = solver.all
							next.invert = solver.invert
							next.items = solver.items
							
							solver.all = not solver.all
							solver.invert = false
							solver.items = [next, right]
						else:
							next.all = not solver.all
							next.invert = invert
							next.items = [solver.items[-1]]
							solver.items[-1] = next
							pos = compile(next, pos)
					
					else:
						solver.items.append(right)
					
					invert = false
		
		pos += 1
	
	return pos
#
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
