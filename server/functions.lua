ESX.RegisterCommand = function(name, group, cb, allowConsole, suggestion)
    if type(name) == 'table' then
        for k, v in ipairs(name) do
            ESX.RegisterCommand(v, group, cb, allowConsole, suggestion)
        end

        return
    end

    if ESX.RegisteredCommands[name] then
        print(('[^3ATTENTION^7] La commande %s est déja enregister sur le serveur, réécriture !'):format(name))

        if ESX.RegisteredCommands[name].suggestion then
            TriggerClientEvent('chat:removeSuggestion', -1, ('/%s'):format(name))
        end
    end

    if suggestion then
        if not suggestion.arguments then
            suggestion.arguments = {}
        end

        if not suggestion.help then
            suggestion.help = ''
        end

        TriggerClientEvent('chat:addSuggestion', -1, ('/%s'):format(name), suggestion.help, suggestion.arguments)
    end

    ESX.RegisteredCommands[name] = {
        group = group,
        cb = cb,
        allowConsole = allowConsole,
        suggestion = suggestion
    }

    RegisterCommand(name, function(playerId, args, rawCommand)
        local command = ESX.RegisteredCommands[name]

        if not command.allowConsole and playerId == 0 then
            print(('[^3ATTENTION^7] %s'):format('La commande n\'est pas utilisable dans la console !'))
        else
            local xPlayer, error = ESX.GetPlayerFromId(playerId), nil

            if command.suggestion then
                if command.suggestion.validate then
                    if #args ~= #command.suggestion.arguments then
                        error = tostring('Argument count mismatch (passed %s, wanted %s)'):format(#args, #command.suggestion.arguments)
                    
                        if #command.suggestion.arguments == 1 and (command.suggestion.arguments[1].type == 'player' or command.suggestion.arguments[1].type == 'playerId') then
							error = nil
						end
                    end
                end

                if not error and command.suggestion.arguments then
                    local newArgs = {}

                    for k, v in ipairs(command.suggestion.arguments) do
                        if v.type then
                            if v.type == 'number' then
                                local newArg = tonumber(args[k])

                                if newArg then
                                    newArgs[v.name] = newArg
                                else
                                    error = tostring('Argument #%s type mismatch (passed string, wanted number)'):format(k)
                                end
                            elseif v.type == 'player' or v.type == 'playerId' then
                                local targetPlayer = tonumber(args[k])

                                if args[k] == 'me' then
                                    targetPlayer = playerId
                                end

								if #command.suggestion.arguments == 1 and #args == 0 then
									targetPlayer = playerId
								end

                                if targetPlayer then
                                    local xTargetPlayer = ESX.GetPlayerFromId(targetPlayer)

                                    if xTargetPlayer then
                                        if v.type == 'player' then
                                            newArgs[v.name] = xTargetPlayer
                                        else
                                            newArgs[v.name] = targetPlayer
                                        end
                                    else
                                        error = tostring('PlayerId invalide')
                                    end
                                else
                                    error = tostring('Argument #%s type mismatch (passed string, wanted number)'):format(k)
                                end
                            elseif v.type == 'string' then
                                newArgs[v.name] = args[k]
                            elseif v.type == 'boolean' or v.type == 'bool' then
								newArgs[v.name] = args[k] == 1 or args[k] == 'true' or args[k] == '1'
                            elseif v.type == 'item' then
                                if ESX.Items[args[k]] then
                                    newArgs[v.name] = args[k]
                                else
                                    error = xPlayer.showNotification('Item invalide')
                                end
                            elseif v.type == 'any' then
                                newArgs[v.name] = args[k]
                            elseif v.type == 'coordinate' then
                                local coord = tonumber(args[k]:match('(-?%d+%.?%d*)'))

                                if not coord then
                                    error = tostring('Argument #%s type mismatch (passed string, wanted number)'):format(k)
                                else
                                    newArgs[v.name] = coord
                                end
                            end
                        end

                        if error then
                            break
                        end
                    end

                    args = newArgs
                end
            end

            if error then
                if playerId == 0 then
                    print(('[^3WARNING^7] %s^7'):format(error))
                else
                    xPlayer.triggerEvent('chatMessage', 'SYSTEM ', {255, 0, 0}, error)
                end
            else
                cb(xPlayer or false, args, function(msg)
                    if playerId == 0 then
                        print(('[^3WARNING^7] %s^7'):format(msg))
                    else
                        xPlayer.triggerEvent('chatMessage', 'SYSTEM ', {255, 0, 0}, msg)
                    end
                end)
            end
        end
    end, true)

    if type(group) == 'table' then
        for k, v in ipairs(ESX.Groups) do
            ExecuteCommand(('add_ace group.%s command.%s allow'):format(v, name))
        end
    else
        ExecuteCommand(('add_ace group.%s command.%s allow'):format(group, name))
    end
end

ESX.SavePlayer = function(xPlayer, cb)
    MySQL.Async.execute('UPDATE players SET accounts = @accounts, job = @job, job_grade = @job_grade, `group` = @group, position = @position, inventory = @inventory WHERE identifier = @identifier', {
        ['@accounts'] = json.encode(xPlayer.getAccounts(true)),
        ['@job'] = xPlayer.job.name,
        ['@job_grade'] = xPlayer.job.grade,
        ['@group'] = xPlayer.getGroup(),
        ['@position'] = json.encode(xPlayer.getCoords()),
        ['@identifier'] = xPlayer.getIdentifier(),
        ['@inventory'] = json.encode(xPlayer.getInventory(true))
    }, cb)
end

ESX.SavePlayers = function(cb)
    local xPlayers = ESX.GetPlayers()

    for i = 1, #xPlayers, 1 do
        local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

        ESX.SavePlayer(xPlayer, cb)
    end
end

ESX.StartDBSync = function()
    function saveData()
        ESX.SavePlayers()
        SetTimeout(10 * 60 * 1000, saveData)
    end

    SetTimeout(10 * 60 * 1000, saveData)
end

ESX.GetPlayers = function()
    local sources = {}

    for k, v in pairs(ESX.Players) do
        table.insert(sources, k)
    end

    return sources
end

ESX.GetExtendedPlayers = function(key, val)
    local xPlayers = {}

    if type(val) == 'table' then
        for _, v in pairs(ESX.Players) do
            checkTable(key, val, v, xPlayers)
        end
    else
        for _, v in pairs(ESX.Players) do
            if key then
                if (key == 'job' and v.job.name == val) or v[key] == val then
                    xPlayers[#xPlayers + 1] = v
                end
            else
                xPlayers[#xPlayers + 1] = v
            end
        end
    end

    return xPlayers
end

ESX.GetPlayerFromId = function(source)
    return ESX.Players[tonumber(source)]
end

ESX.GetPlayerFromIdentifier = function(identifier)
    for k, v in pairs(ESX.Players) do
        if v.identifier == identifier then
            return v
        end
    end
end

ESX.RegisterUsableItem = function(item, cb)
    ESX.UsableItemsCallbacks[item] = cb
end

ESX.UseItem = function(source, item, ...)
    if ESX.Items[item] then
        local itemCallback = ESX.UsableItemsCallbacks[item]

        if itemCallback then
            local success, result = pcall(itemCallback, source, item, ...)

            if not success then
                return result and print(result) or print(('[^3ATTENTION^7] Une erreur s\'est produite lors de l\'item ^5%s^7 ! Cette erreur n\'est pas causé par ESX.'):format(item))
            end
        end
    else
        print(('[^3ATTENTION^7] L\'item ^5%s^7 est introuvable dans la base de données serveur !'):format(item))
    end
end

ESX.GetItemLabel = function(item)
    if ESX.Items[item] then
        return ESX.Items[item].label
    else
        print(('[^3ATTENTION^7] Tentative d\'obtention d\'un item invalide -> ^5%s^7'):format(item))
    end
end

ESX.CreatePickup = function(type, name, count, label, playerId)
	local pickupId = (ESX.PickupId == 65635 and 0 or ESX.PickupId + 1)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	local coords = xPlayer.getCoords()

	ESX.Pickups[pickupId] = {
		type = type, name = name,
		count = count, label = label,
		coords = coords
	}

	TriggerClientEvent('esx:createPickup', -1, pickupId, label, coords)
	ESX.PickupId = pickupId
end

ESX.DoesJobExist = function(job, grade)
    grade = tostring(grade)

    if job and grade then
        if ESX.Jobs[job] and ESX.Jobs[job].grades[grade] then
            return true
        end
    end

    return false
end

ESX.RefreshJobs = function()
    local Jobs = {}
    local jobs = MySQL.query.await('SELECT * FROM jobs')

    for _, v in ipairs(jobs) do
        Jobs[v.name] = v
        Jobs[v.name].grades = {}
    end

    local jobGrades = MySQL.query.await('SELECT * FROM job_grades')

    for _, v in ipairs(jobGrades) do
        if Jobs[v.job_name] then
            Jobs[v.job_name].grades[tostring(v.grade)] = v
        else
            print(('[^3ATTENTION^7] Grade ignoré: ^5%s^0, job inconnu !'):format(v.job_name))
        end
    end

    for _, v in pairs(Jobs) do
        if ESX.Table.SizeOf(v.grades) == 0 then
            Jobs[v.name] = nil
            print(('[^3ATTENTION^7] Job ignoré: ^5%s^0, grade inconnu !'):format(v.name))
        end
    end

    if not Jobs then
        ESX.Jobs['unemployed'] = {
            label = 'Unemployed',
            grades = {
                ['0'] = {
                    grade = 0,
                    label = 'Chomeur',
                    salary = 25,
                    skin_male = {},
                    skin_female = {}
                }
            }
        }
    else
        ESX.Jobs = Jobs
    end
end

ESX.GetVehicleType = function(model, player, cb)
    model = type(model) == 'string' and joaat(model) or model

    if ESX.vehicleTypesByModel[model] then
        return cb(ESX.vehicleTypesByModel[model])
    end

    ESX.TriggerClientCallback(player, 'esx:GetVehicleType', function(vehicleType)
        ESX.vehicleTypesByModel[model] = vehicleType
        cb(vehicleType)
    end, model)
end