-- missions = {
--     {
--         id = 1,
--         label = "Mission 1",
--         description = "This is a mission",
--         reward = false,
--         available = true,
--         completed = false, 
--         active = false
--     }
-- }
RegisterCommand("closemissoes", function(source, args, rawCommand)
    SetNuiFocus(false,false)
    SendNUIMessage({
        type = "close",
    })
 end)

RegisterCommand("missoes", function(source, args, rawCommand)
   local missions = Remote.getMissions()
   if missions then
        SetNuiFocus(true,true)
        SendNUIMessage({
            type = "init",
            missions = missions
        })
   end
end)

RegisterNuiCallback("claimMission", function(data, cb)
    if data.id then
        if Remote.claimMission(data.id) then
            SetNuiFocus(false,false)
            SendNUIMessage({
                type = "close",
            })
        end
    end
end)

RegisterNuiCallback("startMission", function(data, cb)
    if data.id then
        if Remote.startMission(data.id) then
            SetNuiFocus(false,false)
            SendNUIMessage({
                type = "close",
            })
        end
    end
end)

function API.initMission(mission_name)
    if mission_name == "online" then
        mission_online()
    end
end