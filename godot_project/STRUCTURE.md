# Project Structure

This document describes the organized structure of the BakaCirno game project.

## Directory Structure

```text
godot_project/
├── assets/                 # Game assets (textures, sounds, fonts)
│   ├── fonts/             # Font files
│   ├── sounds/            # Audio files (music and SFX)
│   └── textures/          # Image assets
├── docs/                  # Documentation files
│   ├── Howtoplay.txt      # Game instructions
│   └── Todo.txt           # Development tasks and notes
├── scenes/                # Godot scene files (.tscn)
│   ├── Background.tscn
│   ├── Bullet.tscn
│   ├── Enemy.tscn
│   ├── Explosion.tscn
│   ├── HighScoreText.tscn
│   ├── Main.tscn
│   ├── Player.tscn
│   ├── PointBullet.tscn
│   └── TextOverlay.tscn
├── scripts/               # GDScript files (.gd)
│   ├── Background.gd
│   ├── Bullet.gd
│   ├── CircleShots.gd
│   ├── Enemy.gd
│   ├── Explosion.gd
│   ├── HighScoreText.gd
│   ├── Main.gd
│   ├── Player.gd
│   ├── PointBullet.gd
│   ├── RandomShots.gd
│   ├── Sound.gd
│   └── TextOverlay.gd
├── .vscode/               # VS Code configuration
├── icon.svg               # Project icon
├── project.godot          # Godot project file
└── README.md              # Project documentation
```

## Cleaned Up Files

The following files have been removed as they were unused test/debug files:

- `test_fixes.gd` - Test script for bug fixes
- `test_player_animation.gd` - Animation testing script
- `test_player_animation.tscn` - Test scene for animation
- `test_font_loading.gd` - Font loading test
- `test_difficulty_display.gd` - Difficulty display test
- `debug_animation.gd` - Debug helper script
- `assets/textures/placeholder.tres` - Unused placeholder texture

## Organization Benefits

1. **Improved Navigation**: Files are now grouped by type, making it easier to
   find specific assets or scripts
2. **Better Maintainability**: Clear separation of concerns with dedicated
   folders for different file types
3. **Professional Structure**: Follows common game development project
   organization patterns
4. **Cleaner Root Directory**: Reduced clutter in the main project directory
5. **Documentation**: Important project documents are now in a dedicated `docs`
   folder

## Development Notes

- All scene files (.tscn) have been updated to reference the correct script
  paths in the `scripts/` directory
- All scripts have been updated to reference the correct scene paths in the
  `scenes/` directory
- The project structure is now more scalable for future development
