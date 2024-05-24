-- Copyright (c) 2024 RAMPAGE Interactive. All rights reserved.
-- Re-write of Badger_Discord_API to be better organized & additional features.

local triggeredServer = false;

AddEventHandler("playerSpawned", function()
    if not triggeredServer then 
        triggeredServer = true;
        Citizen.Wait(12 * 1000)
        TriggerServerEvent('RAMPAGE_Discord_API:LoadPlayer');
    end
end)

RegisterCommand('refreshdiscord', function()
    TriggerServerEvent('RAMPAGE_Discord_API:LoadPlayer');
end)
