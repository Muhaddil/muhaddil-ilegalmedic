ESX = exports['es_extended']:getSharedObject()

local webhook = 'YOUR-WEBHOOK-GOES-HERE'

ESX.RegisterServerCallback('muhaddil-ilegalmedic:canPay', function(source, cb, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.ReviveInvoice

    local cashMoney = xPlayer.getMoney()
    local bankMoney = xPlayer.getAccount('bank').money

    if cashMoney >= price then
        xPlayer.removeMoney(price)
        cb(true)
    elseif bankMoney >= price then
        xPlayer.removeAccountMoney('bank', price)
        cb(true)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('muhaddil-ilegalmedic:canPayIlegal', function(source, cb, price)
    local xPlayer = ESX.GetPlayerFromId(source)
    local price = Config.ReviveInvoiceIlegal

    local blackMoneyItem = xPlayer.getInventoryItem('black_money')

    if blackMoneyItem.count >= price then
        xPlayer.removeInventoryItem('black_money', price)
        cb(true)
    else
        cb(false)
    end
end)

ESX.RegisterServerCallback('muhaddil-ilegalmedic:checkEMS', function(source, cb)
    local xPlayers = ESX.GetExtendedPlayers('job', Config.EMSJobName)
    if #xPlayers >= Config.MaxEMS then
        cb(true)
    else
        cb(false)
    end
end)

RegisterNetEvent("muhaddil-ilegalmedic:Server:ReviveLogs")
AddEventHandler("muhaddil-ilegalmedic:Server:ReviveLogs", function()
    local xPlayers = ESX.GetExtendedPlayers('job', Config.EMSJobName)
    local EMS = #xPlayers
    local xPlayer = ESX.GetPlayerFromId(source)
    local embedData = {
        embeds = { {
            title = "Jugador Revivido M-Ilegal",
            color = 16753920, -- Color naranja
            fields = {
                { name = "Jugador con ID",    value = tostring(source),                inline = true },
                { name = "Licencia",          value = tostring(xPlayer.identifier),    inline = true },
                { name = "Nombre IG",         value = tostring(xPlayer.getName()),     inline = true },
                { name = "Nombre OOC",        value = tostring(GetPlayerName(source)), inline = true },
                { name = "Nº Médicos Online", value = tostring(EMS),                   inline = true },
            },
            footer = {
                text = "Muhaddil Scripts"
            },
            timestamp = os.date("!%Y-%m-%dT%H:%M:%SZ")
        } }
    }

    PerformHttpRequest(webhook,
        function(err, text, headers)
        end, 'POST', json.encode(embedData),
        { ['Content-Type'] = 'application/json' }
    )
end)

local jsonFile = 'npccoords.json'
local npcCoords = {
    legal = {},
    illegal = {}
}

local function LoadCoords()
    local file = LoadResourceFile(GetCurrentResourceName(), jsonFile)
    if file then
        npcCoords = json.decode(file) or { legal = {}, illegal = {} }
    end
end

local function GenerateId()
    return tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
end

local function SaveCoords()
    SaveResourceFile(GetCurrentResourceName(), jsonFile, json.encode(npcCoords, { indent = true }), -1)
end

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        LoadCoords()
    end
end)

RegisterNetEvent('muhaddil-ilegalmedic:RequestCoords')
AddEventHandler('muhaddil-ilegalmedic:RequestCoords', function()
    local src = source
    TriggerClientEvent('muhaddil-ilegalmedic:SendCoords', src, npcCoords)
end)

ESX.RegisterServerCallback('muhaddil-ilegalmedic:isAdmin', function(src, cb, param1, param2)
    local xPlayer = ESX.GetPlayerFromId(src)
    cb(xPlayer.getGroup() == 'admin')
end)

RegisterNetEvent('muhaddil-ilegalmedic:SaveCoords')
AddEventHandler('muhaddil-ilegalmedic:SaveCoords', function(type, coord)
    if type ~= 'legal' and type ~= 'illegal' then return end
    if coord and coord.x and coord.y and coord.z and coord.w then
        local newCoord = {
            id = GenerateId(),
            x = coord.x,
            y = coord.y,
            z = coord.z,
            w = coord.w
        }
        table.insert(npcCoords[type], newCoord)
        SaveCoords()

        TriggerClientEvent('muhaddil-ilegalmedic:ReloadNPCs', -1)
    end
end)

RegisterNetEvent('muhaddil-ilegalmedic:DeleteCoords')
AddEventHandler('muhaddil-ilegalmedic:DeleteCoords', function(type, id)
    if type ~= 'legal' and type ~= 'illegal' then return end
    local index = tonumber(id)
    if index and npcCoords[type][index] then
        table.remove(npcCoords[type], index)
        SaveCoords()
        TriggerClientEvent('muhaddil-ilegalmedic:ReloadNPCs', -1)
    end
end)
