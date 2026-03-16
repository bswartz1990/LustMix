-- Detection.lua: Haste spike detection for LustMix
local addonName, addon = ...

--------------------------------------------------
-- State
--------------------------------------------------
local isLusted = false
local baselineHaste = nil
local ticker = nil
local cooldownRemaining = 0

local CHECK_INTERVAL = 0.5
local LUST_COOLDOWN = 30

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function DebugPrint(...)
    if LustMixDB.debugMode then
        print("|cff00bfff[LustMix][DEBUG]|r", ...)
    end
end

local function GetCurrentHaste()
    return GetHaste() or 0
end

local function StopTicker()
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
end

local function StartTicker()
    StopTicker()

    ticker = C_Timer.NewTicker(CHECK_INTERVAL, function()
        -- Cooldown prevents retrigger spam
        if cooldownRemaining > 0 then
            cooldownRemaining = cooldownRemaining - CHECK_INTERVAL
            return
        end

        local current = GetCurrentHaste()

        if not baselineHaste then
            baselineHaste = current
            DebugPrint("Baseline set:", baselineHaste)
            return
        end

        local threshold = (LustMixDB.hasteThreshold or 25) / 100
        local increase = (current - baselineHaste) / 100

        -- Trigger
        if increase >= threshold and not isLusted then
            isLusted = true
            cooldownRemaining = LUST_COOLDOWN

            DebugPrint("Haste spike detected! Increase:", increase * 100 .. "%")

            if addon.StartAnimation then addon:StartAnimation() end
            if addon.PlayLustMusic then addon:PlayLustMusic() end

            return
        end

        -- End of lust
        if isLusted and increase < (threshold / 2) then
            DebugPrint("Lust ended. Resetting baseline.")

            isLusted = false
            baselineHaste = current
            cooldownRemaining = 0

            if addon.StopAnimation then addon:StopAnimation() end
            if addon.StopMusic then addon:StopMusic() end

            return
        end
    end)
end

--------------------------------------------------
-- Event Handling
--------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("PLAYER_REGEN_DISABLED")
f:RegisterEvent("PLAYER_REGEN_ENABLED")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        baselineHaste = GetCurrentHaste()
        DebugPrint("Loaded. Baseline haste:", baselineHaste)

    elseif event == "PLAYER_REGEN_DISABLED" then
        -- Entering combat
        baselineHaste = GetCurrentHaste()
        DebugPrint("Entering combat. Baseline:", baselineHaste)
        StartTicker()

    elseif event == "PLAYER_REGEN_ENABLED" then
        -- Leaving combat
        DebugPrint("Leaving combat. Stopping ticker.")
        StopTicker()

        if isLusted then
            isLusted = false
            if addon.StopAnimation then addon:StopAnimation() end
            if addon.StopMusic then addon:StopMusic() end
        end

        baselineHaste = GetCurrentHaste()
        cooldownRemaining = 0

    elseif event == "PLAYER_LOGOUT" then
        StopTicker()
    end
end)

--------------------------------------------------
-- Public API (used by /lustmix status)
--------------------------------------------------
function addon:PrintStatus()
    print("|cff00bfff[LustMix Status]|r")
    print("  Bloodlust active:", isLusted and "|cff00ff00YES|r" or "|cffff0000NO|r")
    print("  In combat:", InCombatLockdown() and "YES" or "NO")
    print(string.format("  Baseline haste: %.1f%%", baselineHaste or 0))
    print(string.format("  Current haste: %.1f%%", GetCurrentHaste()))
    print(string.format("  Cooldown remaining: %.1fs", cooldownRemaining))
    print("  Ticker active:", ticker and "YES" or "NO")
end

--------------------------------------------------
-- Module Hooks for Core.lua
--------------------------------------------------
function addon:OnAddonLoaded()
    -- Nothing needed yet
end

function addon:OnPlayerLogin()
    -- Minimap button is created by Minimap.lua
end