/* 
 *	Author: [SGC] Xephros, [DMCL] _keystone
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
diag_log format ["[GrayCivs] Grey Civilian has been initalized on %1.", name _u];


GC_Tick = 3;                //PFH Tick rate
GC_DrawTime = [0,30];       //[Min,Max] Time in Seconds for GreyCiv to draw weapon.
GC_Act = 100;               //Activation range to switch sides.
GC_Range = 20;              //Visibility range check to draw weapon.
GC_bluSide = west;          //BLUFOR
GC_opSide = east;           //OPFOR
GC_wpnTimeout = 180;        //Cancel weapon search if exceeds timeout
GC_grabChance = 0.5;        //Chance for shooter to grab nearby weapon instead of drawing concealed.

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
        diag_log format ["[GrayCivs] %1 %2 is now searching for targets. Starting PFH.",name _u, getPosATL _u];
        private _grp = createGroup GC_opSide;
        (units group _u) joinSilent _grp;
        _u setCaptive true;
        _u setBehaviour "CARELESS";
        [
            {
                _args params ["_u"];

                //Ends PFH if dead
                if !(alive _u) exitWith {
                    diag_log format ["[GrayCivs] %1 %2 has died. Exiting PFH.",name _u, getPosATL _u];
                    [_this select 1] call CBA_fnc_removePerFrameHandler
                };

                //List of nearby targets
                private _list = [];
                private _listOld = _u getVariable ["GC_List", []];
                _list = (_u nearEntities [["CAManBase","AllVehicles"], GC_Range]) select {(_x != _u) && (side _x == GC_bluSide)};
                if (count _list == 0) exitWith {};
                if (_list isNotEqualTo _listOld) then {
                    _u setVariable ["GC_List", _list];
                    diag_log format ["[GrayCivs] %1 units are in range of %2 %3. %4",count _list, name _u, getPosATL _u, _list];
                };
                

                {
                    //Line of Sight checker to become hostile
                    private _canSee = [objNull, "VIEW"] checkVisibility [eyePos _u, eyePos _x];
                    /* diag_log format ["Visibility to %1: %2", name _x, _canSee]; */
                    if (_canSee > 0.5) then {
                        _u setVariable ["GC_isHostile", true];
                        _u setCaptive false;
                        diag_log format ["[GrayCivs] %1 %2 has visibility on %3", name _u, getPosATL _u, name _x];
                    };
                    private _isHostile = _u getVariable ["GC_isHostile",false];
                    if !(_isHostile) exitWith {};

                    [_this select 1] call CBA_fnc_removePerFrameHandler;

                    //Handles weapon & ammo spawn after draw time ends or gets cuffed
                    if (random 1 < GC_grabChance) then {
                        private _timer = GC_DrawTime call BIS_fnc_randomInt;
                        (selectRandom GC_Weapons) params ["_weap","_mags"];
                        diag_log format ["[GrayCivs] %1 %2 is drawing weapon in %3 seconds. Exiting PFH.", name _u, getPosATL _u, _timer];
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
                        
                    } else {
                        
                        private _timer = GC_DrawTime call BIS_fnc_randomInt;
                        _timer = 1;
                        diag_log format ["[GrayCivs] %1 %2 will search for a nearby weapon in %3 seconds. Exiting PFH.", name _u, getPosATL _u, _timer];
                        [
                            {
                                params ["_u"];
                                private _wpns = (nearestObjects [_u, ["WeaponHolder", "WeaponHolderSimulated"], 30]) select {!(isPlayer (attachedTo _x))};
                                private _wpnsNotTaken = _wpns select {(_x getVariable ["GC_wpnTaken", false]) == false};
                                if (count _wpns == 0 || count _wpnsNotTaken == 0) exitWith {diag_log format ["[GrayCivs] %1 %2 has no nearby guns to grab.", name _u, getPosATL _u]};
                                private _randomGun = selectRandom _wpnsNotTaken;
                                _randomGun setVariable ["GC_wpnTaken", true];
                                if (isNull _randomGun) exitWith {diag_log format ["[GrayCivs] %1 %2 weapon seach cancelled. Gun no longer exists.", name _u, getPosATL _u]};
                                diag_log format ["[GrayCivs] %1 %2 is trying to grab %3 %4.", name _u, getPosATL _u, ((weaponCargo _randomGun) select 0), getPosATL _randomGun];
                                [group _u] call CBA_fnc_clearWaypoints;
                                [group _u, getPosATL _randomGun, 0, "MOVE", "CARELESS", "YELLOW", "FULL", "STAG COLUMN"] call CBA_fnc_addWaypoint;
                                private _visPos = [];
                                if (_randomGun isKindOf "WeaponHolderSimulated") then {
                                    _visPos = [(getPosASL (getCorpse _randomGun)) select 0, (getPosASL (getCorpse _randomGun)) select 1, ((getPosASL (getCorpse _randomGun)) select 2) + 0.7];
                                } else {
                                    _visPos = [(getPosASL _randomGun) select 0, (getPosASL _randomGun) select 1, ((getPosASL _randomGun) select 2) + 0.7];
                                };

                                [
                                    {
                                        params ["_u", "_randomGun","_visPos"];
                                        private _canSeeGun = [objNull, "VIEW"] checkVisibility [eyePos _u, _visPos];
                                        //drawIcon3D ["\A3\ui_f\data\map\markers\military\circle_CA.paa", [1,1,0,1], ASLtoAGL _visPos, 0.3, 0.3, 45, "Here", 0, 0.03, "TahomaB","center",true,0,0.003];
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
                                        deleteVehicle _randomGun;
                                        [group _u] call CBA_fnc_clearWaypoints;
                                    },
                                    [_u, _randomGun,_visPos]
                                ] call CBA_fnc_waitUntilAndExecute;

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
                                    GC_wpnTimeout
                                ] call CBA_fnc_waitAndExecute;
                            },
                            [_u],
                            _timer
                        ] call CBA_fnc_waitAndExecute;
                    };
                } forEach _list;
            },
            GC_Tick,
            [_u]
        ] call CBA_fnc_addPerFrameHandler;
    },
    [_u]
] call CBA_fnc_waitUntilAndExecute;
