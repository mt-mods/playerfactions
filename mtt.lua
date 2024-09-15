local pd = function(...) print(dump(table.pack(...))) end

mtt.register('join players', function(callback)
pd(
	mtt.join_player('Endor'),
	mtt.join_player('Albert'),
	mtt.join_player('Gandalf'),
	mtt.join_player('HanSolo')
)
	callback()
end)

mtt.register('some players leave', function(callback)
pd(
	mtt.leave_player('Albert'),
	mtt.leave_player('Gandalf')
)
	callback()
end)

mtt.register('make factions with backend', function(callback)
	pd(
	factions.register_faction('Endorian', 'Endor', 'eEe'),
	factions.register_faction('Alberian', 'Albert', 'a'),
	factions.register_faction('Gandalfian', 'Gandalf', 'GgG♥💩☺')
	)
	callback()
end)

mtt.register('basic db checks', function(callback)
	local facts = factions.get_facts()
	assert('table' == type(facts))
	assert('table' == type(facts.Alberian))
	assert('Albert' == facts.Alberian.owner)
	assert('Alberian' == facts.Alberian.name)
	assert('table' == type(facts.Alberian.members))
	assert(true == facts.Alberian.members.Albert)
	assert('8b2713b352c6fa2d22272a91612fba2f87d0c01885762a1522a7b4aec5592a80'
		== facts.Endorian.password256)
	assert('ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb'
		== facts.Alberian.password256)
	assert('3bfe911604e3fb079ad535a0c359a8457aea39d663bb4f21648842e3a4eaccf9'
		== facts.Gandalfian.password256)
	assert(nil == facts.Gandalfian.password)
	callback()
end)

mtt.register('backend functions', function(callback)
	-- player_is_in_faction
	assert(false == factions.player_is_in_faction(
		'notExistingFaction', 'notExistingPlayer'))
	assert(false == factions.player_is_in_faction(
		'notExistingFaction', 'Gandalf'))
	assert(false == factions.player_is_in_faction(
		'Gandalfian', 'notExistingPlayer'))
	assert(nil == factions.player_is_in_faction(
		'Gandalfian', 'Albert'))
	assert(true == factions.player_is_in_faction(
		'Gandalfian', 'Gandalf'))

	-- get_player_faction (depricated)
	assert(false == factions.get_player_faction('notExistingPlayer'))
	assert(nil == factions.get_player_faction('HanSolo'))
	assert('Alberian' == factions.get_player_faction('Albert'))

	-- get_player_factions
	assert(false == factions.get_player_factions(nil))
	assert(false == factions.get_player_factions(42))
	assert(false == factions.get_player_factions('notExistingPlayer'))
	assert(false == factions.get_player_factions('HanSolo'))
	assert('Alberian' == factions.get_player_factions('Albert')[1])

	-- get_owned_factions
	assert(false == factions.get_owned_factions(nil))
	assert(false == factions.get_owned_factions(42))
	assert(false == factions.get_owned_factions('notExistingPlayer'))
	assert(false == factions.get_owned_factions('HanSolo'))
	assert('Alberian' == factions.get_owned_factions('Albert')[1])

	-- get_administered_factions
	-- get_owner
	-- chown
	-- register_faction (partly tested in setup)
	-- disband_faction (partly tested in setup)
	-- hash_password (tested in basic db checks)
	-- valid_password
	-- get_password (depricated)
	-- set_password
	-- join_faction
	-- leave_faction
	
	callback()
end)

mtt.register('intermediate db checks', function(callback)
	callback()
end)

mtt.register('frontend functions', function(callback)
	callback()
end)

mtt.register('final db checks', function(callback)
	callback()
end)

mtt.register('foo bar', function(callback)
	pd(factions.get_facts())
	print('total success')
	callback()
end)
