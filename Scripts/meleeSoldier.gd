extends soldier

func _ready():
	type = "melee"
	._ready()
	
func _physics_process(delta):
	.updateMovementAndAction(delta)
	updateSprite()

func updateSprite():
	# correct color
	if unitOwner == "enemy":
		sprite.modulate = Color(255, 0, 0) # red shade
	
	if attackTarget and attackTarget.get_ref():
		weaponSprite.scale.x = sign(attackTarget.get_ref().position.x - position.x)
	else:
		weaponSprite.scale.x = 1

func _on_StopTimer_timeout():
	._on_StopTimer_timeout()

func _on_AnimationPlayer_animation_finished(_anim_name):
	if attackTarget != null && attackTarget.get_ref() != null:
		if attackTarget.get_ref().has_method("takeDamage") && attackTarget.get_ref().currentHealth >= 0:
			attackTarget.get_ref().rpc("takeDamage", .calculateDamge())

func _on_VisionRange_body_entered(body: Node2D):
	._on_VisionRange_body_entered(body)
	
func _on_VisionRange_body_exited(body: Node2D):
	._on_VisionRange_body_exited(body)