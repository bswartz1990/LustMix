-- Minimap.lua: Minimap button for LustMix
local addonName, addon = ...

local BUTTON_NAME = "LustMix_MinimapButton"

--------------------------------------------------
-- DB Init (minimap section only)
--------------------------------------------------
local function EnsureMinimapDB()
    LustMixDB.minimap = LustMixDB.minimap or {}

    if LustMixDB.minimap.hide == nil then
        LustMixDB.minimap.hide = false
    end
    if LustMixDB.minimap.locked == nil then
        LustMixDB.minimap.locked = false
    end

    -- Default position (225°)
    if not LustMixDB.minimap.x or not LustMixDB.minimap.y then
        local angle = math.rad(225)
        local radius = 105
        LustMixDB.minimap.x = math.cos(angle) * radius
        LustMixDB.minimap.y = math.sin(angle) * radius
    end
end

--------------------------------------------------
-- Positioning
--------------------------------------------------
local function UpdateButtonPosition(btn)
    local x = LustMixDB.minimap.x or 0
    local y = LustMixDB.minimap.y or 0
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

--------------------------------------------------
-- Fade Helpers
--------------------------------------------------
local function Fade(btn, target, duration)
    duration = duration or 0.15
    UIFrameFadeRemoveFrame(btn)

    local current = btn:GetAlpha()
    if math.abs(target - current) < 0.01 then return end

    if target > current then
        UIFrameFadeIn(btn, duration, current, target)
    else
        UIFrameFadeOut(btn, duration, current, target)
    end
end

--------------------------------------------------
-- Create Minimap Button
--------------------------------------------------
function addon:CreateMinimapButton()
    EnsureMinimapDB()

    if LustMixDB.minimap.hide then return end

    -- Already exists?
    if _G[BUTTON_NAME] then
        UpdateButtonPosition(_G[BUTTON_NAME])
        return _G[BUTTON_NAME]
    end

    local btn = CreateFrame("Button", BUTTON_NAME, Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel(8)
    btn:SetMovable(true)
    btn:EnableMouse(true)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    btn:SetClampedToScreen(true)
    btn:SetAlpha(0.01)

    --------------------------------------------------
    -- Border
    --------------------------------------------------
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetSize(53, 53)
    btn.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn.border:SetPoint("TOPLEFT")

    --------------------------------------------------
    -- Icon (placeholder until you give me the LustMix icon)
    --------------------------------------------------
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetSize(17, 17)
    btn.icon:SetTexture("Interface\\Icons\\Spell_Nature_BloodLust")
    btn.icon:SetPoint("CENTER")
    btn.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

    --------------------------------------------------
    -- Highlight
    --------------------------------------------------
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")

    --------------------------------------------------
    -- Tooltip
    --------------------------------------------------
    btn:SetScript("OnEnter", function(self)
        if LustMixDB.minimap.hide then return end

        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff00bfffLustMix|r")
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine("|cffff8800Left Click:|r", "Open Settings")
        if not LustMixDB.minimap.locked then
            GameTooltip:AddDoubleLine("|cffff8800Drag:|r", "Move Icon")
        end
        GameTooltip:AddDoubleLine("|cffff8800Right Click:|r", "Lock / Unlock")
        GameTooltip:AddLine(" ")

        local lock = LustMixDB.minimap.locked
            and "|cffff0000[Locked]|r"
            or  "|cff00ff00[Unlocked]|r"
        GameTooltip:AddLine(lock)

        GameTooltip:Show()

        if self.snapped then
            Fade(self, 1)
        end
    end)

    btn:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if self.snapped and not Minimap:IsMouseOver() then
            Fade(self, 0.01)
        end
    end)

    --------------------------------------------------
    -- Minimap hover reveal
    --------------------------------------------------
    Minimap:HookScript("OnEnter", function()
        if not btn.isDragging and btn.snapped and not LustMixDB.minimap.hide then
            Fade(btn, 1)
        end
    end)

    Minimap:HookScript("OnLeave", function()
        if not btn.isDragging and btn.snapped and not btn:IsMouseOver() then
            Fade(btn, 0.01)
        end
    end)

    --------------------------------------------------
    -- Click
    --------------------------------------------------
    btn:SetScript("OnClick", function(self, button)
        if button == "LeftButton" then
            if addon.ToggleSettings then addon:ToggleSettings() end

        elseif button == "RightButton" then
            LustMixDB.minimap.locked = not LustMixDB.minimap.locked
            print("|cff00bfff[LustMix]|r Minimap button " ..
                (LustMixDB.minimap.locked and "|cffff0000locked|r" or "|cff00ff00unlocked|r"))

            if GameTooltip:GetOwner() == self then
                self:GetScript("OnEnter")(self)
            end
        end
    end)

    --------------------------------------------------
    -- Dragging
    --------------------------------------------------
    btn:SetScript("OnDragStart", function(self)
        if LustMixDB.minimap.locked then
            print("|cff00bfff[LustMix]|r Minimap button is locked.")
            return
        end

        self.isDragging = true

        local minimap = Minimap
        local scale   = minimap:GetEffectiveScale()
        local mmCX, mmCY = minimap:GetCenter()
        local edgeRadius = (minimap:GetWidth() + self:GetWidth()) / 2
        local SNAP = edgeRadius - 5
        local PULL = edgeRadius + self:GetWidth() * 0.2
        local FREE = edgeRadius + self:GetWidth() * 0.7

        self:SetScript("OnUpdate", function(self)
            local cx, cy = GetCursorPosition()
            cx, cy = cx / scale, cy / scale
            local dx, dy = cx - mmCX, cy - mmCY
            local dist = math.sqrt(dx*dx + dy*dy)

            local clamp
            if dist <= SNAP then
                self.snapped = true
                clamp = SNAP
            elseif dist < PULL and self.snapped then
                clamp = SNAP
            elseif dist < FREE and self.snapped then
                clamp = SNAP + (dist - PULL) / 2
            else
                self.snapped = false
            end

            if clamp and dist > 0 then
                local f = clamp / dist
                dx, dy = dx * f, dy * f
            end

            LustMixDB.minimap.x = dx
            LustMixDB.minimap.y = dy
            self:SetPoint("CENTER", minimap, "CENTER", dx, dy)
        end)
    end)

    btn:SetScript("OnDragStop", function(self)
        self.isDragging = false
        self:SetScript("OnUpdate", nil)

        if self.snapped and Minimap:IsMouseOver() then
            Fade(self, 1)
        elseif self.snapped then
            Fade(self, 0.01)
        else
            Fade(self, 1)
        end
    end)

    --------------------------------------------------
    -- Cleanup on hide
    --------------------------------------------------
    btn:HookScript("OnHide", function(self)
        UIFrameFadeRemoveFrame(self)
        self:SetScript("OnUpdate", nil)
        self.isDragging = false
    end)

    --------------------------------------------------
    -- Initial state
    --------------------------------------------------
    local edge = (Minimap:GetWidth() + btn:GetWidth()) / 2
    local dist = math.sqrt(LustMixDB.minimap.x^2 + LustMixDB.minimap.y^2)
    btn.snapped = (dist <= edge + btn:GetWidth() * 0.3)

    btn:SetAlpha(btn.snapped and 0.01 or 1)
    UpdateButtonPosition(btn)

    return btn
end

--------------------------------------------------
-- Reset (called by /lustmix minimap reset)
--------------------------------------------------
function addon:ResetMinimapButton()
    local angle = math.rad(225)
    local radius = 105

    LustMixDB.minimap.x = math.cos(angle) * radius
    LustMixDB.minimap.y = math.sin(angle) * radius
    LustMixDB.minimap.hide = false
    LustMixDB.minimap.locked = false

    local btn = _G[BUTTON_NAME]
    if btn then
        btn.snapped = true
        btn:Show()
        btn:SetAlpha(0.01)
        UpdateButtonPosition(btn)
    else
        addon:CreateMinimapButton()
    end

    print("|cff00bfff[LustMix]|r Minimap button reset.")
end