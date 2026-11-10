local _, FL = ...

FL.Reminders = FL.Reminders or {}

local Reminders = FL.Reminders


-- ------------------------------------------------------------
-- Display
-- ------------------------------------------------------------

local ICON_SIZE = 48
local ICON_GAP = 20
local DISPLAY_HEIGHT = 70
-- Allow class reminders, XP food, two weapon stones,
-- and gathering tracking to appear together.
local MAX_REMINDERS = 8

local unlocked = false

local PET_REMINDER_GRACE_SECONDS = 2

local petReminderGraceUntil = 0
local petReminderTimerToken = 0

local battleShoutExpiresAt = 0
local battleShoutTimerToken = 0

local auraStateCache = {}
local auraNameToCacheKey = {}

local hasXPFood = false
local xpFoodItemCache = {}

local pendingXPFoodTooltips = {}

local availableStoneIcons = {}

-- Standard sharpening stones and weightstones.
-- Elemental Sharpening Stone works on melee weapons.
local WEAPON_STONE_TYPES = {
    -- Sharpening stones
    [2862] = "sharp",    -- Rough
    [287978] = "sharp",  -- Rough (Forever variant)
    [2863] = "sharp",    -- Coarse
    [2871] = "sharp",    -- Heavy
    [7964] = "sharp",    -- Solid
    [12404] = "sharp",   -- Dense
    [18262] = "any",     -- Elemental (original)
    [287980] = "any",    -- Elemental (Forever)

    -- Weightstones
    [3239] = "blunt",    -- Rough
    [3240] = "blunt",    -- Coarse
    [3241] = "blunt",    -- Heavy
    [7965] = "blunt",    -- Solid
    [12643] = "blunt",   -- Dense
}

local SHARP_WEAPON_SUBCLASSES = {
    [0] = true,  -- One-handed axes
    [1] = true,  -- Two-handed axes
    [6] = true,  -- Polearms
    [7] = true,  -- One-handed swords
    [8] = true,  -- Two-handed swords
    [15] = true, -- Daggers
}

local BLUNT_WEAPON_SUBCLASSES = {
    [4] = true,  -- One-handed maces
    [5] = true,  -- Two-handed maces
    [10] = true, -- Staves
}

local FIND_HERBS_SPELL_ID = 2383
local FIND_MINERALS_SPELL_ID = 2580


local XP_FOOD_TOOLTIP_TEXT =
    "experience gained from kills is increased by 5%"

local WELL_FED_AURA_NAME = "Well Fed"
local WELL_FED_ICON_SPELL_ID = 1248422

local SLEEPING_BAG_ITEM_ID = 211527
local WELL_RESTED_SPELL_ID = 429959

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
            label = "NO POISON",
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
            label = "NO IMBUE",
        }
    )
end

-- ------------------------------------------------------------
-- Pet reminder helpers
-- ------------------------------------------------------------

local function IsPetReminderSuppressed()
    if UnitOnTaxi("player") then
        return true
    end

    return GetTime() < petReminderGraceUntil
end


local function StartPetReminderGrace()
    petReminderTimerToken =
        petReminderTimerToken + 1

    local timerToken =
        petReminderTimerToken

    petReminderGraceUntil =
        GetTime() + PET_REMINDER_GRACE_SECONDS

    -- Hide any stale pet warning immediately.
    Reminders:Refresh()

    -- Check again after WoW has had time to restore
    -- pets that were temporarily hidden by a flight path.
    C_Timer.After(
        PET_REMINDER_GRACE_SECONDS,
        function()
            if timerToken
                ~= petReminderTimerToken then

                return
            end

            Reminders:Refresh()
        end
    )
end

-- ------------------------------------------------------------
-- Warlock pet
-- ------------------------------------------------------------

local WARLOCK_SUMMON_IMP_SPELL_ID = 688
local WARLOCK_DEMONIC_SACRIFICE_SPELL_ID = 18788

local WARLOCK_DEMONIC_SACRIFICE_AURAS = {
    18789, -- Burning Shadow
    18790, -- Fel Stamina
    18791, -- Touch of Fire
    18792, -- Fel Energy
}

local WARLOCK_DEMONIC_SACRIFICE_CACHE_KEY =
    GetAuraCacheKey(
        WARLOCK_DEMONIC_SACRIFICE_AURAS
    )


local function HasDemonicSacrifice()
    return HasAnyAura(
        WARLOCK_DEMONIC_SACRIFICE_AURAS,
        WARLOCK_DEMONIC_SACRIFICE_CACHE_KEY
    )
end


local function AddWarlockPetReminder(reminders)
    -- Summon Imp is available from level 1 and is our
    -- baseline indication that the normal demon system
    -- is available.
    if not C_SpellBook.IsSpellKnown(
        WARLOCK_SUMMON_IMP_SPELL_ID
    ) then
        return
    end

    if IsPetReminderSuppressed() then
        return
    end

    -- A living active demon means everything is fine.
    if UnitExists("pet")
        and not UnitIsDeadOrGhost("pet") then

        return
    end

    -- Demonic Sacrifice intentionally plays without
    -- the sacrificed demon.
    if HasDemonicSacrifice() then
        return
    end

    local icon =
        C_Spell.GetSpellTexture(
            WARLOCK_SUMMON_IMP_SPELL_ID
        )

    if not icon then
        return
    end

    table.insert(
        reminders,
        {
            icon = icon,
            label = "NO PET",
        }
    )
end

-- ------------------------------------------------------------
-- Hunter
-- ------------------------------------------------------------

local HUNTER_CALL_PET_SPELL_ID = 883
local HUNTER_REVIVE_PET_SPELL_ID = 982

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

local HUNTER_TRUESHOT_SPELLS = {
    20906,   -- Rank 5
    20905,   -- Rank 4
    19506,   -- Rank 3
    1299348, -- Rank 2
    1299346, -- Rank 1
}

local function HasLoneWolf()
    return GetKnownSpell(
        HUNTER_LONE_WOLF_SPELLS
    ) ~= nil
end


local function AddHunterPetReminder(reminders)
    -- Do not warn while pets are temporarily unavailable
    -- or being restored after a flight path.
    if IsPetReminderSuppressed() then
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

    -- Distinguish between an absent pet and a dead pet
    -- so the reminder points to the correct action.
    if UnitExists("pet") then
        if not UnitIsDeadOrGhost("pet") then
            return
        end

        local icon =
            C_Spell.GetSpellTexture(
                HUNTER_REVIVE_PET_SPELL_ID
            )
            or C_Spell.GetSpellTexture(
                HUNTER_CALL_PET_SPELL_ID
            )

        if not icon then
            return
        end

        table.insert(
            reminders,
            {
                icon = icon,
                label = "PET DEAD",
            }
        )

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
            label = "NO PET",
        }
    )
end

-- ------------------------------------------------------------
-- XP food
-- ------------------------------------------------------------

local function TooltipTextContainsXPBonus(text)
    if not text then
        return false
    end

    return string.find(
        string.lower(text),
        XP_FOOD_TOOLTIP_TEXT,
        1,
        true
    ) ~= nil
end



local function IsXPFoodItem(
    bag,
    slot,
    itemID
)
    -- Only consumable items can qualify as XP food.
    -- This excludes recipes and other non-consumables.
    local _, _, _, _, _, itemClassID =
        C_Item.GetItemInfoInstant(
            itemID
        )

    if itemClassID ~= Enum.ItemClass.Consumable then
        return false
    end

    if xpFoodItemCache[itemID] then
        return true
    end

    local tooltip =
        C_TooltipInfo.GetBagItem(
            bag,
            slot
        )

    -- Remember tooltip instances that may still
    -- receive asynchronous data updates.
    if tooltip and tooltip.dataInstanceID then
        pendingXPFoodTooltips[
            tooltip.dataInstanceID
        ] = true
    end

    if not tooltip
        or not tooltip.lines then

        return false
    end

    for _, line in ipairs(tooltip.lines) do
        if TooltipTextContainsXPBonus(
            line.leftText
        )
            or TooltipTextContainsXPBonus(
                line.rightText
            ) then

            xpFoodItemCache[itemID] = true
            return true
        end
    end

    return false
end


local function UpdateXPFoodBagState()
    hasXPFood = false
    wipe(pendingXPFoodTooltips)

    if not FL.db
        or not FL.db.reminders.xpFoodEnabled then

        return
    end

    for bag = 0, 4 do
        local numSlots =
            C_Container.GetContainerNumSlots(
                bag
            )

        for slot = 1, numSlots do
            local itemID =
                C_Container.GetContainerItemID(
                    bag,
                    slot
                )

            if itemID
                and IsXPFoodItem(
                    bag,
                    slot,
                    itemID
                ) then

                hasXPFood = true
                wipe(pendingXPFoodTooltips)
                return
            end
        end
    end
end


-- ------------------------------------------------------------
-- Weapon stone inventory
-- ------------------------------------------------------------

local function UpdateWeaponStoneBagState()
    availableStoneIcons = {}

    if not FL.db
        or not FL.db.reminders.weaponStoneEnabled then
        return
    end

    for bag = 0, 4 do
        local numSlots =
            C_Container.GetContainerNumSlots(
                bag
            )

        for slot = 1, numSlots do
            local itemID =
                C_Container.GetContainerItemID(
                    bag,
                    slot
                )

            local stoneType =
                itemID and WEAPON_STONE_TYPES[itemID]

            if stoneType
                and not availableStoneIcons[stoneType] then

                local _, _, _, _, requiredLevel =
                    C_Item.GetItemInfo(itemID)

                if not requiredLevel
                    or UnitLevel("player") >= requiredLevel then

                    local _, _, _, _, icon =
                        C_Item.GetItemInfoInstant(itemID)

                    if icon then
                        availableStoneIcons[stoneType] = icon
                    end
                end
            end
        end
    end
end

local function AddXPFoodReminder(reminders)
    if not FL.db.reminders.xpFoodEnabled then
        return
    end

    -- Eating is not actionable during combat or
    -- while travelling on a flight path.
    if UnitAffectingCombat("player")
        or UnitOnTaxi("player") then

        return
    end

    -- Stop reminding once the character can no
    -- longer gain experience.
    local maxXP =
        UnitXPMax("player")

    if not maxXP
        or maxXP <= 0 then

        return
    end

    -- Do not nag the player when they have no
    -- qualifying XP food available.
    if not hasXPFood then
        return
    end

    -- Do not mistake restricted aura information
    -- for a missing buff.
    if C_Secrets.ShouldAurasBeSecret() then
        return
    end

    -- The hidden XP aura cannot be queried directly,
    -- but nutritious XP food also applies a visible
    -- aura named Well Fed.
    local wellFed =
        C_UnitAuras.GetAuraDataBySpellName(
            "player",
            WELL_FED_AURA_NAME,
            "HELPFUL"
        )

    if wellFed then
        return
    end

    local icon =
        C_Spell.GetSpellTexture(
            WELL_FED_ICON_SPELL_ID
        )

    if not icon then
        return
    end

    table.insert(
        reminders,
        {
            icon = icon,
            label = "XP FOOD",
        }
    )
end


-- ------------------------------------------------------------
-- Weapon stone reminders
-- ------------------------------------------------------------

local function GetMissingWeaponStoneIcon(
    inventorySlot,
    weaponSlot
)
    local itemID =
        GetInventoryItemID(
            "player",
            inventorySlot
        )

    if not itemID then
        return nil
    end

    local _, _, _, _, _, classID, subClassID =
        C_Item.GetItemInfoInstant(
            itemID
        )

    if classID ~= Enum.ItemClass.Weapon then
        return nil
    end

    local stoneType

    if SHARP_WEAPON_SUBCLASSES[subClassID] then
        stoneType = "sharp"
    elseif BLUNT_WEAPON_SUBCLASSES[subClassID] then
        stoneType = "blunt"
    else
        return nil
    end

    local icon =
        availableStoneIcons[stoneType]
        or availableStoneIcons.any

    if not icon then
        return nil
    end

    local enchants =
        C_Item.GetWeaponEnchantInfo(
            weaponSlot
        ) or {}

    for _, enchant in ipairs(enchants) do
        if enchant.hasEnchant
            and enchant.enchantType
                == Enum.ItemEnchantType.Temporary then

            return nil
        end
    end

    return icon
end


local function AddWeaponStoneReminders(reminders)
    if not FL.db.reminders.weaponStoneEnabled then
        return
    end

    if UnitAffectingCombat("player")
        or UnitOnTaxi("player") then
        return
    end

    local mainHandIcon =
        GetMissingWeaponStoneIcon(
            16,
            Enum.WeaponSlot.MainHand
        )

    if mainHandIcon then
        table.insert(
            reminders,
            {
                icon = mainHandIcon,
                label = "MH STONE",
            }
        )
    end

    local offHandIcon =
        GetMissingWeaponStoneIcon(
            17,
            Enum.WeaponSlot.OffHand
        )

    if offHandIcon then
        table.insert(
            reminders,
            {
                icon = offHandIcon,
                label = "OH STONE",
            }
        )
    end
end


-- ------------------------------------------------------------
-- Gathering tracking reminder
-- ------------------------------------------------------------

local function AddGatheringTrackingReminder(reminders)
    if not FL.db.reminders.gatheringTrackingEnabled then
        return
    end

    if UnitAffectingCombat("player")
        or UnitOnTaxi("player") then
        return
    end

    local knowsHerbs =
        C_SpellBook.IsSpellKnown(
            FIND_HERBS_SPELL_ID
        )

    local knowsMinerals =
        C_SpellBook.IsSpellKnown(
            FIND_MINERALS_SPELL_ID
        )

    if not knowsHerbs
        and not knowsMinerals then
        return
    end

    local count =
        C_Minimap.GetNumTrackingTypes() or 0

    for index = 1, count do
        local info =
            C_Minimap.GetTrackingInfo(
                index
            )

        if info
            and info.active
            and (
                info.spellID == FIND_HERBS_SPELL_ID
                or info.spellID == FIND_MINERALS_SPELL_ID
            ) then
            return
        end
    end

    local spellID =
        knowsMinerals
        and FIND_MINERALS_SPELL_ID
        or FIND_HERBS_SPELL_ID

    local icon =
        C_Spell.GetSpellTexture(
            spellID
        )

    if not icon then
        return
    end

    table.insert(
        reminders,
        {
            icon = icon,
            label = "TRACK!",
        }
    )
end

-- ------------------------------------------------------------
-- Sleeping Bag
-- ------------------------------------------------------------

local function HasSleepingBag()
    for bag = 0, 4 do
        local numSlots =
            C_Container.GetContainerNumSlots(bag)

        for slot = 1, numSlots do
            local itemID =
                C_Container.GetContainerItemID(
                    bag,
                    slot
                )

            if itemID == SLEEPING_BAG_ITEM_ID then
                return true
            end
        end
    end

    return false
end

local function AddSleepingBagReminder(reminders)
    if not FL.db.reminders.sleepingBagEnabled then
        return
    end
    
    -- Hide during combat or while flying.
    if UnitAffectingCombat("player")
        or UnitOnTaxi("player") then
        return
    end

    -- Only relevant while leveling.
    if UnitLevel("player") >= 60 then
        return
    end

    local maxXP = UnitXPMax("player")

    if not maxXP or maxXP <= 0 then
        return
    end

    if not HasSleepingBag() then
        return
    end
    
    -- Only trust aura information when readable.
    if C_Secrets.ShouldAurasBeSecret() then
        return
    end

    -- Check the exact Well-Rested buff.
    local aura =
        C_UnitAuras.GetPlayerAuraBySpellID(
            WELL_RESTED_SPELL_ID
        )

    if aura then
        local stacks = aura.applications

        -- Avoid using restricted aura data.
        if issecretvalue
            and issecretvalue(stacks) then
            return
        end

        if type(stacks) ~= "number" then
            return
        end

        -- Only 3 stacks satisfy the reminder.
        if stacks >= 3 then
            return
        end
    end

    local _, _, _, _, icon =
        C_Item.GetItemInfoInstant(
            SLEEPING_BAG_ITEM_ID
        )

    if not icon then
        return
    end

    table.insert(
        reminders,
        {
            icon = icon,
            label = "REST!",
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


    -- XP food is a separate opt-in feature and can work
    -- even when class buff reminders are disabled.
    if not FL.db.reminders.enabled then
        AddXPFoodReminder(reminders)
        AddWeaponStoneReminders(reminders)
        AddGatheringTrackingReminder(reminders)
        AddSleepingBagReminder(reminders)

        return reminders
    end


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

        -- Divine Spirit.
        -- Prayer of Spirit also satisfies this reminder.
        AddSpellReminder(
            reminders,
            {
                27841, -- Rank 4
                14819, -- Rank 3
                14818, -- Rank 2
                14752, -- Rank 1
                27681, -- Prayer of Spirit
            },
            {
                14752, -- Divine Spirit
                27681, -- Prayer of Spirit
            },
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
                168,    -- Frost Armor
                7302,   -- Ice Armor
                6117,   -- Mage Armor
                428741, -- Molten Armor
            },
            "NO ARMOR"
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
            "NO ASPECT"
        )


        -- Keep Trueshot Aura active when the talent is known.
        AddSpellReminder(
            reminders,
            HUNTER_TRUESHOT_SPELLS,
            HUNTER_TRUESHOT_SPELLS,
            "NO TRUESHOT"
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

        AddWarlockPetReminder(
            reminders
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
            "NO AURA"
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

                -- Blessing of Kings
                20217, -- Kings
            },
            {
                -- Normal Blessings
                19740, -- Might
                19742, -- Wisdom
                20217, -- Kings

                -- Greater Blessings
                25782, -- Greater Might
                25894, -- Greater Wisdom
                25898, -- Greater Kings
            },
            "NO BLESSING"
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
            "NO SHIELD"
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


    AddXPFoodReminder(reminders)
    AddWeaponStoneReminders(reminders)
    AddGatheringTrackingReminder(reminders)
    AddSleepingBagReminder(reminders)

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
        or (
            not FL.db.reminders.enabled
            and not FL.db.reminders.xpFoodEnabled
            and not FL.db.reminders.weaponStoneEnabled
            and not FL.db.reminders.gatheringTrackingEnabled
            and not FL.db.reminders.sleepingBagEnabled
        ) then

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

function Reminders:RefreshXPFoodState()
    UpdateXPFoodBagState()
    self:Refresh()
end

function Reminders:RefreshWeaponStoneState()
    UpdateWeaponStoneBagState()
    self:Refresh()
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
    "TOOLTIP_DATA_UPDATE"
)

eventFrame:RegisterEvent(
    "WEAPON_ENCHANT_CHANGED"
)

eventFrame:RegisterEvent(
    "MINIMAP_UPDATE_TRACKING"
)

eventFrame:RegisterEvent(
    "PLAYER_ALIVE"
)

eventFrame:RegisterEvent(
    "PLAYER_UNGHOST"
)

eventFrame:RegisterEvent(
    "PLAYER_CONTROL_LOST"
)

eventFrame:RegisterEvent(
    "PLAYER_CONTROL_GAINED"
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
    "PLAYER_LEVEL_UP"
)

eventFrame:RegisterEvent(
    "BAG_UPDATE_DELAYED"
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
            UpdateXPFoodBagState()
            UpdateWeaponStoneBagState()

            Reminders:Refresh()

        elseif event == "BAG_UPDATE_DELAYED" then
            UpdateXPFoodBagState()
            UpdateWeaponStoneBagState()
            Reminders:Refresh()

        elseif event == "TOOLTIP_DATA_UPDATE" then
            local dataInstanceID = ...

            if dataInstanceID
                and pendingXPFoodTooltips[
                    dataInstanceID
                ] then

                UpdateXPFoodBagState()
                Reminders:Refresh()
            end

        elseif event == "PLAYER_LEVEL_UP" then
            C_Timer.After(
                0,
                function()
                    UpdateWeaponStoneBagState()
                    Reminders:Refresh()
                end
            )

        elseif event == "PLAYER_CONTROL_LOST" then
            -- Cancel any pending post-flight refresh.
            petReminderTimerToken =
                petReminderTimerToken + 1

            -- Let the taxi state settle before checking it.
            C_Timer.After(
                0,
                function()
                    Reminders:Refresh()
                end
            )


        elseif event == "PLAYER_CONTROL_GAINED" then
            StartPetReminderGrace()


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

                if spellID
                    == WARLOCK_DEMONIC_SACRIFICE_SPELL_ID then

                    auraStateCache[
                        WARLOCK_DEMONIC_SACRIFICE_CACHE_KEY
                    ] = true

                    shouldRefresh = true
                end

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