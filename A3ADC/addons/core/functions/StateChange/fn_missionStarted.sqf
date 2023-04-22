/*
Function:
    DCI_fnc_missionStarted
Description:
    Sets state to playing mission
Scope:
    private
Environment:
    client
Returns:
    nothing
Examples:
    [] call DCI_fnc_missionStarted;
Author: martin
*/
#include "../../script_component.hpp"
FIX_LINE_NUMBERS()
diag_log "DCRP state changed to in mission";

private _enableAssists = false;
private _command = "missionstart";

[] call DCI_fnc_initVars;
private _productVersionArray = productVersion;
if (_productVersionArray # 6 != "Windows") then {
    A3A_DCRP_deactivated = true;
    diag_log  "DCPR no windows detected";
};
if (isDedicated || !hasInterface) then {
    A3A_DCRP_deactivated = true;
    diag_log "DCPR dedicated or no display detected";
};

if (A3A_DCRP_deactivated) exitWith {
	diag_log "DCPR deactiavted";
};

if (
    (!isNil "ace_common_fnc_isModLoaded") && 
    isClass (configFile >> "CfgSounds" >> "ACE_heartbeat_fast_3")
) then {
    A3A_DCRP_detectAce = true;
};

if (["intro", briefingName] call BIS_fnc_inString) exitWith {
	diag_log  "DCRP no role description detected should be game main menu";
	private _result = "dcpr" callExtension "menu";
};

[] spawn {

    waitUntil{sleep 0.5; !(isNil "BIS_fnc_init") && time > 0 && local player};

    private _roleDescription = roleDescription player;
    private _typeName = [configFile >> "CfgVehicles" >> typeOf player] call BIS_fnc_displayName;
    private _slotNumber = playableSlotsNumber independent + playableSlotsNumber west + playableSlotsNumber east;
    private _playerCount = playersNumber independent + playersNumber west + playersNumber east;

    if (_roleDescription == "") then {
        _roleDescription = _typeName;
    };

    private _result = "dcpr" callExtension ["missionstart", [serverName,1, briefingName, _roleDescription, _slotNumber, _playerCount]];

    addMissionEventHandler ["EntityKilled", {
        params ["_killed", "_killer", "_instigator"];
        private _stats = getPlayerScores player;
        private _kills = _stats # 0 + _stats # 1 + _stats # 2 + _stats # 3;
        if (isNull _instigator) then { _instigator = UAVControl vehicle _killer select 0 }; // UAV/UGV player operated road kill
	    if (isNull _instigator) then { _instigator = _killer }; // player driven vehicle road kill
        if (_killed != player) then {
            if (_instigator == player) then {
                _kills = _kills + 1; //current kill happening not counted yet
            }
        };
        if (_killed == player) then  {
            "dcpr" callExtension "died";
        };
        private _death = _stats # 4;
        "dcpr" callExtension ["updateScore", [_kills , _death]];
    }];

    player addEventHandler ["Respawn", {
	    params ["_unit", "_corpse"];
        private _stats = getPlayerScores player;
        private _kills = _stats # 0 + _stats # 1 + _stats # 2 + _stats # 3;
        private _death = _stats # 4;
        "dcpr" callExtension "respawn";
        "dcpr" callExtension "wakeup";
        "dcpr" callExtension ["updateScore", [_kills , _death]];
    }];    

    if(A3A_DCRP_detectAce) then {
        ["ace_unconscious", {
            params ["_unit", "_state"];
            if (_unit == player) then {
                if (_state) then {
                    "dcpr" callExtension "uncon";
                } else {
                    "dcpr" callExtension "wakeup";
                };
            };
        }] call CBA_fnc_addEventHandler;
    };

    [] spawn {
        while {true} do {
            sleep 5;

            private _playerCount = playersNumber independent + playersNumber west + playersNumber east;
            "dcpr" callExtension ["updateplayercount", [_playerCount]];
        };
    }
}