# val-resources

Small QoL scripts for Qbox, QBCore and standalone servers. Everything can be toggled in `config.lua`.

## Features
- Ledge climbing / parkour
- /carry (with accept prompt)
- /me and /do 3D text
- Anti bunny-hop
- Map in hand on pause menu
- /propfix
- Player IDs above heads (HOME)
- Items on back
- Hunger / thirst alerts
- LVC sirens + indicators (rebindable keys)
- /engine
- Wheels stay turned after exiting
- First person when aiming in vehicles
- No pistol whip / combat roll, weapon damage modifiers
- Misc tweaks (no helmet, no wanted level, no air control, density...)
- /fps booster
- Discord rich presence

## Install
1. Drop `val-resources` into your resources folder
2. `ensure val-resources` after your framework
3. Edit `config.lua`

Requires OneSync.

## Exports
```lua
exports['val-resources']:TriggerLedgeClimb()
exports['val-resources']:IsMantling()
```

## Credits
- [qb-extras](https://github.com/MrEvilGamer/qb-extras) - MrEvilGamer
- Luxart Vehicle Control - Lt.Caine
- [karma-climbing](https://github.com/guf1ck/karma-climbing) - KARMA Developments
- CarryPeople - rubbertoe98

## License
GPL-3.0
