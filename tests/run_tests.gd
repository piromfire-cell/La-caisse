extends SceneTree
## Lance toutes les suites de tests de la logique du jeu.
##
##   godot --headless --path . --script res://tests/run_tests.gd
##
## Code de sortie : 0 = tout est vert, 1 = au moins un test a échoué.

const SUITES: Array[String] = [
	"res://tests/test_dice.gd",
	"res://tests/test_rules.gd",
	"res://tests/test_match.gd",
	"res://tests/test_stats.gd",
	"res://tests/test_simulation.gd",
	"res://tests/test_misc.gd",
]


func _init() -> void:
	var total_tests := 0
	var total_assertions := 0
	var failures: Array[String] = []

	for path in SUITES:
		var script: GDScript = load(path)
		if script == null:
			failures.append("Impossible de charger la suite %s" % path)
			continue
		var suite: TestCase = script.new()
		var suite_tests := 0
		for method in suite.get_method_list():
			var method_name: String = method["name"]
			if method_name.begins_with("test_"):
				suite.current_test = "%s::%s" % [path.get_file().get_basename(), method_name]
				suite.call(method_name)
				suite_tests += 1
		total_tests += suite_tests
		total_assertions += suite.assertions
		failures.append_array(suite.failures)
		print("  %s — %d tests, %d vérifications, %d échec(s)" % [
			path.get_file(), suite_tests, suite.assertions, suite.failures.size()])

	print("")
	if failures.is_empty():
		print("✅ TOUS LES TESTS PASSENT : %d tests, %d vérifications." % [total_tests, total_assertions])
		quit(0)
	else:
		print("❌ %d ÉCHEC(S) :" % failures.size())
		for f in failures:
			print("   - " + f)
		quit(1)
