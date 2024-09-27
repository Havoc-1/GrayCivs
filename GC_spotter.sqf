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
GC_SpotTime = [10,30];
GC_MinRange = 30;


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
            _u disableAI "PATH";
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
            ] call CBA_fnc_waitAndExecute;
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
        private _spotTime = GC_SpotTime call BIS_fnc_randomInt;
        _u setVariable ["GC_Spotting",true];
        //_u lookAt (_u getRelPos [([round (GC_SpotRange * 0.3),GC_SpotRange] call BIS_fnc_randomInt), random 360]);

        private _lookAtPos = (_u getRelPos [([round (GC_SpotRange * 0.3),GC_SpotRange] call BIS_fnc_randomInt), ((_u getRelDir (selectRandom _list)) + selectRandom [45,30,15,0,(-15),(-30),(-45)])]);
        _u lookAt _lookAtPos;
        diag_log format ["[GreyCivs] %1 %2 spotting towards %3", name _u, getPosATL _u, _u getDir _lookAtPos];
        
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
                    [20,60] call BIS_fnc_randomInt
                ] call CBA_fnc_waitAndExecute;
            },
            [_u],
            _spotTime
        ] call CBA_fnc_waitAndExecute;

    },
    GC_Tick*5,
    [_u]
] call CBA_fnc_addPerFrameHandler;