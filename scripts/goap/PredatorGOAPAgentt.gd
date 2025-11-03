extends GOAPAgent
class_name PredatorGOAPAgent

# Stats
var hunger: float = 0.0
var max_hunger: float = 100.0
var hunger_rate: float = 1.0 # Hunger per second

var food_count: int = 0
var experience: int = 0
var level: int = 1

# Health component reference
var health_component: HealthComponent
