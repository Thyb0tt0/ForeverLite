local _, FL = ...

FL.Reminders = FL.Reminders or {}

local Reminders = FL.Reminders


-- ------------------------------------------------------------
-- Display
-- ------------------------------------------------------------

local ICON_SIZE = 48
local ICON_GAP = 10
local DISPLAY_HEIGHT = 70
local MAX_REMINDERS = 3

local unlocked = false

local battleShoutExpiresAt = 0
local battleShoutTimerToken = 0

local auraStateCache = {}
local auraNameToCacheKey = {}


local BATTLE_SHOUT_SPELLS = {
    25289, -- Rank 7
    11551, -- Rank 6
    11550, -- Rank 5
    11549, -- Rank 4
    6192,  -- Rank 3
    5242,  -- Rank 2
    6673,  -- Rank 1
}

local DEFAULT_BATTLE_SHOUT_DURATION = 180
local battleShoutDuration = DEFAULT_BATTLE_SHOUT_DURATION

local BATTLE_SHOUT_LOOKUP = {}

for _, spellID in ipairs(BATTLE_SHOUT_SPELLS) do
    BATTLE_SHOUT_LOOKUP[spellID] = true
end


local frame = CreateFrame(
    "Frame",
    "ForeverLiteReminderFrame",
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
    320
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
    if not FL.db then
        return
    end

    local db = FL.db.reminders

    frame:ClearAllPoints()

    frame:SetPoint(
        "CENTER",
        UIParent,
        "CENTER",
        db.x or 0,
        db.y or 320
    )
end


local function SavePosition()
    if not FL.db then
        return
    end

    local frameX, frameY =
        frame:GetCenter()

    local uiX, uiY =
        UIParent:GetCenter()

    if not frameX
        or not frameY
        or not uiX
        or not uiY then
        return
    end

    local db = FL.db.reminders

    db.x = frameX - uiX
    db.y = frameY - uiY

    -- Normalize the anchor immediately so resizing the
    -- reminder group always happens around its center.
    ApplySavedPosition()
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


local function GetAuraCacheKey(spellIDs)
    return table.concat(
        spellIDs,
        ":"
    )
end


local function RegisterAuraNames(
    spellIDs,
    cacheKey
)
    for _, spellID in ipairs(spellIDs) do
        local spellName =
            C_Spell.GetSpellName(
                spellID
            )

        if spellName then
            auraNameToCacheKey[spellName] =
                cacheKey
        end
    end
end


local function HasAnyAura(
    spellIDs,
    cacheKey
)
    cacheKey =
        cacheKey
        or GetAuraCacheKey(
            spellIDs
        )

    -- Aura information is restricted during combat.
    -- Use the last trustworthy state instead.
    if UnitAffectingCombat("player") then
        local cachedState =
            auraStateCache[cacheKey]

        -- If combat somehow began before we ever got
        -- a trustworthy reading, avoid a false warning.
        if cachedState == nil then
            return true
        end

        return cachedState
    end


    for _, spellID in ipairs(spellIDs) do
        local spellName =
            C_Spell.GetSpellName(
                spellID
            )

        if spellName then
            local aura =
                C_UnitAuras.GetAuraDataBySpellName(
                    "player",
                    spellName,
                    "HELPFUL"
                )

            if aura then
                auraStateCache[cacheKey] = true
                return true
            end
        end
    end


    auraStateCache[cacheKey] = false
    return false
end


local function AddSpellReminder(
    reminders,
    knownSpellIDs,
    auraSpellIDs,
    label
)
    local knownSpell =
        GetKnownSpell(
            knownSpellIDs
        )

    if not knownSpell then
        return
    end


    local cacheKey =
        GetAuraCacheKey(
            auraSpellIDs
        )

    -- Register spell names so successful casts can
    -- update the cached state during combat.
    RegisterAuraNames(
        knownSpellIDs,
        cacheKey
    )

    RegisterAuraNames(
        auraSpellIDs,
        cacheKey
    )


    if HasAnyAura(
        auraSpellIDs,
        cacheKey
    ) then
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
-- Warrior Battle Shout
-- ------------------------------------------------------------

local function UpdateBattleShoutState()
    local spellName =
        C_Spell.GetSpellName(
            6673
        )

    if not spellName then
        battleShoutExpiresAt = 0
        return
    end


    local aura =
        C_UnitAuras.GetAuraDataBySpellName(
            "player",
            spellName,
            "HELPFUL"
        )

    if not aura then
        battleShoutExpiresAt = 0
        return
    end


    local duration =
        aura.duration

    if duration
        and (
            not issecretvalue
            or not issecretvalue(
                duration
            )
        )
        and type(duration) == "number"
        and duration > 0 then

        battleShoutDuration =
            duration
    end


    local expirationTime =
        aura.expirationTime

    if expirationTime
        and (
            not issecretvalue
            or not issecretvalue(
                expirationTime
            )
        )
        and type(expirationTime) == "number"
        and expirationTime > 0 then

        battleShoutExpiresAt =
            expirationTime
    else
        -- Fallback if Forever does not expose the
        -- expiration timestamp for some reason.
        battleShoutExpiresAt =
            GetTime()
            + battleShoutDuration
    end
end


local function ScheduleBattleShoutExpiry()
    battleShoutTimerToken =
        battleShoutTimerToken + 1

    local timerToken =
        battleShoutTimerToken

    local delay =
        battleShoutExpiresAt
        - GetTime()

    if delay <= 0 then
        return
    end


    C_Timer.After(
        delay + 0.05,
        function()
            if timerToken
                ~= battleShoutTimerToken then

                return
            end

            if UnitAffectingCombat(
                "player"
            ) then

                Reminders:Refresh()
            end
        end
    )
end


local function AddBattleShoutReminder(
    reminders
)
    local knownSpell =
        GetKnownSpell(
            BATTLE_SHOUT_SPELLS
        )

    if not knownSpell then
        return
    end


    if battleShoutExpiresAt
        > GetTime() then

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
            label = "BUFF!",
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
-- Shaman weapon imbue
-- ------------------------------------------------------------

local SHAMAN_WEAPON_IMBUE_SPELLS = {
    -- Windfury Weapon
    16362,
    10486,
    8235,
    8232,

    -- Flametongue Weapon
    16342,
    16341,
    16339,
    8030,
    8027,
    8024,

    -- Frostbrand Weapon
    16356,
    16355,
    10456,
    8038,
    8033,

    -- Rockbiter Weapon
    16316,
    16315,
    16314,
    10399,
    8019,
    8018,
    8017,
}


local function AddShamanWeaponReminder(reminders)
    local knownImbue =
        GetKnownSpell(
            SHAMAN_WEAPON_IMBUE_SPELLS
        )

    if not knownImbue then
        return
    end

    if not WeaponNeedsTemporaryEnchant(
        16,
        Enum.WeaponSlot.MainHand
    ) then
        return
    end

    local icon =
        C_Spell.GetSpellTexture(
            knownImbue
        )

    if not icon then
        return
    end

    table.insert(
        reminders,
        {
            icon = icon,
            label = "IMBUE!",
        }
    )
end

-- ------------------------------------------------------------
-- Hunter
-- ------------------------------------------------------------

local HUNTER_CALL_PET_SPELL_ID = 883

local HUNTER_LONE_WOLF_SPELLS = {
    415370,
    409979,
}


local HUNTER_ASPECT_KNOWN_SPELLS = {
    -- Aspect of the Monkey
    13163,

    -- Aspect of the Hawk
    25296,
    14322,
    14321,
    14320,
    14319,
    14318,
    13165,

    -- Aspect of the Cheetah
    5118,

    -- Aspect of the Pack
    13159,

    -- Aspect of the Wild
    20190,
    20043,

    -- Aspect of the Beast
    1299447,
    1299446,
    1299445,
    13161,

    -- Forever Aspects
    469145, -- Aspect of the Falcon
    415423, -- Aspect of the Viper
}


local HUNTER_ASPECT_AURAS = {
    13163,  -- Monkey
    13165,  -- Hawk
    5118,   -- Cheetah
    13159,  -- Pack
    20043,  -- Wild
    13161,  -- Beast
    469145, -- Falcon
    415423, -- Viper
}


local function HasLoneWolf()
    return GetKnownSpell(
        HUNTER_LONE_WOLF_SPELLS
    ) ~= nil
end


local function AddHunterPetReminder(reminders)
    -- Pets are temporarily unavailable while using
    -- a flight path, so do not show a false warning.
    if UnitOnTaxi("player") then
        return
    end

    -- Do not remind before the Hunter has unlocked
    -- the normal pet system.
    if not C_SpellBook.IsSpellKnown(
        HUNTER_CALL_PET_SPELL_ID
    ) then
        return
    end

    -- Lone Wolf intentionally plays without a pet.
    if HasLoneWolf() then
        return
    end

    -- A living active pet means everything is fine.
    if UnitExists("pet")
        and not UnitIsDeadOrGhost("pet") then

        return
    end

    local icon =
        C_Spell.GetSpellTexture(
            HUNTER_CALL_PET_SPELL_ID
        )

    if not icon then
        return
    end

    table.insert(
        reminders,
        {
            icon = icon,
            label = "PET!",
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


    elseif class == "DRUID" then

        -- Mark of the Wild.
        -- Gift of the Wild also satisfies this reminder.
        AddSpellReminder(
            reminders,
            {
                9885, -- Rank 7
                9884, -- Rank 6
                8907, -- Rank 5
                5234, -- Rank 4
                6756, -- Rank 3
                5232, -- Rank 2
                1126, -- Rank 1
            },
            {
                1126,  -- Mark of the Wild
                21849, -- Gift of the Wild
            },
            "BUFF!"
        )


    elseif class == "HUNTER" then

        -- Any active Aspect satisfies this reminder.
        AddSpellReminder(
            reminders,
            HUNTER_ASPECT_KNOWN_SPELLS,
            HUNTER_ASPECT_AURAS,
            "ASPECT!"
        )


        -- Keep a living pet active unless Lone Wolf
        -- is selected.
        AddHunterPetReminder(
            reminders
        )


    elseif class == "WARLOCK" then

        -- Demon Skin / Demon Armor.
        -- Either one satisfies the reminder.
        AddSpellReminder(
            reminders,
            {
                11735, -- Demon Armor Rank 5
                11734, -- Demon Armor Rank 4
                11733, -- Demon Armor Rank 3
                1086,  -- Demon Armor Rank 2
                706,   -- Demon Armor Rank 1
                696,   -- Demon Skin Rank 2
                687,   -- Demon Skin Rank 1
            },
            {
                706, -- Demon Armor
                687, -- Demon Skin
            },
            "BUFF!"
        )


    elseif class == "ROGUE" then

        AddRogueReminder(
            reminders
        )

    elseif class == "PALADIN" then

        -- Any Paladin Aura satisfies this reminder.
        -- Devotion Aura is used as the reminder icon.
        AddSpellReminder(
            reminders,
            {
                10293, -- Devotion Aura Rank 7
                10292, -- Rank 6
                1032,  -- Rank 5
                10291, -- Rank 4
                643,   -- Rank 3
                10290, -- Rank 2
                465,   -- Rank 1
            },
            {
                465,   -- Devotion Aura
                7294,  -- Retribution Aura
                19746, -- Concentration Aura
                19876, -- Shadow Resistance Aura
                19888, -- Frost Resistance Aura
                19891, -- Fire Resistance Aura
            },
            "BUFF!"
        )

        -- Any normal long-duration Blessing satisfies this reminder.
        --
        -- Short situational Blessings such as Protection,
        -- Freedom, and Sacrifice deliberately do not count.
        AddSpellReminder(
            reminders,
            {
                -- Blessing of Might
                25291,
                19838,
                19837,
                19836,
                19835,
                19834,
                19740,

                -- Blessing of Wisdom
                25290,
                19854,
                19853,
                19852,
                19850,
                19742,

                -- Other long-duration Blessings
                20217, -- Kings
                1038,  -- Salvation
                19979, -- Light Rank 3
                19978, -- Light Rank 2
                19977, -- Light Rank 1
            },
            {
                -- Normal Blessings
                19740, -- Might
                19742, -- Wisdom
                20217, -- Kings
                1038,  -- Salvation
                19977, -- Light

                -- Greater Blessings
                25782, -- Greater Might
                25894, -- Greater Wisdom
                25898, -- Greater Kings
                25895, -- Greater Salvation
                25890, -- Greater Light
            },
            "BUFF!"
        )

    elseif class == "SHAMAN" then

        -- Keep a temporary imbue on the main-hand weapon.
        AddShamanWeaponReminder(
            reminders
        )


        -- Keep an Elemental Shield active.
        -- Water Shield and Earth Shield also satisfy
        -- the reminder when present on the player.
        AddSpellReminder(
            reminders,
            {
                10432, -- Lightning Shield Rank 7
                10431, -- Rank 6
                8134,  -- Rank 5
                945,   -- Rank 4
                905,   -- Rank 3
                325,   -- Rank 2
                324,   -- Rank 1
            },
            {
                324,    -- Lightning Shield
                408510, -- Water Shield
                408514, -- Earth Shield
            },
            "BUFF!"
        )

    elseif class == "WARRIOR" then

        if not UnitAffectingCombat(
            "player"
        ) then

            -- Aura information is trustworthy here,
            -- so remember the real expiration time.
            UpdateBattleShoutState()


        else
            AddBattleShoutReminder(
                reminders
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
        frame:SetSize(
            ICON_SIZE,
            DISPLAY_HEIGHT
        )

        if unlocked then
            frame:Show()
        else
            frame:Hide()
        end

        return
    end


    local totalWidth =
        (count * ICON_SIZE)
        + ((count - 1) * ICON_GAP)

    frame:SetSize(
        totalWidth,
        DISPLAY_HEIGHT
    )

    frame:Show()
end


-- ------------------------------------------------------------
-- Public functions
-- ------------------------------------------------------------

function Reminders:Refresh()
    if not FL.db
        or not FL.db.reminders.enabled then

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
    if not FL.db then
        return
    end

    local db = FL.db.reminders

    db.x = 0
    db.y = 320

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

eventFrame:RegisterUnitEvent(
    "UNIT_PET",
    "player"
)

eventFrame:RegisterUnitEvent(
    "UNIT_HEALTH",
    "pet"
)

eventFrame:RegisterEvent(
    "TRAIT_CONFIG_UPDATED"
)


eventFrame:SetScript(
    "OnEvent",
    function(_, event, ...)
        if event == "PLAYER_ENTERING_WORLD" then
            ApplySavedPosition()

            Reminders:Refresh()


        elseif event == "PLAYER_CONTROL_LOST"
            or event == "PLAYER_CONTROL_GAINED" then

            C_Timer.After(
                0,
                function()
                    Reminders:Refresh()
                end
            )


        elseif event == "PLAYER_REGEN_DISABLED" then
            ScheduleBattleShoutExpiry()

            Reminders:Refresh()


        elseif event == "PLAYER_REGEN_ENABLED" then
            -- Invalidate any pending combat expiry timer.
            battleShoutTimerToken =
                battleShoutTimerToken + 1

            Reminders:Refresh()


        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
            local unit, _, spellID = ...

            if unit == "player" then
                local shouldRefresh = false


                if BATTLE_SHOUT_LOOKUP[spellID] then
                    battleShoutExpiresAt =
                        GetTime()
                        + battleShoutDuration

                    if UnitAffectingCombat(
                        "player"
                    ) then
                        ScheduleBattleShoutExpiry()
                    end

                    shouldRefresh = true
                end


                local spellName =
                    C_Spell.GetSpellName(
                        spellID
                    )

                local cacheKey =
                    spellName
                    and auraNameToCacheKey[spellName]

                if cacheKey then
                    auraStateCache[cacheKey] = true
                    shouldRefresh = true
                end


                if shouldRefresh then
                    Reminders:Refresh()
                end
            end


        else
            Reminders:Refresh()
        end
    end
)
