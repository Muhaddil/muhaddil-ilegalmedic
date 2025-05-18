ESX = exports['es_extended']:getSharedObject()
lib.locale()

local medicPeds = {}
local medicTargetZones = {}
local medicPedsSpawned = false
local coordsFromServer = { legal = {}, illegal = {} }

local function ClearMedicPeds()
    for _, ped in ipairs(medicPeds) do
        if DoesEntityExist(ped) then
            DeletePed(ped)
        end
    end
    medicPeds = {}

    for _, zoneId in ipairs(medicTargetZones) do
        exports.ox_target:removeZone(zoneId)
    end
    medicTargetZones = {}

    medicPedsSpawned = false
end

local function SpawnPeds()
    if medicPedsSpawned then return end

    RequestModel(Config.PedModel)
    while not HasModelLoaded(Config.PedModel) do Wait(0) end

    for _, spawnPosition in ipairs(coordsFromServer.legal) do
        local heading = spawnPosition.w
        local ped = CreatePed(4, GetHashKey(Config.PedModel), spawnPosition.x, spawnPosition.y, spawnPosition.z - 1.0,
            heading, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetModelAsNoLongerNeeded(Config.PedModel)

        -- Guardamos el ID de la zona que devuelve addBoxZone
        local zoneId = exports.ox_target:addBoxZone({
            coords = vector3(spawnPosition.x, spawnPosition.y, spawnPosition.z),
            size = vector3(1, 1, 2),
            rotation = heading,
            debug = false,
            options = {
                {
                    label = locale('press_to_heal'),
                    icon = 'fas fa-comments',
                    event = 'muhaddil-ilegalmedic:NPCRevive',
                }
            }
        })

        table.insert(medicTargetZones, zoneId)
        table.insert(medicPeds, ped)
    end

    for _, spawnPosition in ipairs(coordsFromServer.illegal) do
        local heading = spawnPosition.w
        local ped = CreatePed(4, GetHashKey(Config.PedModel), spawnPosition.x, spawnPosition.y, spawnPosition.z - 1.0,
            heading, false, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        SetEntityInvincible(ped, true)
        FreezeEntityPosition(ped, true)
        SetModelAsNoLongerNeeded(Config.PedModel)

        local zoneId = exports.ox_target:addBoxZone({
            coords = vector3(spawnPosition.x, spawnPosition.y, spawnPosition.z),
            size = vector3(1, 1, 2),
            rotation = heading,
            debug = false,
            options = {
                {
                    label = locale('press_to_heal2'),
                    icon = 'fas fa-comments',
                    event = 'muhaddil-ilegalmedic:NPCReviveIllegal',
                }
            }
        })

        table.insert(medicTargetZones, zoneId)
        table.insert(medicPeds, ped)
    end

    medicPedsSpawned = true
end

Citizen.CreateThread(function()
    TriggerServerEvent('muhaddil-ilegalmedic:RequestCoords')

    RegisterNetEvent('muhaddil-ilegalmedic:SendCoords')
    AddEventHandler('muhaddil-ilegalmedic:SendCoords', function(coords)
        coordsFromServer = coords or { legal = {}, illegal = {} }
        ClearMedicPeds()
        SpawnPeds()
    end)
end)

RegisterCommand('addnpccoords', function(source, args)
    ESX.TriggerServerCallback('muhaddil-ilegalmedic:isAdmin', function(cb)
        local type = args[1]
        if type ~= 'legal' and type ~= 'illegal' then
            print("Uso: /addnpccoords legal | illegal")
            return
        end

        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local newCoord = { x = pos.x, y = pos.y, z = pos.z, w = heading }
        TriggerServerEvent('muhaddil-ilegalmedic:SaveCoords', type, newCoord)
        lib.notify({ description = locale('NPC_created_successfully'), type = "success" })
    end)
end)

RegisterCommand('listnpccoords', function()
    ESX.TriggerServerCallback('muhaddil-ilegalmedic:isAdmin', function(cb)
        print("NPCs legales:")
        for _, npc in ipairs(coordsFromServer.legal) do
            print(("%s - %.2f, %.2f, %.2f, %.2f"):format(npc.id, npc.x, npc.y, npc.z, npc.w))
        end

        print("NPCs ilegales:")
        for _, npc in ipairs(coordsFromServer.illegal) do
            print(("%s - %.2f, %.2f, %.2f, %.2f"):format(npc.id, npc.x, npc.y, npc.z, npc.w))
        end
    end)
end)

local function DeleteAllMedicPeds()
    for _, ped in ipairs(medicPeds) do
        if DoesEntityExist(ped) then
            DeleteEntity(ped)
        end
    end
    medicPeds = {}

    for _, zoneId in ipairs(medicTargetZones) do
        exports.ox_target:removeZone(zoneId)
    end
    medicTargetZones = {}

    medicPedsSpawned = false
end

RegisterNetEvent('muhaddil-ilegalmedic:ReloadNPCs')
AddEventHandler('muhaddil-ilegalmedic:ReloadNPCs', function()
    DeleteAllMedicPeds()
    TriggerServerEvent('muhaddil-ilegalmedic:RequestCoords')
end)

RegisterNetEvent("muhaddil-ilegalmedic:NPCRevive")
AddEventHandler("muhaddil-ilegalmedic:NPCRevive", function()
    ESX.TriggerServerCallback('muhaddil-ilegalmedic:canPay', function(canPay)
        if canPay then
            if Config.UseProgressBar then
                lib.progressBar({
                    duration = 10000,
                    label = locale('doctor_checking_you'),
                    useWhileDead = true,
                    canCancel = false,
                    disable = {
                        car = true,
                    },
                    anim = {
                        dict = 'missheistdockssetup1clipboard@base',
                        clip = 'base'
                    },
                    prop = prop,
                })
            end
            TriggerEvent('esx_ambulancejob:revive')
            if Config.EnableWebhook then
                TriggerServerEvent('muhaddil-ilegalmedic:Server:ReviveLogs')
            end
            lib.notify({
                description = locale('successfully_paid'),
                showDuration = true,
                type = 'success',
                duration = 5000,
            })
        else
            lib.notify({
                description = locale('not_enough_money'),
                showDuration = true,
                type = 'error',
                duration = 5000,
            })
        end
    end, price)
end)

RegisterNetEvent("muhaddil-ilegalmedic:NPCReviveIllegal")
AddEventHandler("muhaddil-ilegalmedic:NPCReviveIllegal", function()
    ESX.TriggerServerCallback('muhaddil-ilegalmedic:canPayIlegal', function(canPay)
        if canPay then
            if Config.UseProgressBar then
                lib.progressBar({
                    duration = 10000,
                    label = locale('doctor_checking_you'),
                    useWhileDead = true,
                    canCancel = false,
                    disable = {
                        car = true,
                    },
                    anim = {
                        dict = 'missheistdockssetup1clipboard@base',
                        clip = 'base'
                    },
                })
            end
            TriggerEvent('esx_ambulancejob:revive')
            if Config.EnableWebhook then
                TriggerServerEvent('muhaddil-ilegalmedic:Server:ReviveLogs')
            end
            lib.notify({
                description = locale('successfully_paid'),
                showDuration = true,
                type = 'success',
                duration = 5000,
            })
        else
            lib.notify({
                description = locale('not_enough_money'),
                showDuration = true,
                type = 'error',
                duration = 5000,
            })
        end
    end, price)
end)

RegisterNetEvent('getPlayerCoords')
AddEventHandler('getPlayerCoords', function(npcType)
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    TriggerServerEvent('saveNpcCoords', npcType, { x = pos.x, y = pos.y, z = pos.z, w = heading })
end)

local OpenNpcDeleteMenu

local function OpenSingleNpcMenu(type, npcIndex)
    local npcList = coordsFromServer[type] or {}
    local npc = npcList[npcIndex]

    if not npc then
        lib.notify({
            description = "NPC no encontrado.",
            type = "error"
        })
        return
    end

    local options = {
        {
            title = "Teletransportarse", -- You can modify the title here
            icon = "location-arrow",
            onSelect = function()
                local playerPed = PlayerPedId()
                SetEntityCoords(playerPed, npc.x, npc.y, npc.z + 1.0, false, false, false, true)
                lib.notify({ description = "Teletransportado al NPC.", type = "success" })
            end
        },
        {
            title = "Borrar NPC", -- You can modify the title here
            icon = "trash",
            onSelect = function()
                TriggerServerEvent('muhaddil-ilegalmedic:DeleteCoords', type, npcIndex)
                lib.notify({ description = locale('NPC_deleted_successfully'), type = "success" })
                TriggerServerEvent('muhaddil-ilegalmedic:RequestCoords')

                local npcList = coordsFromServer[type] or {}

                if #npcList == 0 then
                    lib.notify({
                        description = "No hay NPCs para borrar en " .. type,
                        type = "error"
                    })
                    return
                else
                    Wait(100)
                    OpenNpcDeleteMenu(type)
                end            
            end
        }
    }

    lib.registerContext({
        id = 'single_npc_menu',
        title = ("Opciones para NPC %d (%s)"):format(npcIndex, type), -- You can modify the title here
        options = options
    })

    lib.showContext('single_npc_menu')
end

OpenNpcDeleteMenu = function(type)
    local npcList = coordsFromServer[type] or {}

    if #npcList == 0 then
        lib.notify({
            description = "No hay NPCs para borrar en " .. type,
            type = "error"
        })
        return
    end

    local options = {}

    for i, npc in ipairs(npcList) do
        table.insert(options, {
            title = ("NPC %d (%.2f, %.2f, %.2f)"):format(i, npc.x, npc.y, npc.z),
            description = "Heading: " .. npc.w,
            icon = "trash",
            onSelect = function()
                OpenSingleNpcMenu(type, i)
            end
        })
    end

    lib.registerContext({
        id = 'npc_delete_menu',
        title = 'Eliminar NPCs - ' .. type, -- You can modify the title here
        options = options
    })

    lib.showContext('npc_delete_menu')
end

RegisterCommand('delnpccoords', function(source, args)
    ESX.TriggerServerCallback('muhaddil-ilegalmedic:isAdmin', function(isAdmin)
        if not isAdmin then
            lib.notify({ description = locale('no_perms'), type = "error" })
            return
        end

        local type = args[1]

        if type ~= 'legal' and type ~= 'illegal' then
            print("Uso: /delnpccoords legal|illegal")
            return
        end

        OpenNpcDeleteMenu(type)
    end)
end)

