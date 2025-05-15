local frame = CreateFrame("Frame")
frame:RegisterEvent("MERCHANT_SHOW")

frame:SetScript("OnEvent", function(self, event, ...)
    if not EmblemOfGoldFrame then
        CreateEmblemOfGoldFrame()
    else
        UpdateEmblemOfGold()
        EmblemOfGoldFrame:Show()
    end
end)

MerchantFrame:HookScript("OnHide", function()
    if EmblemOfGoldFrame then
        EmblemOfGoldFrame:Hide()
    end
end)

function CreateEmblemOfGoldFrame()
    local f = CreateFrame("Frame", "EmblemOfGoldFrame", MerchantFrame)
    f:SetHeight(20)
    f:SetWidth(MerchantFrame:GetWidth() - 20)
    f:SetPoint("TOPLEFT", MerchantFrame, "BOTTOMLEFT", 10, 10)

    f.bg = f:CreateTexture(nil, "BACKGROUND")
    f.bg:SetAllPoints()
    f.bg:SetTexture(0, 0, 0, 0.5)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.text:SetPoint("LEFT", f, "LEFT", 5, 0)
    f.text:SetJustifyH("LEFT")
    f.text:SetWidth(f:GetWidth() - 10)

    UpdateEmblemOfGold()
end

function UpdateEmblemOfGold()
    local gold = GetMoney()
    local goldStr = GetCoinTextureString(gold)

    local emblems = {
        { id = 40752, name = "Heroism" },
        { id = 40753, name = "Valor" },
        { id = 45624, name = "Conquest" },
        { id = 47241, name = "Triumph" },
        { id = 49426, name = "Frost" },
    }

    local parts = {}
    table.insert(parts, "Gold: " .. goldStr)

    for _, emblem in ipairs(emblems) do
        local count = GetItemCount(emblem.id)
        local icon = GetItemIcon(emblem.id)
        if icon then
            local tag = "|T" .. icon .. ":16:16:0:0|t" .. string.sub(emblem.name, 1, 1)
            table.insert(parts, tag .. ": " .. count)
        end
    end

    EmblemOfGoldFrame.text:SetText(table.concat(parts, " | "))
end

