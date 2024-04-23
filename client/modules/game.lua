ESX.Game = {}
ESX.Game.Utils = {}

ESX.Game.GetPedMugshot = function(ped, transparent)
    if not DoesEntityExist(ped) then
        return
    end

    local mugshot = transparent and RegisterPedheadshotTransparent(ped) or RegisterPedheadshot(ped)

    while not IsPedheadshotReady(mugshot) do
        Wait(0)
    end

    return mugshot, GetPedheadshotTxdString(mugshot)
end

ESX.Game.Teleport = function(entity, coords, cb)
    local vector = type(coords) == 'vector4' and coords or type(coords) == 'vector3' and vector4(coords, 0.0) or vec(coords.x, coords.y, coords.z, coords.heading or 0.0)

    if DoesEntityExist(entity) then
        RequestCollisionAtCoord(vector.xyz)

        while not HasCollisionLoadedAroundEntity(entity) do
            Wait(0)
        end

        SetEntityCoords(entity, vector.xyz, false, false, false, false)
        SetEntityHeading(entity, vector.w)
    end

    if cb then
        cb()
    end
end

ESX.Game.SpawnObject = function(object, coords, cb, networked)
    networked = networked == nil and true or networked

    local model = type(object) == 'number' and object or joaat(object)
    local vector = type(coords) == 'vector3' and coords or vec(coords.x, coords.y, coords.z)

    CreateThread(function()
        ESX.Streaming.RequestModel(model)
        local obj = CreateObject(model, vector.xyz, networked, false, true)

        if cb then
            cb(obj)
        end
    end)
end

ESX.Game.SpawnLocalObject = function(object, coords, cb)
    ESX.Game.SpawnObject(object, coords, cb, networked)
end

ESX.Game.DeleteVehicle = function(vehicle)
    SetEntityAsMissionEntity(vehicle, false, true)
    DeleteVehicle(vehicle)
end

ESX.Game.DeleteObject = function(object)
    SetEntityAsMissionEntity(object, false, true)
    DeleteObject(object)
end

ESX.Game.SpawnVehicle = function(vehicleModel, coords, heading, cb, networked)
    local model = type(vehicleModel) == 'number' and vehicleModel or joaat(vehicleModel)
    local vector = type(coords) == 'vector3' and coords or vec(coords.x, coords.y, coords.z)
    networked = networked == nil and true or networked

    local playerCoords = GetEntityCoords(ESX.PlayerData.ped)
    if not vector or not playerCoords then
        return
    end

    local dist = #(playerCoords - vector)
    if dist > 424 then
        local executingResource = GetInvokingResource() or 'Unknown'

        return print(('[^1ERREUR^7] La resource : ^5%s^7 essayer de faire apparaitre un véhicule hors-plage de synchronisation !'):format(executingResource))
    end

    CreateThread(function()
        ESX.Streaming.RequestModel(model)
        local vehicle = CreateVehicle(model, vector.xyz, heading, networked, true)

        if networked then
            local id = NetworkGetNetworkIdFromEntity(vehicle)

            SetNetworkIdCanMigrate(id, true)
            SetEntityAsMissionEntity(vehicle, true, true)
        end

        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetModelAsNoLongerNeeded(model)
        SetVehRadioStation(vehicle, 'OFF')
        RequestCollisionAtCoord(vector.xyz)

        while not HasCollisionLoadedAroundEntity(vehicle) do
            Wait(0)
        end

        if cb then
            cb(vehicle)
        end
    end)
end

ESX.Game.SpawnLocalVehicle = function(vehicle, coords, heading, cb)
    ESX.Game.SpawnVehicle(vehicle, coords, heading, cb, false)
end

ESX.Game.IsVehicleEmpty = function(vehicle)
    local passengers = GetVehicleNumberOfPassengers(vehicle)
    local driverSeatFree = IsVehicleSeatFree(vehicle, -1)

    return passengers == 0 and driverSeatFree
end

ESX.Game.GetObjects = function()
    return GetGamePool('CObject')
end

ESX.Game.GetPeds = function(onlyOtherPeds)
    local pool = GetGamePool('CPed')

    if onlyOtherPeds then
        local myPed = ESX.PlayerData.ped

        for i = 1, #pool do
            if pool[i] == myPed then
                table.remove(pool, i)
                break
            end
        end
    end

    return pool
end

ESX.Game.GetVehicles = function()
    return GetGamePool('CVehicle')
end

ESX.Game.GetPlayers = function(onlyOtherPlayers, returnKeyValue, returnPeds)
    local players, myPlayer = {}, PlayerId()
    local active = GetActivePlayers()

    for i = 1, #active do
        local currentPlayer = active[i]
        local ped = GetPlayerPed(currentPlayer)

        if DoesEntityExist(ped) and ((onlyOtherPlayers and currentPlayer ~= myPlayer) or not onlyOtherPlayers) then
            if returnKeyValue then
                players[currentPlayer] = ped
            else
                players[#players + 1] = returnPeds and ped or currentPlayer
            end
        end
    end

    return players
end

ESX.Game.GetClosestObject = function(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetObjects(), false, coords, modelFilter)
end

ESX.Game.GetClosestPed = function(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetPeds(true), false, coords, modelFilter)
end

ESX.Game.GetClosestPlayer = function(coords)
    return ESX.Game.GetClosestEntity(ESX.Game.GetPlayers(true, true), true, coords, nil)
end

ESX.Game.GetClosestVehicle = function(coords, modelFilter)
    return ESX.Game.GetClosestEntity(ESX.Game.GetVehicles(), false, coords, modelFilter)
end

local function EnumerateEntitiesWithinDistance(entities, isPlayerEntities, coords, maxDistance)
    local nearbyEntities = {}

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = ESX.PlayerData.ped
        coords = GetEntityCoords(playerPed)
    end

    for k, entity in pairs(entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if distance <= maxDistance then
            nearbyEntities[#nearbyEntities + 1] = isPlayerEntities and k or entity
        end
    end

    return nearbyEntities
end

ESX.Game.GetPlayersInArea = function(coords, maxDistance)
    return EnumerateEntitiesWithinDistance(ESX.Game.GetPlayers(true, true), true, coords, maxDistance)
end

ESX.Game.GetVehiclesInArea = function(coords, maxDistance)
    return EnumerateEntitiesWithinDistance(ESX.Game.GetVehicles(), false, coords, maxDistance)
end

ESX.Game.IsSpawnPointClear = function(coords, maxDistance)
    return #ESX.Game.GetVehiclesInArea(coords, maxDistance) == 0
end

ESX.Game.GetClosestEntity = function(entities, isPlayerEntities, coords, modelFilter)
    local closestEntity, closestEntityDistance, filteredEntities = -1, -1, nil

    if coords then
        coords = vector3(coords.x, coords.y, coords.z)
    else
        local playerPed = ESX.PlayerData.ped
        coords = GetEntityCoords(playerPed)
    end

    if modelFilter then
        filteredEntities = {}

        for _, entity in pairs(entities) do
            if modelFilter[GetEntityModel(entity)] then
                filteredEntities[#filteredEntities + 1] = entity
            end
        end
    end

    for k, entity in pairs(filteredEntities or entities) do
        local distance = #(coords - GetEntityCoords(entity))

        if closestEntityDistance == -1 or distance < closestEntityDistance then
            closestEntity, closestEntityDistance = isPlayerEntities and k or entity, distance
        end
    end

    return closestEntity, closestEntityDistance
end

ESX.Game.GetVehicleInDirection = function()
    local playerPed = ESX.PlayerData.ped
    local playerCoords = GetEntityCoords(playerPed)
    local inDirection = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
    local rayHandle = StartExpensiveSynchronousShapeTestLosProbe(playerCoords, inDirection, 10, playerPed, 0)
    local _, hit, _, _, entityHit = GetShapeTestResult(rayHandle)

    if hit == 1 and GetEntityType(entityHit) == 2 then
        local entityCoords = GetEntityCoords(entityHit)

        return entityHit, entityCoords
    end

    return nil
end

ESX.Game.GetVehicleProperties = function(vehicle)
    if not DoesEntityExist(vehicle) then
        return
    end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    local hasCustomPrimaryColor = GetIsVehiclePrimaryColourCustom(vehicle)
    local dashboardColor = GetVehicleDashboardColor(vehicle)
    local interiorColor = GetVehicleInteriorColour(vehicle)
    local customPrimaryColor = nil
    if hasCustomPrimaryColor then
        customPrimaryColor = {GetVehicleCustomPrimaryColour(vehicle)}
    end

    local hasCustomXenonColor, customXenonColorR, customXenonColorG, customXenonColorB = GetVehicleXenonLightsCustomColor(vehicle)
    local customXenonColor = nil
    if hasCustomXenonColor then
        customXenonColor = {customXenonColorR, customXenonColorG, customXenonColorB}
    end

    local hasCustomSecondaryColor = GetIsVehicleSecondaryColourCustom(vehicle)
    local customSecondaryColor = nil
    if hasCustomSecondaryColor then
        customSecondaryColor = {GetVehicleCustomSecondaryColour(vehicle)}
    end

    local extras = {}
    for extraId = 0, 20 do
        if DoesExtraExist(vehicle, extraId) then
            extras[tostring(extraId)] = IsVehicleExtraTurnedOn(vehicle, extraId)
        end
    end

    local doorsBroken, windowsBroken, tyreBurst = {}, {}, {}
    local numWheels = tostring(GetVehicleNumberOfWheels(vehicle))
    local TyresIndex = {
        ['2'] = {0, 4},
        ['3'] = {0, 1, 4, 5},
        ['4'] = {0, 1, 4, 5},
        ['6'] = {0, 1, 2, 3, 4, 5},
    }

    if TyresIndex[numWheels] then
        for _, idx in pairs(TyresIndex[numWheels]) do
            tyreBurst[tostring(idx)] = IsVehicleTyreBurst(vehicle, idx, false)
        end
    end

    for windowId = 0, 7 do
        RollUpWindow(vehicle, windowId)
        windowsBroken[tostring(windowId)] = not IsVehicleWindowIntact(vehicle, windowId)
    end

    local numDoors = GetNumberOfVehicleDoors(vehicle)
    if numDoors and numDoors > 0 then
        for doorsId = 0, numDoors do
            doorsBroken[tostring(doorsId)] = IsVehicleDoorDamaged(vehicle, doorsId)
        end
    end

    return {
        model = GetEntityModel(vehicle),
        doorsBroken = doorsBroken,
        windowsBroken = windowsBroken,
        tyreBurst = tyreBurst,
        tyresCanBurst = GetVehicleTyresCanBurst(vehicle),
        plate = ESX.Math.Trim(GetVehicleNumberPlateText(vehicle)),
        plateIndex = GetVehicleNumberPlateTextIndex(vehicle),
        bodyHealth = ESX.Math.Round(GetVehicleBodyHealth(vehicle), 1),
        engineHealth = ESX.Math.Round(GetVehicleEngineHealth(vehicle), 1),
        tankHealth = ESX.Math.Round(GetVehiclePetrolTankHealth(vehicle), 1),
        fuelLevel = ESX.Math.Round(GetVehicleFuelLevel(vehicle), 1),
        dirtLevel = ESX.Math.Round(GetVehicleDirtLevel(vehicle), 1),
        color1 = colorPrimary,
        color2 = colorSecondary,
        customPrimaryColor = customPrimaryColor,
        customSecondaryColor = customSecondaryColor,
        pearlescentColor = pearlescentColor,
        wheelColor = wheelColor,
        dashboardColor = dashboardColor,
        interiorColor = interiorColor,
        wheels = GetVehicleWheelType(vehicle),
        windowTint = GetVehicleWindowTint(vehicle),
        xenonColor = GetVehicleXenonLightsColor(vehicle),
        customXenonColor = customXenonColor,
        neonEnabled = {
			IsVehicleNeonLightEnabled(vehicle, 0),
			IsVehicleNeonLightEnabled(vehicle, 1),
			IsVehicleNeonLightEnabled(vehicle, 2),
			IsVehicleNeonLightEnabled(vehicle, 3)
		},
        neonColor = table.pack(GetVehicleNeonLightsColour(vehicle)),
        extras = extras,
        tyreSmokeColor = table.pack(GetVehicleTyreSmokeColor(vehicle)),
        modSpoilers = GetVehicleMod(vehicle, 0),
        modFrontBumper = GetVehicleMod(vehicle, 1),
        modRearBumper = GetVehicleMod(vehicle, 2),
        modSideSkirt = GetVehicleMod(vehicle, 3),
        modExhaust = GetVehicleMod(vehicle, 4),
        modFrame = GetVehicleMod(vehicle, 5),
        modGrille = GetVehicleMod(vehicle, 6),
        modHood = GetVehicleMod(vehicle, 7),
        modFender = GetVehicleMod(vehicle, 8),
        modRightFender = GetVehicleMod(vehicle, 9),
        modRoof = GetVehicleMod(vehicle, 10),
        modRoofLivery = GetVehicleRoofLivery(vehicle),
        modEngine = GetVehicleMod(vehicle, 11),
        modBrakes = GetVehicleMod(vehicle, 12),
        modTransmission = GetVehicleMod(vehicle, 13),
        modHorns = GetVehicleMod(vehicle, 14),
        modSuspension = GetVehicleMod(vehicle, 15),
        modArmor = GetVehicleMod(vehicle, 16),
        modTurbo = IsToggleModOn(vehicle, 18),
        modSmokeEnabled = IsToggleModOn(vehicle, 20),
        modXenon = IsToggleModOn(vehicle, 22),
        modFrontWheels = GetVehicleMod(vehicle, 23),
        modCustomFrontWheels = GetVehicleModVariation(vehicle, 23),
        modBackWheels = GetVehicleMod(vehicle, 24),
        modCustomBackWheels = GetVehicleModVariation(vehicle, 24),
        modPlateHolder = GetVehicleMod(vehicle, 25),
        modVanityPlate = GetVehicleMod(vehicle, 26),
        modTrimA = GetVehicleMod(vehicle, 27),
        modOrnaments = GetVehicleMod(vehicle, 28),
        modDashboard = GetVehicleMod(vehicle, 29),
        modDial = GetVehicleMod(vehicle, 30),
        modDoorSpeaker = GetVehicleMod(vehicle, 31),
        modSeats = GetVehicleMod(vehicle, 32),
        modSteeringWheel = GetVehicleMod(vehicle, 33),
        modShifterLeavers = GetVehicleMod(vehicle, 34),
        modAPlate = GetVehicleMod(vehicle, 35),
        modSpeakers = GetVehicleMod(vehicle, 36),
        modTrunk = GetVehicleMod(vehicle, 37),
        modHydrolic = GetVehicleMod(vehicle, 38),
        modEngineBlock = GetVehicleMod(vehicle, 39),
        modAirFilter = GetVehicleMod(vehicle, 40),
        modStruts = GetVehicleMod(vehicle, 41),
        modArchCover = GetVehicleMod(vehicle, 42),
        modAerials = GetVehicleMod(vehicle, 43),
        modTrimB = GetVehicleMod(vehicle, 44),
        modTank = GetVehicleMod(vehicle, 45),
        modWindows = GetVehicleMod(vehicle, 46),
        modLivery = GetVehicleMod(vehicle, 48) == -1 and GetVehicleLivery(vehicle) or GetVehicleMod(vehicle, 48),
        modLightbar = GetVehicleMod(vehicle, 49),
    }
end

ESX.Game.SetVehicleProperties = function(vehicle, props)
    if not DoesEntityExist(vehicle) then
        return
    end

    local colorPrimary, colorSecondary = GetVehicleColours(vehicle)
    local pearlescentColor, wheelColor = GetVehicleExtraColours(vehicle)
    SetVehicleModKit(vehicle, 0)

    if props.tyresCanBurst ~= nil then
        SetVehicleTyresCanBurst(vehicle, props.tyresCanBurst)
    end
    if props.plate ~= nil then
        SetVehicleNumberPlateText(vehicle, props.plate)
    end
    if props.plateIndex ~= nil then
        SetVehicleNumberPlateTextIndex(vehicle, props.plateIndex)
    end
    if props.bodyHealth ~= nil then
        SetVehicleBodyHealth(vehicle, props.bodyHealth + 0.0)
    end
    if props.engineHealth ~= nil then
        SetVehicleEngineHealth(vehicle, props.engineHealth + 0.0)
    end
    if props.tankHealth ~= nil then
        SetVehiclePetrolTankHealth(vehicle, props.tankHealth + 0.0)
    end
    if props.fuelLevel ~= nil then
        SetVehicleFuelLevel(vehicle, props.fuelLevel + 0.0)
    end
    if props.dirtLevel ~= nil then
        SetVehicleDirtLevel(vehicle, props.dirtLevel + 0.0)
    end
    if props.customPrimaryColor ~= nil then
        SetVehicleCustomPrimaryColour(vehicle, props.customPrimaryColor[1], props.customPrimaryColor[2], props.customPrimaryColor[3])
    end
    if props.customSecondaryColor ~= nil then
        SetVehicleCustomSecondaryColour(vehicle, props.customSecondaryColor[1], props.customSecondaryColor[2], props.customSecondaryColor[3])
    end
    if props.color1 ~= nil then
        SetVehicleColours(vehicle, props.color1, colorSecondary)
    end
    if props.color2 ~= nil then
        SetVehicleColours(vehicle, props.color1 or colorPrimary, props.color2)
    end
    if props.pearlescentColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor, wheelColor)
    end
    if props.interiorColor ~= nil then
        SetVehicleInteriorColor(vehicle, props.interiorColor)
    end
    if props.dashboardColor ~= nil then
        SetVehicleDashboardColor(vehicle, props.dashboardColor)
    end
    if props.wheelColor ~= nil then
        SetVehicleExtraColours(vehicle, props.pearlescentColor or pearlescentColor, props.wheelColor)
    end
    if props.wheels ~= nil then
        SetVehicleWheelType(vehicle, props.wheels)
    end
    if props.windowTint ~= nil then
        SetVehicleWindowTint(vehicle, props.windowTint)
    end
    if props.neonEnabled ~= nil then
        SetVehicleNeonLightEnabled(vehicle, 0, props.neonEnabled[1])
        SetVehicleNeonLightEnabled(vehicle, 1, props.neonEnabled[2])
        SetVehicleNeonLightEnabled(vehicle, 2, props.neonEnabled[3])
        SetVehicleNeonLightEnabled(vehicle, 3, props.neonEnabled[4])
    end
    if props.extras ~= nil then
        for extraId, enabled in pairs(props.extras) do
            SetVehicleExtra(vehicle, tonumber(extraId), enabled and 0 or 1)
        end
    end
    if props.neonColor ~= nil then
        SetVehicleNeonLightsColour(vehicle, props.neonColor[1], props.neonColor[2], props.neonColor[3])
    end
    if props.xenonColor ~= nil then
        SetVehicleXenonLightsColor(vehicle, props.xenonColor)
    end
    if props.customXenonColor ~= nil then
        SetVehicleXenonLightsCustomColor(vehicle, props.customXenonColor[1], props.customXenonColor[2], props.customXenonColor[3])
    end
    if props.modSmokeEnabled ~= nil then
        ToggleVehicleMod(vehicle, 20, true)
    end
    if props.tyreSmokeColor ~= nil then
        SetVehicleTyreSmokeColor(vehicle, props.tyreSmokeColor[1], props.tyreSmokeColor[2], props.tyreSmokeColor[3])
    end
    if props.modSpoilers ~= nil then
        SetVehicleMod(vehicle, 0, props.modSpoilers, false)
    end
    if props.modFrontBumper ~= nil then
        SetVehicleMod(vehicle, 1, props.modFrontBumper, false)
    end
    if props.modRearBumper ~= nil then
        SetVehicleMod(vehicle, 2, props.modRearBumper, false)
    end
    if props.modSideSkirt ~= nil then
        SetVehicleMod(vehicle, 3, props.modSideSkirt, false)
    end
    if props.modExhaust ~= nil then
        SetVehicleMod(vehicle, 4, props.modExhaust, false)
    end
    if props.modFrame ~= nil then
        SetVehicleMod(vehicle, 5, props.modFrame, false)
    end
    if props.modGrille ~= nil then
        SetVehicleMod(vehicle, 6, props.modGrille, false)
    end
    if props.modHood ~= nil then
        SetVehicleMod(vehicle, 7, props.modHood, false)
    end
    if props.modFender ~= nil then
        SetVehicleMod(vehicle, 8, props.modFender, false)
    end
    if props.modRightFender ~= nil then
        SetVehicleMod(vehicle, 9, props.modRightFender, false)
    end
    if props.modRoof ~= nil then
        SetVehicleMod(vehicle, 10, props.modRoof, false)
    end
    if props.modRoofLivery ~= nil then
        SetVehicleRoofLivery(vehicle, props.modRoofLivery)
    end
    if props.modEngine ~= nil then
        SetVehicleMod(vehicle, 11, props.modEngine, false)
    end
    if props.modBrakes ~= nil then
        SetVehicleMod(vehicle, 12, props.modBrakes, false)
    end
    if props.modTransmission ~= nil then
        SetVehicleMod(vehicle, 13, props.modTransmission, false)
    end
    if props.modHorns ~= nil then
        SetVehicleMod(vehicle, 14, props.modHorns, false)
    end
    if props.modSuspension ~= nil then
        SetVehicleMod(vehicle, 15, props.modSuspension, false)
    end
    if props.modArmor ~= nil then
        SetVehicleMod(vehicle, 16, props.modArmor, false)
    end
    if props.modTurbo ~= nil then
        ToggleVehicleMod(vehicle, 18, props.modTurbo)
    end
    if props.modXenon ~= nil then
        ToggleVehicleMod(vehicle, 22, props.modXenon)
    end
    if props.modFrontWheels ~= nil then
        SetVehicleMod(vehicle, 23, props.modFrontWheels, props.modCustomFrontWheels)
    end
    if props.modBackWheels ~= nil then
        SetVehicleMod(vehicle, 24, props.modBackWheels, props.modCustomBackWheels)
    end
    if props.modPlateHolder ~= nil then
        SetVehicleMod(vehicle, 25, props.modPlateHolder, false)
    end
    if props.modVanityPlate ~= nil then
        SetVehicleMod(vehicle, 26, props.modVanityPlate, false)
    end
    if props.modTrimA ~= nil then
        SetVehicleMod(vehicle, 27, props.modTrimA, false)
    end
    if props.modOrnaments ~= nil then
        SetVehicleMod(vehicle, 28, props.modOrnaments, false)
    end
    if props.modDashboard ~= nil then
        SetVehicleMod(vehicle, 29, props.modDashboard, false)
    end
    if props.modDial ~= nil then
        SetVehicleMod(vehicle, 30, props.modDial, false)
    end
    if props.modDoorSpeaker ~= nil then
        SetVehicleMod(vehicle, 31, props.modDoorSpeaker, false)
    end
    if props.modSeats ~= nil then
        SetVehicleMod(vehicle, 32, props.modSeats, false)
    end
    if props.modSteeringWheel ~= nil then
        SetVehicleMod(vehicle, 33, props.modSteeringWheel, false)
    end
    if props.modShifterLeavers ~= nil then
        SetVehicleMod(vehicle, 34, props.modShifterLeavers, false)
    end
    if props.modAPlate ~= nil then
        SetVehicleMod(vehicle, 35, props.modAPlate, false)
    end
    if props.modSpeakers ~= nil then
        SetVehicleMod(vehicle, 36, props.modSpeakers, false)
    end
    if props.modTrunk ~= nil then
        SetVehicleMod(vehicle, 37, props.modTrunk, false)
    end
    if props.modHydrolic ~= nil then
        SetVehicleMod(vehicle, 38, props.modHydrolic, false)
    end
    if props.modEngineBlock ~= nil then
        SetVehicleMod(vehicle, 39, props.modEngineBlock, false)
    end
    if props.modAirFilter ~= nil then
        SetVehicleMod(vehicle, 40, props.modAirFilter, false)
    end
    if props.modStruts ~= nil then
        SetVehicleMod(vehicle, 41, props.modStruts, false)
    end
    if props.modArchCover ~= nil then
        SetVehicleMod(vehicle, 42, props.modArchCover, false)
    end
    if props.modAerials ~= nil then
        SetVehicleMod(vehicle, 43, props.modAerials, false)
    end
    if props.modTrimB ~= nil then
        SetVehicleMod(vehicle, 44, props.modTrimB, false)
    end
    if props.modTank ~= nil then
        SetVehicleMod(vehicle, 45, props.modTank, false)
    end
    if props.modWindows ~= nil then
        SetVehicleMod(vehicle, 46, props.modWindows, false)
    end
    if props.modLivery ~= nil then
        SetVehicleMod(vehicle, 48, props.modLivery, false)
        SetVehicleLivery(vehicle, props.modLivery)
    end
    if props.windowsBroken ~= nil then
        for k, v in pairs(props.windowsBroken) do
            if v then
                RemoveVehicleWindow(vehicle, tonumber(k))
            end
        end
    end
    if props.doorsBroken ~= nil then
        for k, v in pairs(props.doorsBroken) do
            if v then
                SetVehicleDoorBroken(vehicle, tonumber(k), true)
            end
        end
    end
    if props.tyreBurst ~= nil then
        for k, v in pairs(props.tyreBurst) do
            if v then
                SetVehicleTyreBurst(vehicle, tonumber(k), true, 1000.0)
            end
        end
    end
end

ESX.Game.Utils.DrawText2D = function(text, x, y, size)
	SetTextScale(size, size)
	SetTextFont(4)
	SetTextProportional(1)
	SetTextEntry('STRING')
	SetTextCentre(1)
	SetTextColour(255, 255, 255, 255)
	SetTextOutline()
	AddTextComponentString(text)
	DrawText(x, y)
end

ESX.Game.Utils.DrawText3D = function(coords, text, size, font)
    local vector = type(coords) == 'vector3' and coords or vec(coords.x, coords.y, coords.z)
    local camCoords = GetFinalRenderedCamCoord()
    local distance = #(vector - camCoords)

    size = size or 1
    font = font or 0

    local scale = (size / distance) * 2
    local fov = (1 / GetGameplayCamFov()) * 100
    scale = scale * fov

    SetTextScale(0.0, 0.55 * scale)
    SetTextFont(font)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    BeginTextCommandDisplayText('STRING')
    SetTextCentre(true)
    AddTextComponentSubstringPlayerName(text)
    SetDrawOrigin(vector.xyz, 0)
    EndTextCommandDisplayText(0.0, 0.0)
    ClearDrawOrigin()
end

ESX.Game.Draw3DText = function(x, y, z, text, distance, v3)
    local dist = distance or 7
    local aze, zea, aez = table.unpack(GetGameplayCamCoords())
    local plyCoords = GetEntityCoords(PlayerPedId())
    local distance = GetDistanceBetweenCoords(aze, zea, aez, x, y, z, 1)
    local Text3D = GetDistanceBetweenCoords((plyCoords), x, y, z, 1) - 1.65
    local scale, fov = ((1 / distance) * (dist * .7)) * (1 / GetGameplayCamFov()) * 100, 255;

    if Text3D < dist then
        fov = math.floor(255 * ((dist - Text3D) / dist))
    elseif Text3D >= dist then
        fov = 0
    end

    fov = v3 or fov
    SetTextFont(0)
    SetTextScale(.0 * scale, .1 * scale)
    SetTextColour(255, 255, 255, math.max(0, math.min(255, fov)))
    SetTextCentre(1)
    SetDrawOrigin(x, y, z, 0)
    SetTextEntry('STRING')
    AddTextComponentString(text)
    DrawText(0.0, 0.0)
    ClearDrawOrigin()
end