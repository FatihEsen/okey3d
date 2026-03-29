extends Node

func run_test(rack):
	print("Running arrange_by_series...")
	rack.arrange_by_series()
	print("Finished rack!")
	get_tree().quit()
