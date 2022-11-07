--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

--	luacheck: globals isLoading
function isLoading(nodeWeapon)
	local sProps = DB.getValue(nodeWeapon, 'properties', ''):lower()

	local bCrossbow = DB.getValue(nodeWeapon, 'name', 'weapon'):lower():find('crossbow')
		and CharManager.hasFeature(nodeWeapon.getChild('...'), 'crossbow expert')

	return not bCrossbow and sProps:find('loading') and not sProps:find('noload')
end

--	luacheck: globals onDamageAction
function onDamageAction(draginfo)
	local nodeWeapon = getDatabaseNode()
	local nodeChar = nodeWeapon.getChild('...')

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
		if nodeAmmo then rActor.ammoPath = nodeAmmo.getPath() end
	end
	-- end bmos adding ammoPath

	ActionDamage.performRoll(draginfo, rActor, rAction)
	return true
end

--	luacheck: globals onDataChanged maxammo.setLink
function onDataChanged(nodeWeapon)
	if super and super.onDataChanged then super.onDataChanged() end

	local nodeChar = nodeWeapon.getChild('...')
	local rActor = ActorManager.resolveActor(nodeChar)
	local bLoading = isLoading(nodeWeapon)
	isloaded.setVisible(bLoading)
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	ammocounter.setVisible(not nodeAmmoLink)
	if nodeAmmoLink then
		maxammo.setLink(nodeAmmoLink.getChild('count'), true)
	else
		maxammo.setLink()
	end
end

function onInit()
	if super then
		if super.onAttackAction then
			local onAttackAction_old
			local function onAttackAction_new(draginfo, ...)
				local nodeWeapon = getDatabaseNode()
				local nodeChar = nodeWeapon.getChild('...')
				local rActor = ActorManager.resolveActor(nodeChar)
				local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))
				local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }

				-- only allow attacks when 'loading' weapons have been loaded
				local bLoading = isLoading(nodeWeapon)
				local bIsLoaded = DB.getValue(nodeWeapon, 'isloaded', 0) == 1
				if not bLoading or (bLoading and bIsLoaded) then
					if bInfiniteAmmo or nAmmo > 0 then
						if bLoading then DB.setValue(nodeWeapon, 'isloaded', 'number', 0) end
						return onAttackAction_old(draginfo, ...)
					else
						messagedata.text = Interface.getString('char_message_atkwithnoammo')
						Comm.deliverChatMessage(messagedata)

						if bLoading then DB.setValue(nodeWeapon, 'isloaded', 'number', 0) end
					end
				else
					local sWeaponName = DB.getValue(nodeWeapon, 'name', 'weapon')
					messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName, true, rActor)
					Comm.deliverChatMessage(messagedata)
				end
				-- end bmos only allowing attacks when ammo is sufficient
			end

			onAttackAction_old = super.onAttackAction
			super.onAttackAction = onAttackAction_new
		end
		if super.onInit then super.onInit() end
	end

	local nodeWeapon = getDatabaseNode()
	DB.addHandler(nodeWeapon.getPath(), 'onChildUpdate', onDataChanged)

	onDataChanged(nodeWeapon)
end

function onClose()
	if super and super.onClose then super.onClose() end

	local nodeWeapon = getDatabaseNode()
	DB.removeHandler(nodeWeapon.getPath(), 'onChildUpdate', onDataChanged)
end
