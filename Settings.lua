local addonName, FT = ...


function FT:InitializeSettings()
    local category = Settings.RegisterVerticalLayoutCategory("ForeverTweaks")

    FT.settingsCategory = category


    -- Show health text
    local healthTextSetting = Settings.RegisterAddOnSetting(
        category,
        "ForeverTweaks_NameplateHealthText",
        "healthText",
        FT.db.nameplates,
        Settings.VarType.Boolean,
        "Show health on nameplates",
        false
    )

    healthTextSetting:SetValueChangedCallback(function(_, value)
        if FT.Nameplates then
            FT.Nameplates:Refresh()
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
        "ForeverTweaks_NameplateHealthFormat",
        "healthFormat",
        FT.db.nameplates,
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
        if FT.Nameplates then
            FT.Nameplates:Refresh()
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
        "ForeverTweaks_NameplateHealthPosition",
        "healthPosition",
        FT.db.nameplates,
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
        if FT.Nameplates then
            FT.Nameplates:Refresh()
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
            "ForeverTweaks_ExperienceEnabled",
            "enabled",
            FT.db.experience,
            Settings.VarType.Boolean,
            "Show XP tracker",
            false
        )

    experienceEnabledSetting:SetValueChangedCallback(
        function(_, value)
            if FT.Experience then
                FT.Experience:Refresh()
            end
        end
    )

Settings.CreateCheckbox(
    category,
    experienceEnabledSetting,
    "Shows your session XP per hour and estimated time to level."
)


-- --------------------------------------------------------
-- Merchant
-- --------------------------------------------------------

local autoRepairSetting =
    Settings.RegisterAddOnSetting(
        category,
        "ForeverTweaks_MerchantAutoRepair",
        "autoRepair",
        FT.db.merchant,
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
        "ForeverTweaks_MerchantAutoSellJunk",
        "autoSellJunk",
        FT.db.merchant,
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
        "ForeverTweaks_TooltipsColorPlayerClass",
        "colorPlayerClass",
        FT.db.tooltips,
        Settings.VarType.Boolean,
        "Enhance player tooltips",
        false
    )

Settings.CreateCheckbox(
    category,
    colorPlayerClassSetting,
    "Improves player tooltips with class colors and guild styling."
)


Settings.RegisterAddOnCategory(category)
end


function FT:OpenSettings()
    if FT.settingsCategory then
        Settings.OpenToCategory(FT.settingsCategory:GetID())
    end
end