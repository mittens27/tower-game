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
	
	match state:
		hpState.THREE:
			sprite.play("3_hearts")
		hpState.TWO:
			sprite.play("2_hearts")
		hpState.ONE:
			sprite.play("1_heart")
		hpState.ZERO:
			sprite.play("0_hearts")
	
func _on_coin_amount_changed(amount):
	$Coins.text = "Coins: %d" % amount
	
func _on_player_health_changed(current_health):
	#print("Health Recieved:", value)
	update_hearts(current_health)
	
func update_hearts(current_health):
	var hp = current_health
	if hp == 3:
		state = hpState.THREE
	elif hp == 2:
		state = hpState.TWO
	elif hp == 1:
		state = hpState.ONE
	else:
		state = hpState.ZERO

func _on_player_player_died():
	toggle_death_note()

func toggle_death_note():
	var deathNote = $DeathNote
	deathNote.visible = not deathNote.visible
