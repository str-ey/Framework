ESX.OneSync = {}

local function getNearbyPlayers(source, closest, distance, ignore)
    local result = {}
    local count = 0
    local playerPed
    local playerCoords

    if not distance then
        distance = 100
    end

    if type(source) == 'number' then
        playerPed = GetPlayerPed(source)

        if not source then
            return result
        end

        playerCoords = GetEntityCoords(playerPed)

        if not playerCoords then
            return result
        end
    end

    if type(source) == 'vector3' then
        playerCoords = source

        if not playerCoords then
            return result
        end
    end

    for _, xPlayer in pairs(ESX.Players) do
        if not ignore or not ignore[xPlayer.source] then
            local entity = GetPlayerPed(xPlayer.source)
            local coords = GetEntityCoords(entity)

            if not closest then
                local dist = #(playerCoords - coords)

                if dist <= distance then
                    count = count + 1
                    result[count] = {
                        id = xPlayer.source,
                        ped = NetworkGetNetworkIdFromEntity(entity),
                        coords = coords,
                        dist = dist
                    }
                end
            else
                if xPlayer.source ~= source then
                    local dist = #(playerCoords - coords)

                    if dist <= (result.dist or distance) then
                        result = {
                            id = xPlayer.source,
                            ped = NetworkGetNetworkIdFromEntity(entity),
                            coords = coords,
                            dist = dist
                        }
                    end
                end
            end
        end
    end

    return result
end

ESX.OneSync.GetClosestPlayer = function(source, maxDistance, ignore)
    return getNearbyPlayers(source, true, maxDistance, ignore)
end

ESX.OneSync.SpawnVehicle = function(model, coords, heading, properties, cb)
    local vehicleModel = GetHashKey(model)
    local vehicleProperties = properties

    CreateThread(function()
        local xPlayer = ESX.OneSync.GetClosestPlayer(coords, 300)

        ESX.GetVehicleType(vehicleModel, xPlayer.id, function(vehicleType)
            local xPlayer = ESX.GetPlayerFromId(source)

            if vehicleType then
                local createdVehicle = CreateVehicleServerSetter(vehicleModel, vehicleType, coords, heading)

                if not DoesEntityExist(createdVehicle) then
                    return
                end

                local networkId = NetworkGetNetworkIdFromEntity(createdVehicle)

                Entity(createdVehicle).state:set('VehicleProperties', vehicleProperties, true)
                cb(networkId)
            else
                xPlayer.triggerEvent('chatMessage', 'SYSTEM ', {255, 0, 0}, 'Le modèle ~r~'..model..'~s~ est invalide !')
            end
        end)
    end)
end