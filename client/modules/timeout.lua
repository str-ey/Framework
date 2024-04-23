ESX.TimeoutCallbacks = {}

ESX.SetTimeout = function(msec, cb)
    table.insert(ESX.TimeoutCallbacks, {
        time = GetGameTimer() + msec,
        cb = cb
    })

    return #ESX.TimeoutCallbacks
end

ESX.ClearTimeout = function(i)
    ESX.TimeoutCallbacks[i] = nil
end

CreateThread(function()
    while true do
        Wait(1)
        local currTime = GetGameTimer()

        for i = 1, #ESX.TimeoutCallbacks, 1 do
            if ESX.TimeoutCallbacks[i] then
                if currTime >= ESX.TimeoutCallbacks[i].time then
                    ESX.TimeoutCallbacks[i].cb()
                    ESX.TimeoutCallbacks[i] = nil
                end
            end
        end
    end
end)