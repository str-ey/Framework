local isInVehicle, isEnteringVehicle, isJumping, inPauseMenu = false, false, false, false
local playerPed = PlayerPedId()
local current = {}

local function GetPedVehicleSeat(ped, vehicle)
    for i = -1, 16 do
        if GetPedInVehicleSeat(vehicle, i) == ped then
            return i
        end
    end

    return -1
end

local function GetData(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    local model = GetEntityModel(vehicle)
    local displayName = GetDisplayNameFromVehicleModel(model)
    local netId = vehicle

    if NetworkGetEntityIsNetworked(vehicle) then
        netId = VehToNet(vehicle)
    end

    return displayName, netId
end

CreateThread(function()
    while not ESX.PlayerLoaded do
        Wait(200)
    end

    while true do
        ESX.SetPlayerData('coords', GetEntityCoords(playerPed))

        if playerPed ~= PlayerPedId() then
            playerPed = PlayerPedId()
            ESX.SetPlayerData('ped', playerPed)
            TriggerEvent('esx:playerPedChanged', playerPed)
            TriggerServerEvent('esx:playerPedChanged', PedToNet(playerPed))

            if Config.DisableHealthRegeneration then
                SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
            end
        end
        
        if IsPedJumping(playerPed) and not isJumping then
            isJumping = true
            TriggerEvent('esx:playerJumping')
            TriggerServerEvent('esx:playerJumping')
        elseif not IsPedJumping(playerPed) and isJumping then
            isJumping = false
        end

        if IsPauseMenuActive() and not inPauseMenu then
            inPauseMenu = true
            TriggerEvent('esx:pauseMenuActive', inPauseMenu)
        elseif not IsPauseMenuActive() and inPauseMenu then
            inPauseMenu = false
            TriggerEvent('esx:pauseMenuActive', inPauseMenu)
        end

        if not isInVehicle and not IsPlayerDead(PlayerId()) then
            if DoesEntityExist(GetVehiclePedIsTryingToEnter(playerPed)) and not isEnteringVehicle then
                local vehicle = GetVehiclePedIsTryingToEnter(playerPed)
                local plate = GetVehicleNumberPlateText(vehicle)
                local seat = GetSeatPedIsTryingToEnter(playerPed)
                local _, netId = GetData(vehicle)

                isEnteringVehicle = true
                TriggerEvent('esx:enteringVehicle', vehicle, plate, seat, netId)
                TriggerServerEvent('esx:enteringVehicle', plate, seat, netId)
            elseif not DoesEntityExist(GetVehiclePedIsTryingToEnter(playerPed)) and not IsPedInAnyVehicle(playerPed, true) and isEnteringVehicle then
                TriggerEvent('esx:enteringVehicleAborted')
                TriggerServerEvent('esx:enteringVehicleAborted')
                isEnteringVehicle = false
            elseif IsPedInAnyVehicle(playerPed, false) then
                isEnteringVehicle = false
                isInVehicle = true
                current.vehicle = GetVehiclePedIsUsing(playerPed)
                current.seat = GetPedVehicleSeat(playerPed, current.vehicle)
                current.plate = GetVehicleNumberPlateText(current.vehicle)
                current.displayName, current.netId = GetData(current.vehicle)
                TriggerEvent('esx:enteredVehicle', current.vehicle, current.plate, current.seat, current.displayName, current.netId)
                TriggerServerEvent('esx:enteredVehicle', current.plate, current.seat, current.displayName, current.netId)
            end
        elseif isInVehicle then
            if not IsPedInAnyVehicle(playerPed, false) or IsPlayerDead(PlayerId()) then
                TriggerEvent('esx:exitedVehicle', current.vehicle, current.plate, current.seat, current.displayName, current.netId)
                TriggerServerEvent('esx:exitedVehicle', current.plate, current.seat, current.displayName, current.netId)
                isInVehicle = false
                current = {}
            end
        end

        Wait(200)
    end
end)