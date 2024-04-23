ESX.CurrentRequestId = 0
ESX.ServerCallbacks = {}
ESX.ClientCallbacks = {}

ESX.TriggerServerCallback = function(name, cb, ...)
    ESX.ServerCallbacks[ESX.CurrentRequestId] = cb
    TriggerServerEvent('esx:triggerServerCallback', name, ESX.CurrentRequestId, ...)

    if ESX.CurrentRequestId < 65535 then
        ESX.CurrentRequestId = ESX.CurrentRequestId + 1
    else
        ESX.CurrentRequestId = 0
    end
end

RegisterNetEvent('esx:serverCallback')
AddEventHandler('esx:serverCallback', function(requestId, ...)
    if not requestId then
		print('requestId nul esx:serverCallback')
		return
	end

	if not ESX.ServerCallbacks[requestId] then
		print('esx:serverCallback callback inconnu : ' .. requestId)
		return
	end

    ESX.ServerCallbacks[requestId](...)
    ESX.ServerCallbacks[requestId] = nil
end)

ESX.RegisterClientCallback = function(eventName, callback)
    ESX.ClientCallbacks[eventName] = callback
end

RegisterNetEvent('esx:triggerClientCallback', function(eventName, requestId, invoker, ...)
    if not ESX.ClientCallbacks[eventName] then
        return print(('Callback client inconnue ! Callback : ^5%s^7, Resource : ^5%s^7'):format(eventName, invoker))
    end

    ESX.ClientCallbacks[eventName](function(...)
        TriggerServerEvent('esx:clientCallback', requestId, invoker, ...)
    end, ...)
end)