# playerfactions

A simple mod which allows player created factions. Not very useful on its own, it becomes very powerful when combined with other mods.

## Usage
We can choose a mode : single or multi factions.
  By default the mod is single faction, if we want to change, all it takes is to add a line `mode_unique_faction = false` into the mod.conf file

Below, parameters with [ ] are useful only with the multi-factions mode.

There is an admin privs to enable every functions for every faction : playerfactions_admin


These commands can be used by anyone:

- `/factions create <faction> <password>`: Create a new faction
- `/factions list`: List available factions
- `/factions info <faction>`: See information on a faction
- `/factions join <faction> <password>`: Join an existing faction
- `/factions leave [faction]`: Leave your faction

These extra commands can only be used by faction owners and someone with the playerfactions_admin priv:

- `/factions kick [faction] <player>`: Kick someone from your faction
- `/factions disband [faction]`: Disband your faction
- `/factions passwd [faction] <password>`: Change your faction's password
- `/factions chown [faction] <player>`: Transfer ownership of your faction

This commands can only be used by someone with the playerfactions_admin priv:
- `/factions invite <player> <faction>`: Add player to a faction


## Translations

As mentioned below, this mod has support for `intllib`! If you know English and another language, please submit a translation! It would be greatly appreciated, and your name will be added to the acknowledgements at the bottom of this page. Thanks!

## Mod integration

The following mods have optional support for `playerfactions`:

- `areas`: Protect faction territory using areas. [link](https://github.com/minetest-mods/areas)
- `protector`: Allow faction to be added as a member to protection blocks. [link](https://notabug.org/TenPlus1/protector)

Additionally, `playerfactions` can optionally depend on the following mods:

- `intllib`: Provide localizations for different languages

### Using `playerfactions` in your own mod

I strongly recommend reading through the `init.lua` file; the functions at the top give you a pretty good idea of how to use it, but just in case you're short on time I'll list the most important functions below.

- `factions.version` is a variable made to check the version of the playerfactions mod to assert compatibility:  
* factions.version == nil for firsts version of playerfactions mod
* factions.version == 2 is the first time this variable is added, with adding multi-faction mode
- `player_is_in_faction(fname, player_name)`: `true` if the player is in the faction, `nil` in other cases (facion or player doesn't exists or player is not a member of the faction)
- `get_facts()`: Get the table with all data. The structure is :
```
{["name_of_faction1"]={
      ["owner"]=name_of_the_owner,
      ["members"]={["name_of_a_member1"]=true, ["name_of_a_member2"]=true}
  }}
```
- `get_player_faction(player)`: Get a string with the faction a player belongs to, `nil` if they haven't joined a faction. In multi-faction mode, it will return the oldest created faction which player is into. (it's not necessarily the one they joined first. It checks the facts variable from the top)
- `get_player_factions(player)`: Get a table with the faction(s) a player belongs to, `nil` if they haven't joined a faction. The structure is: {name_of_faction1, name_of_faction2}
- `get_owner(faction)`: Get the owner of a faction
- `chown(fname, owner)`: Change the owner of a faction
- `register_faction(faction, player, password)`: Create a new faction
- `disband_faction(faction)`: Disband a faction
- `get_password(faction)`: Gets a faction's password
- `set_password(faction, password)`: Sets a faction's password
- `join_faction(faction, player)`: Sets the given player as belonging to this faction
- `leave_faction(faction, player)`: Remove the given player from the faction

Note that all of these functions have sanity checks : if faction or player does not exists, it return false. If operation succeed, it return true or the needed value.

## Acknowledgements

This mod is loosely based off of the (unmaintained) [factions mod made by Jonjeg](https://github.com/Jonjeg/factions).
