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
diag_log format ["[GreyCivs] Grey Civilian has been initalized on %1.",name _u];

private _time = 3;          //PFH Tick rate
private _s = [0,10];        //[Min,Max] Time in Seconds for GreyCiv to draw weapon.
private _act = 100;         //Activation range to switch sides.
private _r = 20;            //Visibility range check to draw weapon.
GC_bluSide = west;          //BLUFOR
GC_opSide = east;           //OPFOR


HostileWeapons = ["sgun_HunterShotgun_01_sawedoff_F","hgun_Pistol_01_F","hgun_ACPC2_F","hgun_Rook40_F"];

[
    {
        params ["_u","_r","_s","_time","_act"];
        count ((_u nearEntities [["CAMan","AllVehicles"],_act]) select {(_x != _u) && (isPlayer _x) && (side _x == GC_bluSide)}) != 0;
    },
    {
        params ["_u","_r","_s","_time"];
        diag_log format ["[GreyCivs] %1 (%2) is now searching for targets. Starting PFH.",name _u, getPosATL _u];
        private _grp = createGroup GC_opSide;
        (units group _u) joinSilent _grp;
        _u setCaptive true;
        [
            {
                _args params ["_u","_r","_s"];
                if !(alive _u) exitWith {
                    diag_log format ["[GreyCivs] %1 (%2) has died. Exiting PFH.",name _u, getPosATL _u];
                    [_this select 1] call CBA_fnc_removePerFrameHandler
                };

                private _list = [];
                private _listOld = _u getVariable ["GC_List", []];
                _list = (_u nearEntities [["CAMan","AllVehicles"],_r]) select {(_x != _u) && (side _x == GC_bluSide)};
                if (count _list == 0) exitWith {};

                if (_list isNotEqualTo _listOld) then {
                    _u setVariable ["GC_List", _list];
                    diag_log format ["[GreyCivs] %1 units are in range of %2 (%3). %4",count _list, name _u, getPosATL _u, _list];
                };

                {
                    private _isHostile = _u getVariable ["GC_isHostile",false];
                    private _canSee = [objNull, "VIEW"] checkVisibility [eyePos _u, eyePos _x];
                    /* diag_log format ["Visibility to %1: %2", name _x, _canSee]; */
                    if (_canSee > 0.5) then {
                        _u setVariable ["GC_isHostile", true];
                        _u setCaptive false;
                        diag_log format ["[GreyCivs] %1 (%2) has visibility on %3", name _u, getPosATL _u, name _x];
                    };
                    if (_isHostile) exitWith {
                        
                        private _timer = _s call BIS_fnc_randomInt;
                        private _selectedWeapon = 
                        selectRandom HostileWeapons;
                        
                        
                        diag_log format ["[GreyCivs] %1 (%2) is drawing %3 in %4 seconds. Exiting PFH.",_u, getPosATL _u, _selectedWeapon, _timer];

                        //Weapon has been added to inventory 
                        _u addItemToUniform _selectedWeapon;
                        //syntax error here
                        _compatMagazines = (compatibleMagazines _selectedWeapon) select 0;
                        _u addMagazines [_compatMagazines, 2];

                        diag_log format ["[GreyCivs] %1 has been added with %2",_selectedWeapon, _compatMagazines];

                        //Add failsafe if players restrain and check inv
                        [
                            {
                                params ["_u"];
                                if (_u getVariable ["ace_captives_isHandcuffed", false]) exitWith {diag_log format ["[GreyCivs] %1 (%2) is restrained, cannot draw weapon.",_u, getPosATL _u]};
                                _u removeItemFromUniform _selectedWeapon;
                                //_u addMagazines ["16Rnd_9x21_Mag", 2];
                                //_u addWeapon "hgun_Rook40_F";
                                _u addWeapon _selectedWeapon;

                                _u setBehaviour "COMBAT";
                                [group _u, getPosATL (_u findNearestEnemy _u), 100] call CBA_fnc_taskAttack;
                                diag_log format ["[GreyCivs] Weapon has been added to %1 (%2)",name _u, getPosATL _u];
                                
                            },
                            [_u, _selectedWeapon],
                            _timer
                        ] call CBA_fnc_waitAndExecute;

                        [_this select 1] call CBA_fnc_removePerFrameHandler;
                    };

                } forEach _list;
            },
            _time,
            [_u,_r,_s]
        ] call CBA_fnc_addPerFrameHandler;
    },
    [_u,_r,_s,_time,_act]
] call CBA_fnc_waitUntilAndExecute;
