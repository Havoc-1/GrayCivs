/*
 *    Author: [SGC] Xephros, [DMCL] Keystone
 *
 *    Gray Civilians settings.
 *    File containing CBA addon option settings 
 */

//GC Faction Side
[
    "GC_Fac",
    "LIST",
    ["Faction of Gray Civilian", "Gray Civilians will change sides to this faction. Should be hostile to player faction."],
    "Settings", [[east, independent, west], ["east","independent","west"], 0];
] call CBA_fnc_addSetting;

[
    "GC_Weapons", 
    "EDITBOX", 
    ["GrayCiv Weapons", "Weapons available for Gray Civilians to conceal carry. Separate with commas."], 
    ["Settings","1. Settings1"], 
    "ACE_Vector, ACE_VectorDay",[[1, 0]]
] call CBA_fnc_addSetting;

[
    "GC_grabChance",
    "SLIDER",
    ["Weapon Grab Chance", "Chance for Gray Civilian to search for a nearby weapon. Default 0.7"],
    ["Settings", "Settings2"],
    [0, 1, 0.7],
    [[0,1]]
] call CBA_fnc_addSetting;