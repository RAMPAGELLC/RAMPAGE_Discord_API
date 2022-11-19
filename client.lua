local triggeredServer = false;
AddEventHandler("playerSpawned", function()
    if not triggeredServer then 
        triggeredServer = true;
        Citizen.Wait(12 * 1000)
        TriggerServerEvent('RAMPAGE_Discord_API:LoadPlayer');
    end
end)