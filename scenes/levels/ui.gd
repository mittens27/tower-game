extends CanvasLayer

enum hpState { THREE, TWO, ONE, ZERO }
var state : hpState = hpState.THREE

@onready var sprite := $healthBar

func _ready():
	Events.player_health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(GMan.player_health)
	Events.coin_amount_changed.connect(_on_coin_amount_changed)
	_on_coin_amount_changed(GMan.coins)
	Events.player_died.connect(_on_player_player_died)
	
	var deathNote := $DeathNote
	deathNote.visible = false
	
func _physics_process(_delta):
	pass
	
func _on_coin_amount_changed(amount):
	$Coins.text = "Coins: %d" % amount
	
func _on_player_health_changed(current_health):
	#print("Health Recieved:", value)
	update_hearts(current_health)
	print("Player Health:", current_health)
	
func update_hearts(current_health):
	var new_state
	
	if current_health == 3:
		new_state = hpState.THREE
	elif current_health == 2:
		new_state = hpState.TWO
	elif current_health == 1:
		new_state = hpState.ONE
	else:
		new_state = hpState.ZERO
		
	if new_state != state:
		state = new_state
		update_animation()
		
func update_animation():
	match state:
		hpState.THREE:
			sprite.play("3_hearts")
		hpState.TWO:
			sprite.play("2_hearts")
		hpState.ONE:
			sprite.play("1_heart")
		hpState.ZERO:
			sprite.play("0_hearts")

func _on_player_player_died():
	toggle_death_note()

func toggle_death_note():
	var deathNote = $DeathNote
	deathNote.visible = not deathNote.visible
