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


    Settings.RegisterAddOnCategory(category)
end


function FT:OpenSettings()
    if FT.settingsCategory then
        Settings.OpenToCategory(FT.settingsCategory:GetID())
    end
end