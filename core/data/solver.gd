class_name Solver
extends Resource

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
