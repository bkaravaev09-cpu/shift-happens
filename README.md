# Shift Happens

A cozy voxel puzzle-platformer for **GitHub Game Off 2026** (theme: **SHIFT**).
You are a single letter. Press **Shift** to change your case, **Caps Lock** to change the
case of the whole world, and restore a scattered letter to a friend.

## Controls
| Key | Action |
|---|---|
| A / D, arrows | move |
| Space / W | jump |
| Shift | lowercase ↔ UPPERCASE hero |
| Caps Lock / Tab | lowercase ↔ UPPERCASE world |
| R | restart level |

## Run
Open the folder in Godot 4.5+ and press F5.
Bot test: `godot --headless --path . res://tests/autoplay.tscn` → prints `ALL LEVELS DONE`.

## Levels
Plain text files in `levels/`, format described at the top of `scripts/level.gd`.

## Credits
- Code & design: <your name>
- Pixel font for voxels: original, made for this game.
- AI-assisted code. No AI-generated art, music or text.
