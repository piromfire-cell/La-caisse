class_name TestCase
extends RefCounted
## Mini cadre de tests maison (aucun module externe à installer).
## Chaque fonction `test_xxx()` d'une suite est exécutée par `run_tests.gd`.

var failures: Array[String] = []
var assertions: int = 0
var current_test: String = ""


func assert_true(condition: bool, message: String = "") -> void:
	assertions += 1
	if not condition:
		failures.append("[%s] %s (attendu: vrai)" % [current_test, message])


func assert_false(condition: bool, message: String = "") -> void:
	assertions += 1
	if condition:
		failures.append("[%s] %s (attendu: faux)" % [current_test, message])


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	assertions += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("[%s] %s — obtenu: %s, attendu: %s" % [current_test, message, str(actual), str(expected)])


func assert_ne(actual: Variant, unexpected: Variant, message: String = "") -> void:
	assertions += 1
	if typeof(actual) == typeof(unexpected) and actual == unexpected:
		failures.append("[%s] %s — valeur interdite: %s" % [current_test, message, str(actual)])


func assert_null(value: Variant, message: String = "") -> void:
	assertions += 1
	if value != null:
		failures.append("[%s] %s — attendu null, obtenu: %s" % [current_test, message, str(value)])


func assert_not_null(value: Variant, message: String = "") -> void:
	assertions += 1
	if value == null:
		failures.append("[%s] %s — attendu non null" % [current_test, message])
