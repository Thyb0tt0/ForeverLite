local addonName, FT = ...

FT.Nameplates = FT.Nameplates or {}

local Nameplates = FT.Nameplates


-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

local function IsNamePlateUnit(unit)
    return type(unit) == "string"
        and unit:match("^nameplate%d+$") ~= nil
end


local function GetHealthLabel(unit)
    local namePlate = C_NamePlate.GetNamePlateForUnit(unit)

    if not namePlate then
        return nil
    end

    -- Use Blizzard's health-bar container when available.
    -- This keeps our text above the actual health-bar texture.
    local parent = namePlate

    if namePlate.UnitFrame
        and namePlate.UnitFrame.HealthBarsContainer then
        parent = namePlate.UnitFrame.HealthBarsContainer
    end

    -- Create the FontString only once for this pooled nameplate.
    if not namePlate.ForeverTweaksHealthText then
        local label = parent:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

        label:SetDrawLayer("OVERLAY", 7)

        label:SetTextColor(1, 1, 1)
        label:SetShadowColor(0, 0, 0, 1)
        label:SetShadowOffset(1, -1)

        namePlate.ForeverTweaksHealthText = label
    end

    local label = namePlate.ForeverTweaksHealthText

    -- Reposition every time so changing the setting takes effect
    -- immediately on already-visible nameplates.
    label:ClearAllPoints()

    if FT.db
        and FT.db.nameplates.healthPosition == "center" then

        label:SetPoint(
            "CENTER",
            parent,
            "CENTER",
            0,
            0
        )
    else
        label:SetPoint(
            "LEFT",
            parent,
            "LEFT",
            3,
            0
        )
    end

    return label
end


local function HideHealthText(unit)
    local namePlate = C_NamePlate.GetNamePlateForUnit(unit)

    if not namePlate then
        return
    end

    local label = namePlate.ForeverTweaksHealthText

    if label then
        label:Hide()
    end
end


-- ------------------------------------------------------------
-- Health updating
-- ------------------------------------------------------------

local function UpdateHealthText(unit)
    if not FT.db then
        return
    end

    if not FT.db.nameplates.healthText then
        return
    end

    if not IsNamePlateUnit(unit) then
        return
    end

    local label = GetHealthLabel(unit)

    if not label then
        return
    end

    local format = FT.db.nameplates.healthFormat

    if format == "percentage" then
        local healthPercent = UnitHealthPercent(
            unit,
            true,
            CurveConstants.ScaleTo100
        )

        label:SetFormattedText(
            "%.0f%%",
            healthPercent
        )

    elseif format == "both" then
        local health = UnitHealth(unit)

        local healthPercent = UnitHealthPercent(
            unit,
            true,
            CurveConstants.ScaleTo100
        )

        local abbreviatedHealth = AbbreviateNumbers(health)

        label:SetFormattedText(
            "%s - %.0f%%",
            abbreviatedHealth,
            healthPercent
        )

    else
        local health = UnitHealth(unit)
        local abbreviatedHealth = AbbreviateNumbers(health)

        label:SetText(abbreviatedHealth)
    end

    label:Show()
end


-- ------------------------------------------------------------
-- Refresh currently visible nameplates
-- ------------------------------------------------------------

function Nameplates:Refresh()
    if not FT.db then
        return
    end

    local namePlates = C_NamePlate.GetNamePlates()

    for _, namePlate in ipairs(namePlates) do
        local unit = namePlate.unitToken

        if unit then
            if FT.db.nameplates.healthText then
                UpdateHealthText(unit)
            else
                local label = namePlate.ForeverTweaksHealthText

                if label then
                    label:Hide()
                end
            end
        end
    end
end


-- ------------------------------------------------------------
-- Events
-- ------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
eventFrame:RegisterEvent("UNIT_HEALTH")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        UpdateHealthText(unit)

    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local unit = ...
        HideHealthText(unit)

    elseif event == "UNIT_HEALTH" then
        local unit = ...
        UpdateHealthText(unit)
    end
end)