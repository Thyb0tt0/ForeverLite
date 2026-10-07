local addonName, FT = ...

FT.name = addonName


-- ------------------------------------------------------------
-- Database
-- ------------------------------------------------------------

local function InitializeDatabase()
    ForeverTweaksDB = ForeverTweaksDB or {}

    ForeverTweaksDB.nameplates = ForeverTweaksDB.nameplates or {}

    if ForeverTweaksDB.nameplates.healthText == nil then
        ForeverTweaksDB.nameplates.healthText = false
    end

    if ForeverTweaksDB.nameplates.healthFormat == nil then
        ForeverTweaksDB.nameplates.healthFormat = "remaining"
    end

    if ForeverTweaksDB.nameplates.healthPosition == nil then
        ForeverTweaksDB.nameplates.healthPosition = "left"
    end

    ForeverTweaksDB.experience = ForeverTweaksDB.experience or {}

    if ForeverTweaksDB.experience.enabled == nil then
        ForeverTweaksDB.experience.enabled = false
    end

    if ForeverTweaksDB.experience.point == nil then
        ForeverTweaksDB.experience.point = "CENTER"
    end

    if ForeverTweaksDB.experience.relativePoint == nil then
        ForeverTweaksDB.experience.relativePoint = "CENTER"
    end

    if ForeverTweaksDB.experience.x == nil then
        ForeverTweaksDB.experience.x = 0
    end

    if ForeverTweaksDB.experience.y == nil then
        ForeverTweaksDB.experience.y = 160
    end

    ForeverTweaksDB.merchant = ForeverTweaksDB.merchant or {}

    if ForeverTweaksDB.merchant.autoRepair == nil then
        ForeverTweaksDB.merchant.autoRepair = false
    end

    if ForeverTweaksDB.merchant.autoSellJunk == nil then
        ForeverTweaksDB.merchant.autoSellJunk = false
    end

    FT.db = ForeverTweaksDB
end


-- ------------------------------------------------------------
-- Slash commands
-- ------------------------------------------------------------

SLASH_FOREVERTWEAKS1 = "/ft"
SLASH_FOREVERTWEAKS2 = "/forevertweaks"

SlashCmdList["FOREVERTWEAKS"] = function(message)
    message = strtrim(string.lower(message or ""))

    if message == "" then
        FT:OpenSettings()

    elseif message == "health" then
        local newValue =
            not FT.db.nameplates.healthText

        local setting = Settings.GetSetting(
            "ForeverTweaks_NameplateHealthText"
        )

        if setting then
            setting:SetValue(newValue)
        else
            FT.db.nameplates.healthText =
                newValue

            if FT.Nameplates then
                FT.Nameplates:Refresh()
            end
        end

    elseif message == "xp" then
        local newValue =
            not FT.db.experience.enabled

        local setting = Settings.GetSetting(
            "ForeverTweaks_ExperienceEnabled"
        )

        if setting then
            setting:SetValue(newValue)
        else
            FT.db.experience.enabled =
                newValue

            if FT.Experience then
                FT.Experience:Refresh()
            end
        end

    elseif message == "xp reset" then
        if FT.Experience then
            FT.Experience:Reset()

            print(
                "|cff33ff99ForeverTweaks|r: "
                .. "XP tracker reset."
            )
        end

    elseif message == "xp unlock" then
        if not FT.db.experience.enabled then
            print(
                "|cff33ff99ForeverTweaks|r: "
                .. "Enable the XP tracker before unlocking it."
            )

            return
        end

        if FT.Experience then
            FT.Experience:SetUnlocked(true)

            print(
                "|cff33ff99ForeverTweaks|r: "
                .. "XP tracker unlocked. "
                .. "Drag it with the left mouse button."
            )
        end

    elseif message == "xp lock" then
        if FT.Experience then
            FT.Experience:SetUnlocked(false)

            print(
                "|cff33ff99ForeverTweaks|r: "
                .. "XP tracker locked."
            )
        end

    elseif message == "xp center" then
        if FT.Experience then
            FT.Experience:ResetPosition()

            print(
                "|cff33ff99ForeverTweaks|r: "
                .. "XP tracker position reset."
            )
        end

    else
        print(
            "|cff33ff99ForeverTweaks|r: Unknown command."
        )

        print(
            "|cffffff00/ft|r - Open settings"
        )

        print(
            "|cffffff00/ft health|r - Toggle nameplate health"
        )

        print(
            "|cffffff00/ft xp|r - Toggle XP tracker"
        )

        print(
            "|cffffff00/ft xp reset|r - Reset XP session"
        )

        print(
            "|cffffff00/ft xp unlock|r - Unlock XP tracker"
        )

        print(
            "|cffffff00/ft xp lock|r - Lock XP tracker"
        )

        print(
            "|cffffff00/ft xp center|r - Reset tracker position"
        )
    end
end

-- ------------------------------------------------------------
-- Addon initialization
-- ------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= addonName then
        return
    end

    InitializeDatabase()

    if FT.InitializeSettings then
        FT:InitializeSettings()
    end

end)