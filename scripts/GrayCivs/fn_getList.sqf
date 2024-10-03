/* 
 *	Author: [SGC] Xephros, [DMCL] _keystone
 *	Function to get a list of nearby enemy units.
 *
 *	Arguments:
 *      0: Unit <OBJECT> - Unit getting the list, center of search range.
 *      1: Range <NUMBER> - Radius of search range.
 *      2: Unit Side <SIDE> - Faction of unit getting the list.
 *
 *	Return Value:
 *      Nearby enemy units <ARRAY>
 */

params ["_u",["_range",GC_Range],["_sideFac",GC_Fac]];

private _getList = [];
private _listOld = _u getVariable ["GC_List", []];
_getList = (_u nearEntities [["CAManBase","AllVehicles"], _range]) select {(_x != _u) && ([side _x, _sideFac] call BIS_fnc_sideIsEnemy)};
if (count _getList == 0) exitWith {};
if (_getList isNotEqualTo _listOld) then {
    _u setVariable ["GC_List", _getList];
    diag_log format ["[GrayCivs] %1 units are in range of %2 %3. %4",count _getList, name _u, getPosATL _u, _getList];
};

//Return Value
_getList;