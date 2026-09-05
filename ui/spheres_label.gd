extends RichTextLabel




func _on_level_objects_update_sphere_count(sphere_amount: int) -> void:
	text = "%03d" % sphere_amount
