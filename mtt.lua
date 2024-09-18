-- requires [fakelib] to work properly
-- https://github.com/OgelGames/fakelib.git

local pd
if table.packer then
	pd = function(...) print(dump(table.pack(...))) end
else
	pd = function(...) for _, v in ipairs({ ... }) do print(dump(v)) end end
end
local f, fcc, S = factions, factions.handle_command, factions.S
f.mode_unique_faction = false
f.max_members_list = 11

-- factions chat command checker
-- b1: expected return bool
-- s1: expected return string
-- n: name of command executor
-- c: string of command parameters (the "/factions " part cut off)
local function fccc(b1, s1, n, c)
	local b2, s2 = fcc(n, c)
	return b1 == b2 and s1 == s2
end

local function resetDB()
	for k in pairs(f.get_facts()) do
		f.disband_faction(k)
	end
end

local function makeFactions()
	return f.register_faction('Endorian', 'Endor', 'eEe')
		and f.register_faction('Alberian', 'Albert', 'a')
		and f.register_faction('Gandalfian', 'Gandalf', 'GgG♥💩☺')
end

local function dbChecks(callback)
	-- basic db integrity tests
	local facts = f.get_facts()
	assert('table' == type(facts))
	assert('table' == type(facts.Alberian))
	assert('Albert' == facts.Alberian.owner)
	assert('Alberian' == facts.Alberian.name)
	assert('table' == type(facts.Alberian.members))
	-- make sure owners have been added as memebers
	assert(true == facts.Alberian.members.Albert)
	-- hash tests, should never fail unless engine made a mistake
	assert('8b2713b352c6fa2d22272a91612fba2f87d0c01885762a1522a7b4aec5592a80'
		== facts.Endorian.password256)
	assert('ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb'
		== facts.Alberian.password256)
	assert('3bfe911604e3fb079ad535a0c359a8457aea39d663bb4f21648842e3a4eaccf9'
		== facts.Gandalfian.password256)
	-- no more cleartext passwords (doesn't make sense in test-environement)
	assert(nil == facts.Gandalfian.password)

	callback()
end

mtt.register('reset db', function(callback) resetDB() callback() end)

mtt.register('join & setup players', function(callback)
	-- some player
	assert('table' == type(mtt.join_player('Endor')))
	-- faction admin
	assert('table' == type(mtt.join_player('Albert')))
	-- some other player
	assert('table' == type(mtt.join_player('Gandalf')))
	-- player without privs or factions
	assert('table' == type(mtt.join_player('HanSolo')))

	-- make Albert a faction-admin
	local player_privs = minetest.get_player_privs('Albert')
	player_privs[f.priv] = true
	minetest.set_player_privs('Albert', player_privs)

	-- make sure the others aren't
	for _, name in ipairs({ 'Endor', 'Gandalf', 'HanSolo' }) do
		player_privs = minetest.get_player_privs(name)
		player_privs[f.priv] = nil
		minetest.set_player_privs(name, player_privs)
	end

	callback()
end)

mtt.register('some players leave', function(callback)
	-- let's test without the admin online
	assert(true == mtt.leave_player('Albert'))
	assert(true == mtt.leave_player('Gandalf'))

	callback()
end)

mtt.register('make factions with backend', function(callback)
	assert(makeFactions())

	callback()
end)

mtt.register('basic db checks', dbChecks)

mtt.register('backend functions: player_is_in_faction', function(callback)
	assert(false == f.player_is_in_faction(
		'notExistingFaction', 'notExistingPlayer'))
	assert(false == f.player_is_in_faction(
		'notExistingFaction', 'Gandalf'))
	assert(false == f.player_is_in_faction(
		'Gandalfian', 'notExistingPlayer'))
	assert(nil == f.player_is_in_faction(
		'Gandalfian', 'Albert'))
	assert(true == f.player_is_in_faction(
		'Gandalfian', 'Gandalf'))

	callback()
end)

mtt.register('backend functions: get_player_faction', function(callback)
	-- (depricated) --> check log output for messages
	assert(false == f.get_player_faction('notExistingPlayer'))
	assert(nil == f.get_player_faction('HanSolo'))
	assert('Alberian' == f.get_player_faction('Albert'))

	callback()
end)

mtt.register('backend functions: get_player_factions', function(callback)
	if pcall(f.get_player_factions, nil) then
		callback('did not fail with nil as player argument -> bad')
	end
	if pcall(f.get_player_factions, 42) then
		callback('did not fail with number as player argument -> bad')
	end
	assert(false == f.get_player_factions('notExistingPlayer'))
	assert(false == f.get_player_factions('HanSolo'))
	assert('Alberian' == f.get_player_factions('Albert')[1])

	callback()
end)

mtt.register('backend functions: get_owned_factions', function(callback)
	assert(false == f.get_owned_factions(nil))
	assert(false == f.get_owned_factions(42))
	assert(false == f.get_owned_factions('notExistingPlayer'))
	assert(false == f.get_owned_factions('HanSolo'))
	local t = f.get_owned_factions('Albert')
	assert(1 == #t and 'Alberian' == t[1])

	callback()
end)

mtt.register('backend functions: get_administered_factions', function(callback)
	if pcall(f.get_administered_factions) then
		callback('calling get_administered_factions with nil did not raise error')
	end
	-- a bit strange that number as player name 'works'
	assert(false == f.get_administered_factions(42))
	assert(false == f.get_administered_factions('notExistingPlayer'))
	assert(false == f.get_administered_factions('HanSolo'))
	local t = f.get_administered_factions('Gandalf')
	assert(1 == #t and 'Gandalfian' == t[1])
	assert(3 == #f.get_administered_factions('Albert'))

	callback()
end)

mtt.register('backend functions: get_owner', function(callback)
	assert(false == f.get_owner('notExistingFaction'))
	assert('Gandalf' == f.get_owner('Gandalfian'))

	callback()
end)

mtt.register('backend functions: chown', function(callback)
	assert(false == f.chown('notExistingFaction', 'Gandalf'))
	assert(true == f.chown('Endorian', 'Gandalf'))
	-- revert the 'illegal' use
	f.chown('Endorian', 'Endor')

	callback()
end)

mtt.register('backend functions: register_faction', function(callback)
	-- (partly tested in setup)
	assert(false == f.register_faction('Endorian', 'Endor', 'rodnE'))
	assert(false == f.register_faction())
	-- empty password
	assert(f.register_faction('foo', 'bar', ''))

	callback()
end)

mtt.register('backend functions: disband_faction', function(callback)
	-- (partly tested in setup)
	assert(f.disband_faction('foo'))
	assert(false == f.disband_faction())
	assert(false == f.disband_faction('notExistingFaction'))

	callback()
end)

mtt.register('backend functions: hash_password', function(callback)
	-- (tested in basic db checks)

	callback()
end)

mtt.register('backend functions: valid_password', function(callback)
	assert(false == f.valid_password())
	assert(false == f.valid_password('Endorian'))
	assert(false == f.valid_password('Endorian', 'foobar'))
	assert(true == f.valid_password('Endorian', 'eEe'))

	callback()
end)

mtt.register('backend functions: get_password (depricated)', function(callback)
	assert(nil == f.get_password())
	assert(nil == f.get_password('Endorian'))

	callback()
end)

mtt.register('backend functions: set_password', function(callback)
	assert(false == f.set_password('notExistingFaction', 'foobar'))
	assert(false == f.set_password('Endorian'))
	assert(true == f.set_password('Endorian', 'EeE'))
	assert(f.valid_password('Endorian', 'EeE'))
	-- revert that again
	f.set_password('Endorian', 'eEe')

	callback()
end)

mtt.register('backend functions: join_faction', function(callback)
	assert(false == f.join_faction())
	assert(false == f.join_faction('Endorian'))
	assert(false == f.join_faction('Endorian', 'notExistingPlayer'))
	assert(true == f.join_faction('Endorian', 'Gandalf'))

	callback()
end)

mtt.register('backend functions: leave_faction', function(callback)
	assert(false == f.leave_faction())
	assert(false == f.leave_faction('Endorian'))
	assert(false == f.leave_faction('Endorian', 'notExistingPlayer'))
	assert(true == f.leave_faction('Endorian', 'Gandalf'))

	callback()
end)

mtt.register('intermediate db checks', dbChecks)

mtt.register('frontend functions: no arguments', function(callback)
	assert(fccc(false, S("Unknown subcommand. Run '/help factions' for help."),
		'', ''))

	callback()
end)

mtt.register('frontend functions: create', function(callback)
	assert(fccc(false, S("Missing faction name."), 'Gandalf', 'create'))
	assert(fccc(false, S("Missing password."), 'Gandalf', 'create foobar'))
	assert(fccc(false, S("Faction @1 already exists.", 'Gandalfian'),
		'Gandalf', 'create Gandalfian foobar'))
	f.mode_unique_faction = true
	assert(fccc(false, S("You are already in a faction."),
		'Gandalf', 'create Gandalfian2 foobar'))
	f.mode_unique_faction = false
	-- correct creation (also with capitals in sub-command)
	assert(fccc(true, S("Registered @1.", 'Gandalfian2'),
		'Gandalf', 'cREate Gandalfian2 foobar'))

	callback()
end)

mtt.register('frontend functions: disband', function(callback)
	assert(fccc(false, S("Missing password."), 'Gandalf', 'disband'))
	-- list order is not predictable, so we try both orders
	assert(fccc(false, S(
		"You are the owner of multiple factions, you have to choose one of them: @1.",
		'Gandalfian, Gandalfian2'), 'Gandalf', 'disband foobar')
		or fccc(false, S(
		"You are the owner of multiple factions, you have to choose one of them: @1.",
		'Gandalfian2, Gandalfian'), 'Gandalf', 'disband foobar'))
	assert(fccc(false, S("You don't own any factions."), 'HanSolo',
		'disband foobar'))
	assert(fccc(false, S("Permission denied: You are not the owner of that faction,"
		.. " and don't have the @1 privilege.", factions.priv),
		'Endor', 'disband foobar Gandalfian2'))
	assert(fccc(false, S("Permission denied: Wrong password."),
		'Endor', 'disband foobar'))
	assert(fccc(true, S("Disbanded @1.", 'Endorian'),
		'Endor', 'disband eEe'))
	-- admin disbands other player's faction w/o knowing password
	assert(fccc(true, S("Disbanded @1.", 'Gandalfian2'),
		'Albert', 'disband foobar Gandalfian2'))
	assert(fccc(false, S("Faction @1 doesn't exist.", 'Gandalfian2'),
		'Gandalf', 'disband eEe Gandalfian2'))

	callback()
end)

mtt.register('frontend functions: list', function(callback)
	assert(fccc(true, S("Factions (@1): @2.", 2, 'Gandalfian, Alberian'),
		'', 'list')
		or fccc(true, S("Factions (@1): @2.", 2, 'Alberian, Gandalfian'),
		'', 'list'))
	resetDB()
	assert(fccc(true, S("There are no factions yet."), '', 'list'))

	callback()
end)

mtt.register('frontend functions: info', function(callback)
	assert(fccc(true, S("No factions found."), 'HanSolo', 'info'))
	makeFactions()
	assert(fccc(false, S("Faction @1 doesn't exist.", 'foobar'),
		'Endor', 'info foobar'))
	f.join_faction('Endorian', 'Gandalf')
	assert(fccc(false, S("You are in multiple factions, you have to choose one of them: @1.",
				'Endorian, Gandalfian'), 'Gandalf', 'info')
		or fccc(false, S("You are in multiple factions, you have to choose one of them: @1.",
				'Gandalfian, Endorian'), 'Gandalf', 'info'))
	-- SwissalpS can't be bothered to check some of these results in depth,
	-- so just dumping result for optical check.
	pd('Endor executes: /factions info', fcc('Endor', 'info'))
	assert(fcc('Endor', 'info'))
	f.max_members_list = 1
	pd('max_members_list == 1 and Endor executes: /factions info',
		fcc('Endor', 'info'))
	assert(fcc('Endor', 'info'))
	f.max_members_list = 11
	pd('Endor executes: /factions info Gandalfian', fcc('Endor', 'info Gandalfian'))
	assert(fcc('Endor', 'info Gandalfian'))

	callback()
end)

mtt.register('frontend functions: player_info', function(callback)
	-- should never happen
	assert(fccc(false, S("Missing player name."), '', 'player_info'))
	assert(fccc(false, S("Player @1 doesn't exist or isn't in any faction.",
		'HanSolo'), 'HanSolo', 'player_info'))
	assert(fccc(false, S("Player @1 doesn't exist or isn't in any faction.",
		'notExistingPlayer'), 'Endor', 'player_info notExistingPlayer'))
	assert(fccc(true, S("@1 is in the following factions: @2.",
			'Endor', 'Endorian') .. "\n"
			.. S("@1 is the owner of the following factions: @2.",
				'Endor', 'Endorian'), 'Endor', 'player_info'))
	assert(fccc(true, S("@1 is in the following factions: @2.",
			'Albert', 'Alberian') .. "\n"
			.. S("@1 is the owner of the following factions: @2.",
				'Albert', 'Alberian') .. "\n"
			.. S("@1 has the @2 privilege so they can admin every faction.",
				'Albert', factions.priv), 'Endor', 'player_info Albert'))

	callback()
end)

mtt.register('frontend functions: join', function(callback)
	f.mode_unique_faction = true
	assert(fccc(false, S("You are already in a faction."),
		'Endor', 'join'))
	f.mode_unique_faction = false
	assert(fccc(false, S("Missing faction name."),
		'Endor', 'join'))
	assert(fccc(false, S("Faction @1 doesn't exist.", 'notExistingFaction'),
		'Endor', 'join notExistingFaction'))
	assert(fccc(false, S("You are already in faction @1.", 'Endorian'),
		'Endor', 'join Endorian'))
	assert(fccc(false, S("Permission denied: Wrong password."),
		'Endor', 'join Gandalfian'))
	assert(fccc(false, S("Permission denied: Wrong password."),
		'Endor', 'join Gandalfian abc'))
	assert(fccc(true, S("Joined @1.", 'Gandalfian'),
		'Endor', 'join Gandalfian GgG♥💩☺'))

	callback()
end)

mtt.register('frontend functions: leave', function(callback)
	assert(fccc(false, S("You are not in a faction."),
			'HanSolo', 'leave'))
	assert(fccc(false, S("You are in multiple factions, you have to choose one of them: @1.",
				'Gandalfian, Endorian'),
			'Endor', 'leave')
			or fccc(false, S("You are in multiple factions, you have to choose one of them: @1.",
				'Endorian, Gandalfian'),
			'Endor', 'leave'))
	assert(fccc(false, S("Faction @1 doesn't exist.", 'notExistingFaction'),
			'Endor', 'leave notExistingFaction'))
	assert(fccc(false, S("You cannot leave your own faction, change owner or disband it."),
			'Albert', 'leave'))
	assert(fccc(false, S("You aren't part of faction @1.", 'Gandalfian'),
			'Albert', 'leave Gandalfian'))
	assert(fccc(true, S("Left @1.", 'Endorian'),
			'Gandalf', 'leave Endorian'))

	callback()
end)

mtt.register('frontend functions: kick', function(callback)
	assert(fccc(false, S("Missing player name."),
			'Gandalf', 'kick'))
	assert(fccc(false, S("You don't own any factions, you can't use this command."),
			'HanSolo', 'kick Endor'))
	local b, s = fcc('Albert', 'kick Endor')
	-- only works if run on English server
	assert(false == b and nil ~= s:find('multiple factions,'))
	assert(fccc(false, S("Permission denied: You are not the owner of that faction, "
				.. "and don't have the @1 privilege.", factions.priv),
			'Endor', 'kick Gandalf Gandalfian'))
	assert(fccc(false, S("@1 is not in the specified faction.", 'Gandalf'),
			'Endor', 'kick Gandalf Endorian'))

	assert(fccc(false, S("You cannot kick the owner of a faction, "
				.. "use '/factions chown <player> <password> [<faction>]' "
				.. "to change the ownership."),
			'Albert', 'kick Gandalf Gandalfian'))
	assert(fccc(true, S("Kicked @1 from faction.", 'Endor'),
			'Gandalf', 'kick Endor Gandalfian'))

	callback()
end)

mtt.register('frontend functions: passwd', function(callback)
	assert(fccc(false, S("Missing password."),
			'HanSolo', 'passwd'))
	assert(fccc(false, S("You don't own any factions, you can't use this command."),
			'HanSolo', 'passwd foobar'))
	local b, s = fcc('Albert', 'passwd foobar')
	-- only works on English locale
	assert(false == b and nil ~= s:find('multiple factions'))
	assert(fccc(false, S("Permission denied: You are not the owner of that faction, "
				.. "and don't have the @1 privilege.", factions.priv),
			'Endor', 'passwd foobar Gandalfian'))
	assert(fccc(true, S("Password has been updated."),
			'Endor', 'passwd foobar'))
	assert(f.get_facts().Endorian.password256 ==
		'c3ab8ff13720e8ad9047dd39466b3c8974e592c2fa383d4a3960714caef0c4f2')
	assert(fccc(true, S("Password has been updated."),
			'Gandalf', 'passwd foobar Gandalfian'))
	assert(f.get_facts().Gandalfian.password256 ==
		'c3ab8ff13720e8ad9047dd39466b3c8974e592c2fa383d4a3960714caef0c4f2')
	assert(fccc(true, S("Password has been updated."),
			'Albert', 'passwd barf Gandalfian'))
	assert(f.get_facts().Gandalfian.password256 ==
		'8a6e40cfcd99060eb1efdfeb689fe26606e221b4fd487bb224ab79a82648ccd9')

	callback()
end)

mtt.register('frontend functions: chown', function(callback)
	assert(fccc(false, S("Missing player name."),
			'Gandalf', 'chown'))
	assert(fccc(false, S("Missing password."),
			'Gandalf', 'chown notExistingPlayer'))
	assert(fccc(false, S("You don't own any factions, you can't use this command."),
			'HanSolo', 'chown notExistingPlayer foobar'))
	local b, s = fcc('Albert', 'chown notExistingPlayer foobar')
	assert(false == b and nil ~= s:find('multiple factions'))
	assert(fccc(false, S("Permission denied: You are not the owner of that faction, "
				.. "and don't have the @1 privilege.", factions.priv),
			'Gandalf', 'chown Endor foobar Endorian'))
	assert(fccc(false, S("@1 isn't in faction @2.", 'notExistingPlayer', 'Gandalfian'),
			'Gandalf', 'chown notExistingPlayer foobar'))
	assert(fccc(false, S("@1 isn't in faction @2.", 'Endor', 'Gandalfian'),
			'Gandalf', 'chown Endor foobar'))
	f.join_faction('Gandalfian', 'Endor')
	assert(fccc(false, S("Permission denied: Wrong password."),
			'Gandalf', 'chown Endor foobar'))
	assert(fccc(true, S("Ownership has been transferred to @1.", 'Endor'),
			'Gandalf', 'chown Endor barf'))
	assert('Endor' == f.get_owner('Gandalfian'))
	assert(fccc(true, S("Ownership has been transferred to @1.", 'Gandalf'),
			'Albert', 'chown Gandalf foobar Gandalfian'))
	assert('Gandalf' == f.get_owner('Gandalfian'))

	callback()
end)

mtt.register('frontend functions: invite', function(callback)
	assert(fccc(false, S("Permission denied: You can't use this command, @1 priv is needed.",
				factions.priv), 'notExistingPlayer', 'invite'))
	assert(fccc(false, S("Permission denied: You can't use this command, @1 priv is needed.",
				factions.priv), 'Endor', 'invite'))
	assert(fccc(false, S("Missing player name."), 'Albert', 'invite'))
	assert(fccc(false, S("Missing faction name."), 'Albert', 'invite Endor'))
	assert(fccc(false, S("Faction @1 doesn't exist.", 'notExistingFaction'),
			'Albert', 'invite Endor notExistingFaction'))
	assert(fccc(false, S("Player @1 doesn't exist.", 'notExistingPlayer'),
			'Albert', 'invite notExistingPlayer Gandalfian'))
	assert(fccc(false, S("Player @1 is already in faction @2.", 'Endor', 'Gandalfian'),
			'Albert', 'invite Endor Gandalfian'))
	f.mode_unique_faction = true
	assert(fccc(false, S("Player @1 is already in faction @2.", 'Gandalf', 'Gandalfian'),
			'Albert', 'invite Gandalf Endorian'))
	f.mode_unique_faction = false
	assert(fccc(true, S("@1 is now a member of faction @2.", 'Gandalf', 'Endorian'),
			'Albert', 'invite Gandalf Endorian'))

	callback()
end)

mtt.register('final db checks', function(callback)
	pd(f.get_facts())

	callback()
end)

mtt.register('remaining players leave', function(callback)
	assert(true == mtt.leave_player('Endor'))
	assert(true == mtt.leave_player('HanSolo'))

	callback()
end)

mtt.register('final', function(callback)
	print('total success')
	callback()
end)
