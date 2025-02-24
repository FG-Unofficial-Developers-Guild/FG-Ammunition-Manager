--
-- Please see the LICENSE.md file included with this distribution for attribution and copyright information.
--

-- luacheck: globals onDataChanged maxammo.setLink
function onDataChanged()
	if super and super.onDataChanged then
		super.onDataChanged()
	end
	if sub_ranged.getValue() == "char_weapon_ranged" then
		sub_ranged.subwindow.onAmmoChanged()
	end
end

--	luacheck: globals isLoaded
function isLoaded(nodeWeapon)
	local nodeAmmoManager = DB.getChild(nodeWeapon, 'ammunitionmanager')
	local bIsLoaded = DB.getValue(nodeAmmoManager, 'isloaded') == 1
	DB.setValue(nodeAmmoManager, 'isloaded', 'number', 0)

	if not AmmunitionManager.hasLoadAction(nodeWeapon) or bIsLoaded then
		return true
	end
	local rActor = ActorManager.resolveActor(DB.getChild(nodeWeapon, '...'))
	local sWeaponName = string.lower(DB.getValue(nodeWeapon, 'name', 'ranged weapon'))

	local messagedata = { text = '', sender = rActor.sName, font = 'emotefont' }
	messagedata.text = string.format(Interface.getString('char_actions_notloaded'), sWeaponName)
	Comm.deliverChatMessage(messagedata)

	return false
end

--	luacheck: globals canShoot
function canShoot(rActor, nodeWeapon)
	local nAmmo, bInfiniteAmmo = AmmunitionManager.getAmmoRemaining(rActor, nodeWeapon, AmmunitionManager.getAmmoNode(nodeWeapon))

	if self.isLoaded(nodeWeapon) and (bInfiniteAmmo or nAmmo > 0) then
		return true
	end
end

--	luacheck: globals onFullAttackAction
function onFullAttackAction(draginfo)
	local nodeWeapon = getDatabaseNode();
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);

	local rRolls = {};
	for i = 1, DB.getValue(nodeWeapon, "attacks", 1) do
		if canShoot(rActor, nodeWeapon) then
			rAttack.modifier = self.calcAttackBonus(i);
			rAttack.order = i;
			table.insert(rRolls, ActionAttack.getRoll(rActor, rAttack));
		else
			break;
		end
	end
	if not OptionsManager.isOption("RMMT", "off") and (#rRolls > 1) then
		for _,v in ipairs(rRolls) do
			v.sDesc = v.sDesc .. " [FULL]";
		end
	end

	ActionsManager.performMultiAction(draginfo, rActor, "attack", rRolls);
	return true;
end

--	luacheck: globals onSingleAttackAction
function onSingleAttackAction(n, draginfo)
	local nodeWeapon = getDatabaseNode();
	local rActor, rAttack = CharManager.getWeaponAttackRollStructures(nodeWeapon);
	rAttack.order = n or 1;
	rAttack.modifier = self.calcAttackBonus(n or 1);

	if self.canShoot(rActor, nodeWeapon) then
		ActionAttack.performRoll(draginfo, rActor, rAttack);
		return true;
	end
end
