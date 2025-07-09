# Quick Font Test Instructions

## Immediate Testing (No Download Required)

The game will work immediately using the system default font. You'll see text
displayed, though it may not have the pixel aesthetic of the original game.

## For Better Visual Match

1. **Download Press Start 2P font:**
   - Visit: https://fonts.google.com/specimen/Press+Start+2P
   - Click "Download family"
   - Extract the ZIP file
   - Find "PressStart2P-Regular.ttf"
   - Copy it to `assets/fonts/PressStart2P.ttf`

2. **Alternative pixel fonts:**
   - Pixel Operator: https://www.dafont.com/pixel-operator.font
   - 04B_03: https://www.dafont.com/04b-03.font
   - Any TTF font you prefer

## Font Detection Priority

The game checks for fonts in this order:

1. `Font.ttf` (original name)
2. `PressStart2P.ttf` (pixel font)
3. `game_font.ttf` (generic)
4. `pixel_font.ttf` (another pixel option)
5. System default font (fallback)

## Testing

1. Add any TTF font to `assets/fonts/`
2. Open the project in Godot
3. Run the game - text should appear using your font
