-- Music.lua: Music playback engine for LustMix
local addonName, addon = ...

--------------------------------------------------
-- Music Source
--------------------------------------------------
local function GetMusicPath()
    local selected = LustMixDB.music

    if selected and selected ~= "" then
        return selected
    end

    local user = _G["LustMix_UserMusic"]
    if type(user) == "table" and user[1] then
        return "Interface\\AddOns\\LustMix\\Music\\" .. user[1]
    end

    return nil
end

--------------------------------------------------
-- State
--------------------------------------------------
local soundHandles = {}
local lastPlay = 0
local PLAY_COOLDOWN = 0.5

local originalVolume = nil
local cvarDirty = false

local fadeTicker = nil
local previewTimer = nil

local CHANNEL_CVARS = {
    Master   = "Sound_MasterVolume",
    SFX      = "Sound_SFXVolume",
    Dialog   = "Sound_DialogVolume",
    Music    = "Sound_MusicVolume",
    Ambience = "Sound_AmbienceVolume",
}

--------------------------------------------------
-- Helpers
--------------------------------------------------
local function CleanupHandles()
    for _, h in ipairs(soundHandles) do StopSound(h) end
    wipe(soundHandles)
end

local function RestoreVolume()
    if cvarDirty and originalVolume then
        local channel = LustMixDB.soundChannel or "Dialog"
        local cvar = CHANNEL_CVARS[channel]
        SetCVar(cvar, tostring(originalVolume))
    end

    cvarDirty = false
    originalVolume = nil
end

local function IsMuted(channel)
    if GetCVar("Sound_EnableAllSound") == "0" then return true end
    if tonumber(GetCVar("Sound_MasterVolume")) <= 0 then return true end

    local cvar = CHANNEL_CVARS[channel]
    if cvar and tonumber(GetCVar(cvar)) <= 0 then return true end

    return false
end

local function StopFade()
    if fadeTicker then
        fadeTicker:Cancel()
        fadeTicker = nil
    end
end

--------------------------------------------------
-- Fade In
--------------------------------------------------
local function FadeIn(targetVolume, duration)
    StopFade()

    if duration <= 0 then
        local channel = LustMixDB.soundChannel or "Dialog"
        local cvar = CHANNEL_CVARS[channel]
        SetCVar(cvar, tostring(targetVolume))
        return
    end

    local channel = LustMixDB.soundChannel or "Dialog"
    local cvar = CHANNEL_CVARS[channel]

    local steps = math.floor(duration / 0.05)
    if steps < 1 then steps = 1 end

    local increment = targetVolume / steps
    local current = 0

    SetCVar(cvar, "0")

    fadeTicker = C_Timer.NewTicker(0.05, function()
        current = current + increment
        if current >= targetVolume then
            SetCVar(cvar, tostring(targetVolume))
            StopFade()
        else
            SetCVar(cvar, tostring(current))
        end
    end)
end

--------------------------------------------------
-- Fade Out
--------------------------------------------------
local function FadeOut(duration, onDone)
    StopFade()

    local channel = LustMixDB.soundChannel or "Dialog"
    local cvar = CHANNEL_CVARS[channel]

    local startVol = tonumber(GetCVar(cvar)) or 1.0

    if duration <= 0 then
        SetCVar(cvar, "0")
        if onDone then onDone() end
        return
    end

    local steps = math.floor(duration / 0.05)
    if steps < 1 then steps = 1 end

    local decrement = startVol / steps
    local current = startVol

    fadeTicker = C_Timer.NewTicker(0.05, function()
        current = current - decrement
        if current <= 0 then
            SetCVar(cvar, "0")
            StopFade()
            if onDone then onDone() end
        else
            SetCVar(cvar, tostring(current))
        end
    end)
end

--------------------------------------------------
-- Play Music
--------------------------------------------------
local function PlayMusic()
    local now = GetTime()
    if now - lastPlay < PLAY_COOLDOWN then return end
    lastPlay = now

    CleanupHandles()
    RestoreVolume()
    StopFade()

    if LustMixDB.muteSound then return end

    local channel = LustMixDB.soundChannel or "Dialog"
    if IsMuted(channel) then return end

    local path = GetMusicPath()
    if not path then return end

    local cvar = CHANNEL_CVARS[channel]
    originalVolume = tonumber(GetCVar(cvar)) or 1.0
    cvarDirty = true

    -- Start silent
    SetCVar(cvar, "0")

    local ok, handle = PlaySoundFile(path, channel)
    if ok then soundHandles[1] = handle end

    -- Fade in
    FadeIn(LustMixDB.volume or 1.0, LustMixDB.fadeIn or 1.0)
end

--------------------------------------------------
-- Public API
--------------------------------------------------
function addon:TestMusic()
    PlayMusic()

    -- Cancel previous preview timer
    if previewTimer then
        previewTimer:Cancel()
        previewTimer = nil
    end

    -- Start new preview timer
    local duration = LustMixDB.previewDuration or 40
    previewTimer = C_Timer.NewTimer(duration, function()
        addon:StopMusic()
        previewTimer = nil
    end)
end

function addon:PlayLustMusic()
    PlayMusic()
end

function addon:StopMusic()
    StopFade()

    FadeOut(LustMixDB.fadeOut or 1.0, function()
        CleanupHandles()
        RestoreVolume()
    end)

    if previewTimer then
        previewTimer:Cancel()
        previewTimer = nil
    end
end

function addon:UpdateVolume(v)
    local channel = LustMixDB.soundChannel or "Dialog"
    local cvar = CHANNEL_CVARS[channel]

    if soundHandles[1] then
        SetCVar(cvar, tostring(v))
        cvarDirty = true
    end
end

function addon:SetSoundChannel(channel)
    RestoreVolume()
    LustMixDB.soundChannel = channel
end

function addon:SetMuteSound(muted)
    LustMixDB.muteSound = muted
    if muted then
        StopFade()
        CleanupHandles()
        RestoreVolume()
    end
end