extends Node

#world
signal entity_died(entity)
signal attack_landed(attacker, target, attack_data)
signal damage_taken(target, attack_data)

#player
signal player_hurt(player)
signal player_health_changed(current_health)
