extends RefCounted

class_name RuleResult

var is_successful : bool 
var reason : String

func _init(p_is_successful : bool = false, 
	p_reason : String = "Reason not set or validation has not been run"):
	self.is_successful = p_is_successful
	self.reason = p_reason
