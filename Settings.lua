-- Settings.lua: Settings window for LustMix
local addonName, addon = ...

local settingsFrame

--------------------------------------------------
-- Utility: Scan for user-added files
--------------------------------------------------
local function ScanUserList(globalName, ext)
    local results = {}
    local tbl = _G[globalName]

    if type(tbl) == "table" then
        for _, file in ipairs(tbl) do
            if type(file) == "string" and file:lower():match("%." .. ext .. "$") then
                table.insert(results, file)
            end
        end
    end

    return results
end

--------------------------------------------------
-- UI Sync
--------------------------------------------------
local function UpdateUI(f)
    if not f or not f.ui then return end
    local ui = f.ui

    -- Animation
    if ui.animDropdown then
        UIDropDownMenu_SetText(ui.animDropdown, LustMixDB.animationStyle)
    end
    if ui.sizeSlider then
        ui.sizeSlider:SetValue(LustMixDB.animationSize)
        ui.sizeLabel:SetText("Animation Size: " .. LustMixDB.animationSize .. " px")
    end
    if ui.fpsSlider then
        ui.fpsSlider:SetValue(LustMixDB.animationFPS)
        ui.fpsLabel:SetText("Animation Speed: " .. LustMixDB.animationFPS .. " FPS")
    end
    if ui.lockAnim then
        ui.lockAnim:SetChecked(LustMixDB.animationLocked)
    end

    -- Music
    if ui.musicDropdown then
        UIDropDownMenu_SetText(
            ui.musicDropdown,
            LustMixDB.music ~= "" and LustMixDB.music or "(Default)"
        )
    end
    if ui.volumeSlider then
        ui.volumeSlider:SetValue(LustMixDB.volume)
        ui.volumeLabel:SetText("Volume: " .. math.floor(LustMixDB.volume * 100) .. "%")
    end
    if ui.previewSlider then
        ui.previewSlider:SetValue(LustMixDB.previewDuration)
        ui.previewLabel:SetText("Preview Duration: " .. LustMixDB.previewDuration .. " sec")
    end
    if ui.fadeInSlider then
        ui.fadeInSlider:SetValue(LustMixDB.fadeIn)
        ui.fadeInLabel:SetText("Fade-In Duration: " .. LustMixDB.fadeIn .. " sec")
    end
    if ui.fadeOutSlider then
        ui.fadeOutSlider:SetValue(LustMixDB.fadeOut)
        ui.fadeOutLabel:SetText("Fade-Out Duration: " .. LustMixDB.fadeOut .. " sec")
    end
    if ui.muteCheck then
        ui.muteCheck:SetChecked(LustMixDB.muteSound)
    end

    -- Audio Channel
    if ui.channelRadios then
        for ch, btn in pairs(ui.channelRadios) do
            btn:SetChecked(LustMixDB.soundChannel == ch)
        end
    end

    -- Detection
    if ui.hasteSlider then
        ui.hasteSlider:SetValue(LustMixDB.hasteThreshold)
        ui.hasteLabel:SetText("Haste Threshold: " .. LustMixDB.hasteThreshold .. "%")
    end

    -- Minimap
    if ui.minimapCheck then
        ui.minimapCheck:SetChecked(not LustMixDB.minimap.hide)
    end

    -- Debug
    if ui.debugCheck then
        ui.debugCheck:SetChecked(LustMixDB.debugMode)
    end
end

--------------------------------------------------
-- Create Settings Window
--------------------------------------------------
local function CreateSettingsWindow()
    if settingsFrame then return settingsFrame end

    local WIDTH = 450
    local f = CreateFrame("Frame", "LustMixSettingsFrame", UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, 600)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetClampedToScreen(true)

    tinsert(UISpecialFrames, "LustMixSettingsFrame")

    f:SetBackdrop({
        bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
    f:SetBackdropColor(0, 0, 0, 0.88)

    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    f.title:SetPoint("TOP", 0, -15)
    f.title:SetText("|cff00bfffLustMix Settings|r")

    local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", -8, -8)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    --------------------------------------------------
    -- ScrollFrame
    --------------------------------------------------
    local scroll = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 10, -45)
    scroll:SetPoint("BOTTOMRIGHT", -30, 35)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(WIDTH - 50, 2400)
    scroll:SetScrollChild(content)

    local y = -10
    f.ui = {}

    local function Header(text)
        local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fs:SetPoint("TOPLEFT", 20, y)
        fs:SetText("|cffff8800" .. text .. "|r")
        y = y - 28
    end

    local function Label(text)
        local fs = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 25, y)
        fs:SetText(text)
        return fs
    end

    local function Sep()
        y = y - 8
        local line = content:CreateTexture(nil, "ARTWORK")
        line:SetSize(WIDTH - 60, 1)
        line:SetPoint("TOPLEFT", 10, y)
        line:SetColorTexture(0.3, 0.3, 0.3, 0.7)
        y = y - 12
    end

    local function Btn(x, w, text, fn)
        local b = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
        b:SetPoint("TOPLEFT", x, y)
        b:SetSize(w, 24)
        b:SetText(text)
        b:SetScript("OnClick", fn)
        return b
    end

    --------------------------------------------------
    -- SECTION: ANIMATION
    --------------------------------------------------
    Header("Animation")

    local animDropdown = CreateFrame("Frame", "LustMixAnimDropdown", content, "UIDropDownMenuTemplate")
    animDropdown:SetPoint("TOPLEFT", 20, y)

    local function InitAnimDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()

        local user = ScanUserList("LustMix_UserAnimations", "tga")
        for _, file in ipairs(user) do
            info.text = file
            info.value = file
            info.func = function()
                LustMixDB.animationStyle = file
                UIDropDownMenu_SetText(animDropdown, file)
                if addon.UpdateAnimationTexture then addon:UpdateAnimationTexture() end
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(animDropdown, InitAnimDropdown)
    UIDropDownMenu_SetWidth(animDropdown, 280)
    y = y - 40
    f.ui.animDropdown = animDropdown

    Btn(25, 185, "Test Animation", function()
        if addon.StartAnimation then addon:StartAnimation() end
    end)
    Btn(220, 185, "Stop Animation", function()
        if addon.StopAnimation then addon:StopAnimation() end
    end)
    y = y - 32

    local lockAnim = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    lockAnim:SetPoint("TOPLEFT", 25, y)
    lockAnim.text:SetText("Lock Position")
    lockAnim:SetChecked(LustMixDB.animationLocked)
    lockAnim:SetScript("OnClick", function(self)
        if addon.SetAnimationLocked then addon:SetAnimationLocked(self:GetChecked()) end
    end)
    f.ui.lockAnim = lockAnim
    y = y - 30

    local sizeLabel = Label("Animation Size: " .. LustMixDB.animationSize .. " px")
    y = y - 22
    local sizeSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    sizeSlider:SetPoint("TOPLEFT", 25, y)
    sizeSlider:SetWidth(380)
    sizeSlider:SetMinMaxValues(32, 512)
    sizeSlider:SetValue(LustMixDB.animationSize)
    sizeSlider:SetValueStep(16)
    sizeSlider:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v / 16) * 16
        LustMixDB.animationSize = v
        sizeLabel:SetText("Animation Size: " .. v .. " px")
        if _G["LustMixAnimFrame"] then
            _G["LustMixAnimFrame"]:SetSize(v, v)
        end
    end)
    f.ui.sizeSlider = sizeSlider
    f.ui.sizeLabel = sizeLabel
    y = y - 36

    local fpsLabel = Label("Animation Speed: " .. LustMixDB.animationFPS .. " FPS")
    y = y - 22
    local fpsSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    fpsSlider:SetPoint("TOPLEFT", 25, y)
    fpsSlider:SetWidth(380)
    fpsSlider:SetMinMaxValues(1, 30)
    fpsSlider:SetValue(LustMixDB.animationFPS)
    fpsSlider:SetValueStep(1)
    fpsSlider:SetScript("OnValueChanged", function(self, v)
        LustMixDB.animationFPS = v
        fpsLabel:SetText("Animation Speed: " .. v .. " FPS")
        if addon.UpdateAnimationFPS then addon:UpdateAnimationFPS(v) end
    end)
    f.ui.fpsSlider = fpsSlider
    f.ui.fpsLabel = fpsLabel
    y = y - 40

    Sep()

    --------------------------------------------------
    -- SECTION: MUSIC
    --------------------------------------------------
    Header("Music")

    local musicDropdown = CreateFrame("Frame", "LustMixMusicDropdown", content, "UIDropDownMenuTemplate")
    musicDropdown:SetPoint("TOPLEFT", 20, y)

    local function InitMusicDropdown(self, level)
        local info = UIDropDownMenu_CreateInfo()

        local user = ScanUserList("LustMix_UserMusic", "mp3")
        for _, file in ipairs(user) do
            local path = "Interface\\AddOns\\LustMix\\Music\\" .. file
            info.text = file
            info.value = path
            info.func = function()
                LustMixDB.music = path
                UIDropDownMenu_SetText(musicDropdown, file)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(musicDropdown, InitMusicDropdown)
    UIDropDownMenu_SetWidth(musicDropdown, 280)
    y = y - 40
    f.ui.musicDropdown = musicDropdown

    local volumeLabel = Label("Volume: " .. math.floor(LustMixDB.volume * 100) .. "%")
    y = y - 22
    local volumeSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    volumeSlider:SetPoint("TOPLEFT", 25, y)
    volumeSlider:SetWidth(380)
    volumeSlider:SetMinMaxValues(0, 1)
    volumeSlider:SetValue(LustMixDB.volume)
    volumeSlider:SetValueStep(0.05)
    volumeSlider:SetScript("OnValueChanged", function(self, v)
        LustMixDB.volume = v
        volumeLabel:SetText("Volume: " .. math.floor(v * 100) .. "%")
        if addon.UpdateVolume then addon:UpdateVolume(v) end
    end)
    f.ui.volumeSlider = volumeSlider
    f.ui.volumeLabel = volumeLabel
    y = y - 36

    -- PREVIEW DURATION SLIDER
    local previewLabel = Label("Preview Duration: " .. LustMixDB.previewDuration .. " sec")
    y = y - 22

    local previewSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    previewSlider:SetPoint("TOPLEFT", 25, y)
    previewSlider:SetWidth(380)
    previewSlider:SetMinMaxValues(5, 120)
    previewSlider:SetValue(LustMixDB.previewDuration)
    previewSlider:SetValueStep(5)

    previewSlider:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v)
        LustMixDB.previewDuration = v
        previewLabel:SetText("Preview Duration: " .. v .. " sec")
    end)

    f.ui.previewSlider = previewSlider
    f.ui.previewLabel = previewLabel
    y = y - 40

    -- FADE-IN SLIDER
    local fadeInLabel = Label("Fade-In Duration: " .. LustMixDB.fadeIn .. " sec")
    y = y - 22

    local fadeInSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    fadeInSlider:SetPoint("TOPLEFT", 25, y)
    fadeInSlider:SetWidth(380)
    fadeInSlider:SetMinMaxValues(0, 10)
    fadeInSlider:SetValue(LustMixDB.fadeIn)
    fadeInSlider:SetValueStep(0.1)

    fadeInSlider:SetScript("OnValueChanged", function(self, v)
        v = tonumber(string.format("%.1f", v))
        LustMixDB.fadeIn = v
        fadeInLabel:SetText("Fade-In Duration: " .. v .. " sec")
    end)

    f.ui.fadeInSlider = fadeInSlider
    f.ui.fadeInLabel = fadeInLabel
    y = y - 40

    -- FADE-OUT SLIDER
    local fadeOutLabel = Label("Fade-Out Duration: " .. LustMixDB.fadeOut .. " sec")
    y = y - 22

    local fadeOutSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    fadeOutSlider:SetPoint("TOPLEFT", 25, y)
    fadeOutSlider:SetWidth(380)
    fadeOutSlider:SetMinMaxValues(0, 10)
    fadeOutSlider:SetValue(LustMixDB.fadeOut)
    fadeOutSlider:SetValueStep(0.1)

    fadeOutSlider:SetScript("OnValueChanged", function(self, v)
        v = tonumber(string.format("%.1f", v))
        LustMixDB.fadeOut = v
        fadeOutLabel:SetText("Fade-Out Duration: " .. v .. " sec")
    end)

    f.ui.fadeOutSlider = fadeOutSlider
    f.ui.fadeOutLabel = fadeOutLabel
    y = y - 40

    local muteCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
    muteCheck:SetPoint("TOPLEFT", 25, y)
    muteCheck.text:SetText("Mute Sound")
    muteCheck:SetChecked(LustMixDB.muteSound)
    muteCheck:SetScript("OnClick", function(self)
        if addon.SetMuteSound then addon:SetMuteSound(self:GetChecked()) end
    end)
    f.ui.muteCheck = muteCheck
    y = y - 32

    Btn(25, 185, "Test Music", function()
        if addon.TestMusic then addon:TestMusic() end
    end)
    Btn(220, 185, "Stop Music", function()
        if addon.StopMusic then addon:StopMusic() end
    end)
    y = y - 32

    Sep()

    --------------------------------------------------
    -- SECTION: AUDIO CHANNEL
    --------------------------------------------------
    Header("Audio Channel")

    local channels = {
        "Master",
        "SFX",
        "Dialog",
        "Music",
        "Ambience",
    }

    local channelRadios = {}
    f.ui.channelRadios = channelRadios

    local function SetChannel(channel)
        LustMixDB.soundChannel = channel
        if addon.SetSoundChannel then addon:SetSoundChannel(channel) end
    end

    local yOffset = y

    for _, ch in ipairs(channels) do
        local btn = CreateFrame("CheckButton", nil, content, "UIRadioButtonTemplate")
        btn:SetPoint("TOPLEFT", 25, yOffset)
        btn.text:SetText(ch)
        btn:SetChecked(LustMixDB.soundChannel == ch)

        btn:SetScript("OnClick", function(self)
            for _, b in pairs(channelRadios) do b:SetChecked(false) end
            self:SetChecked(true)
            SetChannel(ch)
        end)

        channelRadios[ch] = btn
        yOffset = yOffset - 28
    end

    y = yOffset - 10

    Sep()

    --------------------------------------------------
    -- SECTION: DETECTION
    --------------------------------------------------
    Header("Detection")

    local hasteLabel = Label("Haste Threshold: " .. LustMixDB.hasteThreshold .. "%")
    y = y - 22
    local hasteSlider = CreateFrame("Slider", nil, content, "OptionsSliderTemplate")
    hasteSlider:SetPoint("TOPLEFT", 25, y)
    hasteSlider:SetWidth(380)
    hasteSlider:SetMinMaxValues(10, 50)
    hasteSlider:SetValue(LustMixDB.hasteThreshold)
    hasteSlider:SetValueStep(1)
    hasteSlider:SetScript("OnValueChanged", function(self, v)
        LustMixDB.hasteThreshold = v
        hasteLabel:SetText("Haste Threshold: " .. v .. "%")
    end)
    f.ui.hasteSlider = hasteSlider
    f.ui.hasteLabel = hasteLabel
    y = y - 40

    Sep()

    --------------------------------------------------
   --------------------------------------------------
-- SECTION: MINIMAP
--------------------------------------------------
Header("Minimap")

local minimapCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
minimapCheck:SetPoint("TOPLEFT", 25, y)
minimapCheck.text:SetText("Show Minimap Button")
minimapCheck:SetChecked(not LustMixDB.minimap.hide)

minimapCheck:SetScript("OnClick", function(self)
    local show = self:GetChecked()
    LustMixDB.minimap.hide = not show

    local btn = _G["LustMix_MinimapButton"]
    if show then
        if btn then btn:Show() else addon:CreateMinimapButton() end
    else
        if btn then btn:Hide() end
    end
end)

f.ui.minimapCheck = minimapCheck
y = y - 36

Sep()

--------------------------------------------------
-- SECTION: DEBUG
--------------------------------------------------
Header("Debug")

local debugCheck = CreateFrame("CheckButton", nil, content, "UICheckButtonTemplate")
debugCheck:SetPoint("TOPLEFT", 25, y)
debugCheck.text:SetText("Enable Debug Output")
debugCheck:SetChecked(LustMixDB.debugMode)

debugCheck:SetScript("OnClick", function(self)
    LustMixDB.debugMode = self:GetChecked()
    print("|cff00bfff[LustMix]|r Debug mode " ..
        (self:GetChecked() and "|cff00ff00enabled|r" or "|cffff0000disabled|r"))
end)

f.ui.debugCheck = debugCheck
y = y - 32

--------------------------------------------------
-- Finalize
--------------------------------------------------
content:SetSize(WIDTH - 50, math.abs(y) + 20)
f:Hide()

settingsFrame = f
return f
end

--------------------------------------------------
-- Public API
--------------------------------------------------
function addon:ToggleSettings()
    local f = settingsFrame or CreateSettingsWindow()
    if f:IsShown() then
        f:Hide()
    else
        UpdateUI(f)
        f:Show()
    end
end

function addon:ShowSettings()
    local f = settingsFrame or CreateSettingsWindow()
    UpdateUI(f)
    f:Show()
end

function addon:HideSettings()
    if settingsFrame then
        settingsFrame:Hide()
    end
end