# Factions

A simple mod which allows player created factions. Not very useful on its own, it becomes very powerful when combined with other mods.

## Usage

These commands can be used by anyone:

- `/factions create <faction> <password>`: Create a new faction
- `/factions list`: List available factions
- `/factions info <faction>`: See information on a faction
- `/factions join <faction> <password>`: Join an existing faction
- `/factions leave`: Leave your faction

These extra commands can only be used by faction owners:

- `/factions kick <player>`: Kick someone from your faction
- `/factions disband`: Disband your faction
- `/factions passwd`: Change your faction's password
- `/factions chown`: Transfer ownership of your faction

## Translations

As mentioned below, this mod has support for `intllib`! If you know English and another language, please submit a translation! It would be greatly appreciated, and your name will be added to the acknowledgements at the bottom of this page. Thanks!

## Mod integration

The following mods have optional support for `factions`:

- `areas`: Protect faction territory using areas

Additionally, `factions` can optionally depend on the following mods:

- `protector_redo`: Protect faction territory using protection blocks
- `intllib`: Provide localizations for different languages

### Using `factions` in your own mod

I strongly recommend reading through the `init.lua` file; the functions at the top give you a pretty good idea of how to use it, but just in case you're short on time I'll list the most important functions below.

- `get_player_faction(player)`: Get the faction a player belongs to, `nil` if they haven't joined a faction
- `get_owner(faction)`: Get the owner of a faction
- `register_faction(faction, player, password)`: Create a new faction
- `disband_faction(faction)`: Disband a faction
- `get_password(faction)`: Gets a faction's password
- `set_password(faction, password)`: Sets a faction's password
- `join_faction(faction, player)`: Sets the given player as belonging to this faction
- `leave_faction(player)`: Clears a player's faction

Note that none of these functions have any sanity checks (e.g. making sure factions exist), so I strongly recommend you read `init.lua` to determine how they are used. Otherwise, you could end up getting some pretty strange errors.

## Acknowledgements

This mod is loosely based off of the (unmaintained) [factions mod made by Jonjeg](https://github.com/Jonjeg/factions).
