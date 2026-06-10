local _, addon = ...

-- 1. Initialize Database
SoDRuneEnforcerDB = SoDRuneEnforcerDB or { phase = 1 }

-- 2. Define Local Data and Helpers
local L = {
    PHASE_SET = "Current enforcement set to: Phase %d",
    CHECKING = "Checking raid members for Phase %d compliance...",
    VIOLATION = "PLAYER: %s | CLASS: %s | SLOT: %s | INVALID RUNE: %s (Introduced in Phase %d)",
    ALL_CLEAR = "All raid members are compliant with Phase %d restrictions.",
    NOT_IN_RAID = "You are not in a raid group.",
    HELP = "SoD Rune Enforcer Commands:\n/sre phase [1-8] - Set current Phase (1=25, 2=40, 3=50, 4+=60)\n/sre check - Check all raid members\n/sre ui - Toggle control panel",
}

local slots = {
    ["Chest"] = 5, ["Hands"] = 10, ["Legs"] = 7, ["Waist"] = 6, ["Feet"] = 8,
    ["Head"] = 1, ["Wrist"] = 9, ["Back"] = 15, ["Ring1"] = 11, ["Ring2"] = 12,
}

local currentUnitIndex = 0
local isChecking = false
local raidMembers = {}
local mainFrame

-- Tooltip scanner
local scanner = CreateFrame("GameTooltip", "SREScanner", UIParent, "GameTooltipTemplate")
scanner:SetOwner(WorldFrame, "ANCHOR_NONE")

local function GetRuneNameFromSlot(unit, slotID)
    scanner:ClearLines()
    local link = GetInventoryItemLink(unit, slotID)
    if not link then return nil end
    scanner:SetInventoryItem(unit, slotID)
    for i = 1, scanner:NumLines() do
        local line = _G["SREScannerTextLeft"..i]
        if line then
            local text = line:GetText()
            if text then
                local runeName = text:match("^Engraved: (.+)")
                if runeName then return runeName end
                if text:match("^Rune of ") then return text end
            end
        end
    end
    return nil
end

local function GetRunePhase(className, runeName)
    if not addon.RuneData then return nil end
    local classData = addon.RuneData[className]
    if not classData then return nil end
    for phase, pSlots in pairs(classData) do
        for slot, runes in pairs(pSlots) do
            for _, name in ipairs(runes) do
                if name:lower() == runeName:lower() then return phase end
            end
        end
    end
    if addon.RingRunes and addon.RingRunes[runeName] then return addon.RingRunes[runeName] end
    return nil
end

local function PerformUnitCheck(unit)
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    if not class then return false end
    local foundViolation = false
    for slotName, slotID in pairs(slots) do
        local runeName = GetRuneNameFromSlot(unit, slotID)
        if runeName then
            local phase = GetRunePhase(class, runeName)
            if phase and phase > SoDRuneEnforcerDB.phase then
                print(string.format("|cffff0000[SRE] PHASE VIOLATION:|r %s", string.format(L.VIOLATION, name, class, slotName, runeName, phase)))
                foundViolation = true
            end
        end
    end
    return foundViolation
end

local function HighlightViolations()
    if not CharacterFrame or not CharacterFrame:IsVisible() then return end
    local _, class = UnitClass("player")
    for slotName, slotID in pairs(slots) do
        local btn = _G["Character" .. slotName .. "Slot"]
        if btn then
            if not btn.sreRuneWarning then
                btn.sreRuneWarning = btn:CreateTexture(nil, "OVERLAY")
                btn.sreRuneWarning:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
                btn.sreRuneWarning:SetAllPoints()
                btn.sreRuneWarning:SetBlendMode("ADD")
                btn.sreRuneWarning:SetVertexColor(1, 0, 0, 0.5)
                btn.sreRuneWarning:Hide()
            end
            local runeName = GetRuneNameFromSlot("player", slotID)
            local isViolation = false
            if runeName then
                local phase = GetRunePhase(class, runeName)
                if phase and phase > SoDRuneEnforcerDB.phase then isViolation = true end
            end
            if isViolation then btn.sreRuneWarning:Show() else btn.sreRuneWarning:Hide() end
        end
    end
end

local function CheckNextMember()
    if not isChecking then return end
    currentUnitIndex = currentUnitIndex + 1
    if currentUnitIndex > #raidMembers then
        print("|cff00ff00[SRE]|r Scan complete.")
        isChecking = false
        return
    end
    local unit = raidMembers[currentUnitIndex]
    local name = UnitName(unit) or unit
    if unit == "player" then
        PerformUnitCheck("player")
        CheckNextMember()
    elseif CanInspect(unit) then
        if CheckInteractDistance(unit, 4) then
            NotifyInspect(unit)
            C_Timer.After(2, function()
                if isChecking and raidMembers[currentUnitIndex] == unit then
                    print(string.format("|cffff0000[SRE]|r Skip %s (Inspect timeout)", name))
                    CheckNextMember()
                end
            end)
        else
            print(string.format("|cffff0000[SRE]|r Skip %s (Out of range)", name))
            CheckNextMember()
        end
    else
        CheckNextMember()
    end
end

local function CreateUI()
    if mainFrame then return end
    mainFrame = CreateFrame("Frame", "SREMainFrame", UIParent, "BasicFrameTemplateWithInset")
    mainFrame:SetSize(200, 250)
    mainFrame:SetPoint("CENTER")
    mainFrame:SetMovable(true)
    mainFrame:EnableMouse(true)
    mainFrame:RegisterForDrag("LeftButton")
    mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
    mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)
    mainFrame:Hide()

    mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY")
    mainFrame.title:SetFontObject("GameFontHighlight")
    mainFrame.title:SetPoint("TOP", 0, -5)
    mainFrame.title:SetText("SoD Rune Enforcer")

    local function CreatePhaseButton(p, label, yOffset)
        local btn = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
        btn:SetSize(140, 25)
        btn:SetPoint("TOP", 0, yOffset)
        btn:SetText(label)
        btn:SetScript("OnClick", function()
            SoDRuneEnforcerDB.phase = p
            print(string.format("|cff00ff00[SRE]|r " .. L.PHASE_SET, p))
            PerformUnitCheck("player")
            HighlightViolations()
        end)
        return btn
    end

    CreatePhaseButton(1, "Phase 1 (Lv 25)", -35)
    CreatePhaseButton(2, "Phase 2 (Lv 40)", -65)
    CreatePhaseButton(3, "Phase 3 (Lv 50)", -95)
    CreatePhaseButton(4, "Phase 4+ (Lv 60)", -125)

    local scanBtn = CreateFrame("Button", nil, mainFrame, "GameMenuButtonTemplate")
    scanBtn:SetSize(140, 30)
    scanBtn:SetPoint("TOP", 0, -180)
    scanBtn:SetText("SCAN GROUP")
    scanBtn:SetNormalFontObject("GameFontNormalLarge")
    scanBtn:SetScript("OnClick", function() SlashCmdList["SODRUNEENFORCER"]("check") end)
end

-- 3. Register Slash Command
SLASH_SODRUNEENFORCER1 = "/sre"
SlashCmdList["SODRUNEENFORCER"] = function(msg)
    local cmd, arg = msg:match("^(%S*)%s*(.-)$")
    if cmd == "phase" then
        local p = tonumber(arg)
        if p and p >= 1 and p <= 8 then
            SoDRuneEnforcerDB.phase = p
            print(string.format("|cff00ff00[SRE]|r " .. L.PHASE_SET, p))
            PerformUnitCheck("player")
            HighlightViolations()
        else
            print("|cffff0000[SRE]|r Invalid phase. Use /sre phase [1-8].")
        end
    elseif cmd == "ui" then
        CreateUI()
        if mainFrame:IsShown() then mainFrame:Hide() else mainFrame:Show(); PerformUnitCheck("player"); HighlightViolations() end
    elseif cmd == "check" then
        raidMembers = {}
        if IsInRaid() then
            for i = 1, GetNumGroupMembers() do table.insert(raidMembers, "raid"..i) end
        elseif IsInGroup() then
            for i = 1, GetNumGroupMembers() - 1 do table.insert(raidMembers, "party"..i) end
            table.insert(raidMembers, "player")
        else
            table.insert(raidMembers, "player")
        end
        currentUnitIndex = 0
        isChecking = true
        print(string.format("|cff00ff00[SRE]|r " .. L.CHECKING, SoDRuneEnforcerDB.phase))
        CheckNextMember()
    else
        print("|cff00ff00[SRE]|r " .. L.HELP)
    end
end

-- 4. Event Handler
local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("INSPECT_READY")
f:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")

f:SetScript("OnEvent", function(self, event, arg1, ...)
    if event == "ADDON_LOADED" and arg1 == "SoDRuneEnforcer" then
        SoDRuneEnforcerDB = SoDRuneEnforcerDB or { phase = 1 }
        CreateUI()
        print("|cff00ff00[SRE]|r Addon Loaded. Use /sre ui for control panel.")
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        if SoDRuneEnforcerDB then
            PerformUnitCheck("player")
            HighlightViolations()
        end
    elseif event == "INSPECT_READY" then
        local guid = arg1
        local unit = nil
        for _, u in ipairs(raidMembers) do
            if UnitGUID(u) == guid then
                unit = u
                break
            end
        end
        if unit and isChecking then
            PerformUnitCheck(unit)
            ClearInspectPlayer()
            CheckNextMember()
        end
    end
end)
