# Dynamic Bullet Pattern System - Usage Guide

The new dynamic bullet pattern system provides a flexible framework for creating
and managing complex bullet patterns in your BakaCirno game. This guide explains
how to use the system effectively.

## System Overview

The system consists of several key components:

1. **BulletPattern** - Base class for all bullet patterns
2. **PatternParameters** - Configuration class for pattern properties
3. **PatternManager** - Manages pattern selection, sequencing, and difficulty
4. **DifficultyScaler** - Handles dynamic difficulty adjustment

## Basic Usage

### Creating a Simple Pattern

```gdscript
# In your enemy script
func spawn_simple_circle():
    var params = PatternParameters.create_circle_preset()
    params.bullet_speed = 150.0
    params.bullet_density = 12

    pattern_manager.spawn_pattern("circle", global_position, player_position, params)
```

### Using the Pattern Manager

```gdscript
# Initialize pattern manager in enemy _ready()
func _ready():
    pattern_manager = PatternManager.new()
    add_child(pattern_manager)
    pattern_manager.set_enemy_owner(self)
    pattern_manager.auto_spawn_enabled = true
```

## Available Pattern Types

### 1. Circle Pattern

- Creates bullets in a complete circle
- Parameters: bullet_density, bullet_speed, rotation_speed
- Example:

```gdscript
var params = PatternParameters.create_circle_preset()
params.bullet_density = 18  # Number of bullets in circle
params.rotation_speed = 2.0  # Rotation speed in radians/sec
pattern_manager.spawn_pattern("circle", spawn_pos, target_pos, params)
```

### 2. Spiral Pattern

- Creates expanding or contracting spirals
- Parameters: bullet_density, rotation_speed, spiral_arms
- Example:

```gdscript
var params = PatternParameters.create_spiral_preset()
params.set_custom_param("spiral_arms", 3)
params.rotation_speed = 1.5
pattern_manager.spawn_pattern("spiral", spawn_pos, target_pos, params)
```

### 3. Wave Pattern

- Creates sine wave formations
- Parameters: frequency, amplitude, bullet_density
- Example:

```gdscript
var params = PatternParameters.create_wave_preset()
params.frequency = 2.0
params.amplitude = 100.0
params.set_custom_param("continuous_wave", true)
pattern_manager.spawn_pattern("wave", spawn_pos, target_pos, params)
```

### 4. Star Pattern

- Creates star formations with variable points
- Parameters: star_points, bullet_density, rotation_speed
- Example:

```gdscript
var params = PatternParameters.create_star_preset()
params.set_custom_param("star_points", 8)
params.set_custom_param("complex_star", true)
pattern_manager.spawn_pattern("star", spawn_pos, target_pos, params)
```

### 5. Random Pattern

- Shoots bullets toward player with variation
- Parameters: bullet_density, homing_strength, spawn_rate
- Example:

```gdscript
var params = PatternParameters.create_random_preset()
params.homing_strength = 0.3
params.spawn_rate = 3.0
pattern_manager.spawn_pattern("random", spawn_pos, target_pos, params)
```

### 6. Burst Pattern

- Creates rapid bursts of bullets
- Parameters: burst_count, burst_delay, bullet_density
- Example:

```gdscript
var params = PatternParameters.new()
params.pattern_type = PatternParameters.PatternType.BURST
params.burst_count = 3
params.burst_delay = 0.5
params.set_custom_param("burst_type", "spread")
pattern_manager.spawn_pattern("burst", spawn_pos, target_pos, params)
```

## Advanced Configuration

### Custom Pattern Parameters

```gdscript
# Create custom parameters
var params = PatternParameters.new()
params.bullet_speed = 200.0
params.bullet_density = 24
params.rotation_speed = 1.0
params.homing_strength = 0.2
params.pattern_duration = 8.0

# Set custom parameters
params.set_custom_param("special_behavior", true)
params.set_custom_param("color_cycle", ["red", "blue", "yellow"])

# Apply difficulty scaling
params.apply_difficulty_scaling(2.0)
```

### Pattern Sequencing

```gdscript
# Queue multiple patterns in sequence
pattern_manager.queue_pattern("circle", 0.0, spawn_pos, target_pos)
pattern_manager.queue_pattern("spiral", 2.0, spawn_pos, target_pos)
pattern_manager.queue_pattern("wave", 4.0, spawn_pos, target_pos)
```

### Difficulty Scaling

```gdscript
# Configure difficulty scaler
pattern_manager.difficulty_scaler.enable_time_scaling(true)
pattern_manager.difficulty_scaler.enable_performance_scaling(true)
pattern_manager.difficulty_scaler.time_scale_rate = 0.1

# Record events for difficulty adjustment
pattern_manager.difficulty_scaler.record_player_death()
pattern_manager.difficulty_scaler.record_enemy_kill()
```

## Creating Custom Patterns

### 1. Extend BulletPattern

```gdscript
extends BulletPattern
class_name MyCustomPattern

var custom_property: float = 0.0

func initialize_pattern():
    super.initialize_pattern()
    custom_property = pattern_params.get_custom_param("custom_value", 1.0)

func update_pattern(delta: float):
    super.update_pattern(delta)

    # Your custom pattern logic here
    if should_spawn_bullet():
        spawn_custom_bullet()

func spawn_custom_bullet():
    var bullet_texture = get_bullet_texture()
    var bullet_direction = calculate_custom_direction()
    var bullet_velocity = bullet_direction * pattern_params.bullet_speed

    spawn_bullet(bullet_texture, spawn_position, bullet_velocity)
```

### 2. Register Custom Pattern

```gdscript
# In your pattern manager setup
pattern_manager.register_pattern("my_custom", MyCustomPattern, 1.0)
```

## Pattern Manager Configuration

### Auto-Spawn Settings

```gdscript
# Configure automatic pattern spawning
pattern_manager.auto_spawn_enabled = true
pattern_manager.min_pattern_interval = 1.0
pattern_manager.max_pattern_interval = 3.0

# Set pattern weights for selection
pattern_manager.set_pattern_weight("circle", 1.0)
pattern_manager.set_pattern_weight("spiral", 0.8)
pattern_manager.set_pattern_weight("wave", 0.6)
```

### Pattern Constraints

```gdscript
# Limit concurrent patterns
pattern_manager.get_max_concurrent_patterns() # Returns max based on difficulty

# Force specific pattern
pattern_manager.force_next_pattern("star")

# Clear all patterns
pattern_manager.clear_all_patterns()
```

## Tips and Best Practices

### 1. Parameter Balancing

- Start with preset parameters and adjust gradually
- Use difficulty scaling to make patterns progressively harder
- Test patterns at different difficulty levels

### 2. Performance Considerations

- Limit the number of concurrent patterns
- Use appropriate bullet_density values
- Consider pattern_duration for cleanup

### 3. Visual Design

- Use color schemes consistently
- Vary bullet speeds for visual interest
- Combine patterns for complex effects

### 4. Player Experience

- Provide visual telegraphing for complex patterns
- Leave safe spaces for player navigation
- Balance challenge with fairness

## Debugging and Monitoring

### Pattern Statistics

```gdscript
# Get pattern manager statistics
var stats = pattern_manager.get_pattern_stats()
print("Active patterns: ", stats.active_patterns)
print("Current difficulty: ", stats.current_difficulty)
print("Available patterns: ", stats.available_patterns)
```

### Difficulty Statistics

```gdscript
# Get difficulty scaler statistics
var difficulty_stats = pattern_manager.difficulty_scaler.get_stats()
pattern_manager.difficulty_scaler.debug_print_stats()
```

## Example: Complex Boss Pattern

```gdscript
# Create a complex boss attack sequence
func boss_attack_sequence():
    # Phase 1: Circle barrage
    var circle_params = PatternParameters.create_circle_preset()
    circle_params.bullet_density = 24
    circle_params.rotation_speed = 1.5
    pattern_manager.spawn_pattern("circle", global_position, player_position, circle_params)

    # Phase 2: Spiral storm (delayed)
    var spiral_params = PatternParameters.create_spiral_preset()
    spiral_params.set_custom_param("spiral_arms", 4)
    spiral_params.bullet_density = 32
    pattern_manager.queue_pattern("spiral", 2.0, global_position, player_position, spiral_params)

    # Phase 3: Wave finale (delayed)
    var wave_params = PatternParameters.create_wave_preset()
    wave_params.frequency = 3.0
    wave_params.amplitude = 150.0
    wave_params.set_custom_param("continuous_wave", true)
    pattern_manager.queue_pattern("wave", 4.0, global_position, player_position, wave_params)
```

This system provides a powerful foundation for creating intricate and dynamic
bullet patterns that can scale with difficulty and provide engaging gameplay
experiences.
