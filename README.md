# Touch Soccer

A complete Roblox soccer game inspired by Touch Soccer — teams, dribbling, charged shots, slide tackles, passing, goals, halftime, and a full match loop. Designed to be synced into Roblox Studio with [Rojo](https://rojo.space/).

## Features

- **Procedurally built pitch** — grass stripes, boundary walls, center circle, penalty boxes, goal nets, and team-colored goal frames.
- **Ball physics with soft magnetism** — the ball glides ahead of whoever is dribbling, but a closer opponent can steal possession just by running in.
- **Charged shots** — hold the left mouse button (or R2 on controller) to charge, release to shoot. Power scales from a light tap to a full-power screamer.
- **Passing** — press `E` to thread a pass to the best teammate in your aim cone.
- **Slide tackles** — press `Q` or `Shift` to slide. Land near the ball to steal, knock the holder down with a short stun.
- **Match system** — 2 halves × 3 minutes, kickoff countdowns, goal celebrations, halftime, full time, winner announcement, auto-restart.
- **Team system** — auto-balanced Red vs Blue, team-colored characters with name billboards, on-screen switch-team buttons.
- **HUD** — scoreboard, timer, phase label, colored power meter, notifications, ball-holder indicator, control hints, mobile buttons.
- **Camera** — orbit third-person lock with scroll-zoom, `Tab` to toggle cursor lock.

## Controls

| Input | Action |
|-------|--------|
| `W A S D` | Move |
| `Space` | Jump |
| Hold **LMB** / `R2` | Charge shot (release to fire) |
| `E` / `B` | Pass to nearest teammate in aim |
| `Q` / `Shift` / `X` | Slide tackle |
| Mouse / Right stick | Aim camera |
| Scroll wheel | Zoom |
| `Tab` | Toggle cursor lock |

## Project layout

```
default.project.json                — Rojo project definition
src/
├── ReplicatedStorage/Shared/
│   ├── Config.lua                  — Field, ball, kick, tackle, team tuning
│   └── Remotes.lua                 — RemoteEvent factory (shared client/server)
├── ServerScriptService/
│   ├── Boot.server.lua             — Boots all systems
│   ├── FieldBuilder.lua            — Generates pitch, goals, spawnpoints
│   ├── BallController.lua          — Ball physics, possession, kick/pass/tackle
│   ├── TeamManager.lua             — Red/Blue assignment, recoloring, billboards
│   └── MatchManager.lua            — Score, timer, kickoff, halftime, full time
└── StarterPlayer/StarterPlayerScripts/
    ├── Camera.client.lua           — Scriptable orbit camera
    ├── Input.client.lua            — Mouse / key / touch input → RemoteEvents
    └── UI.client.lua                — Scoreboard, power meter, notifications
```

## Installing

1. Install [Rojo](https://rojo.space/docs/v7/getting-started/installation/) (`aftman install` or `cargo install rojo` or the Studio plugin download).
2. Clone this repo and `cd` into it.
3. Start the Rojo server:

   ```bash
   rojo serve
   ```
4. In Roblox Studio, open a new place, install the Rojo plugin, click **Connect**, and the project will sync.
5. Press **Play** — the field, ball, UI, and match loop all spawn automatically.

### Build a `.rbxl` directly

```bash
rojo build -o TouchSoccer.rbxlx
```

Open the generated `.rbxlx` in Studio and press Play.

## Tuning

All tunables live in [Config.lua](src/ReplicatedStorage/Shared/Config.lua):

- `Config.Field` — pitch dimensions, goal size, wall height, colors
- `Config.Ball` — radius, magnet distance/strength, max speed, bounciness
- `Config.Kick` — min/max power, charge time, cooldowns, pass power, height assist
- `Config.Tackle` — slide speed, duration, steal range, stun time
- `Config.Match` — half duration, halftime length, kickoff countdown, celebration length
- `Config.Teams` — team colors and spawn offsets

## License

MIT — see [LICENSE](LICENSE).
