--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

--	luacheck: globals automateAmmo
function automateAmmo(nodeWeapon)
	local nodeAmmoManager = DB.getChild(nodeWeapon, 'ammunitionmanager')
	local bIsLoaded = DB.getValue(nodeAmmoManager, 'isloaded') == 1
	DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0)

	if not AmmunitionManager.hasLoadAction(nodeWeapon) or bIsLoaded then
		return false
	end
	local rActor = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...'))
	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'))

	local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
	messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName)
	Comm.deliverChatMessage(messagedata)

	return true
end

-- luacheck: globals onDataChanged maxammo.setLink
function onDataChanged()
	if super and super.onDataChanged then
		super.onDataChanged()
	end
	if sub_ranged.getValue() == "char_weapon_ranged" then
		sub_ranged.subwindow.onAmmoChanged()
	end
end

function onInit()
	if super and super.onInit then
		super.onInit()
	end
	local sNode = DB.getPath(getDatabaseNode())
	DB.addHandler(sNode, 'onChildUpdate', onDataChanged)
	onDataChanged()
end

function onClose()
	if super and super.onClose then
		super.onClose()
	end
	local sNode = DB.getPath(getDatabaseNode())
	DB.removeHandler(sNode, 'onChildUpdate', onDataChanged)
end
