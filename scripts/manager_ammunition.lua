--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--
--	This table exists so people can add search terms for weapons that should have a load button.
--	luacheck: globals tLoadWeapons tLoadWeaponProps tNoLoadWeapons tNoLoadWeaponProps
tLoadWeapons = {}
tLoadWeaponProps = { 'loadaction' }
tNoLoadWeapons = {}
tNoLoadWeaponProps = { 'noload' }

-- luacheck: globals sAmmunitionManagerSubnode sLinkedCount sUnlinkedAmmo sUnlinkedMaxAmmo sRuleset
sAmmunitionManagerSubnode = 'ammunitionmanager.'
sLinkedCount = 'count'
sUnlinkedAmmo = 'ammo'
sUnlinkedMaxAmmo = 'maxammo'
sRuleset = ''

--	luacheck: globals calculateMargin
function calculateMargin(nDC, nTotal)
	Debug.console('AmmunitionManager.calculateMargin - DEPRECATED - 2022-07-13 - Use AttackMargins.calculateMargin')
	if AttackMargins and AttackMargins.calculateMargin then AttackMargins.calculateMargin(nDC, nTotal) end
end

local function hasSubstring(string, table)
	for _, v in pairs(table) do
		if string.find(string, v) then return true end
	end
end

--	luacheck: globals hasLoadAction
function hasLoadAction(nodeWeapon)
	if not AmmunitionManager.isWeaponRanged(nodeWeapon) then return false end

	local sWeaponProps = string.lower(DB.getValue(nodeWeapon, 'properties', ''))
	local bNoLoad = hasSubstring(sWeaponProps, tNoLoadWeaponProps)
	if bNoLoad then return false end

	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', ''))
	return (hasSubstring(sWeaponName, tLoadWeapons) and not hasSubstring(sWeaponName, tNoLoadWeapons)) or hasSubstring(sWeaponProps, tLoadWeaponProps)
end

--	luacheck: globals getShortcutNode
function getShortcutNode(nodeWeapon, shortcutName)
	local _, sRecord = DB.getValue(nodeWeapon, shortcutName or 'ammunitionmanager.ammopickershortcut')
	if sRecord and sRecord ~= '' then return DB.findNode(sRecord) end
end

-- luacheck: globals parseWeaponCapacity
function parseWeaponCapacity(capacity)
	local sCapacityLower = capacity:lower()
	if sCapacityLower == 'drawn' then return 0, sCapacityLower end
	local splitCapacity = StringManager.splitWords(sCapacityLower)
	return tonumber(splitCapacity[1]), splitCapacity[2]
end

-- luacheck: globals isWeaponRanged
function isWeaponRanged(nodeWeapon)
	local bRanged = DB.getValue(nodeWeapon, 'type', 0) == 1
	if User.getRulesetName() == '5E' then bRanged = bRanged or DB.getValue(nodeWeapon, 'type', 0) == 2 end
	return bRanged
end

---	This function finds the correct node for a weapon's ammunition.
--	It first checks for a path saved in ammopickershortcut. If found, databasenode record is returned.
--	If no path is found, it checks to see if the ammo name is known.
--	If ammo name is available, it searches through the inventory for a match.
--	If found, databasenode record is returned.
--	If no match is found, nothing is returned.
--	luacheck: globals getAmmoNode
function getAmmoNode(nodeWeapon)
	local bRanged = AmmunitionManager.isWeaponRanged(nodeWeapon)
	if not bRanged then return end

	-- check for saved ammopickershortcut windowreference and return if found
	local ammoNode = AmmunitionManager.getShortcutNode(nodeWeapon)
	if ammoNode then return ammoNode end

	-- if ammopickershortcut does not provide a good node and weapon is ranged, try searching the inventory.

	local sAmmo = DB.getValue(nodeWeapon, sAmmunitionManagerSubnode .. 'ammopicker', '')
	if sAmmo == '' then return end

	Debug.console(Interface.getString('debug_ammo_noammoshortcutfound'))

	local nodeInventory = DB.getChild(nodeWeapon, '...inventorylist')
	if DB.getName(nodeInventory) ~= 'inventorylist' then
		Debug.console(Interface.getString('debug_ammo_noinventoryfound'))
		return
	end
	for _, nodeItem in ipairs(DB.getChildList(nodeInventory)) do
		local sItemName
		if ItemManager.getIDState(nodeItem) then
			sItemName = DB.getValue(nodeItem, 'name', '')
		else
			sItemName = DB.getValue(nodeItem, 'nonid_name', '')
		end
		if sItemName == sAmmo then return nodeItem end
	end
	Debug.console(Interface.getString('debug_ammo_itemnotfound'))
end

--	luacheck: globals getWeaponName
function getWeaponName(s)
	local sWeaponName = s:gsub('%[ATTACK%s#?%d*%s?%(%u%)%]', '')
	sWeaponName = sWeaponName:gsub('%[%u+%]', '')
	if sWeaponName:match('%[USING ') then sWeaponName = sWeaponName:match('%[USING (.-)%]') end
	sWeaponName = sWeaponName:gsub('%[.+%]', '')
	sWeaponName = sWeaponName:gsub(' %(vs%. .+%)', '')
	sWeaponName = StringManager.trim(sWeaponName)

	return sWeaponName or ''
end

--	luacheck: globals getAmmoRemaining
function getAmmoRemaining(rSource, nodeWeapon, nodeAmmoLink)
	local function isInfiniteAmmo()
		local bInfiniteAmmo = DB.getValue(nodeWeapon, 'type', 0) ~= 1
		if sRuleset == '5E' then
			local bThrown = DB.getValue(nodeWeapon, 'type', 0) == 2
			bInfiniteAmmo = (bInfiniteAmmo and not bThrown)
		end
		return bInfiniteAmmo or EffectManager.hasCondition(rSource, 'INFAMMO')
	end

	local bInfiniteAmmo = isInfiniteAmmo()

	local nAmmo = 0
	if not bInfiniteAmmo then
		if nodeAmmoLink then
			nAmmo = DB.getValue(nodeAmmoLink, sLinkedCount, 0)
		else
			local nMaxAmmo = DB.getValue(nodeWeapon, sUnlinkedMaxAmmo, 0)
			local nAmmoUsed = DB.getValue(nodeWeapon, sUnlinkedAmmo, 0)
			nAmmo = nMaxAmmo - nAmmoUsed
			if nMaxAmmo == 0 then bInfiniteAmmo = true end
		end
	end
	return nAmmo, bInfiniteAmmo
end

local function countShots(nodeAmmoLink, rRoll)
	if StringManager.contains({ 'miss', 'fumble' }, rRoll.sResult) then
		local nPriorMisses = DB.getValue(nodeAmmoLink, 'missedshots', 0)
		DB.setValue(nodeAmmoLink, 'missedshots', 'number', nPriorMisses + 1)
	elseif StringManager.contains({ 'hit', 'crit' }, rRoll.sResult) then
		local nPriorHits = DB.getValue(nodeAmmoLink, 'hitshots', 0)
		DB.setValue(nodeAmmoLink, 'hitshots', 'number', nPriorHits + 1)
	end
end

local function writeAmmoRemaining(nodeWeapon, nodeAmmoLink, nAmmoRemaining, sWeaponName)
	local messagedata = { text = '', sender = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...')).sName, font = 'emotefont' }
	if nodeAmmoLink then
		if nAmmoRemaining == 0 then
			messagedata.text = string.format(Interface.getString('char_actions_usedallammo'), sWeaponName)
			Comm.deliverChatMessage(messagedata)

			DB.setValue(nodeAmmoLink, sLinkedCount, 'number', nAmmoRemaining)
		else
			DB.setValue(nodeAmmoLink, sLinkedCount, 'number', nAmmoRemaining)
		end
	else
		if nAmmoRemaining <= 0 then
			messagedata.text = string.format(Interface.getString('char_actions_usedallammo'), sWeaponName)
			Comm.deliverChatMessage(messagedata)
		end
		local nMaxAmmo = DB.getValue(nodeWeapon, sUnlinkedMaxAmmo, 0)
		DB.setValue(nodeWeapon, sUnlinkedAmmo, 'number', nMaxAmmo - nAmmoRemaining)
	end
end

--	tick off used ammunition, count misses, post 'out of ammo' chat message
--	luacheck: globals ammoTracker
function ammoTracker(rSource, rRoll)
	if not ActorManager.isPC(rSource) then return end

	local sWeaponName = getWeaponName(rRoll.sDesc)
	if rRoll.sDesc:match('%[CONFIRM%]') or sWeaponName == '' then return end
	local nodeWeaponList = DB.getChild(ActorManager.getCreatureNode(rSource), 'weaponlist')
	for _, nodeWeapon in ipairs(DB.getChildList(nodeWeaponList)) do
		local sWeaponNameFromNode = getWeaponName(DB.getValue(nodeWeapon, 'name', ''))
		if sWeaponNameFromNode == sWeaponName then
			local bMelee = DB.getValue(nodeWeapon, 'type', 0) == 0
			if rRoll.sDesc:match('%[ATTACK%s#?%d*%s?%(R%)%]') and not bMelee then
				local nodeAmmoLink = getAmmoNode(nodeWeapon)
				local nAmmoRemaining, bInfiniteAmmo = getAmmoRemaining(rSource, nodeWeapon, nodeAmmoLink)
				if not bInfiniteAmmo then
					writeAmmoRemaining(nodeWeapon, nodeAmmoLink, nAmmoRemaining - 1, sWeaponName)
					countShots(nodeAmmoLink or nodeWeapon, rRoll)
				end
				break
			end
		end
	end
end

local function noDecrementAmmo() end

-- Function Overrides

local onPostAttackResolve_old
local function onPostAttackResolve_new(rSource, rTarget, rRoll, rMessage, ...)
	onPostAttackResolve_old(rSource, rTarget, rRoll, rMessage, ...)
	AmmunitionManager.ammoTracker(rSource, rRoll)
end

function onInit()
	sRuleset = User.getRulesetName()

	onPostAttackResolve_old = ActionAttack.onPostAttackResolve
	ActionAttack.onPostAttackResolve = onPostAttackResolve_new

	if sRuleset == 'PFRPG' or sRuleset == '3.5E' then
		table.insert(tLoadWeapons, 'firearm')
		table.insert(tLoadWeapons, 'crossbow')
		table.insert(tLoadWeapons, 'javelin')
		table.insert(tLoadWeapons, 'ballista')
		table.insert(tLoadWeapons, 'windlass')
		table.insert(tLoadWeapons, 'pistol')
		table.insert(tLoadWeapons, 'rifle')
		table.insert(tLoadWeapons, 'sling')
	elseif sRuleset == '5E' then
		CharWeaponManager.decrementAmmo = noDecrementAmmo
	end

	if Session.IsHost then AmmunitionManagerUpgrades.upgradeData() end
end
