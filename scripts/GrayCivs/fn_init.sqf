/* 
 *	Author: [SGC] Xephros, [DMCL] _keystone
 *	Init file
 *
 *	Arguments:
 *
 *	Return Value: None
 *
 *	
 */
if !(isServer) exitWith {};
private _zenCheck = isClass(configFile >> "CfgPatches" >> "zen_main");
private _aceCheck = isClass(configFile >> "CfgPatches" >> "ace_main");
private _cbaCheck = isClass(configFile >> "CfgPatches" >> "cba_main");
if !(_zenCheck || _aceCheck || _cbaCheck) exitWith {diag_log format ["[GrayCivs] Failed to initialize GrayCivs, dependencies not loaded. ZEN: %1, ACE: %2, CBA_A3: %3",_zenCheck,_aceCheck,_cbaCheck]};

//General Params
GC_Fac = east;                                                                  //Gray Civilian spots for this faction

//Shooter Params
GC_Tick = 3;                                                                    //PFH Tick rate.
GC_drawTime = [0,30];                                                           //[Min,Max] Time in Seconds for GrayCiv to draw weapon.
GC_Act = 100;                                                                   //Activation range to switch sides.
GC_Range = 20;                                                                  //Visibility range check to draw weapon.
GC_wpnTimeout = 180;                                                            //Cancel weapon search if exceeds timeout.
GC_grabChance = 0.3;                                                            //Chance for civilian to grab nearby weapon instead of drawing concealed.
GC_Weapons = [                                                                  //Weapons to conceal carry [Weapon String, Magazine Count].
    ["hgun_Rook40_F",3],
    ["hgun_Pistol_heavy_02_F",3],
    ["hgun_ACPC2_F",3]
];

//Spotter Params
GC_SpotCheck = 15;                                                              //PFH Tick rate.
GC_Optic = "Binocular";                                                         //Binocular equipment used to spot targets.
GC_RadioItem = "Item_ItemRadio";                                                //Radio equipment in inventory to report targets.
GC_RadioModel = ["Land_PortableLongRangeRadio_F", [[0,-0.4,1],[0,1,0.4]]];      //Visual radio model and setVectorDirAndUp arrays.
GC_RadioChance = 0.7;                                                           //Chance to report with radio.
GC_RadioTime = [20,30];                                                         //[Min,Max] Seconds spotter has radio visible.
GC_SpotRange = [300,700];                                                       //[Min, Max] Spot distance.
GC_SpotTime = [35,60];                                                          //[Min,Max] Time in seconds per interval to spot when binoculars are used.
GC_SpotCooldown = [20,60];                                                      //[Min,Max] Time in seconds before next spot.
GC_MinRange = [30,70];
    /* GC_MinRange prevents spotter from using binoculars when enemy is too close. <NUMBER>
     *	0: Will not spot if enemy is within range.
     *	1: Will not spot if enemy is within range and has line of sight.
     */
GC_MaxAttempts = 100;                                                           //Maximum iterations to search for spotting position.
GC_AlertRange = 200;                                                            //If spots target, will alert a random group within this radius.
GC_Alert = 3;                                                                   //If spotted targets are above knowsAbout GC_Alert, then report targets to random group within GC_AlertRange.

["Gray Civilians", "Assign as GC", 
    {
        private _u = _this select 1;
        [
            "Chance to Conceal Carry",
            [
                ["SLIDER:PERCENT",
                "Chance",
                [0,1,0.5,2],
                false]
            ],
            {
                private _u = _this select 1 select 0;
                private _chance = _this select 0 select 0;
                if (isNull _u || (side _u != civilian) || !(_u isKindOf "CAManBase")) exitWith {["Invalid unit selected.", nil] call zen_common_fnc_showMessage};
                [_u,(1 - _chance)] call XK_GC_fnc_shooter;
            },
            {},
            [_u]
        ] call zen_dialog_fnc_create;
    }
] call zen_custom_modules_fnc_register;

["Gray Civilians", "Assign GC in Area",
    {
        private _r = [_this select 0 select 0, _this select 0 select 1, 0];
        [
            "Assign GC in Area",
            [
                ["SIDES",
                "Side for GC to fight for",
                east,
                false],
                ["SLIDER:PERCENT",
                "Chance to assign as GC",
                [0,1,0.5,2],
                false],
                ["SLIDER:PERCENT",
                ["Chance to conceal carry","GCs will search for nearby weapons if not conceal carrying"],
                [0,1,0.5,2],
                false],
                ["SLIDER:RADIUS",
                "Radius",
                [5,300,80,0,_r,[1,1,1,1]],
                false]
            ],
            {
                _this select 0 params ["_fac","_GCchance","_chance","_radius"];
                if (_fac == civilian) exitWith {["Invalid GC faction, must select West, East, or Indep."] call zen_common_fnc_showMessage};
                _this select 1 params ["_pos"];
                private _nearCivs = ((_pos nearEntities ["CAManBase",_radius]) select {side _x == civilian}) select {!(_x getVariable ["GC_isGC", false])} select {alive _x && !(_x getVariable ["ace_captives_isHandcuffed", false])};
                if (count _nearCivs == 0) exitWith {["No nearby civilians suitable to assign as GC."] call zen_common_fnc_showMessage};
                {
                    if (random 1 <= _GCchance) then {[_x, (1 - _chance), _fac] call XK_GC_fnc_shooter};
                }forEach _nearCivs;
                ["Assigned GCs to area."] call zen_common_fnc_showMessage;
            },
            {},
            [_r]
        ] call zen_dialog_fnc_create;
    }
] call zen_custom_modules_fnc_register;

diag_log format ["[GrayCivs] Gray Civilian has been initialized with these settings: Tick Rate: %1 | Draw Time: %2 | Activation Range: %3 | Visibility Range: %4 | Weapon Timeout: %5 | Grab Chance: %6", GC_Tick, GC_DrawTime, GC_Act, GC_Range, GC_wpnTimeout, GC_grabChance];