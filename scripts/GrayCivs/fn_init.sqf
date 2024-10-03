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

//Push to new function file

//General Params
GC_Fac = east;                                                                  //Gray Civilian spots for this faction

//Shooter Params
GC_Tick = 3;                                                                    //PFH Tick rate.
GC_drawTime = [0,30];                                                           //[Min,Max] Time in Seconds for GrayCiv to draw weapon.
GC_Act = 100;                                                                   //Activation range to switch sides.
GC_Range = 20;                                                                  //Visibility range check to draw weapon.
GC_wpnTimeout = 180;                                                            //Cancel weapon search if exceeds timeout.
GC_grabChance = 0.7;                                                            //Chance for civilian to grab nearby weapon instead of drawing concealed.
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

diag_log format ["[GrayCivs] Gray Civilian has been initialized with these settings: Tick Rate: %1 | Draw Time: %2 | Activation Range: %3 | Visibility Range: %4 | Weapon Timeout: %5 | Grab Chance: %6", GC_Tick, GC_DrawTime, GC_Act, GC_Range, GC_wpnTimeout, GC_grabChance];