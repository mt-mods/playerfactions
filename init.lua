
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

local function save_factions()
	storage:set_string("facts", minetest.serialize(facts))
end

-- Data manipulation
function factions.get_player_faction(name)
	local player = minetest.get_player_by_name(name)
	if player == nil then
		return nil
	else
		local faction = player:get_meta():get_string("faction")
		if faction == "" then
			return nil
		else
			-- Check that faction still exists
			if facts[faction] == nil then
				factions.leave_faction(name)
				return nil
			else
				return faction
			end
		end
	end
end

function factions.get_owner(name)
	if facts[name] == nil then
		return nil
	else
		return facts[name].owner
	end
end

function factions.chown(name, owner)
	facts[name].owner = owner
end

function factions.register_faction(fname, founder, pw)
	facts[fname] = {
		name = fname,
		owner = founder,
		password = pw
	}
	save_factions()
	factions.join_faction(fname, founder)
end

function factions.disband_faction(name)
	facts[name] = nil
	save_factions()
end

function factions.get_password(name)
	return facts[name].password
end

function factions.set_password(name, password)
	facts[name].password = password
end

function factions.join_faction(name, player)
	minetest.get_player_by_name(player):get_meta():set_string("faction", name)
end

function factions.leave_faction(name)
	minetest.get_player_by_name(name):get_meta():set_string("faction", "")
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
		if faction_name == nil then
			minetest.chat_send_player(name, S("Missing faction name"))
		elseif password == nil then
			minetest.chat_send_player(name, S("Missing password"))
		elseif factions.get_owner(faction_name) ~= nil then
			minetest.chat_send_player(name, S("That faction already exists"))
		else
			factions.register_faction(faction_name, name, password)
			minetest.chat_send_player(name, S("Registered @1", faction_name))
			return true
		end
	elseif action == "disband" then
		local faction_name = factions.get_player_faction(name)
		local password = params[2]
		if faction_name == nil then
			minetest.chat_send_player(name, S("You are not in a faction"))
		elseif name ~= factions.get_owner(faction_name) then
			minetest.chat_send_player(name, S("Permission denied"))
		elseif password == nil then
			minetest.chat_send_player(name, S("WARNING! This cannot be reversed! Run again with the password if you're absolutely certain"))
		elseif password ~= factions.get_password(faction_name) then
			print("wrong password")
			minetest.chat_send_player(name, S("Permission denied"))
		else
			factions.disband_faction(faction_name, name, name)
			minetest.chat_send_player(name, S("Disbanded @1", faction_name))
			return true
		end
	elseif action == "list" then
		local faction_list = {}
		for k, f in pairs(facts) do
			table.insert(faction_list, k)
		end
		if #faction_list ~= 0 then
			minetest.chat_send_player(name, "Factions("..#faction_list.."): "..table.concat(faction_list, ","))
		else
			minetest.chat_send_player(name, S("There are no factions yet"))
		end
		return true
	elseif action == "info" then
		local faction_name = params[2]
		if faction_name == nil then
			faction_name = factions.get_player_faction(name)
		end
		if faction_name == nil then
			minetest.chat_send_player(name, S("Missing faction name"))
		else
			minetest.chat_send_player(name, S("Owner: @1", factions.get_owner(faction_name)))
			if factions.get_owner(faction_name) == name then
				minetest.chat_send_player(name, S("Password: @1", factions.get_password(faction_name)))
			end
		end
	elseif action == "join" then
		local faction_name = params[2]
		local password = params[3]
		if factions.get_player_faction(name) ~= nil then
			minetest.chat_send_player(name, S("You are already in a faction"))
		elseif factions.get_owner(faction_name) == nil then
			minetest.chat_send_player(name, S("The faction @1 doesn't exist", faction_name))
		elseif factions.get_password(faction_name) ~= password then
			minetest.chat_send_player(name, S("Permission denied"))
		else
			factions.join_faction(faction_name, name)
			minetest.chat_send_player(name, S("Joined @1", faction_name))
			return true
		end
	elseif action == "leave" then
		local faction_name = factions.get_player_faction(name)
		if faction_name == nil then
			minetest.chat_send_player(name, S("You are not in a faction"))
		elseif factions.get_owner(faction_name) == name then
			minetest.chat_send_player(name, S("You cannot leave your own faction"))
		else
			factions.leave_faction(name)
			minetest.chat_send_player(name, S("Left @1", faction_name))
			return true
		end
	elseif action == "kick" then
		local faction_name = factions.get_player_faction(name)
		local target = params[2]
		if faction_name == nil then
			minetest.chat_send_player(name, S("You are not in a faction"))
		elseif target == nil then
			minetest.chat_send_player(name, S("Missing player name"))
		elseif factions.get_owner(faction_name) ~= name or factions.get_player_faction(target) ~= faction_name then
			minetest.chat_send_player(name, S("Permission denied"))
		elseif target == name then
			minetest.chat_send_player(name, S("You cannot kick yourself"))
		else
			factions.leave_faction(name)
			minetest.chat_send_player(name, S("Kicked @1 from faction", target))
			return true
		end
	elseif action == "passwd" then
		local faction_name = factions.get_player_faction(name)
		local password = params[2]
		if faction_name == nil then
			minetest.chat_send_player(name, S("You are not in a faction"))
		elseif password == nil then
			minetest.chat_send_player(name, S("Missing password"))
		elseif factions.get_owner(faction_name) ~= name then
			minetest.chat_send_player(name, S("Permission denied"))
		else
			factions.set_password(faction_name, password)
			minetest.chat_send_player(name, S("Password has been updated"))
			return true
		end
	elseif action == "chown" then
		local faction_name = factions.get_player_faction(name)
		local target = params[2]
		local password = params[3]
		if faction_name == nil then
			minetest.chat_send_player(name, S("You are not in a faction"))
		elseif target == nil then
			minetest.chat_send_player(name, S("Missing player name"))
		elseif factions.get_player_faction(target) ~= faction_name then
			minetest.chat_send_player(name, S("@1 isn't in your faction", target))
		elseif factions.get_owner(faction_name) ~= name then
			minetest.chat_send_player(name, S("Permission denied"))
		elseif password == nil then
			minetest.chat_send_player(name, S("WARNING! This cannot be reversed! Run again with the password if you're absolutely certain"))
		elseif password ~= factions.get_password(faction_name) then
			minetest.chat_send_player(name, S("Permission denied"))
		else
			factions.chown(faction_name, target)
			minetest.chat_send_player(name, S("Ownership has been transferred to @1", target))
			return true
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
	.."kick <player>: "..S("Kick someone from your faction").."\n"
	.."disband: "..S("Disband your faction").."\n"
	.."passwd <password>: "..S("Change your faction's password").."\n"
	.."chown <player>:"..S("Transfer ownership of your faction").."\n",
	
	description = "",
	privs = {},
	func = handle_command
})
