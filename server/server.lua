local Users <const> = {
    cache = {}
}

local Missions <const> = {
    cache = {}
}

function sendToWebhook(webhook, message)
    PerformHttpRequest(webhook, function(err, text, headers) end, "POST", json.encode({
        content = message
    }), { ["Content-Type"] = "application/json" })
end


Citizen.CreateThread(function()
    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS daily_missions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            user_id INT NOT NULL,
            claimed_missions VARCHAR(600),
            last_mission INT,
            last_claim VARCHAR(100)
        );
    ]])

    exports.oxmysql:execute([[
        CREATE TABLE IF NOT EXISTS missions (
            id INT AUTO_INCREMENT PRIMARY KEY,
            name VARCHAR(100),
            label VARCHAR(100),
            description VARCHAR(100),
            reward INT,
            available BOOLEAN DEFAULT TRUE,
            active BOOLEAN DEFAULT TRUE
        );
    ]])

    local rows = exports.oxmysql:executeSync("SELECT * FROM missions")
    for _, row in ipairs(rows) do
        Missions.cache[row.id] = {
            id = row.id,
            name = row.name,
            label = row.label,
            description = row.description,
            reward = row.reward,
            available = row.available,
            active = row.active
        }
    end
end)

function Users:Create(source)
    local user_id = vRP.getUserId(source)
    if user_id then
        local rows = exports.oxmysql:executeSync("SELECT * FROM daily_missions WHERE user_id = ?", {
            user_id
        })
        if rows and #rows > 0 then
            self.cache[user_id] = {
                user_id = user_id,
                claimed_missions = json.decode(rows[1].claimed_missions),
                last_mission = rows[1].last_mission,
                last_claim = rows[1].last_claim
            }
        else 
            exports.oxmysql:executeSync("INSERT INTO daily_missions (user_id, claimed_missions, last_mission, last_claim) VALUES (?, ?, ?, ?)", {
                user_id,
                json.encode({}), 
                nil, 
                0
            })
    
            self.cache[user_id] = {
                user_id = user_id,
                claimed_missions = {},
                last_mission = nil,
                last_claim = 0
            }
        end
    end
end

Citizen.CreateThread(function ()
    Users:Create(1)
    
    Player(1).state:set('startMission', false, true)
end)

AddEventHandler('vRP:playerSpawn', function(userId, source, firstSpawn)
    local user_id = vRP.getUserId(source)
    if user_id then
        Users:Create(user_id)
    end
end)

function Users:get(user_id)
    return self.cache[user_id] or {}
end

function Users:getMissions()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then
        return {}
    end

    local user = Users:get(user_id)
    if not user then
        return {}
    end

    local filteredRows = {}
    for _, row in pairs(Missions.cache) do
        if row.active then
            local isClaimed = user.claimed_missions[tostring(row.id)]

            -- Verifica se a missão está no claimed_missions e se não está completa ou se passou mais de 24 horas desde o último resgate
            row.available = not isClaimed or isClaimed.completed or os.time() - isClaimed.date >= 86400
            row.claimed = isClaimed and isClaimed.claimed or false
            row.completed = isClaimed and isClaimed.completed or false 

            table.insert(filteredRows, row)
        end
    end

    return filteredRows
end

-- Função para enviar as missões para o cliente
function API.getMissions()
    return Users:getMissions()
end

-- Atualiza o cache do usuário quando ele resgata a recompensa de uma missão
function Users:claimMission(user_id, mission_id)
    if not self.cache[user_id] then return false end

    local mission = self.cache[user_id].claimed_missions[tostring(mission_id)]
    if mission and mission.completed and not mission.claimed then
        mission.claimed = true

        vRP.giveMoney(user_id, Missions.cache[mission_id].reward)
        sendToWebhook(Config.Webhooks['claim'], string.format("Jogador %s resgatou a recompensa da missão: %s", user_id, Missions.cache[mission_id].label))
        TriggerClientEvent("Notify",source,"sucesso","Recompensa da missão "..Missions.cache[mission_id].label.." resgatada com sucesso.")
        return true
    end

    return false
end

-- Função para enviar quando o jogador resgatar a recompensa de uma missão
function API.claimMission(mission_id)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return {error = true, tasks = Users:getMissions()} end

    local user = Users:get(user_id)
    if not user or user.last_mission then return {error = true, tasks = Users:getMissions()} end

    if Missions.cache[mission_id] then
        return Users:claimMission(user_id, mission_id)
    end

    return {error = true, tasks = Users:getMissions()}
end

-- Atualiza o cache do usuário quando ele inicia uma missão
function Users:startMission(source, mission_id)
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    -- Verifica se a missão existe
    if not Missions.cache[mission_id] then return false end

    -- Verifica se o jogador já está com uma missão em andamento
    if Player(source).state.startMission or self.cache[user_id].last_mission then 
        TriggerClientEvent("Notify",source,"negado","Você já está com uma missão em andamento.")
        return false 
    end


    self.cache[user_id].last_mission = mission_id
    self.cache[user_id].claimed_missions[tostring(mission_id)] = {
        completed = false,
        claimed = false,
        date = os.time()
    }

    self.cache[user_id].last_claim = os.time()


    Player(source).state:set('startMission', true, true)

    if Player(source).state.startMission then
        Remote.initMission(source, Missions.cache[mission_id].name)
    end 

    TriggerClientEvent("Notify",source,"sucesso","Missão "..Missions.cache[mission_id].label.." iniciada com sucesso.")

    sendToWebhook(Config.Webhooks['start'], string.format("Jogador %s iniciou a missão: %s", user_id, Missions.cache[mission_id].label))

    return true
end

-- Função para enviar quando o jogador inicia uma missão
function API.startMission(mission_id)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    local user = Users:get(user_id)
    if not user then return false end

    if user.last_claim and os.time() - user.last_claim < 86400 then
        local remainingTime = 86400 - (os.time() - user.last_claim)
        local nextAvailable = os.date("*t", os.time() + remainingTime)
        local formattedDate = string.format("%02d/%02d/%04d às %02d:%02d", 
            nextAvailable.day, 
            nextAvailable.month, 
            nextAvailable.year, 
            nextAvailable.hour, 
            nextAvailable.min
        )
        
        TriggerClientEvent("Notify", source, "negado", 
            "Você já iniciou uma missão em menos de 24 horas. Aguarde até " .. formattedDate .. " para iniciar novamente."
        )
        return {}
    end
    

    if Missions.cache[mission_id] then
        return Users:startMission(source, mission_id)
    else 
        TriggerClientEvent("Notify",source,"negado","Missão inválida.")
    end

    return false
end

-- Atualiza o cache do usuário quando ele finaliza uma missão
function Users:finishMission(source, rows)
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    -- Verifica se o jogador está com alguma missão em andamento 
    if not Player(source).state.startMission or not self.cache[user_id].last_mission then return false end

    -- Verifica se a missão está no claimed_missions
    if not self.cache[user_id].claimed_missions[tostring(self.cache[user_id].last_mission)] then return false end

    -- Verifica se a missão já foi finalizada
    local claimedMission = self.cache[user_id].claimed_missions[tostring(self.cache[user_id].last_mission)]
    if claimedMission.completed then
        return false 
    end

    -- Verifica se a missão já foi resgatada
    if claimedMission.claimed then
        return false
    end 

    -- Atualiza o cache do usuário com a missão finalizada
    claimedMission.completed = true
    claimedMission.claimed = false 
    sendToWebhook(Config.Webhooks['finish'], string.format("Jogador %s finalizou a missão: %s", user_id, Missions.cache[self.cache[user_id].last_mission].label))

    TriggerClientEvent("Notify",source,"sucesso","Missão "..Missions.cache[self.cache[user_id].last_mission].label.." finalizada com sucesso.")

    -- Reseta a última missão resgatada
    self.cache[user_id].last_mission = nil

    Player(source).state:set('startMission', false, true)

    return true
end

-- Função para enviar quando o jogador finalizar a missão
function API.finishMission()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return false end

    local user = Users:get(user_id)
    if not user then return false end

    local mission_id = user.last_mission
    local rows = Missions.cache[mission_id]
    if rows then
        Users:finishMission(source, rows)
        return true
    end

    return false
end

-- Salva o cache do usuário
function Users:Save(user_id)
    local user = Users:get(user_id)
    if not user then return end

    exports.oxmysql:execute("UPDATE daily_missions SET claimed_missions = ?, last_mission = ?, last_claim = ? WHERE user_id = ?", {
        json.encode(user.claimed_missions), user.last_mission, user.last_claim, user_id
    })
end

-- Registra o evento de desconexão
AddEventHandler('vRP:playerLeave', function(source, reason)
    local source = source
    local user_id = vRP.getUserId(source)
    if user_id then
        Users:Save(user_id)
    end
end)

RegisterCommand('criarmissao', function(source, args, rawCommand)
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    if not vRP.hasPermission(user_id, 'developer.permissao') then return end

    local name = vRP.prompt(source, 'Escolha o nome da missão!', "online, offline")
    if name == "" or not name or not Config.Names[name:lower()] then
        return
    end

    local label = vRP.prompt(source, 'Escolha o título da missão!','')
    if label == "" or not label then
        return
    end

    local description = vRP.prompt(source, 'Escolha a descrição da missão!','')
    if description == "" or not description then
        return
    end

    local reward = vRP.prompt(source, 'Escolha a recompensa da missão em dinheiro!', 10000)
    if reward == "" or not reward then
        return
    end

    exports.oxmysql:executeSync("INSERT INTO missions (name, label, description, reward, available, active) VALUES (?, ?, ?, ?, ?, ?)", {
        name, label, description, reward, true, true
    })

    local id = exports.oxmysql:scalarSync("SELECT id FROM missions WHERE name = ?", { name })

    Missions.cache[id] = {
        id = id,
        name = name,
        label = label,
        description = description,
        reward = reward,
        available = true,
        active = true
    }

    sendToWebhook(Config.Webhooks['create'], string.format("Staff ID %s criou a missão: %s", user_id, Missions.cache[id].label))
end)


function API.getStartMission()
    local source = source
    local user_id = vRP.getUserId(source)
    if not user_id then return end

    return Player(source).state.startMission
end 