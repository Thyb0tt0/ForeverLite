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
        local newValue = not FT.db.nameplates.healthText

        local setting = Settings.GetSetting(
            "ForeverTweaks_NameplateHealthText"
        )

        if setting then
            setting:SetValue(newValue)
        else
            FT.db.nameplates.healthText = newValue

            if FT.Nameplates then
                FT.Nameplates:Refresh()
            end
        end

    else
        print("|cff33ff99ForeverTweaks|r: Unknown command.")
        print("Use |cffffff00/ft|r to open settings.")
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

    print("|cff33ff99ForeverTweaks|r loaded.")
end)