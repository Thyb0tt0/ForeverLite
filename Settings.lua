local addonName, FT = ...


function FT:InitializeSettings()
    local category = Settings.RegisterVerticalLayoutCategory("ForeverTweaks")

    FT.settingsCategory = category


    -- --------------------------------------------------------
    -- Nameplate health
    -- --------------------------------------------------------

    local setting = Settings.RegisterAddOnSetting(
        category,
        "ForeverTweaks_NameplateHealthText",
        "healthText",
        FT.db.nameplates,
        Settings.VarType.Boolean,
        "Show remaining health on nameplates",
        false
    )

    setting:SetValueChangedCallback(function(_, value)
        if FT.Nameplates then
            FT.Nameplates:Refresh()
        end
    end)

    Settings.CreateCheckbox(
        category,
        setting,
        "Displays the unit's remaining health directly on its nameplate."
    )


    Settings.RegisterAddOnCategory(category)
end


function FT:OpenSettings()
    if FT.settingsCategory then
        Settings.OpenToCategory(FT.settingsCategory:GetID())
    end
end