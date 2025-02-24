--	luacheck: globals onAmmoChanged maxammo.setLink
function onAmmoChanged()
    local nodeWeapon = getDatabaseNode()
	local nodeAmmoLink = AmmunitionManager.getAmmoNode(nodeWeapon)
	local rActor = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...'))
	local _, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, nodeAmmoLink)

	isloaded.setVisible(AmmunitionManager.hasLoadAction(nodeWeapon))
	ammocounter.setVisible(not bInfiniteAmmo and not nodeAmmoLink)
	ammopicker.setComboBoxVisible(not bInfiniteAmmo and nodeAmmoLink)
	ammopicker.setComboBoxReadOnly(true)

	if not maxammo.setLink then
		return
	end

	local nodeLinkedCount = DB.getChild(nodeAmmoLink, AmmunitionManager.sLinkedCount)
	maxammo.setLink(nodeLinkedCount, nodeLinkedCount ~= nil)
end

--	luacheck: globals onLockModeChanged
function onLockModeChanged(bReadOnly)
    if super and super.onLockModeChanged then
        super.onLockModeChanged()
    end
    self.onAmmoChanged()
end
