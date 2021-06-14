extends KinematicBody2D
class_name Soldier

export var speed : float = 40.0
export var maxHealth = 5

var currentHealth = 5
var selected : bool = false
var dest : Vector2 = Vector2.ZERO
var finalDest : Vector2 = Vector2.ZERO
var velocity : Vector2 = Vector2.ZERO
var targetMax = 1
var lastPosition : Vector2
var possibleTarget = []
const moveThreshold : float = 1.0
var pathfinding : Pathfinding
var unitOwner : String = "ally"

var collisionRadius = 0
var attackTarget = null
var attackRange = 30

onready var stopTimer : Timer = $StopTimer
onready var weapon : Node2D = $Weapon
onready var sprite : Sprite = $Sprite
onready var weaponSprite : Sprite = $Weapon/SpearSprite
onready var healthBar : TextureProgress = $HealthBar
onready var world : Node2D = get_node("/root/world")


func _ready():
	dest = global_position
	finalDest = global_position
	healthBar.max_value = maxHealth
	healthBar.value = currentHealth	
	world.connect("updatePathfinding", self, "setPathfinding")
	# update pathfinding
	
func updateSprite():
	if unitOwner == "enemy":
		weaponSprite.scale.x = -1
		sprite.modulate = Color(0, 0, 1) # blue shade

func setPathfinding(_pathfinding: Pathfinding):
	self.pathfinding = _pathfinding
	
func _physics_process(_delta):
	# set attack target
	if cloestEnemy() != null :
		attackTarget = weakref(cloestEnemy())
		# move to target
		dest = attackTarget.get_ref().global_position
	
	if cloestEnemyWithinRange() != null:
		attackTarget = weakref(cloestEnemyWithinRange())
		# perform attack
		weapon.attack()


	#reset velocity
	velocity = Vector2.ZERO
	var path = pathfinding.getPath(global_position, dest)

	if path.size() > 0:
		if global_position.distance_to(path[0]) > targetMax:
			velocity = position.direction_to(path[0]) * speed
			if get_slide_count() and stopTimer.is_stopped():
				stopTimer.start()
				lastPosition = global_position
	
	velocity = move_and_slide(velocity)

	updateSprite()	
	
func setDest(_dest):
	dest = _dest
	finalDest = _dest

func move_to(tar):
	dest = tar
	
func move_along_path(path):
	for p in path:
		move_to(p)

func stop():
	velocity = Vector2.ZERO
	dest = global_position

func takeDamage(damage: int) -> void:
	currentHealth -= damage
	healthBar.set_value(currentHealth)
	if currentHealth <= 0:
		queue_free()
		
func _on_StopTimer_timeout():
	if get_slide_count():
		if lastPosition.distance_to(dest) < lastPosition.distance_to(dest) + moveThreshold:
			dest = position

func compareDistance(target_a : Node2D, target_b : Node2D):
	if global_position && target_a && target_b:
		if global_position.distance_to(target_a.global_position) <= global_position.distance_to(target_b.global_position):
			return true
		else:
			return false
	else:
		return false

func cloestEnemy() -> Node2D:
	if possibleTarget.size() > 0:
		possibleTarget.sort_custom(self, "compareDistance")
		attackTarget = possibleTarget[0]
		return possibleTarget[0]
	else:
		return null

func cloestEnemyWithinRange() -> Node2D:
	var enemy : Node2D = cloestEnemy()
	if enemy:
		if enemy.global_position.distance_to(global_position) - enemy.collisionRadius <= attackRange:
			return enemy
		else:
			return null
	else:
		return null

func _on_VisionRange_body_entered(body : Node2D):
	if not (body is Builder):
		if body.get("unitOwner") != unitOwner && not possibleTarget.has(body):
			possibleTarget.append(body)

func _on_AnimationPlayer_animation_finished(_anim_name):
	if attackTarget != null && attackTarget.get_ref() != null:
		if attackTarget.get_ref().has_method("takeDamage") && attackTarget.get_ref().currentHealth >= 0:
			attackTarget.get_ref().takeDamage(1)
		else: 
			pass

func _on_VisionRange_body_exited(body: Node2D):
	if possibleTarget.has(body):
		possibleTarget.erase(body)
