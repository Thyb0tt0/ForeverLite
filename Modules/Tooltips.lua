local _, FL = ...

FL.Tooltips = FL.Tooltips or {}


-- ------------------------------------------------------------
-- Helpers
-- ------------------------------------------------------------

local function IsSecret(value)
    return issecretvalue
        and issecretvalue(value)
end


local function GetTooltipUnit(tooltip, tooltipData)
    if tooltipData
        and tooltipData.lines then

        for _, line in ipairs(tooltipData.lines) do
            if not IsSecret(line)
                and line.type == Enum.TooltipDataLineType.UnitName
                and line.unitToken
                and not IsSecret(line.unitToken) then

                return line.unitToken
            end
        end
    end

    if tooltip
        and tooltip.GetUnit then

        local _, unit =
            tooltip:GetUnit()

        if unit
            and not IsSecret(unit) then
            return unit
        end
    end

    return nil
end


local function GetGuildColor()
    local color = ChatTypeInfo["GUILD"]

    return color.r, color.g, color.b
end


local function StyleGuild(
    tooltip,
    tooltipName,
    unit
)
    local guildName =
        GetGuildInfo(unit)

    if not guildName
        or IsSecret(guildName) then
        return
    end

    local formattedGuild =
        "<" .. guildName .. ">"

    local guildR,
        guildG,
        guildB =
        GetGuildColor()

    for lineIndex = 2, tooltip:NumLines() do
        local line =
            _G[
                tooltipName
                .. "TextLeft"
                .. lineIndex
            ]

        if line then
            local text =
                line:GetText()

            if text
                and not IsSecret(text)
                and (
                    text == guildName
                    or text == formattedGuild
                ) then

                line:SetText(formattedGuild)

                line:SetTextColor(
                    guildR,
                    guildG,
                    guildB
                )

                break
            end
        end
    end
end


-- ------------------------------------------------------------
-- Player tooltip styling
-- ------------------------------------------------------------

local function EnhancePlayerTooltip(
    tooltip,
    tooltipData
)
    if not FL.db
        or not FL.db.tooltips.colorPlayerClass then
        return
    end

    if tooltip ~= GameTooltip then
        return
    end

    local unit =
        GetTooltipUnit(
            tooltip,
            tooltipData
        )

    if not unit then
        return
    end

    local isPlayer =
        UnitIsPlayer(unit)

    if IsSecret(isPlayer)
        or not isPlayer then
        return
    end

    local _, classFile =
        UnitClass(unit)

    if not classFile
        or IsSecret(classFile) then
        return
    end

    local classColor =
        RAID_CLASS_COLORS[classFile]

    if not classColor then
        return
    end

    local tooltipName =
        tooltip:GetName()

    if not tooltipName then
        return
    end


    -- --------------------------------------------------------
    -- Player name
    -- --------------------------------------------------------

    local nameLine =
        _G[
            tooltipName
            .. "TextLeft1"
        ]

    if nameLine then
        nameLine:SetTextColor(
            classColor.r,
            classColor.g,
            classColor.b
        )
    end


    -- --------------------------------------------------------
    -- Guild
    -- --------------------------------------------------------

    StyleGuild(
        tooltip,
        tooltipName,
        unit
    )
end


TooltipDataProcessor.AddTooltipPostCall(
    Enum.TooltipDataType.Unit,
    EnhancePlayerTooltip
)