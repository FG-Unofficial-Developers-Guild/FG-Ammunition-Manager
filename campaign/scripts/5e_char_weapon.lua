--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

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
		if nodeAmmo then
			rActor.ammoPath = DB.getPath(nodeAmmo)
		end
	end
	-- end bmos adding ammoPath

	ActionDamage.performRoll(draginfo, rActor, rAction)
	return true
end

--	luacheck: globals onDataChanged_new sub_ranged.getValue sub_ranged.subwindow.onAmmoChanged
local onDataChanged_old
function onDataChanged_new(nodeWeapon)
	onDataChanged_old(nodeWeapon)
	if sub_ranged.getValue() == 'char_weapon_ranged' then
		sub_ranged.subwindow.onAmmoChanged()
	end
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
			if bLoading then
				DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0)
			end
			return onAttackAction_old(draginfo, ...)
		end
		messagedata.text = Interface.getString('char_message_atkwithnoammo')
		Comm.deliverChatMessage(messagedata)

		if bLoading then
			DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0)
		end
	else
		local sWeaponName = DB.getValue(nodeWeapon, 'name', 'weapon')
		messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName, true, rActor)
		Comm.deliverChatMessage(messagedata)
	end
	-- end bmos only allowing attacks when ammo is sufficient
end

function onInit()
	if super and super.onInit then
		super.onInit()
	end

	if super and super.onAttackAction then
		onAttackAction_old = super.onAttackAction
		super.onAttackAction = onAttackAction_new
	end

	if super and super.onDataChanged then
		onDataChanged_old = super.onDataChanged
		super.onDataChanged = onDataChanged_new
	end

	local nodeWeapon = getDatabaseNode()
	DB.addHandler(DB.getPath(nodeWeapon), 'onChildUpdate', self.onDataChanged)

	self.onDataChanged(nodeWeapon)
end

function onClose()
	if super and super.onClose then
		super.onClose()
	end

	if super and super.onAttackAction then
		super.onAttackAction = onAttackAction_old
	end

	local nodeWeapon = getDatabaseNode()
	DB.removeHandler(DB.getPath(nodeWeapon), 'onChildUpdate', self.onDataChanged)
end
