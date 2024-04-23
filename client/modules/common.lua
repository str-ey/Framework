exports('getSharedObject', function()
    return ESX
end)

AddEventHandler('esx:getSharedObject', function(cb)
    local Invoke = GetInvokingResource()

    print(('[^1ERREUR^7] La resource: ^5%s^7 utilise l\'évènement: ^5getSharedObject^7 côter client !'):format(Invoke))
end)