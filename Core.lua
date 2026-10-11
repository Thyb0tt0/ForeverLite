local addonName, FL = ...

FL.name = addonName


-- ------------------------------------------------------------
-- Database
-- ------------------------------------------------------------

local function InitializeDatabase()
    ForeverLiteDB = ForeverLiteDB or {}

    ForeverLiteDB.nameplates = ForeverLiteDB.nameplates or {}

    if ForeverLiteDB.nameplates.healthText == nil then
        ForeverLiteDB.nameplates.healthText = false
    end

    if ForeverLiteDB.nameplates.healthFormat == nil then
        ForeverLiteDB.nameplates.healthFormat = "remaining"
    end

    if ForeverLiteDB.nameplates.healthPosition == nil then
        ForeverLiteDB.nameplates.healthPosition = "left"
    end

    if ForeverLiteDB.nameplates.normalSelectedScale == nil then
        ForeverLiteDB.nameplates.normalSelectedScale = false
    end

    ForeverLiteDB.experience = ForeverLiteDB.experience or {}

    if ForeverLiteDB.experience.enabled == nil then
        ForeverLiteDB.experience.enabled = false
    end

    if ForeverLiteDB.experience.showXPBarText == nil then
        ForeverLiteDB.experience.showXPBarText =
            C_CVar.GetCVarBool("xpBarText")
    end

    if ForeverLiteDB.experience.point == nil then
        ForeverLiteDB.experience.point = "CENTER"
    end

    if ForeverLiteDB.experience.relativePoint == nil then
        ForeverLiteDB.experience.relativePoint = "CENTER"
    end

    if ForeverLiteDB.experience.x == nil then
        ForeverLiteDB.experience.x = 0
    end

    if ForeverLiteDB.experience.y == nil then
        ForeverLiteDB.experience.y = 160
    end

    ForeverLiteDB.merchant = ForeverLiteDB.merchant or {}

    if ForeverLiteDB.merchant.autoRepair == nil then
        ForeverLiteDB.merchant.autoRepair = false
    end

    if ForeverLiteDB.merchant.autoSellJunk == nil then
        ForeverLiteDB.merchant.autoSellJunk = false
    end

    ForeverLiteDB.tooltips = ForeverLiteDB.tooltips or {}

    if ForeverLiteDB.tooltips.colorPlayerClass == nil then
        ForeverLiteDB.tooltips.colorPlayerClass = false
    end

    ForeverLiteDB.menu = ForeverLiteDB.menu or {}

    if ForeverLiteDB.menu.point == nil then
        ForeverLiteDB.menu.point = "CENTER"
    end

    if ForeverLiteDB.menu.relativePoint == nil then
        ForeverLiteDB.menu.relativePoint = "CENTER"
    end

    if ForeverLiteDB.menu.x == nil then
        ForeverLiteDB.menu.x = 0
    end

    if ForeverLiteDB.menu.y == nil then
        ForeverLiteDB.menu.y = 0
    end

    ForeverLiteDB.reminders = ForeverLiteDB.reminders or {}

    if ForeverLiteDB.reminders.enabled == nil then
        ForeverLiteDB.reminders.enabled = false
    end

    if ForeverLiteDB.reminders.x == nil then
        ForeverLiteDB.reminders.x = 0
    end

    if ForeverLiteDB.reminders.y == nil then
        ForeverLiteDB.reminders.y = 120
    end

    FL.db = ForeverLiteDB
end


-- ------------------------------------------------------------
-- Slash commands
-- ------------------------------------------------------------

SLASH_FOREVERLITE1 = "/fl"
SLASH_FOREVERLITE2 = "/foreverlite"

SlashCmdList["FOREVERLITE"] = function(message)
    message = strtrim(string.lower(message or ""))

    if message == "" then
        if FL.Menu then
            FL.Menu:Toggle()
        end

    elseif message == "settings" then
        FL:OpenSettings()

    elseif message == "help" then
        print("|cff33ff99ForeverLite|r commands:")
        print("|cffffff00/fl|r - Toggle addon menu")
        print("|cffffff00/fl help|r - List of all commands")
        print("|cffffff00/fl settings|r - Open addon settings")
        print("|cffffff00/fl health|r - Toggle nameplate health")
        print("|cffffff00/fl xp|r - Toggle XP tracker")
        print("|cffffff00/fl xp reset|r - Reset XP tracker session")
        print("|cffffff00/fl xp unlock|r - Unlock XP tracker position")
        print("|cffffff00/fl xp lock|r - Lock XP tracker position")
        print("|cffffff00/fl xp center|r - Reset XP tracker position")
        print("|cffffff00/fl reminders unlock|r - Unlock buff reminders")
        print("|cffffff00/fl reminders lock|r - Lock buff reminders")
        print("|cffffff00/fl reminders center|r - Reset reminder position")

    elseif message == "health" then
        local newValue =
            not FL.db.nameplates.healthText

        local setting = Settings.GetSetting(
            "ForeverLite_NameplateHealthText"
        )

        if setting then
            setting:SetValue(newValue)
        else
            FL.db.nameplates.healthText =
                newValue

            if FL.Nameplates then
                FL.Nameplates:Refresh()
            end
        end

    elseif message == "xp" then
        local newValue =
            not FL.db.experience.enabled

        local setting = Settings.GetSetting(
            "ForeverLite_ExperienceEnabled"
        )

        if setting then
            setting:SetValue(newValue)
        else
            FL.db.experience.enabled =
                newValue

            if FL.Experience then
                FL.Experience:Refresh()
            end
        end

    elseif message == "xp reset" then
        if FL.Experience then
            FL.Experience:Reset()

            print(
                "|cff33ff99ForeverLite|r: "
                .. "XP tracker reset."
            )
        end

    elseif message == "xp unlock" then
        if not FL.db.experience.enabled then
            print(
                "|cff33ff99ForeverLite|r: "
                .. "Enable the XP tracker before unlocking it."
            )

            return
        end

        if FL.Experience then
            FL.Experience:SetUnlocked(true)

            print(
                "|cff33ff99ForeverLite|r: "
                .. "XP tracker unlocked. "
                .. "Drag it with the left mouse button."
            )
        end

    elseif message == "xp lock" then
        if FL.Experience then
            FL.Experience:SetUnlocked(false)

            print(
                "|cff33ff99ForeverLite|r: "
                .. "XP tracker locked."
            )
        end

    elseif message == "xp center" then
        if FL.Experience then
            FL.Experience:ResetPosition()

            print(
                "|cff33ff99ForeverLite|r: "
                .. "XP tracker position reset."
            )
        end

    elseif message == "reminders unlock" then
        if not FL.db.reminders.enabled then
            print(
                "|cff33ff99ForeverLite|r: "
                .. "Enable buff reminders before unlocking them."
            )

            return
        end

        if FL.Reminders then
            FL.Reminders:SetUnlocked(true)

            print(
                "|cff33ff99ForeverLite|r: "
                .. "Buff reminders unlocked. "
                .. "Drag them with the left mouse button."
            )
        end

    elseif message == "reminders lock" then
        if FL.Reminders then
            FL.Reminders:SetUnlocked(false)

            print(
                "|cff33ff99ForeverLite|r: "
                .. "Buff reminders locked."
            )
        end

    elseif message == "reminders center" then
        if FL.Reminders then
            FL.Reminders:ResetPosition()

            print(
                "|cff33ff99ForeverLite|r: "
                .. "Buff reminder position reset."
            )
        end

    else
        print(
            "|cff33ff99ForeverLite|r: Unknown command. "
            .. "Use |cffffff00/fl help|r for available commands."
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

    if FL.Nameplates then
        FL.Nameplates:ApplySelectedScale()
    end

    if FL.InitializeSettings then
        FL:InitializeSettings()
    end

    if FL.Menu then
        FL.Menu:Initialize()
    end
end)