Locales = {}

function Translate(str, ...)
    if Locales[Config.Locale] ~= nil then
        if Locales[Config.Locale][str] ~= nil then
            return string.format(Locales[Config.Locale][str], ...)
        else
            return 'Texte inconnu [' .. Config.Locale .. '][' .. str .. ']'
        end
    else
        return 'Texte inconnu [' .. Config.Locale .. ']'
    end
end

function TranslateCap(str, ...)
    return tostring(_(str, ...):gsub('^%l', string.upper))
end

_ = Translate
_U = TranslateCap