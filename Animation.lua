-- Animation.lua: LustMix animation engine using animState
local addonName, addon = ...

--------------------------------------------------
-- Animation State
--------------------------------------------------
local animState = {
    isPlaying = false,
    currentFrame = 0,
    frameCount = 32,  -- 4x8 sprite sheet
    columns = 4,
    rows = 8,
    fps = 8,
    ticker = nil,
}

local animFrame = nil
local animTexture = nil

--------------------------------------------------
-- Position Helpers
--------------------------------------------------
local function RestoreAnimationPosition()
    if not animFrame then return end

    local x = LustMixDB.animationX or 0
    local y = LustMixDB.animationY or 0

    animFrame:ClearAllPoints()
    animFrame:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

local function SaveAnimationPosition()
    if not animFrame then return end

    local cx, cy = animFrame:GetCenter()
    local ux, uy = UIParent:GetCenter()

    LustMixDB.animationX = cx - ux
    LustMixDB.animationY = cy - uy
end

--------------------------------------------------
-- Ticker Control
--------------------------------------------------
local function StopTicker()
    if animState.ticker then
        animState.ticker:Cancel()
        animState.ticker = nil
    end
end

local function StartTicker()
    StopTicker()

    if not animState.isPlaying then return end
    if animState.frameCount <= 1 then return end

    local interval = 1.0 / animState.fps

    animState.ticker = C_Timer.NewTicker(interval, function()
        if not animState.isPlaying then
            StopTicker()
            return
        end

        local frameIndex = animState.currentFrame
        if frameIndex >= animState.frameCount then
            frameIndex = 0
        end

        local col = frameIndex % animState.columns
        local row = math.floor(frameIndex / animState.columns)

        local fw = 1.0 / animState.columns
        local fh = 1.0 / animState.rows

        local left   = col * fw
        local right  = left + fw
        local top    = row * fh
        local bottom = top + fh

        animTexture:SetTexCoord(left, right, top, bottom)

        animState.currentFrame = (frameIndex + 1) % animState.frameCount
    end)
end

--------------------------------------------------
-- Frame Creation
--------------------------------------------------
local function CreateAnimationFrame()
    if animFrame then return animFrame end

    animFrame = CreateFrame("Frame", "LustMixAnimFrame", UIParent)
    animFrame:SetSize(LustMixDB.animationSize or 128, LustMixDB.animationSize or 128)
    animFrame:SetFrameStrata("FULLSCREEN_DIALOG")
    animFrame:SetMovable(true)
    animFrame:EnableMouse(true)
    animFrame:RegisterForDrag("LeftButton")

    animTexture = animFrame:CreateTexture(nil, "ARTWORK")
    animTexture:SetAllPoints()

    -- Dragging
    animFrame:SetScript("OnDragStart", function(self)
        if not LustMixDB.animationLocked then
            self:StartMoving()
        end
    end)

    animFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveAnimationPosition()
    end)

    RestoreAnimationPosition()

    return animFrame
end

--------------------------------------------------
-- Update Texture
--------------------------------------------------
function addon:UpdateAnimationTexture()
    CreateAnimationFrame()

    local style = LustMixDB.animationStyle or "none"

    if style == "none" then
        animFrame:Hide()
        animState.isPlaying = false
        StopTicker()
        return
    end

    if style == "text" then
        animTexture:SetTexture(nil)
        animTexture:SetColorTexture(1, 1, 1, 1)
        animTexture:SetTexCoord(0, 1, 0, 1)
        animFrame:Show()
        RestoreAnimationPosition()
        animState.isPlaying = false
        StopTicker()
        return
    end

    -- Real animation
    local path = "Interface\\AddOns\\LustMix\\Animations\\" .. style
    animTexture:SetTexture(path)

    animTexture:SetTexCoord(0, 1, 0, 1)

    animState.currentFrame = 0
    animState.frameCount = 32
    animState.columns = 4
    animState.rows = 8
    animState.fps = LustMixDB.animationFPS or 8

    animFrame:Show()
    RestoreAnimationPosition()

    if animState.isPlaying then
        StartTicker()
    end
end

--------------------------------------------------
-- Update FPS
--------------------------------------------------
function addon:UpdateAnimationFPS(v)
    animState.fps = v
    LustMixDB.animationFPS = v

    if animState.isPlaying then
        StartTicker()
    end
end

--------------------------------------------------
-- Update Size
--------------------------------------------------
function addon:UpdateAnimationSize(v)
    LustMixDB.animationSize = v

    if animFrame then
        animFrame:SetSize(v, v)
        RestoreAnimationPosition()
    end
end

--------------------------------------------------
-- Lock Toggle
--------------------------------------------------
function addon:SetAnimationLocked(locked)
    LustMixDB.animationLocked = locked
end

--------------------------------------------------
-- Start Animation
--------------------------------------------------
function addon:StartAnimation()
    CreateAnimationFrame()

    animState.isPlaying = true
    animState.currentFrame = 0

    self:UpdateAnimationTexture()
    StartTicker()
end

--------------------------------------------------
-- Stop Animation
--------------------------------------------------
function addon:StopAnimation()
    animState.isPlaying = false
    StopTicker()

    if animFrame then
        animFrame:Hide()
    end
end