[![Build FG-Usable File](https://github.com/bmos/FG-Ammunition-Manager/actions/workflows/release.yml/badge.svg)](https://github.com/bmos/FG-Ammunition-Manager/actions/workflows/release.yml)
[![Lua Checks](https://github.com/bmos/FG-Ammunition-Manager/actions/workflows/lua.yml/badge.svg)](https://github.com/bmos/FG-Ammunition-Manager/actions/workflows/lua.yml)

# Ammunition Manager
This extension aids in tracking whether some ranged weapons are loaded and assists in ammo tracking for all ranged weapons.

# Compatibility and Instructions
This extension has been tested with [FantasyGrounds Unity](https://www.fantasygrounds.com/home/FantasyGroundsUnity.php) v4.5.0 (2024-02-21).

This extension works with the 3.5E, PFRPG, PFRPG2, 4E, and 5E rulesets.
When used with 4E, the option "Power: Show item used" must be enabled for ammo tracking to work from the Powers tab (unless the power has the same name as the weapon used).

It used to work for SFRPG, but that has now spun off into its own extension maintained by SoxMax.

# Features
* Adds a checkbox to the left of the ammo label on the weapons section of the actions tab; this checkbox is only shown for some weapons (those with 'firearm', 'crossbow', 'javelin', 'ballista', 'windlass', 'pistol', 'rifle', or 'loadaction' in the weapon name when using PFRPG). Loading these weapon will post a message to chat to help monitor the action-economy. Attacks attempted with these weapons without loading them first will post a message to chat and the attack will not go through. If you want to disable this on a per-weapon basis, add the weapon property 'noload.'

* Opening the weapon details page from the actions tab will allow swapping between ammo types. When an ammo type is selected here it will hide the normal ammo tracker and use the inventory count directly.

* Attacking will mark-off ammunition automatically. Messages will post to chat if there is no ammunition available or if the final arrow is used.

* Ranged attacks that miss will now increment a per-ammo-type counter. If you open the weapon details page from the actions tab, you can now enter a percentage of missed arrows to recover. Clicking the green circle with + symbol will add this percentage of missed arrows back to the quiver.

* An "INFAMMO" effect negates the counting of used ammo and missed shots (as per rules for Abundant Ammunition).

* If used with [Advanced Effects for Pathfinder and 3.5E](https://forge.fantasygrounds.com/shop/items/33/view) or [5E Advanced Effects](https://forge.fantasygrounds.com/shop/items/68/view), "Action Only" effects attached to equipped ammmunition used in an attack will be included in the roll.
This allowed things like "Magic Arrow; ATK: 1 enhancement" to be added to the arrow effects list and it will only be used to modify the attack when the archer uses **those** arrows (even if those arrows are equipped constantly in the inventory).

* Enabling the "Chat: Show weapon name in results" option will add the weapon name to attack results in chat such as "Attack [16] -> [at Goblin] with Shortsword [HIT]" instead of "Attack [16] -> [at Goblin] [HIT]".

* NOTE: Some modules contain entries like "Arrows (20)". If you have quantity 1 of "Arrows (20)" and select this as your weapon, it will reduce you to quantity 0 of "Arrows (20)". You should instead (in this example) change it to quantity 20 of "Arrow" and divide the weight by 20 as well. I'm not sure why the module authors often ignore this detail, but this is how to work around it.

# Video Demonstration (click for video)
[<img src="https://i.ytimg.com/vi_webp/i_vmW9WVkbM/hqdefault.webp">](https://www.youtube.com/watch?v=i_vmW9WVkbM)
