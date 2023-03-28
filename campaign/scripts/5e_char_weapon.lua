--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

--	luacheck: globals isLoading
function isLoading(nodeWeapon)
	Debug.console('AmmunitionManager char_weapon isLoading - DEPRECATED - 2023-03-20 - Use AmmunitionManager.hasLoadAction')
	return AmmunitionManager.hasLoadAction(nodeWeapon)
end

--	luacheck: globals onDamageAction
function onDamageAction(draginfo)
	local nodeWeapon = getDatabaseNode()
	local nodeChar = DB.getChild(nodeWeapon, '...')

	-- Build basic damage action record
	local rAction = CharWeaponManager.buildDamageAction(nodeChar, nodeWeapon)

	-- Perform damage action
	local rActor = ActorManager.resolveActor(nodeChar)

	-- Celestian adding itemPath to rActor so that when effects
	-- are checked we can compare against action only effects
	local _, sRecord = DB.getValue(nodeWeapon, 'shortcut', '', '')
	rActor.itemPath = sRecord
	-- end Adanced Effects piece ---

	-- bmos adding ammoPath for AmmunitionManager + Advanced Effects integration
	-- add this in the onDamageAction function of other effects to maintain compatibility
	if AmmunitionManager then
		local nodeAmmo = AmmunitionManager.getAmmoNode(nodeWeapon, rActor)
		if nodeAmmo then rActor.ammoPath = DB.getPath(nodeAmmo) end
	end
	-- end bmos adding ammoPath

	ActionDamage.performRoll(draginfo, rActor, rAction)
	return true
end

--	luacheck: globals setAmmoVis maxammo.setLink
function setAmmoVis(nodeWeapon, ...)
	if super and super.setAmmoVis then super.setAmmoVis(nodeWeapon, ...) end

	local bLoading = AmmunitionManager.hasLoadAction(nodeWeapon)
	isloaded.setVisible(bLoading)

	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	ammocounter.setVisible(not nodeAmmoLink)

	local nodeCount
	if nodeAmmoLink then nodeCount = DB.getChild(nodeAmmoLink, 'count') end
	maxammo.setLink(nodeCount, nodeCount ~= nil)
end

--	luacheck: globals onDataChanged
function onDataChanged(nodeWeapon)
	if super and super.onDataChanged then super.onDataChanged(nodeWeapon) end

	self.setAmmoVis(nodeWeapon)
end

local onAttackAction_old
local function onAttackAction_new(draginfo, ...)
	local nodeWeapon = getDatabaseNode()
	local nodeChar = DB.getChild(nodeWeapon, '...')
	local rActor = ActorManager.resolveActor(nodeChar)
	local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))
	local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }

	local bLoading = AmmunitionManager.hasLoadAction(nodeWeapon)

	local nodeAmmoManager = DB.getChild(nodeWeapon, 'ammunitionmanager')
	local bIsLoaded = DB.getValue(nodeAmmoManager, 'isloaded') == 1
	if not bLoading or bIsLoaded then
		if bInfiniteAmmo or nAmmo > 0 then
			if bLoading then DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0) end
			return onAttackAction_old(draginfo, ...)
		end
		messagedata.text = Interface.getString('char_message_atkwithnoammo')
		Comm.deliverChatMessage(messagedata)

		if bLoading then DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0) end
	else
		local sWeaponName = DB.getValue(nodeWeapon, 'name', 'weapon')
		messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName, true, rActor)
		Comm.deliverChatMessage(messagedata)
	end
	-- end bmos only allowing attacks when ammo is sufficient
end

function onInit()
	if super and super.onInit then super.onInit() end

	if super then
		if super.onAttackAction then
			onAttackAction_old = super.onAttackAction
			super.onAttackAction = onAttackAction_new
		end
	end

	local nodeWeapon = getDatabaseNode()
	DB.addHandler(DB.getPath(nodeWeapon), 'onChildUpdate', onDataChanged)

	self.onDataChanged(nodeWeapon)
end

function onClose()
	if super and super.onClose then super.onClose() end

	if super then
		if super.onAttackAction then
			super.onAttackAction = onAttackAction_old
		end
	end

	local nodeWeapon = getDatabaseNode()
	DB.removeHandler(DB.getPath(nodeWeapon), 'onChildUpdate', onDataChanged)
end
