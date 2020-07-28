minetest.register_privilege("playerfactions_admin", {description = "Authorize to use every /factions commands",give_to_singleplayer = false})
-- Load support for intllib.
local MP = minetest.get_modpath(minetest.get_current_modname())
local S, NS = dofile(MP.."/intllib.lua")

-- Data
factions = {}
local facts = {}
local storage = minetest.get_mod_storage()
if storage:get_string("facts") ~= "" then
	facts = minetest.deserialize(storage:get_string("facts"))
end
-- Fix factions
for fname, fact in pairs(facts) do
	if fact.members == nil then
		fact.members = {}
	end
end


local modConf = io.open(minetest.get_modpath("playerfactions").."/mod.conf")
local content = modConf:read("*all")
local found, _ , mod_u = content:find("mode_unique_faction%s-=%s-(%S+)")
if found == nil then
	factions.mode_unique_faction = true
elseif mod_u == "false" then
	factions.mode_unique_faction = false
else
	factions.mode_unique_faction = true
end



local function save_factions()
	storage:set_string("facts", minetest.serialize(facts))
end

-- Data manipulation
function factions.get_player_faction(name)
	if not minetest.player_exists(name) then
		return false
	end
	for fname, fact in pairs(facts) do
		if fact.members[name] then
			return fname
		end
	end
	return nil
end

function factions.get_player_factions(name)
	if not minetest.player_exists(name) then
		return false
	end
	local player_factions = {}
	for fname, fact in pairs(facts) do
		if fact.members[name] then
			table.insert(player_factions, fname)
		end
	end
	return player_factions
end

function factions.get_owned_factions(name)
	local own_factions = {}
	for fname, fact in pairs(facts) do
		if minetest.get_player_privs(name).playerfactions_admin or fact.owner == name then
			table.insert(own_factions, fname)
		end
	end
	return own_factions
end

function factions.get_owner(fname)
	if facts[fname] == nil then
		return false
	end
	return facts[fname].owner
end

function factions.chown(fname, owner)
	if facts[fname] == nil then
		return false
	end
	facts[fname].owner = owner
	save_factions()
	return true
end

function factions.register_faction(fname, founder, pw)
	if facts[fname] ~= nil then
		return false
	end
	facts[fname] = {
		name = fname,
		owner = founder,
		password = pw,
		members = {[founder] = true}
	}
	save_factions()
	return true
end

function factions.disband_faction(fname)
	if facts[fname] == nil then
		return false
	end
	facts[fname] = nil
	save_factions()
	return true
end

function factions.get_password(fname)
	if facts[fname] == nil then
		return false
	end
	return facts[fname].password
end

function factions.set_password(fname, password)
	if facts[fname] == nil then
		return false
	end
	facts[fname].password = password
	save_factions()
	return true
end

function factions.join_faction(fname, player)
	if facts[fname] == nil or not minetest.player_exists(player) then
		return false
	end
	facts[fname].members[player] = true
	save_factions()
	return true
end

function factions.leave_faction(fname, player_name)
	if facts[fname] == nil or not minetest.player_exists(player_name) then
		return false
	end
	facts[fname].members[player_name] = nil
	save_factions()
	return true
end

-- Chat commands
local function handle_command(name, param)
	local params = {}
	for p in string.gmatch(param, "[^%s]+") do
		table.insert(params, p)
	end
	if params == nil then
		minetest.chat_send_player(name, S("Unknown subcommand. Run '/help factions' for help"))
	end
	local action = params[1]
	if action == "create" then
		local faction_name = params[2]
		local password = params[3]
		if factions.mode_unique_faction and factions.get_player_faction(name) ~= nil then
			minetest.chat_send_player(name, S("You are already in a faction you can't create one"))
		elseif faction_name == nil then
			minetest.chat_send_player(name, S("Missing faction name"))
		elseif password == nil then
			minetest.chat_send_player(name, S("Missing password"))
		elseif facts[faction_name] ~= nil then
			minetest.chat_send_player(name, S("That faction already exists"))
		else
			factions.register_faction(faction_name, name, password)
			minetest.chat_send_player(name, S("Registered @1", faction_name))
			return true
		end
	elseif action == "disband" then
		local password = nil
		local faction_name = nil
		local own_factions = factions.get_owned_factions(name)
		local number_factions = #own_factions
		if number_factions == 0 then
			password = "No importance, player will not be abble because player is not the owner of no faction"
		elseif #params == 1 then
			faction_name = "No importance, player will not be abble because no password is given"
		elseif #params == 2 and number_factions == 1 then
			password = params[2]
			faction_name = own_factions[1]
		elseif #params >= 3 then
			faction_name = params[2]
			password = params[3]
		end
		if password == nil then
			minetest.chat_send_player(name, S("Password is needed"))
		elseif faction_name == nil then
			if number_factions == 0 then
				minetest.chat_send_player(name, S("You are the owner of no faction, you can't use this command"))
			else
				minetest.chat_send_player(name, S("You are the owner of many factions, you have to choose one of them : @1", table.concat(own_factions, ", ")))
			end
		elseif not facts[faction_name] then
			minetest.chat_send_player(name, S("This faction doesn't exists"))
		elseif name ~= factions.get_owner(faction_name) and not minetest.get_player_privs(name).playerfactions_admin then
			minetest.chat_send_player(name, S("Permission denied : you are not the owner of this faction and don't have the privs playerfactions_admin."))
		elseif password ~= factions.get_password(faction_name) then
			print("wrong password")
			minetest.chat_send_player(name, S("Permission denied: wrong password"))
		else
			factions.disband_faction(faction_name)
			minetest.chat_send_player(name, S("Disbanded @1", faction_name))
			return true
		end
	elseif action == "list" then
		local faction_list = {}
		for k, f in pairs(facts) do
			table.insert(faction_list, k)
		end
		if #faction_list ~= 0 then
			minetest.chat_send_player(name, "Factions("..#faction_list.."): "..table.concat(faction_list, ", "))
		else
			minetest.chat_send_player(name, S("There are no factions yet"))
		end
		return true
	elseif action == "info" then
		local faction_name = params[2]
		if faction_name == nil then
			faction_name = factions.get_player_faction(name)
			minetest.chat_send_player(name, S("No faction were given, returning information about your oldest faction (e.g. the oldest created faction you are in)"))
		end
		if faction_name == nil then
			minetest.chat_send_player(name, S("Missing faction name"))
		elseif facts[faction_name] == nil then
			minetest.chat_send_player(name, S("This faction is not registered"))
		else
			local fmembers = ""
			for play,_ in pairs(facts[faction_name].members) do
				if fmembers == "" then
					fmembers = play
				else
					fmembers = fmembers..", "..play
				end
			end
			minetest.chat_send_player(name, S("Name: @1\nOwner: @2\nMembers: #@3", faction_name, factions.get_owner(faction_name), fmembers))
			if factions.get_owner(faction_name) == name or minetest.get_player_privs(name).playerfactions_admin then
				minetest.chat_send_player(name, S("Password: @1", factions.get_password(faction_name)))
			end
		end
	elseif action == "join" then
		local faction_name = params[2]
		local password = params[3]
		if factions.get_player_faction(name) ~= nil and factions.mode_unique_faction then
			minetest.chat_send_player(name, S("You are already in a faction"))
		elseif facts[faction_name] == nil then
			minetest.chat_send_player(name, S("The faction @1 doesn't exist", faction_name))
		elseif factions.get_password(faction_name) ~= password then
			minetest.chat_send_player(name, S("Permission denied : wrong password."))
		else
			if factions.join_faction(faction_name, name) then
				minetest.chat_send_player(name, S("Joined @1", faction_name))
				return true
			else
				minetest.chat_send_player(name, S("Error on joining, please try again"))
				return false
			end
		end
	elseif action == "leave" then
		local player_factions = factions.get_player_factions(name)
		local number_factions = table.getn(player_factions)
		local faction_name = nil
		if number_factions == 0 then
			faction_name = nil
		elseif #params == 1 and number_factions == 1 then
			faction_name = player_factions[1]
		elseif #params >= 1 and facts[params[2]] ~= nil then
			faction_name = params[2]
		end
		if faction_name == nil then
			if number_factions == 0 then
				minetest.chat_send_player(name, S("You are not in a faction"))
			elseif facts[params[2]] then
				minetest.chat_send_player(name, S("You are in many factions (@1), you must precise which one you want to leave", table.concat(player_factions, ", ")))
			else
				minetest.chat_send_player(name, "The given faction doesn't exists")
			end
		elseif factions.get_owner(faction_name) == name then
			minetest.chat_send_player(name, S("You cannot leave your own faction, change owner or disband it."))
		else
			if factions.leave_faction(faction_name, name) then
				minetest.chat_send_player(name, S("Left @1", faction_name))
				return true
			else
				minetest.chat_send_player(name, S("Error on leaving the faction, please try again"))
				return false
			end
		end
	elseif action == "kick" then
		local target = nil
		local faction_name = nil
		local own_factions = factions.get_owned_factions(name)
		local number_factions = table.getn(own_factions)
		if number_factions == 0 then
			target = "No importance, the permission is denied"
		elseif #params == 2 and number_factions == 1 then
			target = params[2]
			faction_name = own_factions[1]
		elseif #params >= 3 then
			faction_name = params[2]
			target = params[3]
		elseif facts[params[2]] ~= nil then
			faction_name = "No importance, no target is given"
		end
		if faction_name == nil then
			if number_factions == 0 then
				minetest.chat_send_player(name, S("You are the owner of no faction, you can't use this command"))
			else
				minetest.chat_send_player(name, S("You are the owner of many factions, you have to choose one of them : @1", table.concat(own_factions, ", ")))
			end
		elseif target == nil then
			minetest.chat_send_player(name, S("Missing player name"))
		elseif factions.get_owner(faction_name) ~= name and not minetest.get_player_privs(name).playerfactions_admin then
			minetest.chat_send_player(name, S("Permission denied"))
		elseif not facts[faction_name].members[target] then
			minetest.chat_send_player(name, S("This player is not in the faction"))
		elseif target == name then
			minetest.chat_send_player(name, S("You cannot kick yourself"))
		else
			if factions.leave_faction(faction_name, target) then
				minetest.chat_send_player(name, S("Kicked @1 from faction", target))
				if target == factions.get_owner(faction_name) then
					if factions.chown(faction_name, name) then
						minetest.chat_send_player(name, S("@1 was the owner of the faction, the ownership of the faction belongs to you",target))
					end
				end
				return true
			else
				minetest.chat_send_player(name, S("Error on kicking @1 from faction, please try again", target))
				return false
			end
		end
	elseif action == "passwd" then
		local password = nil
		local faction_name = nil
		local own_factions = factions.get_owned_factions(name)
		local number_factions = table.getn(own_factions)
		if #params == 1 then
			faction_name = "No importance, there is no password"
		elseif number_factions == 0 then
			password = "No importance, player is the owner of no faction"
		elseif #params == 2 and number_factions == 1 then
			password = params[2]
			faction_name = own_factions[1]
		elseif #params >= 3 then
			faction_name = params[2]
			password = params[3]
		elseif facts[params[2]] ~= nil then
			faction_name = params[2]
		end
		if faction_name == nil then
			if number_factions == 0 then
				minetest.chat_send_player(name, S("You are the owner of no faction, you can't use this command"))
			else
				minetest.chat_send_player(name, S("You are the owner of many factions, you have to choose one of them : @1", table.concat(own_factions, ", ")))
			end
		elseif password == nil then
			minetest.chat_send_player(name, S("Missing password"))
		elseif factions.get_owner(faction_name) ~= name and not minetest.get_player_privs(name).playerfactions_admin then
			minetest.chat_send_player(name, S("Permission denied"))
		else
			if factions.set_password(faction_name, password) then
				minetest.chat_send_player(name, S("Password has been updated"))
				return true
			else
				minetest.chat_send_player(name, S("Error, password didn't change, please try again"))
				return false
			end
		end
	elseif action == "chown" then
		local own_factions = factions.get_owned_factions(name)
		local number_factions = table.getn(own_factions)
		local faction_name = nil
		local target = nil
		local password = nil
		if #params < 3 then
			faction_name = "No importance, there is no target or no password"
			if minetest.player_exists(params[2]) then
				target = "No importance, there is no password"
			end
		elseif number_factions == 0 then
			target = "No importance, player is owner of no faction"
			password = "No importance, player is owner of no faction"
		elseif number_factions == 1 and #params == 3 then
			faction_name = own_factions[1]
			target = params[2]
			password = params[3]
		elseif #params >= 4 then
			faction_name = params[2]
			target = params[3]
			password = params[4]
		end
		if faction_name == nil then
			if number_factions == 0 then
				minetest.chat_send_player(name, S("You are the owner of no faction, you can't use this command"))
			else
				minetest.chat_send_player(name, S("You are the owner of many factions, you have to choose one of them : @1", table.concat(own_factions, ", ")))
			end
		elseif target == nil then
			minetest.chat_send_player(name, S("Missing player name"))
		elseif password == nil then
			minetest.chat_send_player(name, S("Missing password"))
		elseif name ~= factions.get_owner(faction_name) and not minetest.get_player_privs(name).playerfactions_admin then
			minetest.chat_send_player(name, S("Permission denied: you're not the owner of this faction"))
		elseif not facts[faction_name].members[target] then
			minetest.chat_send_player(name, S("@1 isn't in your faction", target))
		elseif password ~= factions.get_password(faction_name) then
			minetest.chat_send_player(name, S("Permission denied: wrong password"))
		else
			if factions.chown(faction_name, target) then
				minetest.chat_send_player(name, S("Ownership has been transferred to @1", target))
				return true
			else
				minetest.chat_send_player(name, S("Error, the owner didn't change, please verify parameters and try again"))
				return false
			end
		end
	elseif action == "invite" then
		if not minetest.get_player_privs(name).playerfactions_admin then
			minetest.chat_send_player(name, "Permission denied: You can't use this command, playerfactions_admin priv is needed.")
		else
			local target = params[2]
			local faction_name = params[3]
			if facts[faction_name] == nil then
				minetest.chat_send_player(name, "The faction doesn't exist")
			elseif not minetest.player_exists(target) then
				minetest.chat_send_player(name, "The player doesn't exist")
			elseif factions.mode_unique_faction and factions.get_player_faction(target) ~= nil then
				minetest.chat_send_player(name, S("The player is already in the faction \"@1\"",factions.get_player_faction(target)))
			else
				if factions.join_faction(faction_name, target) then
					minetest.chat_send_player(name, "The player is now a member of the guild")
					return true
				else
					minetest.chat_send_player(name, S("Error on adding @1 into @2, please verify parameters and try again", target, faction_name))
					return true
				end
			end
		end
	else
		minetest.chat_send_player(name, S("Unknown subcommand. Run '/help factions' for help"))
	end
	return false
end

minetest.register_chatcommand("factions", {
	params = "create <faction> <password>: "..S("Create a new faction").."\n"
	.."list: "..S("List available factions").."\n"
	.."info <faction>: "..S("See information on a faction").."\n"
	.."join <faction> <password>: "..S("Join an existing faction").."\n"
	.."leave: "..S("Leave your faction").."\n"
	.."kick [faction] <player>: "..S("Kick someone from your faction or from the given faction").."\n"
	.."disband [faction] <password>: "..S("Disband your faction or the given faction").."\n"
	.."passwd [faction] <password>: "..S("Change your faction's password or the password of the given faction").."\n"
	.."chown [faction] <player>:"..S("Transfer ownership of your faction").."\n"
	.."invite <player> <faction>:"..S("Add player to a faction, you need factionsplayer_admin privs").."\n",

	description = "",
	privs = {},
	func = handle_command
})
