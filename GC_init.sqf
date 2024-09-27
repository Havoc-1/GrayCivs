/* 
 *	Author: [SGC] Xephros
 *	Function to initialize Grey Civilian on unit.
 *
 *	Arguments:
 *      0: Unit <OBJECT> - Civilian to turn into grey civ. 
 *
 *	Return Value: None
 *
 *	Example:
 *		[this] execVM "GC_init.sqf";
 */

_this params ["_u"];
diag_log format ["[GreyCivs] Grey Civilian has been initalized on %1.", name _u];


GC_Tick = 3;                //PFH Tick rate
GC_DrawTime = [0,30];       //[Min,Max] Time in Seconds for GreyCiv to draw weapon.
GC_Act = 100;               //Activation range to switch sides.
GC_Range = 20;              //Visibility range check to draw weapon.
GC_bluSide = west;          //BLUFOR
GC_opSide = east;           //OPFOR

GC_Weapons = [
    ["hgun_Rook40_F",3],
    ["hgun_Pistol_heavy_02_F",3],
    ["hgun_ACPC2_F",3]
];

//Activates search when BLUFOR is in range
[
    {
        params ["_u"];
        count ((_u nearEntities [["CAMan","AllVehicles"], GC_Act]) select {(_x != _u) && (isPlayer _x) && (side _x == GC_bluSide)}) != 0;
    },
    {
        params ["_u"];
        diag_log format ["[GreyCivs] %1 %2 is now searching for targets. Starting PFH.",name _u, getPosATL _u];
        private _grp = createGroup GC_opSide;
        (units group _u) joinSilent _grp;
        _u setCaptive true;
        [
            {
                _args params ["_u"];

                //Ends PFH if dead
                if !(alive _u) exitWith {
                    diag_log format ["[GreyCivs] %1 %2 has died. Exiting PFH.",name _u, getPosATL _u];
                    [_this select 1] call CBA_fnc_removePerFrameHandler
                };

                //List of nearby targets
                private _list = [];
                private _listOld = _u getVariable ["GC_List", []];
                _list = (_u nearEntities [["CAMan","AllVehicles"], GC_Range]) select {(_x != _u) && (side _x == GC_bluSide)};
                if (count _list == 0) exitWith {};
                if (_list isNotEqualTo _listOld) then {
                    _u setVariable ["GC_List", _list];
                    diag_log format ["[GreyCivs] %1 units are in range of %2 %3. %4",count _list, name _u, getPosATL _u, _list];
                };

                {
                    //Line of Sight checker to become hostile
                    private _canSee = [objNull, "VIEW"] checkVisibility [eyePos _u, eyePos _x];
                    /* diag_log format ["Visibility to %1: %2", name _x, _canSee]; */
                    if (_canSee > 0.5) then {
                        _u setVariable ["GC_isHostile", true];
                        _u setCaptive false;
                        diag_log format ["[GreyCivs] %1 %2 has visibility on %3", name _u, getPosATL _u, name _x];
                    };
                    private _isHostile = _u getVariable ["GC_isHostile",false];
                    
                    //Handles weapon & ammo spawn after draw time ends or gets cuffed
                    if (_isHostile) exitWith {
                        private _timer = GC_DrawTime call BIS_fnc_randomInt;
                        (selectRandom GC_Weapons) params ["_weap","_mags"];
                        diag_log format ["[GreyCivs] %1 %2 is drawing weapon in %3 seconds. Exiting PFH.", name _u, getPosATL _u, _timer];
                        [
                            {
                                params ["_u","_weap","_mags"];
                                (_u getVariable ["ace_captives_isHandcuffed", false]) == true;
                            },
                            {
                                params ["_u","_weap","_mags"];
                                if !(_weap in weapons _u) exitWith {
                                    diag_log format ["[GreyCivs] %1 %2 is restrained, cannot draw weapon.", name _u, getPosATL _u];
                                    _u addMagazines [((compatibleMagazines _weap) select 0),_mags];
                                    _u addWeapon _weap;
                                    _u setBehaviour "COMBAT";
                                    [group _u, getPosATL (_u findNearestEnemy _u), 100] call CBA_fnc_taskAttack;
                                    diag_log format ["[GreyCivs] %1 with %2 mags added to %3 %4",_weap, _mags, name _u, getPosATL _u];
                                };
                            },
                            [_u,_weap,_mags]
                        ] call CBA_fnc_waitUntilAndExecute;
                        [
                            {
                                params ["_u","_weap","_mags"];
                                if !(_weap in weapons _u) then {
                                    if (_u getVariable ["ace_captives_isHandcuffed", false]) exitWith {
                                    diag_log format ["[GreyCivs] %1 %2 is restrained, cannot draw weapon.", name _u, getPosATL _u];
                                    };
                                    _u addMagazines [((compatibleMagazines _weap) select 0),_mags];
                                    _u addWeapon _weap;
                                    _u setBehaviour "COMBAT";
                                    [group _u, getPosATL (_u findNearestEnemy _u), 100] call CBA_fnc_taskAttack;
                                    diag_log format ["[GreyCivs] %1 with %2 mags added to %3 %4",_weap, _mags, name _u, getPosATL _u];
                                };
                            },
                            [_u,_weap,_mags],
                            _timer
                        ] call CBA_fnc_waitAndExecute;

                        [_this select 1] call CBA_fnc_removePerFrameHandler;
                    };
                } forEach _list;
            },
            GC_Tick,
            [_u]
        ] call CBA_fnc_addPerFrameHandler;
    },
    [_u]
] call CBA_fnc_waitUntilAndExecute;
