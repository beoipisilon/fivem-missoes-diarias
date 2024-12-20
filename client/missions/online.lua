Citizen.CreateThread(function ()
    mission_online()
end)
function mission_online()
    -- verifica o estado do jogador se ele está com alguma missão ativa
    if Remote.getStartMission() then
        print('Mission online started')
        Citizen.CreateThread(function()
            Wait(10000)
            -- Envia a missão para o servidor para ser finalizada após 30 segundos
            print('Finish Mission')
            Remote.finishMission()
        end)
    end
end