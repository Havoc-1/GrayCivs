/* 
 *	Author: [SGC] Xephros, [DMCL] _keystone
 *	Function for Gray Civilian to search for nearby weapon.
 *
 *	Arguments:
 *      0: Unit <OBJECT> - Unit to search for nearby weapon.
 *      1: Time <NUMBER> (Optional) - Time delay before searching for nearby weapon.
 *      2: Timeout <NUMBER> (Optional) - Switches back to civilian side if unable to find weapon after timeout expires.
 *      3: Debug Mode <BOOL> (Optional) - DrawIcon3D for visibility check on weapon.
 *
 *  Examples:
 *      [man1] call XK_fn_searchWeap;
 *      [man1, 5, 180, false] call XK_fn_searchWeap;
 *
 *	Return Value: None
 */

params ["_u",["_timer",1],["_timeout",GC_wpnTimeout],["_debug", false]];
diag_log format ["[GrayCivs] %1 %2 will search for a nearby weapon in %3 seconds. Exiting PFH.", name _u, getPosATL _u, _timer];
[
    {
        params ["_u", "_timeout", "_debug"];
        private _wpns = (nearestObjects [_u, ["WeaponHolder", "WeaponHolderSimulated"], 30]) select {!(isPlayer (attachedTo _x))};
        private _wpnsNotTaken = _wpns select {(_x getVariable ["GC_wpnTaken", false]) == false};
        if (count _wpns == 0 || count _wpnsNotTaken == 0) exitWith {diag_log format ["[GrayCivs] %1 %2 has no nearby guns to grab.", name _u, getPosATL _u]};
        private _randomGun = selectRandom _wpnsNotTaken;
        _randomGun setVariable ["GC_wpnTaken", true];
        if (isNull _randomGun) exitWith {diag_log format ["[GrayCivs] %1 %2 weapon seach cancelled. Gun no longer exists.", name _u, getPosATL _u]};
        diag_log format ["[GrayCivs] %1 %2 is trying to grab %3 %4.", name _u, getPosATL _u, ((weaponCargo _randomGun) select 0), getPosATL _randomGun];
        [group _u] call CBA_fnc_clearWaypoints;
        [group _u, getPosATL _randomGun, 0, "MOVE", "CARELESS", "YELLOW", "FULL", "STAG COLUMN"] call CBA_fnc_addWaypoint;
        
        //Line of sight raised above the ground for consistency
        private _visPos = [];
        if (_randomGun isKindOf "WeaponHolderSimulated") then {
            _visPos = [(getPosASL (getCorpse _randomGun)) select 0, (getPosASL (getCorpse _randomGun)) select 1, ((getPosASL (getCorpse _randomGun)) select 2) + 0.7];
        } else {
            _visPos = [(getPosASL _randomGun) select 0, (getPosASL _randomGun) select 1, ((getPosASL _randomGun) select 2) + 0.7];
        };

        //Gives weapon to unit if in range and line of sight
        [
            {
                params ["_u", "_randomGun","_visPos"];
                private _canSeeGun = [objNull, "VIEW"] checkVisibility [eyePos _u, _visPos];
                if (_debug) then {drawIcon3D ["\A3\ui_f\data\map\markers\military\circle_CA.paa", [1,1,0,1], ASLtoAGL _visPos, 0.3, 0.3, 45, "Here", 0, 0.03, "TahomaB","center",true,0,0.003]};
                (_u distance _randomGun < 4) && (_canSeeGun > 0.2);
            },
            {
                params ["_u", "_randomGun"];
                if !(alive _u || alive _randomGun) exitWith {};
                diag_log format ["[GrayCivs] %1 %2 has grabbed %3 %4.", name _u, getPosATL _u, ((weaponCargo _randomGun) select 0), getPosATL _randomGun];
                _u action ["TakeWeapon", _randomGun, ((weaponCargo _randomGun) select 0)];
                _u addMagazines [((compatibleMagazines ((weaponCargo _randomGun) select 0)) select 0),1];
                _u addWeapon ((weaponCargo _randomGun) select 0);
                _u selectWeapon ((weaponCargo _randomGun) select 0);
                _u setBehaviour "COMBAT";
                _u setVariable ["GC_gunDrawn", true];
                deleteVehicle _randomGun;
                [group _u] call CBA_fnc_clearWaypoints;
                [group _u, getPosATL (_u findNearestEnemy _u), 100] call CBA_fnc_taskAttack;
            },
            [_u, _randomGun,_visPos]
        ] call CBA_fnc_waitUntilAndExecute;

        //Turns back to civilian if fails to get weapon
        [
            {
                params ["_u"];
                private _gunDrawn = _u getVariable ["GC_gunDrawn", false];
                if (_gunDrawn) exitWith {};
                _u setBehaviour "AWARE";
                private _grp = createGroup civilian;
                (units group _u) joinSilent _grp;
            },
            [_u],
            _timeout
        ] call CBA_fnc_waitAndExecute;
    },
    [_u, _timeout, _debug],
    _timer
] call CBA_fnc_waitAndExecute;