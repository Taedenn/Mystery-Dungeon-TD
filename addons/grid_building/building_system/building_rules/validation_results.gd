class_name ValidationResults
extends RefCounted
## Results of building rule tests ran

var is_successful : bool = false
var message : String
var reasons : Array[String]
var rule_results : Array[RuleResult] = []

func _init(p_is_successful : bool, p_message : String, p_rule_results : Array[RuleResult]):
	self.is_successful = p_is_successful
	self.message = p_message
	self.rule_results = p_rule_results
