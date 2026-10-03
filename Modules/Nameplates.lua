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

    -- Create the label only once for each pooled nameplate frame.
    if not namePlate.ForeverTweaksHealthText then
        local label = namePlate:CreateFontString(
            nil,
            "OVERLAY",
            "GameFontNormalSmall"
        )

        label:SetTextColor(1, 1, 1)

        label:SetShadowColor(0, 0, 0, 1)
        label:SetShadowOffset(1, -1)

        local anchor = namePlate

        if namePlate.UnitFrame
            and namePlate.UnitFrame.HealthBarsContainer then
            anchor = namePlate.UnitFrame.HealthBarsContainer
        end

        label:SetPoint(
            "CENTER",
            anchor,
            "CENTER",
            0,
            0
        )

        namePlate.ForeverTweaksHealthText = label
    end

    return namePlate.ForeverTweaksHealthText
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

    local health = UnitHealth(unit)

    local abbreviatedHealth = AbbreviateNumbers(health)

    label:SetText(abbreviatedHealth)
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