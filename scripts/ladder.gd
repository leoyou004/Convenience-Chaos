extends Area3D

const LADDER_SPEED := 4.0

var bodies_on_ladder: Array = []

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(_delta: float) -> void:
	for body in bodies_on_ladder:
		if not is_instance_valid(body):
			continue

		if body.is_in_group("player"):
			_handle_player(body)
		elif body is CharacterBody3D:
			_handle_enemy(body)

func _handle_player(player: CharacterBody3D) -> void:
	var up = Input.is_key_pressed(KEY_W) or Input.is_action_pressed("sprint")
	var down = Input.is_key_pressed(KEY_S)

	if up:
		player.velocity.y = LADDER_SPEED
		player.velocity.x = 0
		player.velocity.z = 0
	elif down:
		player.velocity.y = -LADDER_SPEED
		player.velocity.x = 0
		player.velocity.z = 0
	else:
		player.velocity.y = 0
		player.velocity.x = 0
		player.velocity.z = 0

func _handle_enemy(enemy: CharacterBody3D) -> void:
	# Enemy always climbs up the ladder when touching it
	enemy.velocity.y = LADDER_SPEED * 0.6
	enemy.velocity.x = 0
	enemy.velocity.z = 0

func _on_body_entered(body: Node) -> void:
	if body is CharacterBody3D:
		bodies_on_ladder.append(body)

func _on_body_exited(body: Node) -> void:
	bodies_on_ladder.erase(body)
