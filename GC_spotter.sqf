/* 
 *	Author: [SGC] Xephros
 *	Function to initialize Grey Civilian Spotter on unit.
 *
 *	Arguments:
 *      0: Unit <OBJECT> - Civilian to turn into grey civ spotter. 
 *
 *	Return Value: None
 *
 *	Example:
 *		[this] execVM "GC_spotter.sqf";
 */

//Add variable for civilian vs enemy spotter

_this params ["_u"];
diag_log format ["[GreyCivs] Grey Civilian (Spotter) has been initalized on %1 %2.", name _u, getPosATL _u];

GC_Fac = east;                      //Faction of spotter
GC_SpotCheck = 15;                  //PFH Tick rate
GC_Optic = "Binocular";             //Binocular equipment used to spot targets.
GC_RadioItem = "Item_ItemRadio";    //Radio equipment in inventory to report targets.
GC_RadioChance = 0.7;               //Chance to report with radio
GC_RadioTime = [10,20];             //[Min,Max] Seconds spotter has radio visible
GC_SpotRange = [300,700];           //[Min, Max] Spot distance
GC_SpotTime = [30,60];              //[Min,Max] Time in seconds per interval to spot when binoculars are used
GC_SpotCooldown = [20,60];          //[Min,Max] Time in seconds before next spot
GC_MinRange = [30,70];
    /* GC_MinRange prevents spotter from using binoculars when BLUFOR is too close. <NUMBER>
     *	0: Will not spot if enemy is within range.
     *	1: Will not spot if enemy is within range and has line of sight.
     */


//Adds bino & radio to inventory
if !((GC_Optic in (items _u)) && ((binocular _u) != GC_Optic)) then {
    _u addItem GC_Optic;
    diag_log format ["[GreyCivs] %1 %2 has been given %3.", name _u, getPosATL _u, GC_Optic];
};
if !(GC_RadioItem in (items _u)) then {
    _u addItem GC_RadioItem;
    diag_log format ["[GreyCivs] %1 %2 has been given %3.", name _u, getPosATL _u, GC_RadioItem];
};

//Faction switch
private _grp = createGroup GC_Fac;
(units group _u) joinSilent _grp;
_u setCaptive true;

//Spotting PFH
[
    {
        _args params ["_u"];
        
        //Exits PFH if killed or incapped
        private _unCon = (_u getVariable ["ACE_isUnconscious", false]);
        if ((!alive _u) || _unCon) exitWith {
            [_this select 1] call CBA_fnc_removePerFrameHandler;
            diag_log format ["[GreyCivs] %1 %2 has been killed or incapacitated. Removing PFH.",name _u, getPosATL _u];
        };

        //Checks if Binos are used
        private _isSpotting = _u getVariable ["GC_Spotting",false];
        if (_isSpotting) exitWith {};

        //List of nearby targets
        private _list = [];
        private _listOld = _u getVariable ["GC_List", []];
        _list = (_u nearEntities [["CAMan","AllVehicles"], (GC_SpotRange select 1)]) select {(_x != _u) && (side _x != civilian) && !([side _x, GC_Fac] call BIS_fnc_sideIsFriendly)};
        if (count _list == 0) exitWith {};
        if (_list isNotEqualTo _listOld) then {
            _u setVariable ["GC_List", _list];
            diag_log format ["[GreyCivs] %1 units are in range of %2 %3. %4",count _list, name _u, getPosATL _u, _list];
        };

        //Cancel spot if units are too close or line of sight
        private _cancelSpot = false;
        private _listSort = [_list, [], {_x distance getPosATL _u}, "ASCEND"] call BIS_fnc_sortBy;
        if ((_listSort select 0) distance _u <= (GC_MinRange select 0)) exitWith {
            _cancelSpot = true;
            diag_log format ["[GreyCivs] Units within minimum distance of %1 %2. Cancelling spot.", name _u, getPosATL _u];
        };
        {
            if (([objNull, "VIEW"] checkVisibility [eyePos _u, eyePos _x]) > 0.5) exitWith {
                _cancelSpot = true;
                diag_log format ["[GreyCivs] Close units have line of sight to %1 %2. Cancelling spot.", name _u, getPosATL _u];
            };   
        } forEach _listSort select {_x distance _u <= (GC_MinRange select 1)};
        if (_cancelSpot) exitWith {};

        //Begin scanning area
        diag_log format ["[GreyCivs] %1 %2 is starting scan.", name _u, getPosATL _u];
        _u disableAI "PATH";
        _u addWeapon GC_Optic;
        _u removeItem GC_Optic;
        _u selectWeapon GC_Optic;
        _u setVariable ["GC_Spotting",true];
        //private _uPos = selectRandom ["DOWN","UP","MIDDLE","AUTO"];
        private _uPos = selectRandom ["UP","MIDDLE","AUTO"];
        _u setUnitPos _uPos;
        
        //Gathers positions to spot
        [
            {
                params ["_u"];
                private _spotRange = GC_SpotRange;
                private _scanPos = [];
                private _attempts = 0;
                private _result = [];
                _u setVariable ["GC_SpotReady", false];
                while {count _scanPos <= 5} do {
                    if (count _scanPos == 5) exitWith {
                        diag_log format ["[GreyCivs] %1 %2 has 5 positions, ready to spot.", name _u, getPosATL _u];
                        _u setVariable ["GC_SpotReady", true];
                        _u setVariable ["GC_ScanPos", _scanPos];
                        _scanPos = [];
                        _attempt = 0;
                    };
                    if !(alive _u) exitWith {diag_log format ["[GreyCivs] %1 %2 has died, cancelling scan.", name _u, getPosATL _u]};

                    private _checkPos = [getPosATL _u, (_spotRange select 0), (_spotRange select 1),0,0,0,0,[],[getPosATL _u]] call BIS_Fnc_findSafePos;
                    private _dist = _checkPos distance (getPosATL _u);
                    if (_dist >= (_spotRange select 0)) then {
                        private _terrainBlocked = terrainIntersect [getPosATL _u, _checkPos];
                        private _newPos = _u getRelPos [30, _u getRelDir _checkPos];
                        private _visBlocked = [objNull, "VIEW"] checkVisibility [eyePos _u, [_newPos select 0, _newPos select 1, (eyePos _u) select 2]];
                        if !(_terrainBlocked && (_visBlocked < 0.8)) then {
                            if (count _scanPos == 0) exitWith {
                                _scanPos pushBackUnique _checkPos;
                                diag_log format ["[GreyCivs] %1 %2 has added %3 to scan positions (%4). Dir: %6.", name _u, getPosATL _u, _checkPos, count _scanPos, _visBlocked, _u getDir _checkPos];
                            };
                            
                            {
                                if (_checkPos distance _x > 10) exitWith {
                                    _scanPos pushBackUnique _checkPos;
                                    diag_log format ["[GreyCivs] %1 %2 has added %3 to scan positions (%4). Dir: %6.", name _u, getPosATL _u, _checkPos, count _scanPos, _visBlocked, _u getDir _checkPos];
                                };
                            } forEach _scanPos;
                            
                        };
                        //diag_log format ["[GreyCivs] %1 %2 is attempted scan #%3. Visibility: %4", name _u, getPosATL _u,_attempts, _visBlocked];
                    };

                    //Failsafe
                    if (_attempts >= 100) exitWith {
                        diag_log format ["[GreyCivs] %1 %2 has exceeded maximum attempts (%3) to find suitable spot location. Exiting scan loop with random direction.", name _u, getPosATL _u, _attempts];
                        _result = _u getRelPos [(_spotRange call BIS_fnc_randomInt), random 360];
                        _scanPos pushBackUnique _result;
                        _u setVariable ["GC_SpotReady", true];
                        _u setVariable ["GC_ScanPos", _scanPos];
                        _scanPos = [];
                        _attempts = 0;
                    };
                    _attempts = _attempts + 1;
                };

                //Begin spotting
                [
                    {
                        params ["_u"];
                        _u getVariable "GC_SpotReady";
                    },
                    {
                        params ["_u"];
                        _u setVariable ["GC_SpotReady", nil];
                        private _scanPosNew = _u getVariable "GC_ScanPos";
                        private _lookAtPos = selectRandom _scanPosNew;
                        _scanPos = [];
                        _scanPosNew = [];
                        _u setVariable ["GC_ScanPos", nil];
                        _u lookAt _lookAtPos;
                        diag_log format ["[GreyCivs] %1 %2 spotting towards %3 at %4", name _u, getPosATL _u, _u getDir _lookAtPos, _lookAtPos];
                        private _spotTime = GC_SpotTime call BIS_fnc_randomInt;
                        if (_spotTime < 5) then {_spotTime = 5};
                        private _radio = "Land_PortableLongRangeRadio_F" createVehicle getPosATL _u;
                        
                        //Chance to use radio
                        if (random 1 <= GC_RadioChance) then {
                            _u setCaptive false;
                            _radio attachTo [_u, [-0.1,0.07,0.15], "Spine3", true];
                            _radio setVectorDirAndUp [[0,-0.4,1],[0,1,0.4]];
                            private _radioDelay = 1;

                            private _radioTime = GC_radioTime call BIS_fnc_randomInt;
                            if (_radioTime > _spotTime) then {
                                _radioDelay = floor (_spotTime * 0.2);
                            } else {
                                _radioDelay = floor (random (_spotTime - _radioTime));
                                if (_radioDelay < 1) then {_radioDelay = 1};
                            };
                            //diag_log format ["[GreyCivs] %1 %2 radioTime: %3, spotTime: %4, radioDelay: %5", name _u, getPosATL _u, _radioTime, _spotTime, _radioDelay];
                            [
                                {
                                    params ["_radio","_u"];
                                    deleteVehicle _radio;
                                    //_u setCaptive true;
                                },
                                [_radio,_u],
                                _radioDelay
                            ] call CBA_fnc_waitAndExecute;
                        };
                        
                        //Hides radio
                        [
                            {
                                params ["_u"];
                                if (alive _u || !(_u getVariable ["ACE_isUnconscious", false])) then {
                                    _u removeWeapon binocular _u;
                                    _u addItem GC_Optic;
                                };

                                //Delay between next spot
                                [
                                    {
                                        params ["_u"];
                                        _u setVariable ["GC_Spotting",false];
                                        _u enableAI "PATH";
                                        _u setUnitPos "AUTO";
                                    },
                                    [_u],
                                    GC_spotCooldown call BIS_fnc_randomInt
                                ] call CBA_fnc_waitAndExecute;
                            },
                            [_u],
                            _spotTime
                        ] call CBA_fnc_waitAndExecute;
                    },
                    [_u]
                ] call CBA_fnc_waitUntilAndExecute;
            },
            [_u],
            3
        ] call CBA_fnc_waitAndExecute;
    },
    GC_SpotCheck,
    [_u]
] call CBA_fnc_addPerFrameHandler;