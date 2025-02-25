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

local function hasSubstring(string, table)
	for _, v in pairs(table) do
		if string.find(string, v) then
			return true
		end
	end
end

--	luacheck: globals hasLoadAction
function hasLoadAction(nodeWeapon)
	if not AmmunitionManager.isWeaponRanged(nodeWeapon) then
		return false
	end

	local sWeaponProps = string.lower(DB.getValue(nodeWeapon, 'properties', ''))
	local bNoLoad = hasSubstring(sWeaponProps, tNoLoadWeaponProps)
	if bNoLoad then
		return false
	end

	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', ''))
	return (hasSubstring(sWeaponName, tLoadWeapons) and not hasSubstring(sWeaponName, tNoLoadWeapons)) or hasSubstring(sWeaponProps, tLoadWeaponProps)
end

--	luacheck: globals getShortcutNode
function getShortcutNode(nodeWeapon, shortcutName)
	local _, sRecord = DB.getValue(nodeWeapon, shortcutName or 'ammunitionmanager.ammopickershortcut')
	if sRecord and sRecord ~= '' then
		return DB.findNode(sRecord)
	end
end

--	luacheck: globals isAmmo
function isAmmo(nodeItem, nodeWeapon, sTypeField)
	local bThrown = false
	if nodeWeapon and User.getRulesetName() == '5E' then
		bThrown = DB.getValue(nodeWeapon, 'type', 0) == 2
	end
	if sTypeField and DB.getChild(nodeItem, sTypeField) then
		local sItemType = DB.getValue(nodeItem, sTypeField, ''):lower()
		if bThrown then
			return (sItemType:match('weapon') ~= nil)
		else
			return (sItemType:match('ammunition') ~= nil) or (sItemType:match('ammo') ~= nil)
		end
	end
end

-- luacheck: globals parseWeaponCapacity
function parseWeaponCapacity(capacity)
	local sCapacityLower = capacity:lower()
	if sCapacityLower == 'drawn' then
		return 0, sCapacityLower
	end
	local splitCapacity = StringManager.splitWords(sCapacityLower)
	return tonumber(splitCapacity[1]), splitCapacity[2]
end

-- luacheck: globals isWeaponRanged
function isWeaponRanged(nodeWeapon)
	local bRanged = DB.getValue(nodeWeapon, 'type', 0) == 1
	if User.getRulesetName() == '5E' then
		bRanged = bRanged or DB.getValue(nodeWeapon, 'type', 0) == 2
	end
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
	if not bRanged then
		return
	end

	-- check for saved ammopickershortcut windowreference and return if found
	local ammoNode = AmmunitionManager.getShortcutNode(nodeWeapon)
	if ammoNode then
		return ammoNode
	end

	-- if ammopickershortcut does not provide a good node and weapon is ranged, try searching the inventory.

	local sAmmo = DB.getValue(nodeWeapon, sAmmunitionManagerSubnode .. 'ammopicker', '')
	if sAmmo == '' then
		return
	end

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
		if sItemName == sAmmo then
			return nodeItem
		end
	end
	Debug.console(Interface.getString('debug_ammo_itemnotfound'))
end

local function trimAttackDescription(s)
	local sTrim = s:gsub('%[ATTACK%s#?%d*%s?%(%u%)%]', '')
	sTrim = sTrim:gsub('%[%u+%s*%-*%d*%]', '')
	if sTrim:match('%[USING ') then
		sTrim = sTrim:match('%[USING (.-)%]')
	end
	--sTrim = sTrim:gsub('%*.+%*', '') -- compat with Dropped Order extension
	sTrim = sTrim:gsub('%[.+%]', '')
	sTrim = sTrim:gsub(' %(vs%. .+%)', '')
	sTrim = StringManager.trim(sTrim)

	return sTrim or ''
end

local function isInfiniteAmmo(rSource, nodeWeapon)
	local bInfiniteAmmo = DB.getValue(nodeWeapon, 'type', 0) ~= 1
	if sRuleset == '5E' then
		local bThrown = DB.getValue(nodeWeapon, 'type', 0) == 2
		bInfiniteAmmo = (bInfiniteAmmo and not bThrown)
	end
	return bInfiniteAmmo or EffectManager.hasCondition(rSource, 'INFAMMO')
end

--	luacheck: globals getAmmoRemaining
function getAmmoRemaining(rSource, nodeWeapon, nodeAmmoLink)
	if isInfiniteAmmo(rSource, nodeWeapon) then
		return 0, true
	end
	if nodeAmmoLink then
		return DB.getValue(nodeAmmoLink, sLinkedCount, 0), false
	end

	local nMaxAmmo = DB.getValue(nodeWeapon, sUnlinkedMaxAmmo, 0)
	local nAmmoUsed = DB.getValue(nodeWeapon, sUnlinkedAmmo, 0)
	local nAmmo = nMaxAmmo - nAmmoUsed

	return nAmmo, nMaxAmmo == 0
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

local function trackWeaponAmmo(rSource, rRoll, nodeWeapon, sWeaponNameFromSource)
	if sWeaponNameFromSource:lower() ~= DB.getValue(nodeWeapon, 'name', ''):lower() then
		return false
	end
	if not rRoll.sDesc:match('%[ATTACK%s#?%d*%s?%(R%)%]') then
		return false
	end
	if DB.getValue(nodeWeapon, 'type', 0) == 0 then
		return false
	end

	local nodeAmmoLink = getAmmoNode(nodeWeapon)
	local nAmmoRemaining, bInfiniteAmmo = getAmmoRemaining(rSource, nodeWeapon, nodeAmmoLink)
	if bInfiniteAmmo then
		return true
	end

	writeAmmoRemaining(nodeWeapon, nodeAmmoLink, nAmmoRemaining - 1, sWeaponNameFromSource)
	countShots(nodeAmmoLink or nodeWeapon, rRoll)
	return true
end

--	tick off used ammunition, count misses, post 'out of ammo' chat message
--	luacheck: globals ammoTracker
function ammoTracker(rSource, rRoll)
	if not ActorManager.isPC(rSource) or rRoll.sDesc:match('%[CONFIRM%]') then
		return
	end

	local sWeaponNameFromSource = trimAttackDescription(rRoll.sDesc)
	if sWeaponNameFromSource == '' then
		return
	end

	for _, nodeWeapon in ipairs(DB.getChildList(ActorManager.getCreatureNode(rSource), 'weaponlist')) do
		if trackWeaponAmmo(rSource, rRoll, nodeWeapon, sWeaponNameFromSource) then
			break
		end
	end
end

-- placeholder function to negate in-built pre-attack ammo tracking
local function noDecrementAmmo() end

-- Function Overrides

local onPostAttackResolve_old
local function onPostAttackResolve_new(rSource, rTarget, rRoll, rMessage, ...)
	onPostAttackResolve_old(rSource, rTarget, rRoll, rMessage, ...)
	AmmunitionManager.ammoTracker(rSource, rRoll)
end

-- Handles multi-item ammo packages like "Arrows (20)" by breaking them into individual items
local function itemizeAmmunitionPackage(nodeItem)
	if not isAmmo(nodeItem, nil, 'subtype') and not isAmmo(nodeItem, nil, 'type') then
		return nodeItem
	end

	local sItemName = DB.getValue(nodeItem, 'name', '')
	local nPackageCount
	sItemName, nPackageCount = string.match(sItemName, '^(.-) %((%d+)%)$')
	sItemName = string.match(sItemName or '', '^(.-)s?$')
	if not nPackageCount then
		return nodeItem
	end

	local nCount = DB.getValue(nodeItem, 'count', 1)
	local nWeight = DB.getValue(nodeItem, 'weight', 0)
	local sCost = string.lower(DB.getValue(nodeItem, 'cost', ''))
	local nVal, nCurr = string.match(sCost, '(%d+) ([gscp]p)')
	if nVal and nCurr then
		sCost = tostring(nVal / nPackageCount) .. ' ' .. nCurr
	end

	DB.setValue(nodeItem, 'name', 'string', sItemName)
	DB.setValue(nodeItem, 'count', 'number', nCount * nPackageCount)
	DB.setValue(nodeItem, 'weight', 'number', nWeight / nPackageCount)
	DB.setValue(nodeItem, 'cost', 'string', sCost)

	return nodeItem
end

local addItemToList_old
local function addItemToList_new(vList, sClass, vSource, bTransferAll, nTransferCount, ...)
	local nodeItem = addItemToList_old(vList, sClass, vSource, bTransferAll, nTransferCount, ...)
	nodeItem = itemizeAmmunitionPackage(nodeItem)
	return nodeItem
end

function onInit()
	sRuleset = User.getRulesetName()

	onPostAttackResolve_old = ActionAttack.onPostAttackResolve
	ActionAttack.onPostAttackResolve = onPostAttackResolve_new

	addItemToList_old = ItemManager.addItemToList
	ItemManager.addItemToList = addItemToList_new

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

	if Session.IsHost then
		AmmunitionManagerUpgrades.upgradeData()
	end
end
