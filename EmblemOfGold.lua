-- Emblem of Gold
-- Shows your WotLK emblem counts (Heroism, Valor, Conquest, Triumph, Frost)
-- inside the vendor window, on the same row as the player's money.

local EMBLEMS = {
    { id = 40752, name = "Heroism" },
    { id = 40753, name = "Valor" },
    { id = 45624, name = "Conquest" },
    { id = 47241, name = "Triumph" },
    { id = 49426, name = "Frost" },
}

-- gap     = pixels between the badges and the player's gold.
--           bigger = badges move further left, negative = towards the gold.
-- spacing = how many spaces sit between each badge.
-- scale   = size multiplier for the number font and the icons (1 = same as gold).
-- Change these in game with:  /eog gap 40   /eog space 5   /eog scale 1.2   /eog reset
local SETTINGS_DEFAULTS = { gap = 24, spacing = 3, scale = 1 }

-- bump this whenever the defaults above change, so values saved by an older
-- copy of the addon do not keep overriding the new defaults
local CONFIG_VERSION = 2

local badgeBar
local moneyFrame
local settings

local function GetSettings()
    if type(EmblemOfGoldDB) ~= "table" then
        EmblemOfGoldDB = {}
    end
    settings = EmblemOfGoldDB
    if settings.configVersion ~= CONFIG_VERSION then
        settings.configVersion = CONFIG_VERSION
        for key, value in pairs(SETTINGS_DEFAULTS) do
            settings[key] = value
        end
    end
    for key, value in pairs(SETTINGS_DEFAULTS) do
        if type(settings[key]) ~= "number" then
            settings[key] = value
        end
    end
    return settings
end

-- ---------------------------------------------------------------- money frame

-- The merchant ui also has a money frame per item price and for the buyback
-- slot (MerchantItem3MoneyFrame, MerchantBuyBackItemMoneyFrame, ...). Those are
-- children of the item buttons; the player's own money frame is a direct child
-- of MerchantFrame, so only search that one level.
local function FindMerchantMoneyFrame()
    local byName = _G.MerchantMoneyFrame or _G.MerchantFrameMoneyFrame
    if byName and byName.GetName then
        return byName
    end

    if MerchantFrame then
        for i = 1, MerchantFrame:GetNumChildren() do
            local child = select(i, MerchantFrame:GetChildren())
            local name = child and child.GetName and child:GetName()
            -- every money frame has Gold/Silver/Copper button children
            if name and _G[name .. "GoldButton"] then
                return child
            end
        end
    end

    return nil
end

local function MoneyName(money)
    return money and money.GetName and money:GetName() or nil
end

-- Anchor to the actual coin graphics rather than the money frame box: the box
-- does not shrink to its contents, so its left edge is not the left edge of the
-- coins. The leftmost *visible* coin button is.
local function GetMoneyAnchor()
    local money = moneyFrame or FindMerchantMoneyFrame()
    if not money then
        return nil
    end
    moneyFrame = money

    local name = MoneyName(money)
    if name then
        for _, denomination in ipairs({ "Gold", "Silver", "Copper" }) do
            local button = _G[name .. denomination .. "Button"]
            if button and button:IsShown() then
                return button
            end
        end
    end

    return money
end

-- Read the font the money frame itself uses, so the badges come out the same
-- height as the gold, and the size of its coin icons.
local function GetMoneyStyle()
    local money = moneyFrame or FindMerchantMoneyFrame()
    if not money then
        return nil
    end
    moneyFrame = money
    local name = MoneyName(money)

    local style = { font = "Fonts\\FRIZQT__.TTF", size = 14, flags = "OUTLINE" }

    local text = name and _G[name .. "GoldButtonText"]
    if text and text.GetFont then
        local ok, font, size, flags = pcall(text.GetFont, text)
        if ok and font and size then
            style.font, style.size, style.flags = font, size, flags or ""
        end
    end

    local button = name and _G[name .. "GoldButton"]
    local texture = button and button.GetNormalTexture and button:GetNormalTexture()
    if texture and texture.GetWidth then
        local ok, width = pcall(texture.GetWidth, texture)
        if ok and type(width) == "number" and width >= 6 then
            style.iconSize = width
        end
    end
    if not style.iconSize then
        if money.small and MONEY_ICON_WIDTH_SMALL then
            style.iconSize = MONEY_ICON_WIDTH_SMALL
        else
            style.iconSize = MONEY_ICON_WIDTH or style.size
        end
    end

    return style
end

-- ------------------------------------------------------------------ badge bar

local function AnchorBadgeBar()
    if not badgeBar then
        return
    end
    badgeBar:ClearAllPoints()

    local anchor = GetMoneyAnchor()
    if anchor then
        badgeBar:SetPoint("RIGHT", anchor, "LEFT", -GetSettings().gap, 0)
        badgeBar:SetFrameLevel(anchor:GetFrameLevel() + 2)
    elseif MerchantFrame then
        badgeBar:SetPoint("BOTTOMRIGHT", MerchantFrame, "BOTTOMRIGHT", -180, 14)
        badgeBar:SetFrameLevel(MerchantFrame:GetFrameLevel() + 5)
    end
end

local function CreateBadgeBar()
    if badgeBar then
        return badgeBar
    end

    -- Child of MerchantFrame, so it shows and hides with the vendor window.
    badgeBar = CreateFrame("Frame", "EmblemOfGoldFrame", MerchantFrame)
    badgeBar:SetSize(20, 14)
    badgeBar:EnableMouse(true)

    badgeBar.text = badgeBar:CreateFontString(nil, "OVERLAY")
    badgeBar.text:SetPoint("RIGHT", badgeBar, "RIGHT", 0, 0)
    badgeBar.text:SetJustifyH("RIGHT")
    badgeBar.text:SetTextColor(1, 0.82, 0)

    badgeBar:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Emblem of Gold", 1, 0.82, 0)
        for _, emblem in ipairs(EMBLEMS) do
            GameTooltip:AddDoubleLine(emblem.name, GetItemCount(emblem.id))
        end
        GameTooltip:Show()
    end)
    badgeBar:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    AnchorBadgeBar()
    return badgeBar
end

local function UpdateBadgeBar()
    local bar = CreateBadgeBar()
    local settings = GetSettings()
    local style = GetMoneyStyle()

    local font, size, flags, iconSize
    if style then
        font = style.font
        size = style.size
        flags = style.flags
        iconSize = style.iconSize
    else
        font, size, flags, iconSize = "Fonts\\FRIZQT__.TTF", 14, "OUTLINE", 19
    end

    size = math.floor((size * settings.scale) + 0.5)
    iconSize = math.floor((iconSize * settings.scale) + 0.5)
    bar.text:SetFont(font, size, flags)
    bar.text:SetTextColor(1, 0.82, 0)
    bar:SetHeight(iconSize)

    local parts = {}
    for _, emblem in ipairs(EMBLEMS) do
        local count = GetItemCount(emblem.id)
        local icon = GetItemIcon(emblem.id)
        if icon then
            table.insert(parts, "|T" .. icon .. ":" .. iconSize .. ":" .. iconSize .. ":0:0|t " .. count)
        else
            table.insert(parts, count)
        end
    end

    bar.text:SetText(table.concat(parts, string.rep(" ", math.max(1, settings.spacing))))
    bar:SetWidth(math.max(bar.text:GetStringWidth(), 20))
    -- re-anchor every update so it follows the money row if Blizzard moves it
    AnchorBadgeBar()
end

local events = CreateFrame("Frame")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_UPDATE")
events:SetScript("OnEvent", UpdateBadgeBar)

-- ------------------------------------------------------------------- /eog

local function Describe(frame)
    if not frame or not frame.GetLeft then
        return "nil"
    end
    local name = frame.GetName and frame:GetName()
    if frame:GetLeft() == nil then
        return (name or "?") .. " (no rect)"
    end
    return string.format("%s  l=%.0f r=%.0f b=%.0f t=%.0f h=%.0f  shown=%s",
        name or "?", frame:GetLeft(), frame:GetRight(), frame:GetBottom(),
        frame:GetTop(), frame:GetHeight(), tostring(frame:IsShown()))
end

local function PrintDebug()
    local s = GetSettings()
    print(string.format("|cff00ff00Emblem of Gold|r v2.0   gap=%d  spacing=%d  scale=%.2f",
        s.gap, s.spacing, s.scale))
    print("  /eog gap <n>    moves the badges (bigger = further from the gold)")
    print("  /eog space <n>  space between each badge")
    print("  /eog scale <n>  badge size multiplier (1 = match the gold)")
    print("  /eog reset")
    print("  MerchantFrame: " .. Describe(MerchantFrame))
    print("  resolved money frame: " .. Describe(moneyFrame or FindMerchantMoneyFrame()))

    local money = moneyFrame or FindMerchantMoneyFrame()
    local name = MoneyName(money)
    if name then
        local text = _G[name .. "GoldButtonText"]
        if text and text.GetFont then
            local ok, font, size, flags = pcall(text.GetFont, text)
            print(string.format("  gold font: %s  size=%s  flags=%s", tostring(font), tostring(size), tostring(flags)))
        end
        print("  " .. name .. "GoldButtonText: " .. Describe(text))
        print("  " .. name .. "GoldButton: " .. Describe(_G[name .. "GoldButton"]))
    end

    print("  badge bar: " .. Describe(badgeBar))
    if badgeBar and badgeBar.text.GetFont then
        local _, badgeSize = badgeBar.text:GetFont()
        print("  badge font size: " .. tostring(badgeSize))
    end
end

SLASH_EMBLEMOFGOLD1 = "/eog"
SlashCmdList["EMBLEMOFGOLD"] = function(msg)
    local command, argument = string.match(msg or "", "^(%S*)%s*(.*)$")
    command = string.lower(command or "")
    local number = tonumber(argument)

    if command == "gap" and number then
        GetSettings().gap = number
        if badgeBar then UpdateBadgeBar() end
        print(string.format("Emblem of Gold: gap = %d", number))
    elseif (command == "space" or command == "spacing") and number then
        GetSettings().spacing = number
        if badgeBar then UpdateBadgeBar() end
        print(string.format("Emblem of Gold: spacing = %d", number))
    elseif command == "scale" and number and number > 0 then
        GetSettings().scale = number
        if badgeBar then UpdateBadgeBar() end
        print(string.format("Emblem of Gold: scale = %.2f", number))
    elseif command == "reset" then
        GetSettings()
        for key, value in pairs(SETTINGS_DEFAULTS) do
            settings[key] = value
        end
        if badgeBar then UpdateBadgeBar() end
        print("Emblem of Gold: settings reset")
    else
        PrintDebug()
    end
end
