# BakaCirno - Godot 4 Migration

This is a complete migration of the BakaCirno bullet hell game from MonoGame
(C#) to Godot 4 using GDScript. The game features a bullet hell gameplay with
Cirno-themed graphics and music.

## 🎮 Game Features

- **Player Movement**: WASD or Arrow Keys
- **Shooting**: Space Bar or Left Ctrl
- **Power Shot**: Hold Left Shift while shooting
- **Enemy Patterns**: Circle shots and random bullet patterns
- **Scoring System**: Points for destroying enemies and collecting point bullets
- **Background Music**: Cirno theme song during gameplay
- **Game States**: Menu, Playing, Game Over

## 📁 Project Structure

```
godot_project/
├── Main.gd & Main.tscn          # Main game manager and scene
├── Player.gd & Player.tscn      # Player character with movement and shooting
├── Enemy.gd & Enemy.tscn        # Enemy AI with bullet patterns
├── Bullet.gd & Bullet.tscn      # Player and enemy bullets
├── Explosion.gd & Explosion.tscn # Death animations
├── PointBullet.gd & PointBullet.tscn # Collectible point items
├── TextOverlay.gd & TextOverlay.tscn # UI text display
├── HighScoreText.gd & HighScoreText.tscn # Game over screen
├── CircleShots.gd               # Circular bullet pattern
├── RandomShots.gd               # Random bullet pattern
├── Sound.gd                     # Audio management
├── Background.gd & Background.tscn # Background images
└── assets/                      # Game assets (textures, sounds, fonts)
    ├── textures/               # PNG image files
    ├── sounds/                 # WAV/OGG audio files
    └── fonts/                  # TTF/OTF font files
```

## 🚀 Setup Instructions

### 1. Asset Migration

The original MonoGame project assets need to be migrated:

1. **Copy texture files** from `BakaCirno/assets/textures/` to
   `godot_project/assets/textures/`
2. **Copy sound files** from `BakaCirno/assets/sound/` to
   `godot_project/assets/sounds/`
3. **Replace font files**: XNB fonts need to be replaced with TTF/OTF
   equivalents

Run the migration helper script:

```bash
cd godot_project
chmod +x migrate_assets.sh
./migrate_assets.sh
```

### 2. Audio Conversion (for Web Export)

For web compatibility, convert audio files:

- **WAV files**: Keep as-is or convert to OGG for smaller size
- **WMA files**: Convert to OGG format (required for web)

### 3. Font Setup

Replace the XNB font files with web-compatible fonts:

**Option 1: Quick Setup (Recommended)**

```bash
chmod +x setup_fonts.sh
./setup_fonts.sh
```

**Option 2: Manual Setup**

- Download a TTF/OTF font (e.g., "Press Start 2P" from Google Fonts)
- Place it in `assets/fonts/` directory
- Rename to one of these for auto-detection:
  - `Font.ttf` (matches original name)
  - `PressStart2P.ttf` (popular pixel font)
  - `game_font.ttf` or `pixel_font.ttf`

**Option 3: Use System Font**

- No action needed - the game will use the system default font
- May not match the original pixel aesthetic

### 4. Godot Project Setup

1. Open Godot 4.4+
2. Import the project by selecting `godot_project/project.godot`
3. Check asset import settings in the FileSystem dock
4. Verify all textures import correctly
5. Test audio playback

## 🎯 Game Controls

| Action         | Keys               |
| -------------- | ------------------ |
| Move           | WASD or Arrow Keys |
| Shoot          | Space or Left Ctrl |
| Power Shot     | Hold Left Shift    |
| Start Game     | Enter (from menu)  |
| Return to Menu | Escape             |
| Exit Game      | Escape + F1        |

## 🔧 Migration Checklist

### ✅ Completed Components

- [x] **Main.tscn + Main.gd** - Game state management
- [x] **TextOverlay.tscn + TextOverlay.gd** - Score/time display
- [x] **HighScoreText.tscn + HighScoreText.gd** - Game over screen
- [x] **Player.tscn + Player.gd** - Player mechanics
- [x] **Bullet.tscn + Bullet.gd** - Bullet system
- [x] **Explosion.tscn + Explosion.gd** - Death animations
- [x] **Enemy.tscn + Enemy.gd** - Enemy AI
- [x] **CircleShots.gd** - Circular bullet patterns
- [x] **RandomShots.gd** - Random bullet patterns
- [x] **PointBullet.tscn + PointBullet.gd** - Collectible items
- [x] **Sound.gd** - Audio management
- [x] **Background.tscn + Background.gd** - Background system

### 🔄 Remaining Tasks

- [ ] **Asset Migration** - Copy and convert original assets
- [ ] **Font Replacement** - Replace XNB fonts with TTF/OTF
- [ ] **Audio Conversion** - Convert WMA to OGG for web
- [ ] **Testing** - Verify all gameplay mechanics
- [ ] **Web Export** - Configure for HTML5 deployment

## 🌐 Web Export Setup

To export for web (HTML5):

1. Install web export templates in Godot
2. Convert WMA audio files to OGG
3. Check that all assets are web-compatible
4. Configure export settings:
   - Set canvas resize policy
   - Enable required web features
   - Test in browser

## 🎵 Audio Notes

The original game uses:

- **CirnoThemeSongWMA.wma** - Main background music (convert to OGG)
- **ButtonPlaySelectSFX.wav** - Menu selection sound
- **PlayershotSFX.wav** - Player shooting sound
- **DeathSFX.wav** - Player death sound
- **enemyDeathSFX.wav** - Enemy death sound
- **EnemyShootSFX1.wav** - Enemy circle shot sound
- **EnemyShootSFX2.wav** - Enemy random shot sound

## 🐛 Troubleshooting

### Common Issues

1. **Missing Assets**: Ensure all files are copied to correct directories
2. **Font Errors**: Replace XNB fonts with TTF/OTF files
3. **Audio Not Playing**: Check file formats and import settings
4. **Web Export Issues**: Verify all assets are web-compatible

### Performance Tips

- Use compressed texture formats for web
- Optimize audio file sizes
- Test performance in web browser during development

## 📝 Development Notes

This migration maintains the original game's logic while adapting to Godot's
node-based architecture. Key changes include:

- **Frame-based to Delta-based**: Timing converted from frame-based to delta
  time
- **Rectangle to Rect2**: Collision system adapted to Godot's types
- **SpriteBatch to Sprite2D**: Rendering system modernized
- **XNA to Godot Audio**: Audio system completely replaced

## 🎉 Credits

Original MonoGame version by the BakaCirno development team. Godot 4 migration
implemented following the original game design and logic.

---

Ready to play some bullet hell action with Cirno! 🧊✨
