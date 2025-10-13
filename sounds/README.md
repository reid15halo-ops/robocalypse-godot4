# Sound Files for Roboclaust

This directory contains meme sound effects for the game. The audio system is already implemented in `AudioManager.gd`.

## Required Sound Files

Add the following sound files in `.ogg` format:

1. **vine_boom.ogg** - Vine Boom sound (boss spawn, critical hits)
2. **bruh.ogg** - Bruh sound effect (player death)
3. **windows_error.ogg** - Windows XP error sound (errors, failed actions)
4. **oof.ogg** - Roblox Oof sound (taking damage)
5. **metal_pipe.ogg** - Metal pipe falling sound (enemy death)
6. **nokia.ogg** - Nokia ringtone (wave complete)
7. **discord_join.ogg** - Discord join sound (item pickup)
8. **wilhelm_scream.ogg** - Wilhelm scream (explosions, kamikaze drones)

## Where to Get These Sounds

You can find these popular meme sounds on:
- YouTube (download and convert to .ogg)
- Freesound.org
- MyInstants.com
- Sound effect libraries

## How to Add Sounds

1. Download the sounds
2. Convert them to `.ogg` format (use Audacity or online converter)
3. Place them in this directory with the exact filenames listed above
4. The AudioManager will automatically detect and play them

## Audio Already Integrated

The following game events will trigger sounds automatically:

- Player takes damage → Oof sound
- Player dies → Bruh sound
- Enemy dies → Metal Pipe sound
- Boss spawns → Vine Boom sound
- Wave complete → Nokia Ringtone
- Item pickup → Discord Join sound
- Explosion → Wilhelm Scream
- Errors → Windows Error sound

## Audio System Features

- **8-player pool** for overlapping sounds
- **Volume control** per sound type
- **Automatic fallback** if sound files are missing
- **Performance optimized** for many simultaneous sounds
