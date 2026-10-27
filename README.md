# Space War

A 2D platform shooter made with **Godot 4.7**.

## ▶ Play in your browser

**https://mattsi.github.io/space-war-web/**

Play it in Chrome or Edge on a computer. Click the game once to turn on sound. You need a keyboard or a gamepad.

<!-- Screenshot: add one here, e.g. ![Space War](screenshot.png) -->

## Controls

| Action | Keyboard | Gamepad |
|---|---|---|
| Move | `A` `D` or `←` `→` | Left stick |
| Jump / double jump | `Space` | `A` |
| Shoot | `J` | `RT` |
| Aim (hold) | `K` or `Shift` | `LT` |
| Aim direction | `W` `A` `S` `D` or arrow keys | Left stick |

Hold jump to jump higher. Hold aim to shoot in 16 directions.

## Game

- 2 levels. Reach the goal to finish a level.
- You have 5 health points.
- Touch a checkpoint to restart there when you die.

## Run from source

1. Install [Godot 4.7](https://godotengine.org/download).
2. Clone this repository and open `project.godot` in Godot.
3. Press **F5** to play.

## Build for the web

1. In Godot, open **Editor → Manage Export Templates** and install the **Web Single-Threaded** templates.
2. Open **Project → Export**, choose the **Web** preset and click **Export Project**. The output goes to `build/index.html`.
3. To test, serve the folder (opening the HTML file directly won't work):

   ```bash
   python -m http.server 8000 --directory build
   ```

   Then open `http://localhost:8000`.

The web version is published from a separate repository: [space-war-web](https://github.com/MattSi/space-war-web).

## How it's built

About 1,100 lines of GDScript.

**Structure**
- Each game object (player, enemy, bullet, checkpoint, goal) is its own small scene. Levels are made by placing these scenes.
- Two global managers:
  - `GameManager` loads levels and handles checkpoints and respawns.
  - `AudioManager` plays music and sounds by name.

| Folder | What's in it |
|---|---|
| `scenes/` | Reusable objects: player, enemies, bullet, checkpoint, goal |
| `levels/` | Main menu and levels |
| `scripts/` | GDScript for each object and the two managers |
| `ui/` | HUD (health and score) |
| `assets/` | Sprites, tiles, music and sounds |

**Patterns**
- **Signals (Observer):** the player sends events like `died` and `health_changed`. The HUD and `GameManager` react to them.
- **State machine:** enemies switch between states, e.g. `PATROL → CHASE → DIVE → DEAD`.
- **Shared `take_damage()`:** bullets can hit anything that has this method, so player and enemies use the same bullet.
- **Groups:** objects find the player through the `Player` group, not a fixed path.

**Small details**
- Checkpoints are kept after you die and the level reloads.
- Game values (speed, jump, health) are set in the Godot editor.
- Keyboard and gamepad use the same input actions.

## Credits

- **Music:** "Orbital Colossus" by **Matthew Pablo** (https://www.matthewpablo.com), [OpenGameArt](https://opengameart.org/content/space-boss-battle-theme), [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/).
<!-- TODO: credit the sprites and sound effects (author, link, license) -->

Made by **Mian Si** ([MattSi](https://github.com/MattSi)).
