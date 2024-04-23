ESX.StartPayCheck = function()
    function payCheck()
        local xPlayers = ESX.GetPlayers()

        for i = 1, #xPlayers, 1 do
            local xPlayer = ESX.GetPlayerFromId(xPlayers[i])
            local job = xPlayer.job.grade_name
            local salary = xPlayer.job.grade_salary

            if salary > 0 then
                if job == 'unemployed' then
                    xPlayer.addAccountMoney('bank', salary)
                    TriggerClientEvent('esx:showNotification', xPlayer.source, 'Jour de paye : ~g~+'..salary.. '$~s~')
                else
                    xPlayer.addAccountMoney('bank', salary)
                    TriggerClientEvent('esx:showNotification', xPlayer.source, 'Jour de paye : ~g~+'..salary.. '$~s~')
                end
            end
        end

        SetTimeout(Config.PaycheckInterval, payCheck)
    end

    SetTimeout(Config.PaycheckInterval, payCheck)
end