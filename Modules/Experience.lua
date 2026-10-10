local addonName, FL = ...

FL.Experience = FL.Experience or {}

local Experience = FL.Experience


-- ------------------------------------------------------------
-- Tracker frame
-- ------------------------------------------------------------

local frame = CreateFrame(
    "Frame",
    "ForeverLiteXPTracker",
    UIParent
)

frame:SetSize(200, 64)
frame:SetClampedToScreen(true)
frame:SetMovable(true)
frame:EnableMouse(false)
frame:RegisterForDrag("LeftButton")

-- Temporary position until SavedVariables are loaded.
frame:SetPoint(
    "CENTER",
    UIParent,
    "CENTER",
    0,
    160
)

frame:Hide()


local xpText = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlight"
)

xpText:SetPoint(
    "TOPLEFT",
    frame,
    "TOPLEFT",
    0,
    0
)

xpText:SetJustifyH("LEFT")


local timeText = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlight"
)

timeText:SetPoint(
    "TOPLEFT",
    xpText,
    "BOTTOMLEFT",
    0,
    -3
)

timeText:SetJustifyH("LEFT")

local elapsedText = frame:CreateFontString(
    nil,
    "OVERLAY",
    "GameFontHighlight"
)

elapsedText:SetPoint(
    "TOPLEFT",
    timeText,
    "BOTTOMLEFT",
    0,
    -3
)

elapsedText:SetJustifyH("LEFT")


-- ------------------------------------------------------------
-- Session data
-- ------------------------------------------------------------

local sessionXP = 0
local startTime = nil
local lastXP = nil
local updateAccumulator = 0
local unlocked = false


-- ------------------------------------------------------------
-- Position
-- ------------------------------------------------------------

local function ApplySavedPosition()
    if not FL.db then
        return
    end

    local db = FL.db.experience

    frame:ClearAllPoints()

    frame:SetPoint(
        db.point or "CENTER",
        UIParent,
        db.relativePoint or "CENTER",
        db.x or 0,
        db.y or 160
    )
end


local function SavePosition()
    if not FL.db then
        return
    end

    local point, _, relativePoint, x, y =
        frame:GetPoint(1)

    local db = FL.db.experience

    db.point = point or "CENTER"
    db.relativePoint = relativePoint or "CENTER"
    db.x = x or 0
    db.y = y or 160
end


frame:SetScript("OnDragStart", function(self)
    if unlocked then
        self:StartMoving()
    end
end)


frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()

    SavePosition()
end)


-- ------------------------------------------------------------
-- Formatting
-- ------------------------------------------------------------

local function FormatXP(value)
    if value >= 1000000 then
        return string.format(
            "%.1fM",
            value / 1000000
        )

    elseif value >= 1000 then
        return string.format(
            "%.1fK",
            value / 1000
        )

    else
        return string.format(
            "%.0f",
            value
        )
    end
end


local function FormatTime(seconds)
    if seconds < 60 then
        return "<1m"
    end

    local totalMinutes = math.floor(
        seconds / 60 + 0.5
    )

    local hours = math.floor(
        totalMinutes / 60
    )

    local minutes = totalMinutes % 60

    if hours > 0 then
        return string.format(
            "%dh %02dm",
            hours,
            minutes
        )
    end

    return string.format(
        "%dm",
        minutes
    )
end

local function FormatElapsed(seconds)
    seconds = math.floor(seconds)

    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    local remainingSeconds = seconds % 60

    if hours > 0 then
        return string.format(
            "%dh %02dm %02ds",
            hours,
            minutes,
            remainingSeconds
        )
    elseif minutes > 0 then
        return string.format(
            "%dm %02ds",
            minutes,
            remainingSeconds
        )
    else
        return string.format(
            "%ds",
            remainingSeconds
        )
    end
end


-- ------------------------------------------------------------
-- Display
-- ------------------------------------------------------------

local function UpdateDisplay()
    if not FL.db
        or not FL.db.experience.enabled then
        return
    end

    local maxXP = UnitXPMax("player")

    if not maxXP or maxXP <= 0 then
        xpText:SetText("XP/hr: —")
        timeText:SetText("Time to level: Max level")
        return
    end

    local elapsed = 0

    if startTime then
        elapsed = GetTime() - startTime
    end

    elapsedText:SetText(
        "Session: " .. FormatElapsed(elapsed)
    )

    if sessionXP <= 0 or elapsed < 10 then
        xpText:SetText("XP/hr: —")
        timeText:SetText("Time to level: —")
        return
    end

    local xpPerHour =
        sessionXP / elapsed * 3600

    local currentXP =
        UnitXP("player")

    local remainingXP =
        math.max(
            maxXP - currentXP,
            0
        )

    local secondsToLevel =
        remainingXP / xpPerHour * 3600

    xpText:SetText(
        "XP/hr: " .. FormatXP(xpPerHour)
    )

    timeText:SetText(
        "Time to level: "
            .. FormatTime(secondsToLevel)
    )
end


-- ------------------------------------------------------------
-- Public functions
-- ------------------------------------------------------------

function Experience:Reset()
    sessionXP = 0
    startTime = GetTime()
    lastXP = UnitXP("player")

    UpdateDisplay()
end


function Experience:Refresh()
    if not FL.db
        or not FL.db.experience.enabled then

        unlocked = false
        frame:EnableMouse(false)
        frame:Hide()
        return
    end

    local wasShown = frame:IsShown()

    frame:Show()

    if not wasShown then
        self:Reset()
    else
        UpdateDisplay()
    end
end


function Experience:SetUnlocked(value)
    unlocked = value

    frame:EnableMouse(unlocked)

    if unlocked then
        frame:Show()
    else
        self:Refresh()
    end
end


function Experience:ResetPosition()
    if not FL.db then
        return
    end

    local db = FL.db.experience

    db.point = "CENTER"
    db.relativePoint = "CENTER"
    db.x = 0
    db.y = 160

    ApplySavedPosition()
end


-- ------------------------------------------------------------
-- XP tracking
-- ------------------------------------------------------------

local function HandleXPUpdate()
    local currentXP =
        UnitXP("player")

    if lastXP == nil then
        lastXP = currentXP
        return
    end

    if FL.db
        and FL.db.experience.enabled then

        local gainedXP =
            currentXP - lastXP

        if gainedXP > 0 then
            sessionXP =
                sessionXP + gainedXP
        end
    end

    lastXP = currentXP

    UpdateDisplay()
end


-- ------------------------------------------------------------
-- Display updates
-- ------------------------------------------------------------

frame:SetScript("OnUpdate", function(self, elapsed)
    updateAccumulator =
        updateAccumulator + elapsed

    if updateAccumulator < 1 then
        return
    end

    updateAccumulator = 0

    UpdateDisplay()
end)


-- ------------------------------------------------------------
-- Events
-- ------------------------------------------------------------

local eventFrame =
    CreateFrame("Frame")

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_XP_UPDATE")
eventFrame:RegisterEvent("PLAYER_LEVEL_UP")


eventFrame:SetScript(
    "OnEvent",
    function(self, event, ...)
        if event == "PLAYER_LOGIN" then
            lastXP = UnitXP("player")

            ApplySavedPosition()
            Experience:Refresh()

        elseif event == "PLAYER_XP_UPDATE" then
            local unit = ...

            if unit == "player" then
                HandleXPUpdate()
            end

        elseif event == "PLAYER_LEVEL_UP" then
            C_Timer.After(0, function()
                sessionXP = 0
                startTime = nil
                lastXP = UnitXP("player")

                if FL.db
                    and FL.db.experience.enabled then
                    Experience:Reset()
                end
            end)
        end
    end
)