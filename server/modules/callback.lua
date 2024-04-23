ESX.ServerCallbacks = {}
ESX.ClientCallbacks = {}
ESX.RequestId = 0

RegisterServerEvent('esx:triggerServerCallback')
AddEventHandler('esx:triggerServerCallback', function(name, requestId, ...)
	local playerId = source

	ESX.TriggerServerCallback(name, requestId, playerId, function(...)
		TriggerClientEvent('esx:serverCallback', playerId, requestId, ...)
	end, ...)
end)

ESX.RegisterServerCallback = function(name, cb)
    ESX.ServerCallbacks[name] = cb
end

ESX.TriggerServerCallback = function(name, requestId, source, cb, ...)
    if ESX.ServerCallbacks[name] then
        ESX.ServerCallbacks[name](source, cb, ...)
    else
        print(('[^3ATTENTION^7] Le callback serveur %s est introuvable !'):format(name))
    end
end

ESX.TriggerClientCallback = function(player, eventName, callback, ...)
    ESX.ClientCallbacks[ESX.RequestId] = callback

    TriggerClientEvent('esx:triggerClientCallback', player, eventName, ESX.RequestId, GetInvokingResource() or 'inconnue', ...)

    ESX.RequestId = ESX.RequestId + 1
end

RegisterNetEvent('esx:clientCallback', function(requestId, invoker, ...)
    if not ESX.ClientCallbacks[requestId] then
        return print(('Callback client avec requestId : ^5%s^7 à été demander par la resource : ^5%s^7 !'):format(requestId, invoker))
    end

    ESX.ClientCallbacks[requestId](...)
    ESX.ClientCallbacks[requestId] = nil
end)