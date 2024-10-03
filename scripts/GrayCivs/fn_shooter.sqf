/* 
 *	Author: [SGC] Xephros, [DMCL] _keystone
 *	Init file
 *
 *	Arguments:
 *
 *	Return Value: None
 *
 *	Examples:
 *      [man1, east, 100, 3] call XK_GC_fnc_shooter;
 */

//Push to new function file
_this params ["_u",["_fac", GC_Fac],["_range",GC_Act],["_tick",GC_Tick]];

//Faction failsafe
if ((side _u != civilian) && (_u isKindOf "CAManBase")) exitWith {diag_log format ["[GrayCivs] WARNING: %1 %2 is not a civilian. Exiting script.", name _u, getPosATL _u]};
if (_fac == civilian) then {
    _fac = east;
    diag_log format ["[GrayCivs] %1 %2 cannot be spotting for civilian faction. Defaulting to east."];
};

private _isGC = _u getVariable ["GC_isGC", false];
if !(_isGC) exitWith {};
_u setVariable ["GC_isGC", true];
diag_log format ["[GrayCivs] Grey Civilian (Shooter) has been initalized on %1.", name _u];
[_u] joinSilent grpNull;

//Activates search when BLUFOR is in range
[
    {
        params ["_u","_fac","_range"];
        count ((_u nearEntities [["CAMan","AllVehicles"], _range]) select {(_x != _u) && (isPlayer _x) && ([side _x, _fac] call BIS_fnc_sideIsEnemy)}) != 0;
    },
    {
        params ["_u","_fac","_range","_tick"];
        diag_log format ["[GrayCivs] %1 %2 is now searching for targets. Starting PFH.",name _u, getPosATL _u];
        diag_log format ["[GrayCivs] Faction: %1, Range: %2", _fac, _range];
        private _grp = createGroup _fac;
        
        [_u] joinSilent _grp;
        _u setCaptive true;
        //_u setBehaviour "CARELESS";
        [
            {
                _args params ["_u"];

                //Ends PFH if dead
                if !(alive _u) exitWith {
                    diag_log format ["[GrayCivs] %1 %2 has died. Exiting PFH.",name _u, getPosATL _u];
                    [_this select 1] call CBA_fnc_removePerFrameHandler
                };
                
                //Line of Sight checker to become hostile
                {
                    
                    private _canSee = [objNull, "VIEW"] checkVisibility [eyePos _u, eyePos _x];
                    private _isHostile = _u getVariable ["GC_isHostile",false];
                    if (_isHostile) exitWith {};
                    if (_canSee > 0.5) then {
                        _u setVariable ["GC_isHostile", true];
                        _u setCaptive false;
                        diag_log format ["[GrayCivs] %1 %2 has visibility on %3", name _u, getPosATL _u, name _x];
                    };

                    //Checks if unit has become hostile
                    private _isHostile = _u getVariable ["GC_isHostile",false];
                    if (_isHostile) exitWith {
                        [_this select 1] call CBA_fnc_removePerFrameHandler;

                        //Decides whether unit is drawing or grabbing gun
                        private _timer = GC_drawTime call BIS_fnc_randomInt;
                        if (random 1 > GC_grabChance) then {
                            //Draws concealed weapon
                            [_u, _timer] call XK_GC_fnc_drawWeap;
                        } else {
                            //Search for nearby weapon
                            [_u, _timer] call XK_GC_fnc_searchWeap;
                        };
                    };
                } forEach ([_u] call XK_GC_fnc_getList);
            },
            _tick,
            [_u]
        ] call CBA_fnc_addPerFrameHandler;
    },
    [_u,_fac,_range,_tick]
] call CBA_fnc_waitUntilAndExecute;