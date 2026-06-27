extends Node3D
class_name Ring


func get_ring():
	var collect_sound = $CollectSound
	collect_sound.reparent(get_parent())
	get_parent().remove_child(self)
	queue_free()
	
	collect_sound.play()
	await collect_sound.finished
	collect_sound.queue_free()
