extends Node
class_name DifficultyScaler

# Handles dynamic difficulty scaling based on time, player performance, and game state

# Base difficulty settings
var base_difficulty: float = 1.0
var current_difficulty: float = 1.0
var min_difficulty: float = 0.5
var max_difficulty: float = 5.0

# Time-based scaling
var time_based_scaling: bool = true
var game_time: float = 0.0
var time_scale_rate: float = 0.1 # Difficulty increase per minute
var time_scale_curve: float = 1.0 # Exponential curve factor

# Performance-based scaling
var performance_based_scaling: bool = true
var player_deaths: int = 0
var enemy_kills: int = 0
var accuracy_percentage: float = 100.0
var survival_time: float = 0.0

# Performance scaling weights
var death_penalty: float = -0.2 # Difficulty decrease per death
var kill_bonus: float = 0.1 # Difficulty increase per kill
var accuracy_factor: float = 0.5 # How much accuracy affects difficulty
var survival_bonus: float = 0.05 # Bonus per minute survived

# Adaptive scaling
var adaptive_scaling: bool = true
var recent_deaths: Array[float] = [] # Timestamps of recent deaths
var death_window: float = 30.0 # Time window for recent deaths (seconds)
var max_recent_deaths: int = 3 # Max deaths before scaling down

# Difficulty curve settings
var difficulty_curve: Array[Vector2] = [
	Vector2(0.0, 1.0), # Start at normal difficulty
	Vector2(60.0, 1.3), # 1 minute: slightly harder
	Vector2(180.0, 1.6), # 3 minutes: moderately harder
	Vector2(300.0, 2.0), # 5 minutes: significantly harder
	Vector2(600.0, 2.5), # 10 minutes: very hard
	Vector2(1200.0, 3.0) # 20 minutes: extreme
]

# Signals
signal difficulty_changed(new_difficulty: float)
signal difficulty_tier_changed(tier: String)

func _ready():
	current_difficulty = base_difficulty

func update_difficulty(delta: float):
	"""Update difficulty based on all factors"""
	game_time += delta
	survival_time += delta

	var new_difficulty = calculate_difficulty()

	if abs(new_difficulty - current_difficulty) > 0.01:
		var old_tier = get_difficulty_tier(current_difficulty)
		current_difficulty = clamp(new_difficulty, min_difficulty, max_difficulty)

		emit_signal("difficulty_changed", current_difficulty)

		var new_tier = get_difficulty_tier(current_difficulty)
		if new_tier != old_tier:
			emit_signal("difficulty_tier_changed", new_tier)

func calculate_difficulty() -> float:
	"""Calculate the current difficulty based on all factors"""
	var difficulty = base_difficulty

	# Time-based scaling
	if time_based_scaling:
		difficulty += calculate_time_difficulty()

	# Performance-based scaling
	if performance_based_scaling:
		difficulty += calculate_performance_difficulty()

	# Adaptive scaling
	if adaptive_scaling:
		difficulty += calculate_adaptive_difficulty()

	return difficulty

func calculate_time_difficulty() -> float:
	"""Calculate difficulty increase based on time"""
	var time_minutes = game_time / 60.0

	# Use curve if available
	if not difficulty_curve.is_empty():
		return interpolate_difficulty_curve(game_time) - base_difficulty

	# Fallback to linear scaling
	return time_minutes * time_scale_rate * pow(time_minutes, time_scale_curve - 1.0)

func interpolate_difficulty_curve(time: float) -> float:
	"""Interpolate difficulty from curve"""
	if difficulty_curve.is_empty():
		return base_difficulty

	# Find the two points to interpolate between
	var point1 = difficulty_curve[0]
	var point2 = difficulty_curve[-1]

	for i in range(difficulty_curve.size() - 1):
		if time >= difficulty_curve[i].x and time <= difficulty_curve[i + 1].x:
			point1 = difficulty_curve[i]
			point2 = difficulty_curve[i + 1]
			break

	# Linear interpolation
	if point1.x == point2.x:
		return point1.y

	var t = (time - point1.x) / (point2.x - point1.x)
	return lerp(point1.y, point2.y, t)

func calculate_performance_difficulty() -> float:
	"""Calculate difficulty adjustment based on player performance"""
	var performance_adjustment = 0.0

	# Death penalty
	performance_adjustment += player_deaths * death_penalty

	# Kill bonus
	performance_adjustment += enemy_kills * kill_bonus

	# Accuracy factor
	var accuracy_adjustment = (accuracy_percentage - 50.0) / 100.0 * accuracy_factor
	performance_adjustment += accuracy_adjustment

	# Survival bonus
	var survival_minutes = survival_time / 60.0
	performance_adjustment += survival_minutes * survival_bonus

	return performance_adjustment

func calculate_adaptive_difficulty() -> float:
	"""Calculate difficulty adjustment based on recent performance"""
	var adaptive_adjustment = 0.0

	# Clean old death timestamps
	var current_time = game_time
	recent_deaths = recent_deaths.filter(func(death_time): return current_time - death_time <= death_window)

	# Scale down if too many recent deaths
	if recent_deaths.size() >= max_recent_deaths:
		adaptive_adjustment = -0.5 # Significant difficulty reduction
	elif recent_deaths.size() >= max_recent_deaths / 2:
		adaptive_adjustment = -0.2 # Moderate difficulty reduction

	return adaptive_adjustment

func record_player_death():
	"""Record a player death for difficulty scaling"""
	player_deaths += 1
	recent_deaths.append(game_time)

	print("Player death recorded. Total deaths: ", player_deaths)

func record_enemy_kill():
	"""Record an enemy kill for difficulty scaling"""
	enemy_kills += 1

	print("Enemy kill recorded. Total kills: ", enemy_kills)

func update_accuracy(shots_fired: int, shots_hit: int):
	"""Update accuracy statistics"""
	if shots_fired > 0:
		accuracy_percentage = (shots_hit / float(shots_fired)) * 100.0

func reset_survival_time():
	"""Reset survival time (called when player dies)"""
	survival_time = 0.0

func get_difficulty_tier(difficulty: float = -1.0) -> String:
	"""Get difficulty tier name"""
	if difficulty < 0:
		difficulty = current_difficulty

	if difficulty < 0.8:
		return "Very Easy"
	elif difficulty < 1.2:
		return "Easy"
	elif difficulty < 1.5:
		return "Normal"
	elif difficulty < 2.0:
		return "Hard"
	elif difficulty < 2.5:
		return "Very Hard"
	elif difficulty < 3.0:
		return "Extreme"
	else:
		return "Nightmare"

func get_difficulty_multiplier() -> float:
	"""Get the current difficulty as a multiplier"""
	return current_difficulty / base_difficulty

func get_scaled_value(base_value: float, scale_type: String = "linear") -> float:
	"""Get a value scaled by current difficulty"""
	var multiplier = get_difficulty_multiplier()

	match scale_type:
		"linear":
			return base_value * multiplier
		"square":
			return base_value * multiplier * multiplier
		"sqrt":
			return base_value * sqrt(multiplier)
		"log":
			return base_value * (1.0 + log(multiplier))
		_:
			return base_value * multiplier

func set_difficulty_curve(curve: Array[Vector2]):
	"""Set a custom difficulty curve"""
	difficulty_curve = curve
	# Sort by time
	difficulty_curve.sort_custom(func(a, b): return a.x < b.x)

func add_difficulty_point(time: float, difficulty: float):
	"""Add a point to the difficulty curve"""
	difficulty_curve.append(Vector2(time, difficulty))
	difficulty_curve.sort_custom(func(a, b): return a.x < b.x)

func enable_time_scaling(enabled: bool):
	"""Enable or disable time-based scaling"""
	time_based_scaling = enabled

func enable_performance_scaling(enabled: bool):
	"""Enable or disable performance-based scaling"""
	performance_based_scaling = enabled

func enable_adaptive_scaling(enabled: bool):
	"""Enable or disable adaptive scaling"""
	adaptive_scaling = enabled

func reset_difficulty():
	"""Reset difficulty to base level"""
	current_difficulty = base_difficulty
	game_time = 0.0
	survival_time = 0.0
	player_deaths = 0
	enemy_kills = 0
	accuracy_percentage = 100.0
	recent_deaths.clear()

	emit_signal("difficulty_changed", current_difficulty)

func get_stats() -> Dictionary:
	"""Get difficulty statistics"""
	return {
		"current_difficulty": current_difficulty,
		"difficulty_tier": get_difficulty_tier(),
		"game_time": game_time,
		"survival_time": survival_time,
		"player_deaths": player_deaths,
		"enemy_kills": enemy_kills,
		"accuracy": accuracy_percentage,
		"recent_deaths": recent_deaths.size(),
		"multiplier": get_difficulty_multiplier()
	}

func debug_print_stats():
	"""Print debug information about difficulty"""
	var stats = get_stats()
	print("=== Difficulty Stats ===")
	print("Difficulty: ", stats.difficulty_tier, " (", stats.current_difficulty, ")")
	print("Game Time: ", stats.game_time, "s")
	print("Survival Time: ", stats.survival_time, "s")
	print("Deaths: ", stats.player_deaths)
	print("Kills: ", stats.enemy_kills)
	print("Accuracy: ", stats.accuracy, "%")
	print("Recent Deaths: ", stats.recent_deaths)
	print("Multiplier: ", stats.multiplier)
	print("========================")
