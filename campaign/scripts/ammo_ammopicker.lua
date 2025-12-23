--
-- Please see the LICENSE.md file included with this distribution for
-- attribution and copyright information.
--

-- luacheck: globals itemsheetname defaultvalue findItems
function findItems()
	local aAutoFill = {}
	table.insert(aAutoFill, Interface.getString(defaultvalue[1]))

	local nodeWeapon = window.getDatabaseNode()
	local nodeInventory = DB.getChild(nodeWeapon, '...inventorylist')
	if nodeInventory then
		for _, nodeItem in ipairs(DB.getChildList(nodeInventory)) do
			if DB.getValue(nodeItem, 'carried', 0) ~= 0 and itemsheetname and type(itemsheetname[1]) == 'table' then
				local sName = ItemManager.getDisplayName(nodeItem, true)
				for _, v in ipairs(itemsheetname) do
					if v.field and type(v.field) == 'table' and v.string and AmmunitionManager.isAmmo(nodeItem, nodeWeapon, v.field[1]) then
						table.insert(aAutoFill, sName)
					end
				end
			end
		end
	end
	super.addItems(aAutoFill)
end

-- luacheck: globals setValue setTooltipText
function onInit()
	if super then
		if super.onInit then
			super.onInit()
		end

		local setValue_old
		local function setValue_new(sValue)
			setValue_old(sValue)

			-- save node to weapon node when choosing ammo
			local nodeWeapon = DB.getParent(getDatabaseNode())

			local nodeInventory = DB.getChild(nodeWeapon, '...inventorylist')
			local nodeAmmoManager = DB.getChild(nodeWeapon, 'ammunitionmanager')
			if not nodeAmmoManager or not nodeInventory then
				return
			end

			local sDefaultValue = Interface.getString(defaultvalue[1])
			for _, nodeItem in ipairs(DB.getChildList(nodeInventory)) do
				local sName = ItemManager.getDisplayName(nodeItem, true)
				local sShortcutNodeName = DB.getName(getDatabaseNode()) .. 'shortcut'
				if sValue == sDefaultValue then
					DB.setValue(nodeAmmoManager, sShortcutNodeName, 'windowreference', 'item', '')
				elseif sValue == sName then
					DB.setValue(nodeAmmoManager, sShortcutNodeName, 'windowreference', 'item', '.....inventorylist.' .. DB.getName(nodeItem))
				end
			end
		end

		setValue_old = super.setValue
		super.setValue = setValue_new
	end

	findItems()
end
