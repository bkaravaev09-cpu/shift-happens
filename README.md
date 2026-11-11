# Shift Happens

A cozy voxel puzzle-platformer for **GitHub Game Off 2026** (theme: **SHIFT**).
A journey through *Alice's Adventures in Wonderland* — the levels are made of the book's
own lines. Like Alice, you keep changing size: press **Shift** to switch your letter between
lowercase and UPPERCASE, and **Caps Lock** when the Queen shouts and the whole world follows.

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
10 chapters from the book. Plain text files in `levels/`: format at the top of
`scripts/level.gd`, special props (water, Cheshire grins, tea trays, cards) in
`scripts/props.gd`.

## Credits
- Code & design: <your name>
- Pixel font for voxels: original, made for this game.
- Story text: *Alice's Adventures in Wonderland* by Lewis Carroll (1865), public domain.
- AI-assisted code. No AI-generated art, music or text.
