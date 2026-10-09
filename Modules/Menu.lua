local _, FT = ...

FT.Menu = FT.Menu or {}

local Menu = FT.Menu


-- ------------------------------------------------------------
-- Layout
-- ------------------------------------------------------------

local FRAME_WIDTH = 380

local CONTENT_LEFT = 28
local CONTENT_RIGHT = -28

local FIRST_SECTION_Y = -50
local SECTION_HEIGHT = 27
local SECTION_GAP = 4
local ROW_HEIGHT = 30

local FOOTER_SPACE = 70


-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

local function SetSetting(name, value)
    local setting = Settings.GetSetting(name)

    if setting then
        setting:SetValue(value)
    end
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

frame:SetWidth(FRAME_WIDTH)
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
-- Dynamic content layout
-- ------------------------------------------------------------

local cursorY = FIRST_SECTION_Y
local hasSection = false


local function AddSection(text)
    if hasSection then
        cursorY = cursorY - SECTION_GAP
    end

    local label = frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontNormal"
    )

    label:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        20,
        cursorY
    )

    label:SetText(text)


    local line = frame:CreateTexture(
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
        frame,
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


    cursorY = cursorY - SECTION_HEIGHT
    hasSection = true
end


local function AddCheckboxRow(
    text,
    onClick
)
    local row = CreateFrame(
        "Frame",
        nil,
        frame
    )

    row:SetHeight(28)

    row:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        CONTENT_LEFT,
        cursorY
    )

    row:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        CONTENT_RIGHT,
        cursorY
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


    cursorY = cursorY - ROW_HEIGHT

    return checkbox
end


local function AddDropdownRow(
    text,
    defaultText
)
    local row = CreateFrame(
        "Frame",
        nil,
        frame
    )

    row:SetHeight(28)

    row:SetPoint(
        "TOPLEFT",
        frame,
        "TOPLEFT",
        CONTENT_LEFT,
        cursorY
    )

    row:SetPoint(
        "TOPRIGHT",
        frame,
        "TOPRIGHT",
        CONTENT_RIGHT,
        cursorY
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


    cursorY = cursorY - ROW_HEIGHT

    return dropdown
end


-- ------------------------------------------------------------
-- Nameplates
-- ------------------------------------------------------------

AddSection("Nameplates")


local healthCheckbox =
    AddCheckboxRow(
        "Show health on nameplates",
        function(value)
            SetSetting(
                "ForeverTweaks_NameplateHealthText",
                value
            )
        end
    )


local healthFormatDropdown =
    AddDropdownRow(
        "Health format",
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
    AddDropdownRow(
        "Health position",
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

AddSection("Experience")


local experienceCheckbox =
    AddCheckboxRow(
        "Show XP tracker",
        function(value)
            SetSetting(
                "ForeverTweaks_ExperienceEnabled",
                value
            )
        end
    )


local xpBarTextCheckbox =
    AddCheckboxRow(
        "Always show XP bar text",
        function(value)
            SetSetting(
                "ForeverTweaks_ExperienceShowXPBarText",
                value
            )
        end
    )


-- ------------------------------------------------------------
-- Vendor
-- ------------------------------------------------------------

AddSection("Vendor")


local autoRepairCheckbox =
    AddCheckboxRow(
        "Automatically repair equipment",
        function(value)
            SetSetting(
                "ForeverTweaks_MerchantAutoRepair",
                value
            )
        end
    )


local autoSellCheckbox =
    AddCheckboxRow(
        "Automatically sell junk",
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

AddSection("Tooltips")


local tooltipCheckbox =
    AddCheckboxRow(
        "Color player tooltips",
        function(value)
            SetSetting(
                "ForeverTweaks_TooltipsColorPlayerClass",
                value
            )
        end
    )


-- ------------------------------------------------------------
-- Dynamic frame height
-- ------------------------------------------------------------

frame:SetHeight(
    math.abs(cursorY) + FOOTER_SPACE
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

    xpBarTextCheckbox:SetChecked(
        FT.db.experience.showXPBarText
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