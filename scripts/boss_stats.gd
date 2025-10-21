extends Resource
class_name BossStats

## Boss Stats Resource
## Zentrale Konfiguration für alle Boss-Eigenschaften
## Kann im Editor angepasst werden ohne Code zu ändern

#region CORE_STATS
@export_group("Core Stats")
## Boss Health für ~30s Time-To-Kill (bei ~400 DPS)
@export var max_health: int = 12000
@export var base_speed: float = 140.0
@export var score_value: int = 100
@export var scrap_award: int = 50
#endregion

#region COLLISION
@export_group("Collision")
@export var collision_layer: int = 2
@export var collision_mask: int = 14
@export var arena_size: int = 1792
#endregion

#region PHASE_CONFIGURATION
@export_group("Phase System")
## Gesundheits-Schwellenwerte für Phasenwechsel (%)
@export var phase_2_threshold: float = 0.66  # Bei 66% Health -> Phase 2
@export var phase_3_threshold: float = 0.33  # Bei 33% Health -> Phase 3

## Speed-Multiplikatoren pro Phase
@export var phase_1_speed_mult: float = 1.0
@export var phase_2_speed_mult: float = 1.3
@export var phase_3_speed_mult: float = 1.6

## Regenerations-Rate pro Phase
@export var phase_1_regen: float = 0.0
@export var phase_2_regen: float = 0.5
@export var phase_3_regen: float = 1.2
#endregion

#region MINION_SPAWNING
@export_group("Minion Spawning")
@export var minion_cooldown: float = 6.0
@export var minion_base_count: int = 3
@export var minion_min_distance: float = 120.0
@export var minion_max_distance: float = 240.0

## Anzahl Minions pro Phase
@export var phase_1_minions: int = 3
@export var phase_2_minions: int = 5
@export var phase_3_minions: int = 7
#endregion

#region SHIELD_SYSTEM
@export_group("Shield System")
@export var shield_max_value: float = 900.0
@export var shield_duration: float = 7.0
@export var shield_activation_health_percent: float = 0.5  # Bei 50% Health
@export var shield_cooldown: float = 15.0
#endregion

#region GRAVITY_WELL
@export_group("Gravity Well Attack")
@export var gravity_well_strength: float = 450.0
@export var gravity_well_pull_distance: float = 120.0
@export var gravity_well_damage: int = 35
@export var gravity_well_duration: float = 4.0
@export var gravity_well_cooldown: float = 8.0
@export var gravity_damage_tick_rate: float = 0.5  # Damage alle 0.5s
#endregion

#region PLASMA_WALLS
@export_group("Plasma Wall Attack")
@export var plasma_wall_damage_radius: float = 140.0
@export var plasma_wall_base_damage: int = 30
@export var plasma_wall_damage_per_phase: int = 10
@export var plasma_wall_duration: float = 6.0
@export var plasma_wall_cooldown: float = 10.0
@export var plasma_wall_count_phase_1: int = 2
@export var plasma_wall_count_phase_2: int = 3
@export var plasma_wall_count_phase_3: int = 4
#endregion

#region LASER_ATTACK
@export_group("Laser Attack")
@export var laser_damage: int = 25
@export var laser_cooldown: float = 3.5
@export var laser_speed: float = 400.0
@export var laser_range: float = 800.0
#endregion

#region SPECIAL_ATTACKS
@export_group("Special Attacks")
@export var special_attack_cooldown: float = 4.5
@export var charge_attack_speed: float = 300.0
@export var charge_attack_damage: int = 40
@export var stomp_attack_radius: float = 200.0
@export var stomp_attack_damage: int = 50
#endregion

#region VISUAL_CONFIGURATION
@export_group("Visuals")
@export var health_bar_max_width: float = 60.0
@export var sprite_enabled: bool = true
@export var damage_flash_duration: float = 0.15
@export var death_animation_duration: float = 1.0
#endregion

#region HELPER_FUNCTIONS
## Gibt den aktuellen Speed-Multiplikator für eine Phase zurück
func get_speed_multiplier(phase: int) -> float:
	match phase:
		1: return phase_1_speed_mult
		2: return phase_2_speed_mult
		3: return phase_3_speed_mult
		_: return 1.0

## Gibt die Anzahl zu spawnender Minions für eine Phase zurück
func get_minion_count(phase: int) -> int:
	match phase:
		1: return phase_1_minions
		2: return phase_2_minions
		3: return phase_3_minions
		_: return minion_base_count

## Gibt die Regenerations-Rate für eine Phase zurück
func get_regen_rate(phase: int) -> float:
	match phase:
		1: return phase_1_regen
		2: return phase_2_regen
		3: return phase_3_regen
		_: return 0.0

## Gibt die Anzahl Plasma-Wände für eine Phase zurück
func get_plasma_wall_count(phase: int) -> int:
	match phase:
		1: return plasma_wall_count_phase_1
		2: return plasma_wall_count_phase_2
		3: return plasma_wall_count_phase_3
		_: return 2

## Berechnet den Plasma-Wall-Schaden basierend auf Phase
func get_plasma_wall_damage(phase: int) -> int:
	return plasma_wall_base_damage + (plasma_wall_damage_per_phase * (phase - 1))

## Gibt die aktuelle Phase basierend auf Health-Prozent zurück
func get_phase_from_health_percent(health_percent: float) -> int:
	if health_percent > phase_2_threshold:
		return 1
	elif health_percent > phase_3_threshold:
		return 2
	else:
		return 3
#endregion
