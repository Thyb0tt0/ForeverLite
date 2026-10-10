local _, FT = ...

FT.Reminders = FT.Reminders or {}

local Reminders = FT.Reminders


-- ------------------------------------------------------------
-- Display
-- ------------------------------------------------------------

local ICON_SIZE = 48
local ICON_GAP = 10
local DISPLAY_HEIGHT = 70
local MAX_REMINDERS = 3

local unlocked = false
local battleShoutCastThisCombat = false


local BATTLE_SHOUT_SPELLS = {
    25289, -- Rank 7
    11551, -- Rank 6
    11550, -- Rank 5
    11549, -- Rank 4
    6192,  -- Rank 3
    5242,  -- Rank 2
    6673,  -- Rank 1
}


local BATTLE_SHOUT_LOOKUP = {}

for _, spellID in ipairs(BATTLE_SHOUT_SPELLS) do
    BATTLE_SHOUT_LOOKUP[spellID] = true
end


local frame = CreateFrame(
    "Frame",
    "ForeverTweaksReminderFrame",
    UIParent
)

frame:SetSize(
    ICON_SIZE,
    DISPLAY_HEIGHT
)

frame:SetPoint(
    "CENTER",
    UIParent,
    "CENTER",
    0,
    120
)

frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(false)
frame:RegisterForDrag("LeftButton")

frame:Hide()


-- ------------------------------------------------------------
-- Unlock indicator
-- ------------------------------------------------------------

local moveBackground =
    frame:CreateTexture(
        nil,
        "BACKGROUND"
    )

moveBackground:SetAllPoints()

moveBackground:SetColorTexture(
    0,
    0,
    0,
    0.45
)

moveBackground:Hide()


local moveText =
    frame:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlightSmall"
    )

moveText:SetPoint(
    "BOTTOM",
    frame,
    "TOP",
    0,
    4
)

moveText:SetText(
    "Drag to move"
)

moveText:Hide()


-- ------------------------------------------------------------
-- Position
-- ------------------------------------------------------------

local function ApplySavedPosition()
    if not FT.db then
        return
    end

    local db = FT.db.reminders

    frame:ClearAllPoints()

    frame:SetPoint(
        db.point or "CENTER",
        UIParent,
        db.relativePoint or "CENTER",
        db.x or 0,
        db.y or 120
    )
end


local function SavePosition()
    if not FT.db then
        return
    end

    local point, _, relativePoint, x, y =
        frame:GetPoint(1)

    local db = FT.db.reminders

    db.point = point or "CENTER"
    db.relativePoint = relativePoint or "CENTER"
    db.x = x or 0
    db.y = y or 120
end


frame:SetScript(
    "OnDragStart",
    function(self)
        if unlocked then
            self:StartMoving()
        end
    end
)


frame:SetScript(
    "OnDragStop",
    function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end
)


-- ------------------------------------------------------------
-- Reminder displays
-- ------------------------------------------------------------

local displays = {}


for index = 1, MAX_REMINDERS do
    local display = CreateFrame(
        "Frame",
        nil,
        frame
    )

    display:SetSize(
        ICON_SIZE,
        DISPLAY_HEIGHT
    )


    local icon = display:CreateTexture(
        nil,
        "ARTWORK"
    )

    icon:SetSize(
        ICON_SIZE,
        ICON_SIZE
    )

    icon:SetPoint(
        "TOP",
        display,
        "TOP",
        0,
        0
    )

    -- Slightly zoom into the spell icon.
    icon:SetTexCoord(
        0.10,
        0.90,
        0.10,
        0.90
    )


    local text = display:CreateFontString(
        nil,
        "OVERLAY",
        "GameFontHighlight"
    )

    text:SetPoint(
        "TOP",
        icon,
        "BOTTOM",
        0,
        -3
    )

    text:SetShadowColor(
        0,
        0,
        0,
        1
    )

    text:SetShadowOffset(
        1,
        -1
    )


    display.icon = icon
    display.text = text

    display:Hide()

    displays[index] = display
end


-- ------------------------------------------------------------
-- Aura helpers
-- ------------------------------------------------------------

local function GetKnownSpell(spellIDs)
    for _, spellID in ipairs(spellIDs) do
        if C_SpellBook.IsSpellKnown(spellID) then
            return spellID
        end
    end

    return nil
end


local function HasAnyAura(spellIDs)
    for _, spellID in ipairs(spellIDs) do
        local spellName =
            C_Spell.GetSpellName(spellID)

        if spellName then
            local aura =
                C_UnitAuras.GetAuraDataBySpellName(
                    "player",
                    spellName,
                    "HELPFUL"
                )

            if aura then
                return true
            end
        end
    end

    return false
end


local function AddSpellReminder(
    reminders,
    knownSpellIDs,
    auraSpellIDs,
    label
)
    local knownSpell =
        GetKnownSpell(knownSpellIDs)

    if not knownSpell then
        return
    end

    if HasAnyAura(auraSpellIDs) then
        return
    end

    local icon =
        C_Spell.GetSpellTexture(
            knownSpell
        )

    if not icon then
        return
    end

    table.insert(
        reminders,
        {
            icon = icon,
            label = label or "BUFF!",
        }
    )
end


-- ------------------------------------------------------------
-- Rogue poison
-- ------------------------------------------------------------

local function HasTemporaryWeaponEnchant(weaponSlot)
    local enchants =
        C_Item.GetWeaponEnchantInfo(
            weaponSlot
        )

    if not enchants then
        return false
    end

    for _, enchant in ipairs(enchants) do
        if enchant.hasEnchant
            and (
                enchant.enchantType
                    == Enum.ItemEnchantType.Temporary
                or enchant.enchantType
                    == Enum.ItemEnchantType.Imbue
            ) then

            return true
        end
    end

    return false
end


local function WeaponNeedsTemporaryEnchant(
    inventorySlot,
    weaponSlot
)
    if not GetInventoryItemID(
        "player",
        inventorySlot
    ) then
        return false
    end

    return not HasTemporaryWeaponEnchant(
        weaponSlot
    )
end


local function AddRogueReminder(reminders)
    local POISONS_SPELL_ID = 2842

    if not C_SpellBook.IsSpellKnown(
        POISONS_SPELL_ID
    ) then
        return
    end

    local mainHandNeedsPoison =
        WeaponNeedsTemporaryEnchant(
            16,
            Enum.WeaponSlot.MainHand
        )

    local offHandNeedsPoison =
        WeaponNeedsTemporaryEnchant(
            17,
            Enum.WeaponSlot.OffHand
        )

    if not mainHandNeedsPoison
        and not offHandNeedsPoison then
        return
    end

    local icon =
        C_Spell.GetSpellTexture(
            POISONS_SPELL_ID
        )

    if not icon then
        return
    end

    table.insert(
        reminders,
        {
            icon = icon,
            label = "POISON!",
        }
    )
end


-- ------------------------------------------------------------
-- Class reminders
-- ------------------------------------------------------------

local function GetMissingReminders()
    local reminders = {}

    local _, class =
        UnitClass("player")


    if class == "PRIEST" then

        AddSpellReminder(
            reminders,
            { 1243 },
            {
                1243,
                21562,
            },
            "BUFF!"
        )

        AddSpellReminder(
            reminders,
            { 588 },
            { 588 },
            "BUFF!"
        )


    elseif class == "MAGE" then

        AddSpellReminder(
            reminders,
            { 1459 },
            {
                1459,
                23028,
            },
            "BUFF!"
        )

        AddSpellReminder(
            reminders,
            {
                6117,
                7302,
                168,
            },
            {
                168,
                7302,
                6117,
            },
            "BUFF!"
        )


    elseif class == "ROGUE" then

        AddRogueReminder(
            reminders
        )


    elseif class == "WARRIOR" then

        if UnitAffectingCombat("player")
            and not battleShoutCastThisCombat then

            AddSpellReminder(
                reminders,
                BATTLE_SHOUT_SPELLS,
                { 6673 },
                "BUFF!"
            )
        end
    end


    return reminders
end


-- ------------------------------------------------------------
-- Display updating
-- ------------------------------------------------------------

local function UpdateDisplay(reminders)
    local count =
        math.min(
            #reminders,
            MAX_REMINDERS
        )

    for index = 1, MAX_REMINDERS do
        local display =
            displays[index]

        local reminder =
            reminders[index]

        if index <= count
            and reminder then

            display.icon:SetTexture(
                reminder.icon
            )

            display.text:SetText(
                reminder.label
            )

            display:ClearAllPoints()

            display:SetPoint(
                "TOPLEFT",
                frame,
                "TOPLEFT",
                (index - 1)
                    * (ICON_SIZE + ICON_GAP),
                0
            )

            display:Show()
        else
            display:Hide()
        end
    end


    if count == 0 then
        if unlocked then
            frame:Show()
        else
            frame:Hide()
        end

        return
    end

    frame:Show()
end


-- ------------------------------------------------------------
-- Public functions
-- ------------------------------------------------------------

function Reminders:Refresh()
    if not FT.db
        or not FT.db.reminders.enabled then

        frame:Hide()
        return
    end

    if UnitIsDeadOrGhost("player") then
        frame:Hide()
        return
    end

    local reminders =
        GetMissingReminders()

    UpdateDisplay(
        reminders
    )
end


function Reminders:SetUnlocked(value)
    unlocked = value

    frame:EnableMouse(
        unlocked
    )

    if unlocked then
        moveBackground:Show()
        moveText:Show()

        self:Refresh()

        -- Keep a mover visible even when no buff
        -- is currently missing.
        frame:Show()
    else
        moveBackground:Hide()
        moveText:Hide()

        self:Refresh()
    end
end


function Reminders:ResetPosition()
    if not FT.db then
        return
    end

    local db = FT.db.reminders

    db.point = "CENTER"
    db.relativePoint = "CENTER"
    db.x = 0
    db.y = 120

    ApplySavedPosition()
end


-- ------------------------------------------------------------
-- Events
-- ------------------------------------------------------------

local eventFrame =
    CreateFrame("Frame")


eventFrame:RegisterEvent(
    "PLAYER_ENTERING_WORLD"
)

eventFrame:RegisterEvent(
    "SPELLS_CHANGED"
)

eventFrame:RegisterEvent(
    "PLAYER_REGEN_DISABLED"
)

eventFrame:RegisterEvent(
    "PLAYER_REGEN_ENABLED"
)

eventFrame:RegisterEvent(
    "UNIT_INVENTORY_CHANGED"
)

eventFrame:RegisterUnitEvent(
    "UNIT_AURA",
    "player"
)

eventFrame:RegisterUnitEvent(
    "UNIT_SPELLCAST_SUCCEEDED",
    "player"
)


eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            ApplySavedPosition()

            Reminders:Refresh()


        elseif event == "PLAYER_REGEN_DISABLED" then
            battleShoutCastThisCombat = false

            Reminders:Refresh()


        elseif event == "PLAYER_REGEN_ENABLED" then
            battleShoutCastThisCombat = false

            Reminders:Refresh()


        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...

            if unit == "player"
                and BATTLE_SHOUT_LOOKUP[spellID] then

                battleShoutCastThisCombat = true

                Reminders:Refresh()
            end


        else
            Reminders:Refresh()
        end
    end
)