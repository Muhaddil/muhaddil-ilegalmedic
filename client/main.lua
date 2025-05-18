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
    local playerData = ESX.GetPlayerData()

    for _, spawnPosition in ipairs(coordsFromServer.legal) do
        if not spawnPosition.job or (playerData.job and playerData.job.name == spawnPosition.job) then
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
    end
    for _, spawnPosition in ipairs(coordsFromServer.illegal) do
        if not spawnPosition.job or (playerData.job and playerData.job.name == spawnPosition.job) then
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
            lib.notify({ description = locale('usage_addnpccoords'), type = "error" })
            return
        end

        local job = args[2]
        local ped = PlayerPedId()
        local pos = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)
        local newCoord = { x = pos.x, y = pos.y, z = pos.z, w = heading }
        TriggerServerEvent('muhaddil-ilegalmedic:SaveCoords', type, newCoord, job)
        lib.notify({ description = locale('NPC_created_successfully'), type = "success" })
    end)
end)

RegisterCommand('listnpccoords', function()
    ESX.TriggerServerCallback('muhaddil-ilegalmedic:isAdmin', function(cb)
        print(locale('legal_npcs') .. ":")
        for _, npc in ipairs(coordsFromServer.legal) do
            print(("%s - %.2f, %.2f, %.2f, %.2f"):format(npc.id, npc.x, npc.y, npc.z, npc.w))
        end

        print(locale('illegal_npcs') .. ":")
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
            description = locale('npc_not_found'),
            type = "error"
        })
        return
    end

    local options = {
        {
            title = locale('teleport_to_npc'),
            icon = "location-arrow",
            onSelect = function()
                local playerPed = PlayerPedId()
                SetEntityCoords(playerPed, npc.x, npc.y, npc.z + 1.0, false, false, false, true)
                lib.notify({ description = locale('teleported_to_npc'), type = "success" })
            end
        },
        {
            title = locale('delete_npc'),
            icon = "trash",
            onSelect = function()
                TriggerServerEvent('muhaddil-ilegalmedic:DeleteCoords', type, npcIndex)
                lib.notify({ description = locale('NPC_deleted_successfully'), type = "success" })
                TriggerServerEvent('muhaddil-ilegalmedic:RequestCoords')

                local npcList = coordsFromServer[type] or {}

                if #npcList == 0 then
                    lib.notify({
                        description = string.format(locale('no_npcs_to_delete'), type),
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
        title = string.format(locale('npc_options_title'), npcIndex, type),
        options = options
    })

    lib.showContext('single_npc_menu')
end

OpenNpcDeleteMenu = function(type)
    local npcList = coordsFromServer[type] or {}

    if #npcList == 0 then
        lib.notify({
            description = locale('no_npcs_to_delete', type),
            type = "error"
        })
        return
    end

    local options = {}

    for i, npc in ipairs(npcList) do
        table.insert(options, {
            title = string.format(locale('npc_entry_title'), i, npc.x, npc.y, npc.z),
            description = string.format(locale('npc_heading'), npc.w),
            icon = "trash",
            onSelect = function()
                OpenSingleNpcMenu(type, i)
            end
        })
    end

    lib.registerContext({
        id = 'npc_delete_menu',
        title = string.format(locale('delete_npcs_title'), type),
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

local lastPlayerJob = nil

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    if not lastPlayerJob or lastPlayerJob.name ~= job.name then
        Wait(1000)
        lastPlayerJob = job
        ClearMedicPeds()
        SpawnPeds()
    end
end)

local function promptAddNpc(type)
    local input = lib.inputDialog(locale('admin_add_' .. type), {
        {
            type = "input",
            label = locale('admin_job_optional'),
            description = locale('admin_job_optional_desc'),
            required = false
        }
    })
    if not input then return end
    local job = input[1]
    if job and job ~= "" then
        ExecuteCommand(("addnpccoords %s %s"):format(type, job))
    else
        ExecuteCommand(("addnpccoords %s"):format(type))
    end
end

local function OpenAdminNpcMenu()
    local options = {
        {
            title = locale('admin_add_legal'),
            icon = "plus",
            onSelect = function()
                promptAddNpc('legal')
            end
        },
        {
            title = locale('admin_add_illegal'),
            icon = "plus",
            onSelect = function()
                promptAddNpc('illegal')
            end
        },
        {
            title = locale('admin_del_legal'),
            icon = "trash",
            onSelect = function()
                ExecuteCommand("delnpccoords legal")
            end
        },
        {
            title = locale('admin_del_illegal'),
            icon = "trash",
            onSelect = function()
                ExecuteCommand("delnpccoords illegal")
            end
        },
        {
            title = locale('admin_list'),
            icon = "list",
            onSelect = function()
                ExecuteCommand("listnpccoords")
                lib.notify({ description = locale('admin_list_console'), type = "info" })
            end
        }
    }

    lib.registerContext({
        id = 'npc_admin_menu',
        title = locale('admin_menu_title'),
        options = options
    })

    lib.showContext('npc_admin_menu')
end

RegisterCommand('npccadmin', function(source, args)
    ESX.TriggerServerCallback('muhaddil-ilegalmedic:isAdmin', function(isAdmin)
        if not isAdmin then
            lib.notify({ description = locale('no_perms'), type = "error" })
            return
        end
        OpenAdminNpcMenu()
    end)
end)
