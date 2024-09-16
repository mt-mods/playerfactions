-- Translation support
local S = minetest.get_translator("playerfactions")

-- Global factions table
factions = {}
-- This variable "version" can be used by other mods to check the compatibility of this mod
factions.version = 2

-- Settings
factions.mode_unique_faction = minetest.settings:get_bool(
	"player_factions.mode_unique_faction", true)
factions.max_members_list = tonumber(minetest.settings:get(
	"player_factions.max_members_list")) or 50
factions.priv = minetest.settings:get(
	"player_factions.priv_admin") or "playerfactions_admin"

-- Privilege registration (if needed)
minetest.register_on_mods_loaded(function()
	if not minetest.registered_privileges[factions.priv] then
		minetest.register_privilege(factions.priv, {
			description = S("Allow the use of all playerfactions commands"),
			give_to_singleplayer = false
		})
	end
end)

-- Data
local facts = {}
local storage = minetest.get_mod_storage()
if storage:get_string("facts") ~= "" then
	facts = minetest.deserialize(storage:get_string("facts"))
end



local function save_factions()
	storage:set_string("facts", minetest.serialize(facts))
end

local function table_copy(data)
	local copy = {}
	if type(data) == "table" then
		for k,v in pairs(data) do
			copy[k]=table_copy(v)
		end
		return copy
	else
		return data
	end
end


-- Data manipulation
function factions.get_facts()
	return table_copy(facts)
end

function factions.player_is_in_faction(faction_name, player_name)
	if not minetest.player_exists(player_name) or not facts[faction_name] then
		return false
	end
	return facts[faction_name].members[player_name]
end

function factions.get_player_faction(player_name)
	minetest.log("warning", "Function factions.get_player_faction() is deprecated in favor of " ..
		"factions.get_player_factions(). Please check updates of mods depending on playerfactions.")
	if not minetest.player_exists(player_name) then
		return false
	end
	for faction_name, fact in pairs(facts) do
		if fact.members[player_name] then
			return faction_name
		end
	end
	return nil
end

function factions.get_player_factions(player_name)
	if not minetest.player_exists(player_name) then
		return false
	end
	local player_factions = {}
	for faction_name, fact in pairs(facts) do
		if fact.members[player_name] then
			table.insert(player_factions, faction_name)
		end
	end
	return 0 < table.getn(player_factions) and player_factions or false
end

function factions.get_owned_factions(player_name)
	local owned_factions = {}
	for faction_name, fact in pairs(facts) do
		if fact.owner == player_name then
			table.insert(owned_factions, faction_name)
		end
	end
	return 0 < table.getn(owned_factions) and owned_factions or false
end

function factions.get_administered_factions(player_name)
	local is_admin = minetest.get_player_privs(player_name)[factions.priv]
	local adm_factions = {}
	for faction_name, fact in pairs(facts) do
		if is_admin or fact.owner == player_name then
			table.insert(adm_factions, faction_name)
		end
	end
	return 0 < table.getn(adm_factions) and adm_factions or false
end

function factions.get_owner(faction_name)
	if not facts[faction_name] then
		return false
	end
	return facts[faction_name].owner
end

function factions.chown(faction_name, player_name)
	if not facts[faction_name] then
		return false
	end
	facts[faction_name].owner = player_name
	save_factions()
	return true
end

function factions.register_faction(faction_name, player_name, password)
  if not ('string' == type(faction_name) and 'string' == type(player_name)
			and 'string' == type(password)) then
		return false
	end
	if facts[faction_name] then
		return false
	end
	facts[faction_name] = {
		name = faction_name,
		owner = player_name,
		password256 = factions.hash_password(password),
		members = { [player_name] = true }
	}
	save_factions()
	return true
end

function factions.disband_faction(faction_name)
	if not facts[faction_name] then
		return false
	end
	facts[faction_name] = nil
	save_factions()
	return true
end

function factions.hash_password(password)
	return minetest.sha256(password)
end

function factions.valid_password(faction_name, password)
	if not facts[faction_name] or not password then
		return false
	end
	return factions.hash_password(password) == facts[faction_name].password256
end

function factions.get_password()
	minetest.log("warning", "Deprecated use of factions.get_password(). "
		.. "Please update to using factions.valid_password() instead.")
	return nil
end

	if not facts[fname] then
function factions.set_password(faction_name, password)
		return false
	end
	facts[faction_name].password256 = factions.hash_password(password)
	save_factions()
	return true
end

	if not (facts[fname] and minetest.player_exists(player)) then
function factions.join_faction(faction_name, player_name)
		return false
	end
	facts[faction_name].members[player_name] = true
	save_factions()
	return true
end

	if not (facts[fname] and minetest.player_exists(player_name)) then
function factions.leave_faction(faction_name, player_name)
		return false
	end
	facts[faction_name].members[player_name] = nil
	save_factions()
	return true
end

-- Chat commands
local cc = {}

function cc.create(player_name, params)
	local faction_name = params[2]
	local password = params[3]
	if not faction_name then
		return false, S("Missing faction name.")
	elseif not password then
		return false, S("Missing password.")
	elseif factions.mode_unique_faction and factions.get_player_factions(player_name) then
		return false, S("You are already in a faction.")
	elseif facts[faction_name] then
		return false, S("Faction @1 already exists.", faction_name)
	else
		factions.register_faction(faction_name, player_name, password)
		return true, S("Registered @1.", faction_name)
	end
end

function cc.disband(player_name, params, not_admin)
	local password = params[2]
	if not password then
		return false, S("Missing password.")
	end
	local faction_name = params[3]
	local owned_factions = factions.get_administered_factions(player_name)
	local number_factions = owned_factions and table.getn(owned_factions) or 0
	if not_admin and number_factions == 0 then
		return false, S("You don't own any factions.")
	elseif not faction_name and number_factions == 1 then
		faction_name = owned_factions[1]
	elseif not faction_name then
		return false, S(
			"You are the owner of multiple factions, you have to choose one of them: @1.",
			table.concat(owned_factions, ", ")
		)
	end
	if not facts[faction_name] then
		return false, S("Faction @1 doesn't exist.", faction_name)
	elseif not_admin and player_name ~= factions.get_owner(faction_name) then
		return false, S("Permission denied: You are not the owner of that faction,"
			.. " and don't have the @1 privilege.", factions.priv)
	elseif not_admin and factions.valid_password(faction_name, password) then
		return false, S("Permission denied: Wrong password.")
	else
		factions.disband_faction(faction_name)
		return true, S("Disbanded @1.", faction_name)
	end
end

function cc.list()
	local faction_list = {}
	for k in pairs(facts) do
		table.insert(faction_list, k)
	end
	if table.getn(faction_list) == 0 then
		return true, S("There are no factions yet.")
	else
		return true, S("Factions (@1): @2.",
			table.getn(faction_list), table.concat(faction_list, ", "))
	end
end

function cc.info(player_name, params)
	local faction_name = params[2]
	if not faction_name then
		local player_factions = factions.get_player_factions(player_name)
		if not player_factions then
			return true, S("No factions found.")
		elseif table.getn(player_factions) == 1 then
			faction_name = player_factions[1]
		else
			return false, S(
				"You are in multiple factions, you have to choose one of them: @1.",
				table.concat(player_factions, ", ")
			)
		end
	end
	if not facts[faction_name] then
		return false, S("Faction @1 doesn't exist.", faction_name)
	else
		local fmembers = {}
		if table.getn(facts[faction_name].members) > factions.max_members_list then
			table.insert(fmembers, S("The faction has more than @1 members,"
				.. " the members list can't be shown.", factions.max_members_list))
		else
			for play in pairs(facts[faction_name].members) do
				table.insert(fmembers, play)
			end
		end
		local summary = S("Name: @1\nOwner: @2\nMembers: @3",
			faction_name, factions.get_owner(faction_name),
			table.concat(fmembers, ", "))
		return true, summary
	end
end

function cc.player_info(player_name, params)
	player_name = params[2] or player_name
	if not player_name then
		return false, S("Missing player name.")
	end
	local player_factions = factions.get_player_factions(player_name)
	if not player_factions then
		return false, S(
			"Player @1 doesn't exist or isn't in any faction.", player_name)
	else
		local summary = S("@1 is in the following factions: @2.",
			player_name, table.concat(player_factions, ", "))
		local owned_factions = factions.get_owned_factions(player_name)
		if not owned_factions then
			summary = summary .. "\n" .. S(
				"@1 doesn't own any factions.", player_name)
		else
			summary = summary .. "\n" .. S(
				"@1 is the owner of the following factions: @2.",
				player_name, table.concat(owned_factions, ", ")
			)
		end
		if minetest.get_player_privs(player_name)[factions.priv] then
			summary = summary .. "\n" .. S(
				"@1 has the @2 privilege so they can admin every faction.",
				player_name, factions.priv
			)
		end
		return true, summary
	end
end

function cc.join(player_name, params)
	local faction_name = params[2]
	local password = params[3]
	if factions.mode_unique_faction and factions.get_player_factions(player_name) then
		return false, S("You are already in a faction.")
	elseif not faction_name then
		return false, S("Missing faction name.")
	elseif not facts[faction_name] then
		return false, S("Faction @1 doesn't exist.", faction_name)
	elseif facts[faction_name].members[player_name] then
		return false, S("You are already in faction @1.", faction_name)
	elseif not factions.valid_password(faction_name, password) then
		return false, S("Permission denied: Wrong password.")
	else
		if factions.join_faction(faction_name, player_name) then
			return true, S("Joined @1.", faction_name)
		else
			return false, S("Error joining faction.")
		end
	end
end

function cc.leave(player_name, params)
	local player_factions = factions.get_player_factions(player_name)
	local number_factions = player_factions and table.getn(player_factions) or 0
	local faction_name = params[2]
	if number_factions == 0 then
		return false, S("You are not in a faction.")
	elseif not faction_name then
		if number_factions == 1 then
			faction_name = player_factions[1]
		else
			return false, S(
				"You are in multiple factions, you have to choose one of them: @1.",
				table.concat(player_factions, ", ")
			)
		end
	end
	if not facts[faction_name] then
		return false, S("Faction @1 doesn't exist.", faction_name)
	elseif factions.get_owner(faction_name) == player_name then
		return false, S("You cannot leave your own faction, change owner or disband it.")
	elseif not facts[faction_name].members[player_name] then
		return false, S("You aren't part of faction @1.", faction_name)
	else
		if factions.leave_faction(faction_name, player_name) then
			return true, S("Left @1.", faction_name)
		else
			return false, S("Error leaving faction.")
		end
	end
end

function cc.kick(player_name, params, not_admin)
	local target_name = params[2]
	if not target_name then
		return false, S("Missing player name.")
	end
	local faction_name = params[3]
	local owned_factions = factions.get_administered_factions(player_name)
	local number_factions = owned_factions and table.getn(owned_factions) or 0
	if number_factions == 0 then
		return false, S("You don't own any factions, you can't use this command.")
	elseif not faction_name and number_factions == 1 then
		faction_name = owned_factions[1]
	elseif not faction_name then
		return false, S(
			"You are the owner of multiple factions, you have to choose one of them: @1.",
			table.concat(owned_factions, ", ")
		)
	end
	if not_admin and factions.get_owner(faction_name) ~= player_name then
		return false, S("Permission denied: You are not the owner of that faction, "
			.. "and don't have the @1 privilege.", factions.priv)
	elseif not facts[faction_name].members[target_name] then
		return false, S("@1 is not in the specified faction.", target_name)
	elseif target_name == factions.get_owner(faction_name) then
		return false, S("You cannot kick the owner of a faction, "
			.. "use '/factions chown <player> <password> [<faction>]' "
			.. "to change the ownership.")
	else
		if factions.leave_faction(faction_name, target_name) then
			return true, S("Kicked @1 from faction.", target_name)
		else
			return false, S("Error kicking @1 from faction.", target_name)
		end
	end
end

function cc.passwd(player_name, params, not_admin)
	local password = params[2]
	if not password then
		return false, S("Missing password.")
	end
	local faction_name = params[3]
	local owned_factions = factions.get_administered_factions(player_name)
	local number_factions = owned_factions and table.getn(owned_factions) or 0
	if number_factions == 0 then
		return false, S("You don't own any factions, you can't use this command.")
	elseif not faction_name and number_factions == 1 then
		faction_name = owned_factions[1]
	elseif not faction_name then
		return false, S(
			"You are the owner of multiple factions, you have to choose one of them: @1.",
			table.concat(owned_factions, ", ")
		)
	end
	if not_admin and factions.get_owner(faction_name) ~= player_name then
		return false, S("Permission denied: You are not the owner of that faction, "
			.. "and don't have the @1 privilege.", factions.priv)
	else
		if factions.set_password(faction_name, password) then
			return true, S("Password has been updated.")
		else
			return false, S("Failed to change password.")
		end
	end
end

function cc.chown(player_name, params, not_admin)
	local target_name = params[2]
	local password = params[3]
	local faction_name = params[4]
	if not target_name then
		return false, S("Missing player name.")
	elseif not password then
		return false, S("Missing password.")
	end
	local owned_factions = factions.get_administered_factions(player_name)
	local number_factions = owned_factions and table.getn(owned_factions) or 0
	if number_factions == 0 then
		return false, S("You don't own any factions, you can't use this command.")
	elseif not faction_name and number_factions == 1 then
		faction_name = owned_factions[1]
	elseif not faction_name then
		return false, S(
			"You are the owner of multiple factions, you have to choose one of them: @1.",
			table.concat(owned_factions, ", ")
		)
	end
	if not_admin and player_name ~= factions.get_owner(faction_name) then
		return false, S("Permission denied: You are not the owner of that faction, "
			.. "and don't have the @1 privilege.", factions.priv)
	elseif not facts[faction_name].members[target_name] then
		return false, S("@1 isn't in faction @2.", target_name, faction_name)
	elseif not_admin and not factions.valid_password(faction_name, password) then
		return false, S("Permission denied: Wrong password.")
	else
		if factions.chown(faction_name, target_name) then
			return true, S("Ownership has been transferred to @1.", target_name)
		else
			return false, S("Failed to transfer ownership.")
		end
	end
end

function cc.invite(_, params, not_admin)
	if not_admin then
		return false, S(
			"Permission denied: You can't use this command, @1 priv is needed.",
			factions.priv
		)
	end
	local target_name = params[2]
	local faction_name = params[3]
	if not target_name then
		return false, S("Missing player name.")
	elseif not faction_name then
		return false, S("Missing faction name.")
	elseif not facts[faction_name] then
		return false, S("Faction @1 doesn't exist.", faction_name)
	elseif not minetest.player_exists(target_name) then
		return false, S("Player @1 doesn't exist.", target_name)
	end
	local player_factions = factions.get_player_factions(target_name)
	if player_factions and facts[faction_name].members[target_name] then
		return false, S("Player @1 is already in faction @2.",
			target_name, faction_name)
	elseif player_factions and factions.mode_unique_faction then
		return false, S("Player @1 is already in faction @2.",
			target_name, player_factions[1])
	else
		if factions.join_faction(faction_name, target_name) then
			return true, S("@1 is now a member of faction @2.", target_name, faction_name)
		else
			return false, S("Error adding @1 to @2.", target_name, faction_name)
		end
	end
end

local function handle_command(player_name, param)
	local params = {}
	for p in string.gmatch(param, "[^%s]+") do
		table.insert(params, p)
	end
	local action = params[1]
	if not action or not cc[action:lower()] then
		return false, S("Unknown subcommand. Run '/help factions' for help.")
	end

	local not_admin = not minetest.get_player_privs(player_name)[factions.priv]
	return cc[action:lower()](player_name, params, not_admin)
end

minetest.register_chatcommand("factions", {
	params = "create <faction> <password>: "..S("Create a new faction").."\n"
	.."list: "..S("List available factions").."\n"
	.."info [<faction>]: "..S("See information about a faction").."\n"
	.."player_info [<player>]: "..S("See information about a player").."\n"
	.."join <faction> <password>: "..S("Join an existing faction").."\n"
	.."leave [<faction>]: "..S("Leave your faction").."\n"
	.."kick <player> [<faction>]: "..S("Kick someone from your faction or from the given faction").."\n"
	.."disband <password> [<faction>]: "..S("Disband your faction or the given faction").."\n"
	.."passwd <password> [<faction>]: "..S("Change your faction's password or the password of the given faction").."\n"
	.."chown <player> <password> [<faction>]: "..S("Transfer ownership of your faction").."\n"
	.."invite <player> <faction>: "..S("Add player to a faction, you need @1 priv", factions.priv).."\n",

	description = "",
	privs = {},
	func = handle_command
})

-- Fix factions
do
	local save_needed = false
	for _, fact in pairs(facts) do
		if not fact.members then
			fact.members = {
				[fact.owner] = true
			}
		end
		if fact.password then
			fact.password256 = factions.hash_password(fact.password)
			fact.password = nil
			save_needed = true
		end
	end
	if save_needed then
		save_factions()
	end
end

-- Integration testing
if minetest.get_modpath("mtt") and mtt.enabled then
	factions.handle_command = handle_command
	dofile(minetest.get_modpath(minetest.get_current_modname()) .. "/mtt.lua")
end

print("[playerfactions] loaded")
