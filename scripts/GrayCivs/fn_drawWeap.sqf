/* 
 *	Author: [SGC] Xephros, [DMCL] _keystone
 *	Function for Gray Civilian to draw concealled weapon.
 *
 *	Arguments:
 *      0: Unit <OBJECT> - Unit to draw concealled weapon.
 *      1: Time <NUMBER> - Time delay before drawing concealled weapon.
 *      2: Weapons & Mags <ARRAY> - Array of possible weapons to draw with magazine count to add.
 *          0: Weapon <STRING> - Weapon to draw.
 *          1: Magazine Count <NUMBER> - Number of magazines to add to unit inventory.
 *
 *  Examples:
 *      [man1] call XK_fn_drawWeap;
 *      [man1, 5, [["hgun_Rook40_F",3],["hgun_ACPC2_F",3]]] call XK_fn_drawWeap;
 *
 *	Return Value: None
 */

params ["_u", ["_timer", 1], ["_weapList", GC_Weapons]];

(selectRandom _weapList) params ["_weap","_mags"];
diag_log format ["[GrayCivs] %1 %2 is drawing weapon in %3 seconds. Exiting PFH.", name _u, getPosATL _u, _timer];

//Adds weapon to unit inventory if handcuffed
[
    {
        params ["_u","_weap","_mags"];
        (_u getVariable ["ace_captives_isHandcuffed", false]) == true;
    },
    {
        params ["_u","_weap","_mags"];
        private _gunDrawn = _u getVariable ["GC_gunDrawn", false];
        if !(_gunDrawn) exitWith {
            _u setVariable ["GC_gunDrawn", true];
            diag_log format ["[GrayCivs] %1 %2 is restrained, cannot draw weapon.", name _u, getPosATL _u];
            _u addMagazines [((compatibleMagazines _weap) select 0),_mags];
            _u addWeapon _weap;
            _u setBehaviour "COMBAT";
            [group _u, getPosATL (_u findNearestEnemy _u), 100] call CBA_fnc_taskAttack;
            diag_log format ["[GrayCivs] %1 with %2 mags added to %3 %4",_weap, _mags, name _u, getPosATL _u];
        };
    },
    [_u,_weap,_mags]
] call CBA_fnc_waitUntilAndExecute;

//Draws Weapon if timer expires
[
    {
        params ["_u","_weap","_mags"];
        private _gunDrawn = _u getVariable ["GC_gunDrawn", false];
        if !(_gunDrawn) then {
            _u setVariable ["GC_gunDrawn", true];
            if (_u getVariable ["ace_captives_isHandcuffed", false]) exitWith {
            diag_log format ["[GrayCivs] %1 %2 is restrained, cannot draw weapon.", name _u, getPosATL _u];
            };
            _u addMagazines [((compatibleMagazines _weap) select 0),_mags];
            _u addWeapon _weap;
            _u setBehaviour "COMBAT";
            [group _u, getPosATL (_u findNearestEnemy _u), 100] call CBA_fnc_taskAttack;
            diag_log format ["[GrayCivs] %1 with %2 mags added to %3 %4",_weap, _mags, name _u, getPosATL _u];
        };
    },
    [_u,_weap,_mags],
    _timer
] call CBA_fnc_waitAndExecute;