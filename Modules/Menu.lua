local _, FT = ...

FT.Menu = FT.Menu or {}

local Menu = FT.Menu


-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

local function SetSetting(name, value)
    local setting = Settings.GetSetting(name)

    if setting then
        setting:SetValue(value)
    end
end


local function CreateSection(parent, text, y)
    local label = parent:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )

    label:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        20,
        y
    )

    label:SetText(text)

    local line = parent:CreateTexture(
        nil,
        "ARTWORK"
    )

    line:SetHeight(1)

    line:SetPoint(
        "LEFT",
        label,
        "RIGHT",
        10,
        0
    )

    line:SetPoint(
        "RIGHT",
        parent,
        "RIGHT",
        -20,
        0
    )

    line:SetColorTexture(
        0.25,
        0.25,
        0.30,
        0.8
    )
end


local function CreateCheckboxRow(
    parent,
    text,
    y,
    onClick
)
    local row = CreateFrame(
        "Frame",
        nil,
        parent
    )

    row:SetHeight(28)

    row:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        28,
        y
    )

    row:SetPoint(
        "TOPRIGHT",
        parent,
        "TOPRIGHT",
        -28,
        y
    )


    local label = row:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )

    label:SetPoint(
        "LEFT",
        row,
        "LEFT",
        0,
        0
    )

    label:SetText(text)


    local checkbox = CreateFrame(
        "CheckButton",
        nil,
        row,
        "UICheckButtonTemplate"
    )

    checkbox:SetPoint(
        "RIGHT",
        row,
        "RIGHT",
        0,
        0
    )

    checkbox:SetScript(
        "OnClick",
        function(self)
            onClick(self:GetChecked())
        end
    )

    return checkbox
end


local function CreateDropdownRow(
    parent,
    text,
    y,
    defaultText
)
    local row = CreateFrame(
        "Frame",
        nil,
        parent
    )

    row:SetHeight(28)

    row:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        28,
        y
    )

    row:SetPoint(
        "TOPRIGHT",
        parent,
        "TOPRIGHT",
        -28,
        y
    )


    local label = row:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )

    label:SetPoint(
        "LEFT",
        row,
        "LEFT",
        0,
        0
    )

    label:SetText(text)


    local dropdown = CreateFrame(
        "DropdownButton",
        nil,
        row,
        "WowStyle1DropdownTemplate"
    )

    dropdown:SetSize(
        210,
        24
    )

    dropdown:SetPoint(
        "RIGHT",
        row,
        "RIGHT",
        0,
        0
    )

    dropdown:SetDefaultText(
        defaultText
    )

    return dropdown
end


-- ------------------------------------------------------------
-- Main frame
-- ------------------------------------------------------------

local frame = CreateFrame(
    "Frame",
    "ForeverTweaksMenu",
    UIParent,
    "BackdropTemplate"
)

frame:SetSize(
    380,
    440
)

frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:SetFrameStrata("DIALOG")
frame:SetToplevel(true)

frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 16,
    edgeSize = 14,
    insets = {
        left = 3,
        right = 3,
        top = 3,
        bottom = 3,
    },
})

frame:SetBackdropColor(
    0.03,
    0.03,
    0.04,
    0.97
)

frame:SetBackdropBorderColor(
    0.35,
    0.35,
    0.40,
    1
)

frame:Hide()


table.insert(
    UISpecialFrames,
    "ForeverTweaksMenu"
)


-- ------------------------------------------------------------
-- Title bar
-- ------------------------------------------------------------

local titleBar = CreateFrame(
    "Frame",
    nil,
    frame
)

titleBar:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    4,
    -4
)

titleBar:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -4,
    -4
)

titleBar:SetHeight(30)

titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")


local titleBackground =
    titleBar:CreateTexture(
        nil,
        "BACKGROUND"
    )

titleBackground:SetAllPoints()

titleBackground:SetColorTexture(
    0.06,
    0.06,
    0.08,
    1
)


local titleText =
    titleBar:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormalLarge"
    )

titleText:SetPoint(
    "LEFT",
    titleBar,
    "LEFT",
    10,
    0
)

titleText:SetText(
    FT.name or "ForeverTweaks"
)


local titleLine =
    frame:CreateTexture(
        nil,
        "ARTWORK"
    )

titleLine:SetHeight(1)

titleLine:SetPoint(
    "TOPLEFT",
    titleBar,
    "BOTTOMLEFT",
    0,
    0
)

titleLine:SetPoint(
    "TOPRIGHT",
    titleBar,
    "BOTTOMRIGHT",
    0,
    0
)

titleLine:SetColorTexture(
    0.30,
    0.30,
    0.35,
    1
)


local closeButton = CreateFrame(
    "Button",
    nil,
    frame,
    "UIPanelCloseButton"
)

closeButton:SetPoint(
    "TOPRIGHT",
    frame,
    "TOPRIGHT",
    -2,
    -2
)


-- ------------------------------------------------------------
-- Position
-- ------------------------------------------------------------

local function ApplySavedPosition()
    if not FT.db then
        return
    end

    local db = FT.db.menu

    frame:ClearAllPoints()

    frame:SetPoint(
        db.point or "CENTER",
        UIParent,
        db.relativePoint or "CENTER",
        db.x or 0,
        db.y or 0
    )
end


local function SavePosition()
    if not FT.db then
        return
    end

    local point, _, relativePoint, x, y =
        frame:GetPoint(1)

    local db = FT.db.menu

    db.point = point or "CENTER"
    db.relativePoint = relativePoint or "CENTER"
    db.x = x or 0
    db.y = y or 0
end


titleBar:SetScript(
    "OnDragStart",
    function()
        frame:StartMoving()
    end
)


titleBar:SetScript(
    "OnDragStop",
    function()
        frame:StopMovingOrSizing()
        SavePosition()
    end
)


-- ------------------------------------------------------------
-- Nameplates
-- ------------------------------------------------------------

CreateSection(
    frame,
    "Nameplates",
    -53
)


local healthCheckbox =
    CreateCheckboxRow(
        frame,
        "Show health on nameplates",
        -72,
        function(value)
            SetSetting(
                "ForeverTweaks_NameplateHealthText",
                value
            )
        end
    )


local healthFormatDropdown =
    CreateDropdownRow(
        frame,
        "Health format",
        -105,
        "Remaining health"
    )


healthFormatDropdown:SetupMenu(
    function(dropdown, rootDescription)
        local function IsSelected(value)
            return FT.db
                and FT.db.nameplates
                and FT.db.nameplates.healthFormat == value
        end

        local function SetSelected(value)
            if not FT.db then
                return
            end

            SetSetting(
                "ForeverTweaks_NameplateHealthFormat",
                value
            )
        end

        rootDescription:CreateRadio(
            "Remaining health",
            IsSelected,
            SetSelected,
            "remaining"
        )

        rootDescription:CreateRadio(
            "Percentage",
            IsSelected,
            SetSelected,
            "percentage"
        )

        rootDescription:CreateRadio(
            "Remaining health + percentage",
            IsSelected,
            SetSelected,
            "both"
        )
    end
)


local healthPositionDropdown =
    CreateDropdownRow(
        frame,
        "Health position",
        -136,
        "Left"
    )


healthPositionDropdown:SetupMenu(
    function(dropdown, rootDescription)
        local function IsSelected(value)
            return FT.db
                and FT.db.nameplates
                and FT.db.nameplates.healthPosition == value
        end

        local function SetSelected(value)
            if not FT.db then
                return
            end

            SetSetting(
                "ForeverTweaks_NameplateHealthPosition",
                value
            )
        end

        rootDescription:CreateRadio(
            "Left",
            IsSelected,
            SetSelected,
            "left"
        )

        rootDescription:CreateRadio(
            "Center",
            IsSelected,
            SetSelected,
            "center"
        )
    end
)


-- ------------------------------------------------------------
-- Experience
-- ------------------------------------------------------------

CreateSection(
    frame,
    "Experience",
    -179
)


local experienceCheckbox =
    CreateCheckboxRow(
        frame,
        "Show XP tracker",
        -198,
        function(value)
            SetSetting(
                "ForeverTweaks_ExperienceEnabled",
                value
            )
        end
    )


-- ------------------------------------------------------------
-- Merchant
-- ------------------------------------------------------------

CreateSection(
    frame,
    "Vendor",
    -241
)


local autoRepairCheckbox =
    CreateCheckboxRow(
        frame,
        "Automatically repair equipment",
        -260,
        function(value)
            SetSetting(
                "ForeverTweaks_MerchantAutoRepair",
                value
            )
        end
    )


local autoSellCheckbox =
    CreateCheckboxRow(
        frame,
        "Automatically sell junk",
        -291,
        function(value)
            SetSetting(
                "ForeverTweaks_MerchantAutoSellJunk",
                value
            )
        end
    )


-- ------------------------------------------------------------
-- Tooltips
-- ------------------------------------------------------------

CreateSection(
    frame,
    "Tooltips",
    -334
)


local tooltipCheckbox =
    CreateCheckboxRow(
        frame,
        "Enhance player tooltips",
        -353,
        function(value)
            SetSetting(
                "ForeverTweaks_TooltipsColorPlayerClass",
                value
            )
        end
    )


-- ------------------------------------------------------------
-- Bottom controls
-- ------------------------------------------------------------

local bottomLine =
    frame:CreateTexture(
        nil,
        "ARTWORK"
    )

bottomLine:SetHeight(1)

bottomLine:SetPoint(
    "BOTTOMLEFT",
    frame,
    "BOTTOMLEFT",
    18,
    50
)

bottomLine:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -18,
    50
)

bottomLine:SetColorTexture(
    0.25,
    0.25,
    0.30,
    0.8
)


local settingsButton = CreateFrame(
    "Button",
    nil,
    frame,
    "UIPanelButtonTemplate"
)

settingsButton:SetSize(
    135,
    24
)

settingsButton:SetPoint(
    "BOTTOMLEFT",
    frame,
    "BOTTOMLEFT",
    18,
    15
)

settingsButton:SetText(
    "Addon Settings"
)

settingsButton:SetScript(
    "OnClick",
    function()
        FT:OpenSettings()
    end
)


local reloadButton = CreateFrame(
    "Button",
    nil,
    frame,
    "UIPanelButtonTemplate"
)

reloadButton:SetSize(
    105,
    24
)

reloadButton:SetPoint(
    "BOTTOMRIGHT",
    frame,
    "BOTTOMRIGHT",
    -18,
    15
)

reloadButton:SetText(
    "Reload UI"
)

reloadButton:SetScript(
    "OnClick",
    function()
        ReloadUI()
    end
)


-- ------------------------------------------------------------
-- Public functions
-- ------------------------------------------------------------

function Menu:Refresh()
    if not FT.db then
        return
    end

    healthCheckbox:SetChecked(
        FT.db.nameplates.healthText
    )

    experienceCheckbox:SetChecked(
        FT.db.experience.enabled
    )

    autoRepairCheckbox:SetChecked(
        FT.db.merchant.autoRepair
    )

    autoSellCheckbox:SetChecked(
        FT.db.merchant.autoSellJunk
    )

    tooltipCheckbox:SetChecked(
        FT.db.tooltips.colorPlayerClass
    )

    -- If a setting was changed from Blizzard Settings,
    -- refresh the dropdown text when our menu opens.
    healthFormatDropdown:GenerateMenu()
    healthPositionDropdown:GenerateMenu()
end


function Menu:Toggle()
    if frame:IsShown() then
        frame:Hide()
    else
        ApplySavedPosition()
        self:Refresh()
        frame:Show()
    end
end


function Menu:Initialize()
    ApplySavedPosition()
    self:Refresh()
end