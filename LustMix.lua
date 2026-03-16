-- LustMix.lua: Core addon initialization + shared API
local addonName, addon = ...

_G.LustMix = addon

--------------------------------------------------
-- SavedVariables Initialization
--------------------------------------------------
local function InitDB()
    LustMixDB = LustMixDB or {}

    LustMixDB.version = LustMixDB.version or 1

    --------------------------------------------------
    -- Animation defaults
    --------------------------------------------------
    LustMixDB.animationStyle  = LustMixDB.animationStyle  or "LunaSnow.tga"
    LustMixDB.animationSize   = LustMixDB.animationSize   or 128
    LustMixDB.animationFPS    = LustMixDB.animationFPS    or 8
    LustMixDB.animationX      = LustMixDB.animationX      or 0
    LustMixDB.animationY      = LustMixDB.animationY      or 0
    LustMixDB.animationLocked = LustMixDB.animationLocked or false

    --------------------------------------------------
    -- Music defaults
    --------------------------------------------------
    LustMixDB.music =
        LustMixDB.music
        or "Interface\\AddOns\\LustMix\\Music\\LunaSnow.mp3"

    LustMixDB.volume       = LustMixDB.volume       or 1.0
    LustMixDB.soundChannel = LustMixDB.soundChannel or "Master"
    LustMixDB.muteSound    = LustMixDB.muteSound    or false

    --------------------------------------------------
    -- Fade defaults
    --------------------------------------------------
    LustMixDB.fadeIn  = LustMixDB.fadeIn  or 1.0
    LustMixDB.fadeOut = LustMixDB.fadeOut or 1.0

    --------------------------------------------------
    -- Preview Duration default
    --------------------------------------------------
    LustMixDB.previewDuration = LustMixDB.previewDuration or 40

    --------------------------------------------------
    -- Detection defaults
    --------------------------------------------------
    LustMixDB.hasteThreshold = LustMixDB.hasteThreshold or 25

    --------------------------------------------------
    -- Minimap defaults
    --------------------------------------------------
    LustMixDB.minimap = LustMixDB.minimap or {}
    if LustMixDB.minimap.hide == nil then LustMixDB.minimap.hide = false end
    if LustMixDB.minimap.locked == nil then LustMixDB.minimap.locked = false end

    --------------------------------------------------
    -- Debug
    --------------------------------------------------
    LustMixDB.debugMode = LustMixDB.debugMode or false
end

--------------------------------------------------
-- Event Handling
--------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")

f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        InitDB()
        if addon.OnAddonLoaded then addon:OnAddonLoaded() end

    elseif event == "PLAYER_LOGIN" then
        if addon.CreateMinimapButton then addon:CreateMinimapButton() end
        if addon.OnPlayerLogin then addon:OnPlayerLogin() end

        print("|cff00bfff[LustMix]|r Loaded. Type |cffff8800/lustmix|r for options.")
    end
end)

--------------------------------------------------
-- Slash Commands
--------------------------------------------------
SLASH_LUSTMIX1 = "/lustmix"
SLASH_LUSTMIX2 = "/lm"

SlashCmdList["LUSTMIX"] = function(msg)
    msg = msg:lower() or ""

    if msg == "settings" then
        if addon.ToggleSettings then addon:ToggleSettings() end

    elseif msg == "test" then
        if addon.StartAnimation then addon:StartAnimation() end
        if addon.TestMusic then addon:TestMusic() end

    elseif msg == "stop" then
        if addon.StopAnimation then addon:StopAnimation() end
        if addon.StopMusic then addon:StopMusic() end

    elseif msg == "status" then
        if addon.PrintStatus then addon:PrintStatus() end

    else
        print("|cff00bfff[LustMix Commands]|r")
        print("  /lustmix settings")
        print("  /lustmix test")
        print("  /lustmix stop")
        print("  /lustmix status")
    end
end

--------------------------------------------------
-- Public API (modules attach here)
--------------------------------------------------
addon.OnAddonLoaded = addon.OnAddonLoaded or nil
addon.OnPlayerLogin = addon.OnPlayerLogin or nil

addon.StartAnimation = addon.StartAnimation or nil
addon.StopAnimation  = addon.StopAnimation  or nil
addon.UpdateAnimationFPS = addon.UpdateAnimationFPS or nil
addon.UpdateAnimationTexture = addon.UpdateAnimationTexture or nil
addon.SetAnimationLocked = addon.SetAnimationLocked or nil

addon.TestMusic = addon.TestMusic or nil
addon.PlayLustMusic = addon.PlayLustMusic or nil
addon.StopMusic = addon.StopMusic or nil
addon.UpdateVolume = addon.UpdateVolume or nil
addon.SetSoundChannel = addon.SetSoundChannel or nil
addon.SetMuteSound = addon.SetMuteSound or nil

addon.ToggleSettings = addon.ToggleSettings or nil
addon.CreateMinimapButton = addon.CreateMinimapButton or nil
addon.PrintStatus = addon.PrintStatus or nil