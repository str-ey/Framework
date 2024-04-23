local pickups = {}

CreateThread(function()
    while true do
        Wait(100)

        if NetworkIsPlayerActive(PlayerId()) then
            DoScreenFadeOut(0)
            Wait(500)
            TriggerServerEvent('esx:onPlayerJoined')
            break
        end
    end
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
    ESX.PlayerData = xPlayer
    FreezeEntityPosition(PlayerPedId(), true)

    ESX.Game.Teleport(PlayerPedId(), {
        x = ESX.PlayerData.coords.x,
        y = ESX.PlayerData.coords.y,
        z = ESX.PlayerData.coords.z + 0.25,
        heading = ESX.PlayerData.coords.heading
    }, function()
        TriggerServerEvent('esx:onPlayerSpawn')
        TriggerEvent('esx:onPlayerSpawn')
        ShutdownLoadingScreen()
        ShutdownLoadingScreenNui()
        FreezeEntityPosition(PlayerPedId(), false)
    end)

    ESX.PlayerLoaded = true
    local playerId = PlayerId()
    local timer = GetGameTimer()

    while not HaveAllStreamingRequestsCompleted(ESX.PlayerData.ped) and (GetGameTimer() - timer) < 2000 do
        Wait(0)
    end

    while not DoesEntityExist(ESX.PlayerData.ped) do
        Wait(20)
    end

	while not HasCollisionLoadedAroundEntity(ESX.PlayerData.ped) do
        Wait(0)
    end

    if Config.EnablePVP then
        SetCanAttackFriendly(PlayerPedId(), true, false)
        NetworkSetFriendlyFireOption(true)
    end

    if not Config.EnableWantedLevel then
        ClearPlayerWantedLevel(playerId)
        SetMaxWantedLevel(0)
    end

    for i = 1, #Config.RemoveHudComponents do
        if Config.RemoveHudComponents[i] then
            SetHudComponentPosition(i, 999999.0, 999999.0)
        end
    end

    if Config.DisableNPCDrops then
        local weaponPickups = {'PICKUP_WEAPON_CARBINERIFLE', 'PICKUP_WEAPON_PISTOL', 'PICKUP_WEAPON_PUMPSHOTGUN'}

        for i = 1, #weaponPickups do
            ToggleUsePickupsForPlayer(playerId, weaponPickups[i], false)
        end
    end

    if Config.DisableVehicleSeatShuff then
        AddEventHandler('esx:enteredVehicle', function(vehicle, _, seat)
            if seat == 0 then
                SetPedIntoVehicle(ESX.PlayerData.ped, vehicle, 0)
                SetPedConfigFlag(ESX.PlayerData.ped, 184, true)
            end
        end)
    end

    if Config.DisableHealthRegeneration then
        SetPlayerHealthRechargeMultiplier(playerId, 0.0)
    end

    if Config.DisableWeaponWheel or Config.DisableAimAssist or Config.DisableVehicleRewards then
        CreateThread(function()
            while true do
                if Config.DisableDisplayAmmo then
                    DisplayAmmoThisFrame(false)
                end

                if Config.DisableWeaponWheel then
                    BlockWeaponWheelThisFrame()
                    DisableControlAction(0, 37, true)
                end

                if Config.DisableAimAssist then
                    if IsPedArmed(ESX.PlayerData.ped, 4) then
                        SetPlayerLockonRangeOverride(playerId, 2.0)
                    end
                end

                if Config.DisableVehicleRewards then
                    DisablePlayerVehicleRewards(playerId)
                end

                Wait(0)
            end
        end)
    end

    if Config.DisableDispatchServices then
        for i = 1, 15 do
            EnableDispatchService(i, false)
        end
    end

    if Config.DisableScenarios then
        local scenarios = {
            'WORLD_VEHICLE_ATTRACTOR',
            'WORLD_VEHICLE_AMBULANCE',
            'WORLD_VEHICLE_BICYCLE_BMX',
            'WORLD_VEHICLE_BICYCLE_BMX_BALLAS',
            'WORLD_VEHICLE_BICYCLE_BMX_FAMILY',
            'WORLD_VEHICLE_BICYCLE_BMX_HARMONY',
            'WORLD_VEHICLE_BICYCLE_BMX_VAGOS',
            'WORLD_VEHICLE_BICYCLE_MOUNTAIN',
            'WORLD_VEHICLE_BICYCLE_ROAD',
            'WORLD_VEHICLE_BIKE_OFF_ROAD_RACE',
            'WORLD_VEHICLE_BIKER',
            'WORLD_VEHICLE_BOAT_IDLE',
            'WORLD_VEHICLE_BOAT_IDLE_ALAMO',
            'WORLD_VEHICLE_BOAT_IDLE_MARQUIS',
            'WORLD_VEHICLE_BOAT_IDLE_MARQUIS',
            'WORLD_VEHICLE_BROKEN_DOWN',
            'WORLD_VEHICLE_BUSINESSMEN',
            'WORLD_VEHICLE_HELI_LIFEGUARD',
            'WORLD_VEHICLE_CLUCKIN_BELL_TRAILER',
            'WORLD_VEHICLE_CONSTRUCTION_SOLO',
            'WORLD_VEHICLE_CONSTRUCTION_PASSENGERS',
            'WORLD_VEHICLE_DRIVE_PASSENGERS',
            'WORLD_VEHICLE_DRIVE_PASSENGERS_LIMITED',
            'WORLD_VEHICLE_DRIVE_SOLO',
            'WORLD_VEHICLE_FIRE_TRUCK',
            'WORLD_VEHICLE_EMPTY',
            'WORLD_VEHICLE_MARIACHI',
            'WORLD_VEHICLE_MECHANIC',
            'WORLD_VEHICLE_MILITARY_PLANES_BIG',
            'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
            'WORLD_VEHICLE_PARK_PARALLEL',
            'WORLD_VEHICLE_PARK_PERPENDICULAR_NOSE_IN',
            'WORLD_VEHICLE_PASSENGER_EXIT',
            'WORLD_VEHICLE_POLICE_BIKE',
            'WORLD_VEHICLE_POLICE_CAR',
            'WORLD_VEHICLE_POLICE',
            'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
            'WORLD_VEHICLE_QUARRY',
            'WORLD_VEHICLE_SALTON',
            'WORLD_VEHICLE_SALTON_DIRT_BIKE',
            'WORLD_VEHICLE_SECURITY_CAR',
            'WORLD_VEHICLE_STREETRACE',
            'WORLD_VEHICLE_TOURBUS',
            'WORLD_VEHICLE_TOURIST',
            'WORLD_VEHICLE_TANDL',
            'WORLD_VEHICLE_TRACTOR',
            'WORLD_VEHICLE_TRACTOR_BEACH',
            'WORLD_VEHICLE_TRUCK_LOGS',
            'WORLD_VEHICLE_TRUCKS_TRAILERS',
            'WORLD_VEHICLE_DISTANT_EMPTY_GROUND',
            'WORLD_HUMAN_PAPARAZZI',
        }

        for _, v in pairs(scenarios) do
            SetScenarioTypeEnabled(v, false)
        end
    end

	if IsScreenFadedOut() then
        DoScreenFadeIn(500)
    end

    SetDefaultVehicleNumberPlateTextPattern(-1, Config.CustomAIPlates)
    StartServerSyncLoops()
end)

RegisterNetEvent('esx:onPlayerLogout')
AddEventHandler('esx:onPlayerLogout', function()
	ESX.PlayerLoaded = false
end)

RegisterNetEvent('esx:setMaxWeight')
AddEventHandler('esx:setMaxWeight', function(newMaxWeight)
    ESX.SetPlayerData('maxWeight', newMaxWeight)
end)

local function onPlayerSpawn()
    ESX.SetPlayerData('ped', PlayerPedId())
    ESX.SetPlayerData('dead', false)
end

AddEventHandler('playerSpawned', onPlayerSpawn)
AddEventHandler('esx:onPlayerSpawn', onPlayerSpawn)
AddEventHandler('esx:onPlayerDeath', function()
    ESX.SetPlayerData('ped', PlayerPedId())
    ESX.SetPlayerData('dead', true)
end)

AddEventHandler('skinchanger:modelLoaded', function()
    while not ESX.PlayerLoaded do
        Wait(100)
    end
end)

AddStateBagChangeHandler('VehicleProperties', nil, function(bagName, _, value)
    if not value then
        return
    end

    local netId = bagName:gsub('entity:', '')
    local timer = GetGameTimer()

    while not NetworkDoesEntityExistWithNetworkId(tonumber(netId)) do
        Wait(0)

        if GetGameTimer() - timer > 10000 then
            return
        end
    end

    local vehicle = NetToVeh(tonumber(netId))
    local timer2 = GetGameTimer()

    while NetworkGetEntityOwner(vehicle) ~= PlayerId() do
        Wait(0)

        if GetGameTimer() - timer2 > 10000 then
            return
        end
    end

    ESX.Game.SetVehicleProperties(vehicle, value)
end)

RegisterNetEvent('esx:setAccountMoney')
AddEventHandler('esx:setAccountMoney', function(account)
    for k, v in ipairs(ESX.PlayerData.accounts) do
        if v.name == account.name then
            ESX.PlayerData.accounts[k] = account
            break
        end
    end

    ESX.SetPlayerData('accounts', ESX.PlayerData.accounts)
end)

RegisterNetEvent('esx:addInventoryItem')
AddEventHandler('esx:addInventoryItem', function(item, count)
    for k, v in ipairs(ESX.PlayerData.inventory) do
        if v.name == item then
            ESX.PlayerData.inventory[k].count = count
            break
        end
    end
end)

RegisterNetEvent('esx:removeInventoryItem')
AddEventHandler('esx:removeInventoryItem', function(item, count)
    for k, v in ipairs(ESX.PlayerData.inventory) do
        if v.name == item then
            ESX.PlayerData.inventory[k].count = count
            break
        end
    end
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(Job)
    ESX.SetPlayerData('job', Job)
end)

RegisterNetEvent('esx:setGroup')
AddEventHandler('esx:setGroup', function(Group, lastGroup)
    ESX.SetPlayerData('group', Group)
end)

RegisterNetEvent('esx:teleport')
AddEventHandler('esx:teleport', function(coords)
    ESX.Game.Teleport(PlayerPedId(), coords)
end)

RegisterNetEvent('esx:createPickup')
AddEventHandler('esx:createPickup', function(pickupId, label, coords)
	local function setObjectProperties(object)
		SetEntityAsMissionEntity(object, true, false)
		PlaceObjectOnGroundProperly(object)
		FreezeEntityPosition(object, true)
		SetEntityCollision(object, false, true)

		pickups[pickupId] = {
			obj = object,
			label = label,
			inRange = false,
			coords = vector3(coords.x, coords.y, coords.z)
		}
	end

	ESX.Game.SpawnLocalObject('prop_money_bag_01', coords, setObjectProperties)
end)

RegisterNetEvent('esx:createMissingPickups')
AddEventHandler('esx:createMissingPickups', function(missingPickups)
	for pickupId,pickup in pairs(missingPickups) do
		TriggerEvent('esx:createPickup', pickupId, pickup.label, pickup.coords)
	end
end)

RegisterNetEvent('esx:registerSuggestions')
AddEventHandler('esx:registerSuggestions', function(registeredCommands)
    for name, command in pairs(registeredCommands) do
        if command.suggestion then
            TriggerEvent('chat:addSuggestion', ('/%s'):format(name), command.suggestion.help, command.suggestion.arguments)
        end
    end
end)

RegisterNetEvent('esx:removePickup')
AddEventHandler('esx:removePickup', function(pickupId)
	if pickups[pickupId] and pickups[pickupId].obj then
		ESX.Game.DeleteObject(pickups[pickupId].obj)
		pickups[pickupId] = nil
	end
end)

RegisterNetEvent('esx:deleteVehicle')
AddEventHandler('esx:deleteVehicle', function()
    local vehicle, attempt = ESX.Game.GetVehicleInDirection(), 0

    if IsPedInAnyVehicle(PlayerPedId(), true) then
        vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    end

    while not NetworkHasControlOfEntity(vehicle) and attempt < 100 and DoesEntityExist(vehicle) do
        Wait(0)
        NetworkRequestControlOfEntity(vehicle)
        attempt = attempt + 1
    end

    if DoesEntityExist(vehicle) and NetworkHasControlOfEntity(vehicle) then
        ESX.Game.DeleteVehicle(vehicle)
    end
end)

function StartServerSyncLoops()
    CreateThread(function()
        local previousCoords = vector3(ESX.PlayerData.coords.x, ESX.PlayerData.coords.y, ESX.PlayerData.coords.z)

        while true do
            Wait(1500)
            local playerPed = PlayerPedId()

            if DoesEntityExist(playerPed) then
                local playerCoords = GetEntityCoords(playerPed)
                local distance = #(playerCoords - previousCoords)

                if distance > 1 then
                    previousCoords = playerCoords
                    local playerHeading = ESX.Math.Round(GetEntityHeading(playerPed), 1)
                    local formattedCoords = {
                        x = ESX.Math.Round(playerCoords.x, 1),
                        y = ESX.Math.Round(playerCoords.y, 1),
                        z = ESX.Math.Round(playerCoords.z, 1),
                        heading = playerHeading
                    }

                    TriggerServerEvent('esx:updateCoords', formattedCoords)
                end
            end
        end
    end)
end

CreateThread(function()
	while true do
		Wait(0)
		local playerPed = PlayerPedId()
		local playerCoords, letSleep = GetEntityCoords(playerPed), true
		local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer(playerCoords)

		for pickupId,pickup in pairs(pickups) do
			local distance = #(playerCoords - pickup.coords)

			if distance < 5 then
				local label = pickup.label
				letSleep = false

				if distance < 1 then
					if IsControlJustReleased(0, 38) then
						if IsPedOnFoot(playerPed) and (closestDistance == -1 or closestDistance > 3) and not pickup.inRange then
							pickup.inRange = true
							local dict, anim = 'weapons@first_person@aim_rng@generic@projectile@sticky_bomb@', 'plant_floor'
                            
							ESX.Streaming.RequestAnimDict(dict)
							TaskPlayAnim(playerPed, dict, anim, 8.0, 1.0, 1000, 16, 0.0, false, false, false)
							Wait(1000)
							TriggerServerEvent('esx:onPickup', pickupId)
							PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', false)
						end
					end

					label = ('%s~n~%s'):format(label, 'Appuye sur ~y~E~s~ pour ramasser')
				end

				ESX.Game.Utils.DrawText3D({
					x = pickup.coords.x,
					y = pickup.coords.y,
					z = pickup.coords.z + 0.25
				}, label, 1.2, 1)
			elseif pickup.inRange then
				pickup.inRange = false
			end
		end

		if letSleep then
			Wait(500)
		end
	end
end)

RegisterNetEvent('esx:tpw')
AddEventHandler('esx:tpw', function()
    local GetEntityCoords = GetEntityCoords
    local GetGroundZFor_3dCoord = GetGroundZFor_3dCoord
    local GetFirstBlipInfoId = GetFirstBlipInfoId
    local DoesBlipExist = DoesBlipExist
    local DoScreenFadeOut = DoScreenFadeOut
    local GetBlipInfoIdCoord = GetBlipInfoIdCoord
    local GetVehiclePedIsIn = GetVehiclePedIsIn
    local blipMarker = GetFirstBlipInfoId(8)

    if not DoesBlipExist(blipMarker) then
        TriggerEvent('chatMessage', 'SYSTEM ', {255, 0, 0}, 'Aucun marker trouvé !')
        return 'marker'
    end

    local ped, coords = ESX.PlayerData.ped, GetBlipInfoIdCoord(blipMarker)
    local vehicle = GetVehiclePedIsIn(ped, false)
    local oldCoords = GetEntityCoords(ped)
    local x, y, groundZ, Z_START = coords['x'], coords['y'], 850.0, 950.0
    local found = false

    FreezeEntityPosition(vehicle > 0 and vehicle or ped, true)

    for i = Z_START, 0, -25.0 do
        local z = i

        if (i % 2) ~= 0 then
            z = Z_START - i
        end

        NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
        local curTime = GetGameTimer()

        while IsNetworkLoadingScene() do
            if GetGameTimer() - curTime > 1000 then
                break
            end

            Wait(0)
        end

        NewLoadSceneStop()
        SetPedCoordsKeepVehicle(ped, x, y, z)

        while not HasCollisionLoadedAroundEntity(ped) do
            RequestCollisionAtCoord(x, y, z)
            if GetGameTimer() - curTime > 1000 then
                break
            end

            Wait(0)
        end

        found, groundZ = GetGroundZFor_3dCoord(x, y, z, false)

        if found then
            Wait(0)
            SetPedCoordsKeepVehicle(ped, x, y, groundZ)

            break
        end

        Wait(0)
    end

    FreezeEntityPosition(vehicle > 0 and vehicle or ped, false)

    if not found then
        SetPedCoordsKeepVehicle(ped, oldCoords['x'], oldCoords['y'], oldCoords['z'] - 1.0)
        TriggerEvent('chatMessage', 'SYSTEM ', {255, 0, 0}, 'Téléportation effectué')
    end

    SetPedCoordsKeepVehicle(ped, x, y, groundZ)
    TriggerEvent('chatMessage', 'SYSTEM ', {255, 0, 0}, 'Téléportation effectué')
end)

RegisterNetEvent('esx:stuck')
AddEventHandler('esx:stuck', function()
    local pos = GetEntityCoords(PlayerPedId())
    local interiorid = GetInteriorAtCoords(pos.x, pos.y, pos.z)

    if #(GetEntityCoords(PlayerPedId()).xy) < 30 or GetEntityCoords(PlayerPedId()).z < -30 or interiorid ~= 0 then
        ClearPedTasksImmediately(PlayerPedId())
        SetEntityVisible(PlayerPedId(), true, 1)
        FreezeEntityPosition(PlayerPedId(), false)
        SetEntityCoords(PlayerPedId(), 241.23, -807.15, 30.27, false, false, false, true)
        TriggerEvent('chatMessage', '', {0, 0, 0}, '^1^*Vous vous êtes débloqué !')
    else
        TriggerEvent('chatMessage', '', {0, 0, 0}, '^1^*Vous n\'êtes pas bloqué')
    end
end)

RegisterNetEvent('esx:setHealth')
AddEventHandler('esx:setHealth', function(health)
	SetEntityHealth(PlayerPedId(), health)
end)

RegisterNetEvent('esx:setVehicleProps')
AddEventHandler('esx:setVehicleProps', function(netId, vehicleProps)
	if NetworkDoesEntityExistWithNetworkId(netId) then
		ESX.Game.SetVehicleProperties(NetworkGetEntityFromNetworkId(netId), vehicleProps)
	end
end)

RegisterNetEvent('esx:repairVehiclePed')
AddEventHandler('esx:repairVehiclePed', function()
    local ped = ESX.PlayerData.ped
    local vehicle = GetVehiclePedIsIn(ped, false)

    SetVehicleEngineHealth(vehicle, 1000)
    SetVehicleEngineOn(vehicle, true, true)
    SetVehicleFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0)
end)

RegisterNetEvent('esx:freezePlayer')
AddEventHandler('esx:freezePlayer', function(input)
    local player = PlayerId()

    if input == 'freeze' then
        SetEntityCollision(ESX.PlayerData.ped, false)
        FreezeEntityPosition(ESX.PlayerData.ped, true)
        SetPlayerInvincible(player, true)
    elseif input == 'unfreeze' then
        SetEntityCollision(ESX.PlayerData.ped, true)
        FreezeEntityPosition(ESX.PlayerData.ped, false)
        SetPlayerInvincible(player, false)
    end
end)

RegisterNetEvent('esx:revive')
AddEventHandler('esx:revive', function()
    local playerPed = PlayerPedId()
    local coords = GetEntityCoords(playerPed)

    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do
        Wait(1)
    end

    local formattedCoords = {
        x = ESX.Math.Round(coords.x, 1),
        y = ESX.Math.Round(coords.y, 1),
        z = ESX.Math.Round(coords.z, 1)
    }

    RespawnPed(playerPed, formattedCoords, 0.0)
    ClearTimecycleModifier()
    SetPedMotionBlur(playerPed, false)
    ClearExtraTimecycleModifier()
    EndDeathCam()
    DoScreenFadeIn(800)
end)

function RespawnPed(ped, coords, heading)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    NetworkResurrectLocalPlayer(coords.x, coords.y, coords.z, heading, true, false)
    SetPlayerInvincible(ped, false)
    ClearPedBloodDamage(ped)
    TriggerEvent('esx:resetStatus')
    TriggerServerEvent('esx:onPlayerSpawn')
    TriggerEvent('esx:onPlayerSpawn')
    TriggerEvent('playerSpawned')
end

function EndDeathCam()
    ClearFocus()
    RenderScriptCams(false, false, 0, true, false)
    DestroyCam(cam, false)
    cam = nil
end

RegisterNetEvent('esx:slapPlayer')
AddEventHandler('esx:slapPlayer', function()
    ApplyForceToEntity(PlayerPedId(), 1, 9500.0, 3.0, 7100.0, 1.0, 0.0, 0.0, 1, false, true, false, false, true)
end)

ESX.RegisterClientCallback('esx:GetVehicleType', function(cb, model)
    cb(ESX.GetVehicleType(model))
end)