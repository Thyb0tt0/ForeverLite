local addonName, FL = ...


function FL:InitializeSettings()
    local category = Settings.RegisterVerticalLayoutCategory("ForeverLite")

    FL.settingsCategory = category


    -- Show health text
    local healthTextSetting = Settings.RegisterAddOnSetting(
        category,
        "ForeverLite_NameplateHealthText",
        "healthText",
        FL.db.nameplates,
        Settings.VarType.Boolean,
        "Show health on nameplates",
        false
    )

    healthTextSetting:SetValueChangedCallback(function(_, value)
        if FL.Nameplates then
            FL.Nameplates:Refresh()
        end
    end)

    Settings.CreateCheckbox(
        category,
        healthTextSetting,
        "Displays the unit's health directly on its nameplate."
    )


    -- Health format
    local healthFormatSetting = Settings.RegisterAddOnSetting(
        category,
        "ForeverLite_NameplateHealthFormat",
        "healthFormat",
        FL.db.nameplates,
        Settings.VarType.String,
        "Health format",
        "remaining"
    )

    local function GetHealthFormatOptions()
        local container = Settings.CreateControlTextContainer()

        container:Add(
            "remaining",
            "Remaining health",
            "Displays values such as 245, 1.3K, or 12K."
        )

        container:Add(
            "percentage",
            "Percentage",
            "Displays values such as 27%."
        )

        container:Add(
            "both",
            "Remaining health + percentage",
            "Displays values such as 746 - 63%."
        )

        return container:GetData()
    end

    healthFormatSetting:SetValueChangedCallback(function(_, value)
        if FL.Nameplates then
            FL.Nameplates:Refresh()
        end
    end)

    Settings.CreateDropdown(
        category,
        healthFormatSetting,
        GetHealthFormatOptions,
        "Choose how health is displayed on nameplates."
    )

    -- --------------------------------------------------------
    -- Health position
    -- --------------------------------------------------------

    local healthPositionSetting = Settings.RegisterAddOnSetting(
        category,
        "ForeverLite_NameplateHealthPosition",
        "healthPosition",
        FL.db.nameplates,
        Settings.VarType.String,
        "Health position",
        "left"
    )

    local function GetHealthPositionOptions()
        local container = Settings.CreateControlTextContainer()

        container:Add(
            "left",
            "Left",
            "Displays health on the left side of the nameplate."
        )

        container:Add(
            "center",
            "Center",
            "Displays health in the center of the nameplate."
        )

        return container:GetData()
    end

    healthPositionSetting:SetValueChangedCallback(function(_, value)
        if FL.Nameplates then
            FL.Nameplates:Refresh()
        end
    end)

    Settings.CreateDropdown(
        category,
        healthPositionSetting,
        GetHealthPositionOptions,
        "Choose where health is displayed on the nameplate."
    )

    -- --------------------------------------------------------
    -- XP tracker
    -- --------------------------------------------------------

    local experienceEnabledSetting =
        Settings.RegisterAddOnSetting(
            category,
            "ForeverLite_ExperienceEnabled",
            "enabled",
            FL.db.experience,
            Settings.VarType.Boolean,
            "Show XP tracker",
            false
        )

    experienceEnabledSetting:SetValueChangedCallback(
        function(_, value)
            if FL.Experience then
                FL.Experience:Refresh()
            end
        end
    )

Settings.CreateCheckbox(
    category,
    experienceEnabledSetting,
    "Shows your session XP per hour and estimated time to level."
)

local showXPBarTextSetting =
    Settings.RegisterAddOnSetting(
        category,
        "ForeverLite_ExperienceShowXPBarText",
        "showXPBarText",
        FL.db.experience,
        Settings.VarType.Boolean,
        "Always show XP bar text",
        C_CVar.GetCVarBool("xpBarText")
    )

showXPBarTextSetting:SetValueChangedCallback(
    function(_, value)
        C_CVar.SetCVar(
            "xpBarText",
            value and 1 or 0
        )
    end
)

Settings.CreateCheckbox(
    category,
    showXPBarTextSetting,
    "Always displays your current and required XP on the experience bar."
)


-- --------------------------------------------------------
-- Merchant
-- --------------------------------------------------------

local autoRepairSetting =
    Settings.RegisterAddOnSetting(
        category,
        "ForeverLite_MerchantAutoRepair",
        "autoRepair",
        FL.db.merchant,
        Settings.VarType.Boolean,
        "Automatically repair equipment",
        false
    )

Settings.CreateCheckbox(
    category,
    autoRepairSetting,
    "Automatically repairs damaged equipment when visiting a repair vendor."
)


local autoSellJunkSetting =
    Settings.RegisterAddOnSetting(
        category,
        "ForeverLite_MerchantAutoSellJunk",
        "autoSellJunk",
        FL.db.merchant,
        Settings.VarType.Boolean,
        "Automatically sell junk",
        false
    )

Settings.CreateCheckbox(
    category,
    autoSellJunkSetting,
    "Automatically sells gray-quality items when visiting a merchant."
)


-- --------------------------------------------------------
-- Tooltips
-- --------------------------------------------------------

local colorPlayerClassSetting =
    Settings.RegisterAddOnSetting(
        category,
        "ForeverLite_TooltipsColorPlayerClass",
        "colorPlayerClass",
        FL.db.tooltips,
        Settings.VarType.Boolean,
        "Color player tooltips",
        false
    )

Settings.CreateCheckbox(
    category,
    colorPlayerClassSetting,
    "Colors player names by class and styles guild names."
)


-- --------------------------------------------------------
-- Reminders
-- --------------------------------------------------------

local remindersEnabledSetting =
    Settings.RegisterAddOnSetting(
        category,
        "ForeverLite_RemindersEnabled",
        "enabled",
        FL.db.reminders,
        Settings.VarType.Boolean,
        "Show missing buff reminders",
        false
    )

remindersEnabledSetting:SetValueChangedCallback(
    function(_, value)
        if FL.Reminders then
            FL.Reminders:Refresh()
        end
    end
)

Settings.CreateCheckbox(
    category,
    remindersEnabledSetting,
    "Shows an icon when an important personal buff is missing."
)



Settings.RegisterAddOnCategory(category)
end


function FL:OpenSettings()
    if FL.settingsCategory then
        Settings.OpenToCategory(FL.settingsCategory:GetID())
    end
end