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

_this params ["_u"];
diag_log format ["[GreyCivs] Grey Civilian (Spotter) has been initalized on %1.", name _u];

GC_Tick = 3;                //PFH Tick rate
GC_DrawTime = [0,30];       //[Min,Max] Time in Seconds for GreyCiv to draw weapon.
GC_Act = 100;               //Activation range to switch sides.
GC_Range = 20;              //Visibility range check to draw weapon.
GC_bluSide = west;          //BLUFOR
GC_opSide = east;           //OPFOR

GC_SpotRange = 500;
GC_SpotTime = [20,40];
GC_MinRange = 20;


[
    {
        _args params ["_u"];

        if !(alive _u) exitWith {
            [_this select 1] call CBA_fnc_removePerFrameHandler;
            diag_log format ["%1 %2 has died. Removing PFH.",name _u, getPosATL _u];
        };

        //Checks if Binos are used
        private _isSpotting = _u getVariable ["GC_Spotting",false];
        if (_isSpotting) exitWith {};

        //List of nearby targets
        private _list = [];
        private _listOld = _u getVariable ["GC_List", []];
        _list = (_u nearEntities [["CAMan","AllVehicles"], GC_SpotRange]) select {(_x != _u) && (side _x == GC_bluSide)};
        if (count _list == 0) exitWith {
            /* _u disableAI "PATH";
            //Add checker for bino in inventory
            _u addWeapon "Binocular";
            _u selectWeapon "Binocular";
            
            //Scans area
            private _spotTime = GC_SpotTime call BIS_fnc_randomInt;
            _u setVariable ["GC_Spotting",true];
            _u lookAt (_u getRelPos [([round (GC_SpotRange * 0.3),GC_SpotRange] call BIS_fnc_randomInt), random 360]);
            _u setUnitPos (selectRandom ["DOWN","UP","MIDDLE","AUTO"]);
            [
                {
                    params ["_u"];
                    if (alive _u) then {
                        //Add bino to inv
                        _u removeWeapon binocular _u;
                    };
                    [
                        {
                            params ["_u"];
                            _u setVariable ["GC_Spotting",false];
                            _u enableAI "PATH";
                            _u setUnitPos "AUTO";
                        },
                        [_u],
                        random 10
                    ] call CBA_fnc_waitAndExecute;
                },
                [_u],
                _spotTime
            ] call CBA_fnc_waitAndExecute; */
        };

        if (_list isNotEqualTo _listOld) then {
            _u setVariable ["GC_List", _list];
            diag_log format ["[GreyCivs] %1 units are in range of %2 %3. %4",count _list, name _u, getPosATL _u, _list];
        };

        private _listSort = [_list, [], {_x distance getPosATL _u}, "ASCEND"] call BIS_fnc_sortBy;
        if ((_listSort select 0) distance _u <= GC_MinRange) exitWith {};

        _u disableAI "PATH";
        //Add checker for bino in inventory
        _u addWeapon "Binocular";
        _u selectWeapon "Binocular";
        
        //Scans area
        
        _u setVariable ["GC_Spotting",true];
        //private _uPos = selectRandom ["DOWN","UP","MIDDLE","AUTO"];
        private _uPos = selectRandom ["UP","MIDDLE","AUTO"];
        _u setUnitPos _uPos;
        //Get random pos to look at
        private _minSpotRange = GC_SpotRange  * 0.4;
        private _scanPos = [];
        private _attempts = 0;
        private _result = [];
        _u setVariable ["GC_SpotReady", false];

        diag_log format ["[GreyCivs] %1 %2 is starting scan.", name _u, getPosATL _u];
        while {count _scanPos <= 5} do {
            if (count _scanPos == 5) exitWith {
                diag_log format ["[GreyCivs] %1 %2 has 5 positions, ready to spot.", name _u, getPosATL _u];
                _u setVariable ["GC_SpotReady", true];
                _u setVariable ["GC_ScanPos", _scanPos];
                _scanPos = [];
                _attempt = 0;
            };
            //diag_log format ["[GreyCivs] %1 %2 is attempting scan #%3.", name _u, getPosATL _u,_attempts];
            //if (primaryWeapon _u != "Binocular") exitWith {diag_log format ["[GreyCivs] %1 %2 cancelled scan due to removed Binoculars.", name _u, getPosATL _u]};
            if !(alive _u) exitWith {diag_log format ["[GreyCivs] %1 %2 has died, cancelling scan.", name _u, getPosATL _u]};

            private _checkPos = [getPosATL _u, _minSpotRange, GC_SpotRange,0,0,0,0,[],[getPosATL _u]] call BIS_Fnc_findSafePos;
            private _dist = _checkPos distance (getPosATL _u);
            if (_dist >= _minSpotRange) then {
                private _terrainBlocked = terrainIntersect [getPosATL _u, _checkPos];
                private _newPos = _u getRelPos [30, _u getRelDir _checkPos];
                private _visBlocked = [objNull, "VIEW"] checkVisibility [eyePos _u, [_newPos select 0, _newPos select 1, (eyePos _u) select 2]];
                if !(_terrainBlocked && _visBlocked < 0.8) then {
                    if (count _scanPos == 0) exitWith {
                        _scanPos pushBackUnique _checkPos;
                        diag_log format ["[GreyCivs] %1 %2 has added %3 to scan positions (%4). Visibility: %5. Dir: %6.", name _u, getPosATL _u, _checkPos, count _scanPos, _visBlocked, _u getDir _checkPos];
                    };
                    
                    {
                        if ((_checkPos distance _x > 10) && !(_visBlocked < 0.8)) exitWith {
                            _scanPos pushBackUnique _checkPos;
                            diag_log format ["[GreyCivs] %1 %2 has added %3 to scan positions (%4). Visibility: %5. Dir: %6.", name _u, getPosATL _u, _checkPos, count _scanPos, _visBlocked, _u getDir _checkPos];
                        };
                    } forEach _scanPos;
                    
                };
                //diag_log format ["[GreyCivs] %1 %2 is attempted scan #%3. Visibility: %4", name _u, getPosATL _u,_attempts, _visBlocked];
            };

            //Failsafe
            if (_attempts > 100) exitWith {
                diag_log format ["[GreyCivs] %1 %2 has exceeded maximum attempts to find suitable spot location. Exiting scan loop.", name _u, getPosATL _u];
                _result = _u getRelPos [([round (GC_SpotRange * 0.4),GC_SpotRange] call BIS_fnc_randomInt), random 360];
                _scanPos pushBackUnique _result;
                _u setVariable ["GC_SpotReady", true];
                _u setVariable ["GC_ScanPos", _scanPos];
                _scanPos = [];
                _attempts = 0;
            };
            _attempts = _attempts + 1;
        };

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
                diag_log format ["[GreyCivs] %1 %2 spotting towards %3", name _u, getPosATL _u, _u getDir _lookAtPos];
                private _spotTime = GC_SpotTime call BIS_fnc_randomInt;
                private _radio = "Land_PortableLongRangeRadio_F" createVehicle getPosATL _u;
                
                if (random 1 <= 0.7) then {
                    _radio attachTo [_u, [-0.1,0.07,0.15], "Spine3", true];
                    _radio setVectorDirAndUp [[0,-0.4,1],[0,1,0.4]];
                    [
                        {
                            params ["_radio"];
                            deleteVehicle _radio;
                        },
                        [_radio],
                        [10,20] call BIS_fnc_randomInt
                    ] call CBA_fnc_waitAndExecute;
                };
                [
                    {
                        params ["_u"];
                        if (alive _u) then {
                            //Add bino to inv
                            _u removeWeapon binocular _u;
                        };
                        [
                            {
                                params ["_u"];
                                _u setVariable ["GC_Spotting",false];
                                _u enableAI "PATH";
                                _u setUnitPos "AUTO";
                            },
                            [_u],
                            [20,60] call BIS_fnc_randomInt
                        ] call CBA_fnc_waitAndExecute;
                    },
                    [_u],
                    _spotTime
                ] call CBA_fnc_waitAndExecute;
            },
            [_u,_scanPos]
        ] call CBA_fnc_waitUntilAndExecute;
    },
    GC_Tick*5,
    [_u]
] call CBA_fnc_addPerFrameHandler;