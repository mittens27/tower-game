extends Node

@onready var music_player = $MusicPlayer
@onready var ui_player = $UISoundPlayer

@export var sound_library : SoundLibrary

const MAX_SIMULTANEOUS_SFX = 10

func _ready():
	Events.game_reset.connect(_on_game_reset)
	Events.attack_landed.connect(_on_attack_landed)
	Events.player_jumped.connect(_on_player_jumped)
	Events.player_slammed.connect(_on_player_slammed)
	Events.player_hurt.connect(_on_player_hurt)
	Events.entity_died.connect(_on_entity_died)
	Events.coin_collected.connect(_on_coin_collected)
	Events.player_fell.connect(_on_player_fell)
	Events.switch_toggled.connect(_on_switch_toggled)
	Events.spores_collected.connect(_on_spores_collected)
	Events.spore_jump.connect(_on_spore_jump)
	Events.log_door_opened.connect(_on_log_door_opened)
	Events.potion_collected.connect(_on_potion_collected)
	
func play_music(stream: AudioStream):
	music_player.stream = stream
	music_player.play()
	
func play_ui(stream: AudioStream):
	ui_player.stream = stream
	ui_player.play()
	
func play_sfx(id: String, position: Vector2):
	if get_child_count() > MAX_SIMULTANEOUS_SFX:
		return
	
	var matches = []

	for key in sound_library.sounds.keys():
		if key.begins_with(id):
			matches.append(sound_library.sounds[key])
			
	if matches.is_empty():
		return
		
	var sound : SoundData = matches.pick_random()
	  
	var player = AudioStreamPlayer2D.new()
	player.stream = sound.stream
	player.global_position = position
	player.bus = "SFX"

	player.volume_db = sound.volume_db
	
	var pitch = sound.pitch_scale
	pitch += randf_range(-sound.random_pitch, sound.random_pitch)
	
	player.pitch_scale = pitch
	
	add_child(player)
	player.play()
	
	player.finished.connect(player.queue_free)

func _on_attack_landed(attacker, target, attack_data):
	if attack_data == null:
		return
	if attack_data.hit_sound != "" and attacker.is_in_group("player"):
		play_sfx(attack_data.hit_sound, target.global_position)

func _on_player_jumped(player):
	play_sfx("jump", player.global_position)

func _on_player_slammed(player):
	play_sfx("slam", player.global_position)

func _on_player_hurt(player):
	if player.is_in_group("player"):
		play_sfx("hurt", player.global_position)

func _on_entity_died(entity):
	if entity.is_in_group("player"):
		music_player.stop()
		play_sfx("player_die", entity.global_position)
	elif entity.is_in_group("enemies"):
		play_sfx("die", entity.global_position)
		
func _on_player_fell(player):
	music_player.stop()
	play_sfx("fall", player.global_position)

func _on_coin_collected(player):
	play_sfx("coin", player.global_position)
	
func _on_game_reset():
	music_player.play()
	
func _on_switch_toggled(player):
	play_sfx("switch", player.global_position)
	
func _on_spores_collected(player):
	play_sfx("spores", player.global_position)

func _on_spore_jump(player):
	play_sfx("superJump", player.global_position)

func _on_log_door_opened(door):
	print("log door sfx")
	play_sfx("doorOpen1", door.global_position)
	
func _on_potion_collected(player, potion_data):
	if potion_data.type == "healing_potion":
		play_sfx(potion_data.collect_sound, player.global_position)
