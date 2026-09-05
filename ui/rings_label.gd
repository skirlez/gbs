extends RichTextLabel


func _on_level_objects_update_ring_count(ring_amount: int) -> void:
	text =  "%03d" % ring_amount
