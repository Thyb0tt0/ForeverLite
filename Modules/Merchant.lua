local _, FL = ...

FL.Merchant = FL.Merchant or {}

local Merchant = FL.Merchant


-- ------------------------------------------------------------
-- Money formatting
-- ------------------------------------------------------------

local function FormatMoney(copper)
    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local remainingCopper = copper % 100

    if gold > 0 then
        return string.format(
            "%dg %ds %dc",
            gold,
            silver,
            remainingCopper
        )
    elseif silver > 0 then
        return string.format(
            "%ds %dc",
            silver,
            remainingCopper
        )
    else
        return string.format(
            "%dc",
            remainingCopper
        )
    end
end


-- ------------------------------------------------------------
-- Auto repair
-- ------------------------------------------------------------

local function AutoRepair()
    if not FL.db
        or not FL.db.merchant.autoRepair then
        return
    end

    if not CanMerchantRepair() then
        return
    end

    local repairCost, canRepair =
        GetRepairAllCost()

    if not canRepair
        or not repairCost
        or repairCost <= 0 then
        return
    end

    if GetMoney() < repairCost then
        print(
            "|cff33ff99ForeverLite|r: "
            .. "Not enough money to repair. "
            .. "Cost: "
            .. FormatMoney(repairCost)
        )

        return
    end

    RepairAllItems()

    print(
        "|cff33ff99ForeverLite|r: "
        .. "Repaired equipment for "
        .. FormatMoney(repairCost)
        .. "."
    )
end


-- ------------------------------------------------------------
-- Auto sell junk
-- ------------------------------------------------------------

local function AutoSellJunk()
    if not FL.db
        or not FL.db.merchant.autoSellJunk then
        return
    end

    local soldItems = 0
    local totalValue = 0

    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        local numSlots =
            C_Container.GetContainerNumSlots(bag)

        for slot = 1, numSlots do
            local itemInfo =
                C_Container.GetContainerItemInfo(
                    bag,
                    slot
                )

            if itemInfo
                and itemInfo.quality == 0
                and itemInfo.stackCount
                and itemInfo.stackCount > 0 then

                local itemID =
                    itemInfo.itemID

                local sellPrice = 0

                if itemID then
                    local _, _, _, _, _, _, _, _, _, _, price =
                        C_Item.GetItemInfo(itemID)

                    sellPrice =
                        price or 0
                end

                totalValue =
                    totalValue
                    + (
                        sellPrice
                        * itemInfo.stackCount
                    )

                soldItems =
                    soldItems + 1

                C_Container.UseContainerItem(
                    bag,
                    slot
                )
            end
        end
    end

    if soldItems > 0 then
        print(
            "|cff33ff99ForeverLite|r: "
            .. "Sold "
            .. soldItems
            .. " junk item"
            .. (soldItems == 1 and "" or "s")
            .. " for "
            .. FormatMoney(totalValue)
            .. "."
        )
    end
end


-- ------------------------------------------------------------
-- Events
-- ------------------------------------------------------------

local eventFrame =
    CreateFrame("Frame")

eventFrame:RegisterEvent("MERCHANT_SHOW")

eventFrame:SetScript(
    "OnEvent",
    function(_, event)
        if event == "MERCHANT_SHOW" then
            AutoRepair()
            AutoSellJunk()
        end
    end
)