# oddball-base
Fistful of Frags Oddball Weapon

## PRESENT ISSUES

Client-Side Prediction causes the base weapon's sound to play.

Sometimes the primary attack does not have an animation.

Secondary attack is not properly disabled.

Custom content is not downloaded to players connecting to server.

## Installation

### Server
Merge the 'fof' folder with your server's 'fof' folder.

### Client
Copy fof/custom/*.vpk to your custom folder. Note this is necessary for all players connecting to the server, since automatic resource downloading is not implemented yet.

## Added Weapons

In console, type "cg weapon_name" to spawn a weapon on the ground.

weapon_oddball: The oddball! High-damage melee. Forced to equip on pickup, can't switch off unless dropped.

